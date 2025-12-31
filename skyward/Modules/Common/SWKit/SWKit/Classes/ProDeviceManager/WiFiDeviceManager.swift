//
//  WiFiDeviceError.swift
//  22222
//
//  Created by TXTS on 2025/12/10.
//


import Foundation
import Network

// MARK: - WiFi设备管理器
public class WiFiDeviceManager {
    
    public static let shared = WiFiDeviceManager()
    // MARK: - 配置
    var host: String = "192.168.0.7"
    var port: UInt16 = 2018
    private let maxRetryCount = 5
    private let timeoutInterval: TimeInterval = 10.0
    
    // MARK: - 网络连接
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "WiFiDeviceManagerQueue", qos: .userInitiated)
    
    // MARK: - 数据接收
    private var isReceiving = false
    private var receiveBuffer = Data()
    
    // MARK: - 线程安全存储（添加串行队列保护）
    private let storageQueue = DispatchQueue(label: "WiFiDeviceManager.StorageQueue")
    private var pendingResponses: [String: String] = [:] // [command: response]
    private var responseSemaphores: [String: DispatchSemaphore] = [:]
    private var lastCommandId = 0
    
    // MARK: - 状态
    public private(set) var isConnected = false
    public private(set) var isLogStreaming = false
    public private(set) var isNewVersionDeviece = true
    
    // MARK: - 回调
    public var onConnectionStatusChanged: ((Bool) -> Void)?
    public var onLogReceived: ((String) -> Void)?
    public var onNewVersionDevice: ((Bool) -> Void)?
    public var onError: ((Error) -> Void)?
    public var onDeviceWarning: ((FaultCodes) -> Void)?
    public var onStatusUpdate: ((ProDeviceStatus) -> Void)?
    
    // MARK: - 初始化
    init() {}
    
    deinit {
        disconnect()
    }
    
    // MARK: - 线程安全的字典操作方法
    private func setResponse(_ response: String, forKey key: String) {
        storageQueue.async(flags: .barrier) {
            self.pendingResponses[key] = response
        }
    }
    
    private func getResponse(forKey key: String) -> String? {
        var result: String?
        storageQueue.sync {
            result = self.pendingResponses[key]
        }
        return result
    }
    
    private func removeResponse(forKey key: String) {
        storageQueue.async(flags: .barrier) {
            self.pendingResponses.removeValue(forKey: key)
        }
    }
    
    private func setSemaphore(_ semaphore: DispatchSemaphore, forKey key: String) {
        storageQueue.async(flags: .barrier) {
            self.responseSemaphores[key] = semaphore
        }
    }
    
    private func getSemaphore(forKey key: String) -> DispatchSemaphore? {
        var result: DispatchSemaphore?
        storageQueue.sync {
            result = self.responseSemaphores[key]
        }
        return result
    }
    
    private func removeSemaphore(forKey key: String) {
        storageQueue.async(flags: .barrier) {
            self.responseSemaphores.removeValue(forKey: key)
        }
    }
    
    // MARK: - 连接管理
    public func connect(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        guard !isConnected else {
            print("设备已连接")
            completion?(.success(true))
            return
        }
        
        print("开始连接设备: \(host):\(port)")
        
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        
        let parameters = NWParameters.tcp
        connection = NWConnection(to: endpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            print("连接状态变化: \(state)")
            
            switch state {
            case .ready:
                print("连接就绪，开始接收数据")
                self.isConnected = true
                self.startReceiving()
                self.onConnectionStatusChanged?(true)
                self.saveCurrentDeviceAfterConnection()
                DispatchQueue.main.async {
                    completion?(.success(true))
                }
                
            case .failed(let error):
                print("连接失败: \(error)")
                self.isConnected = false
                self.isReceiving = false
                self.onConnectionStatusChanged?(false)
                self.cleanupConnection()
                DispatchQueue.main.async {
                    completion?(.failure(error))
                    self.onError?(error)
                }
                
            case .cancelled:
                print("连接取消")
                self.isConnected = false
                self.isReceiving = false
                self.onConnectionStatusChanged?(false)
                self.cleanupConnection()
                
            case .waiting(let error):
                print("连接等待: \(error)")
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
                
            case .preparing:
                print("连接准备中...")
            case .setup:
                print("setup-------------")
            @unknown default:
                print("未知连接状态")
            }
        }
        
        connection?.start(queue: queue)
    }
    
    public func disconnect() {
        print("断开设备连接")
        cleanupConnection()
    }
    
    private func cleanupConnection() {
        stopReceiving()
        connection?.cancel()
        connection = nil
        isConnected = false
        isLogStreaming = false
        receiveBuffer.removeAll()
        pendingResponses.removeAll()
        responseSemaphores.removeAll()
        
        DispatchQueue.main.async {
            self.onConnectionStatusChanged?(false)
        }
    }
    
    // MARK: - 数据接收处理
    private func startReceiving() {
        guard !isReceiving, let connection = connection else { return }
        
        isReceiving = true
        print("开始持续接收数据...")
        
        func receiveLoop() {
            guard isReceiving, isConnected else {
                print("停止接收数据")
                return
            }
            
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("接收数据错误: \(error)")
                    if self.isConnected {
                        // 重试接收
                        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                            receiveLoop()
                        }
                    }
                    return
                }
                
                if isComplete {
                    print("接收完成")
                    self.isReceiving = false
                    return
                }
                
                if let data = data, !data.isEmpty {
                    print("收到数据包，大小: \(data.count) 字节")
                    print("收到数据包，内容: \(data.hexString)")
                    self.processReceivedData(data)
                }
                
                // 继续接收下一个数据包
                receiveLoop()
            }
        }
        
        receiveLoop()
    }
    
    private func stopReceiving() {
        isReceiving = false
        print("停止接收数据")
    }
    
    private func processReceivedData(_ data: Data) {
        // 添加到缓冲区
        receiveBuffer.append(data)
        
        // 按换行符分割消息
        processBuffer()
    }
    
    private func processBuffer() {
        // 首先检查是否有完整的换行分隔消息
        while let newlineRange = receiveBuffer.firstRange(of: "\n".data(using: .ascii)!) {
            let messageData = receiveBuffer[..<newlineRange.lowerBound]
            receiveBuffer.removeSubrange(..<newlineRange.upperBound)
            
            if let message = String(data: messageData, encoding: .ascii) {
                let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                print("📨 收到换行分隔消息: \(trimmedMessage)")
                handleReceivedMessage(trimmedMessage)
            }
        }
        
        // ⚠️ 新增：检查是否有无换行符的完整消息
        // 假设消息以 $ 开头且长度合理（例如 2-100 字符）
        if receiveBuffer.count > 0 {
            // 尝试查找消息开始标记（比如 $）
            if let dollarIndex = receiveBuffer.firstIndex(of: 0x24) { // 0x24 = "$"
                let remainingData = receiveBuffer[dollarIndex...]
                
                // 尝试解析为ASCII字符串
                if let message = String(data: remainingData, encoding: .ascii) {
                    // 检查是否看起来像一个完整的消息
                    if isCompleteMessage(message) {
                        print("📨 收到无换行符消息: \(message)")
                        handleReceivedMessage(message)
                        
                        // 从缓冲区移除已处理的数据
                        receiveBuffer.removeSubrange(dollarIndex...)
                    }
                }
            }
        }
        
        // 清理过大的缓冲区
        if receiveBuffer.count > 10240 {
            receiveBuffer.removeFirst(receiveBuffer.count - 5120)
            print("接收缓冲区过大，已清理")
        }
    }

    private func isCompleteMessage(_ message: String) -> Bool {
        // 检查消息是否看起来完整
        let patterns = [
            "^\\$ACK,ER$",      // $ACK,ER
            "^\\$ACK,IN$",      // $ACK,IN
            "^\\$ACK,DS,\\d+$", // $ACK,DS,1
            "^OTA,.+$",         // OTA,START,ACK
            "^AUTOOFF,.+$",     // AUTOOFF响应
            // 添加其他可能的模式
        ]
        
        for pattern in patterns {
            if message.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - 消息处理
    private func handleReceivedMessage(_ message: String) {
        guard !message.isEmpty else { return }
        
        // 1. 检查是否是日志流数据
        if message.hasPrefix("$SHOW") {
            print("收到日志流: \(message)")
            DispatchQueue.main.async {
                self.onLogReceived?(message)
            }
            return
        }
        
        // 2. 检查是否是设备主动上报的消息
        if let warning = parseDeviceWarning(message) {
            print("设备主动上报告警: \(warning.description)")
            DispatchQueue.main.async {
                self.onDeviceWarning?(warning)
                self.onLogReceived?("⚠️ 设备告警: \(warning.description)")
                NotificationCenter.default.post(
                    name: .proDeviceWarningData,
                    object: nil,
                    userInfo: [
                        "warning": warning
                    ]
                )
            }
            return
        }
        
        if message.hasPrefix("REQAPPLOC") {
            print("设备请求手机定位: \(message)")
            DispatchQueue.main.async {
                self.onLogReceived?("📱 设备请求手机定位")
                guard let location = LocationManager.lastLocation() else { return }
                // 对中国经纬度进行限制处理
                var longitude = location.coordinate.longitude
                var latitude = location.coordinate.latitude
                
                // 中国经度范围：73°E 到 135°E
                // 东经为正，西经为负，所以都是正值
                if longitude > 135 {
                    longitude = 135
                } else if longitude < 73 {
                    longitude = 73
                }
                
                // 中国纬度范围：3°N 到 54°N
                // 北纬为正，南纬为负
                if latitude > 54 {
                    latitude = 54
                } else if latitude < 3 {
                    latitude = 3
                }
                self.uploadPhoneLoc(longitude: longitude, latitude: latitude, altitude: location.altitude) { ruselt in
                    
                }
            }
            return
        }
        
        // 3. 检查是否是命令响应
        if let (commandKey, response) = parseCommandResponse(message) {
            print("命令响应[\(commandKey)]: \(response)")
            
            // 存储响应并通知等待的调用者
            queue.async {
                self.pendingResponses[commandKey] = response
                self.responseSemaphores[commandKey]?.signal()
            }
            
            return
        }
        
        // 4. 检查是否是状态更新
        if let status = ProDeviceStatus(from: extractResponseContent(message)) {
            print("设备状态更新")
            DispatchQueue.main.async {
                self.onStatusUpdate?(status)
            }
            return
        }
        
        // 5. 其他未知消息
        print("收到未知消息: \(message)")
        DispatchQueue.main.async {
            self.onLogReceived?("📨 收到: \(message)")
        }
    }
    
    // MARK: - 日志缓冲区管理
    private var logBuffer: [String] = []
    private let logBufferLock = NSLock()

    private func appendToLogBuffer(_ log: String) {
        logBufferLock.lock()
        defer { logBufferLock.unlock() }
        logBuffer.append(log)
    }

    private func clearLogBuffer() {
        logBufferLock.lock()
        defer { logBufferLock.unlock() }
        logBuffer.removeAll()
    }

    private func getLogBuffer() -> [String] {
        logBufferLock.lock()
        defer { logBufferLock.unlock() }
        return logBuffer
    }
    
    // MARK: - 命令响应解析
    private func parseCommandResponse(_ message: String) -> (String, String)? {
        
        print("应答消息---\(message)")
        
        if message.hasPrefix("$ACK,ER") {
            print("🔍 匹配到擦除成功响应")
            return ("BINARY_DATA", message)
        }
        if message.hasPrefix("$ACK,IN") {
            return ("BINARY_DATA", message)
        }
        if message.hasPrefix("$ACK,DS") {
            return ("BINARY_DATA", message)
        }
        if message.hasPrefix("$ACK") {
            return ("BINARY_DATA", message)  // 通用的ACK响应
        }
        if message.hasPrefix("OTA,START,ACK") {
            print("🔍 匹配到OTA开始响应")
            return ("OTA", message)  // 这里返回的命令键必须和 sendCommand 时使用的一致
        }
        if message.hasPrefix("OTA,END,OK") {
            print("🔍 匹配到OTA结束响应")
            return ("OTA", message)
        }
        if message.hasPrefix("OTA") {
            print("🔍 匹配到OTA通用响应")
            return ("OTA", message)
        }
        
        // 支持的命令列表
        let commandPrefixes = [
            "AUTOOFF": "AUTOOFF",
            "AUTOSATALI": "AUTOSATALI",
            "HAFSATALI": "AUTOSATALI",
            "DEEPSLEEP": "DEEPSLEEP",
            "REQENV": "REQENV",
            "REQLOC": "REQLOC",
            "RESET": "RESET",
            "RESET_ACU": "RESET_ACU",
            "DEV_WARING": "DEV_WARING",
            "REQDEV_INFO": "REQDEV_INFO",
            "REQ_BEACON": "REQ_BEACON",
            "REQ_LOG": "REQ_LOG",
            "LOG_SWON": "LOG_SWON",
            "LOG_SWOFF": "LOG_SWOFF",
            "OTA,START": "OTA,START",
            "OTA,END": "OTA,END",
            "OTA_START": "OTA_START",
            "OTA_END": "OTA_END"
        ]
        
        for (key, prefix) in commandPrefixes {
            if message.hasPrefix(prefix) {
                // 返回命令键和完整响应
                return (key, message)
            }
        }
        
        return nil
    }
    
    private func parseDeviceWarning(_ message: String) -> FaultCodes? {
        guard message.hasPrefix("DEV_WARING") else { return nil }
        
        let content = extractResponseContent(message)
        let components = content.components(separatedBy: ",")
        let codes = components.compactMap { Int($0) }
        
        guard codes.count >= 5 else { return nil }
        
        return FaultCodes(codes: codes)
    }
    
    private func extractResponseContent(_ response: String) -> String {
        // 移除命令前缀和可能的逗号
        let components = response.components(separatedBy: ",")
        guard components.count > 1 else { return response }
        
        // 返回逗号后的内容
        return components[1...].joined(separator: ",")
    }
    
    // MARK: - 命令发送
    func sendCommand(_ command: String,
                   retryCount: Int = 0,
                   completion: @escaping (Result<String, Error>) -> Void) {
        
        guard let connection = connection, isConnected else {
            print("❌ 发送命令失败: 设备未连接")
            completion(.failure(WiFiDeviceError.disconnected))
            return
        }
        
        // 生成命令ID用于追踪
        _ = "\(command)_\(Date().timeIntervalSince1970)"
        let commandKey = command.components(separatedBy: ",").first ?? command
        let fullCommand = command + "\n"
        
        
        guard let data = fullCommand.data(using: .ascii) else {
            print("❌ 命令编码失败: \(command)")
            completion(.failure(WiFiDeviceError.invalidResponse))
            return
        }
        
        print("📤 发送命令[\(commandKey)]: \(command)")
        
        // 创建信号量用于等待响应
        let semaphore = DispatchSemaphore(value: 0)
        responseSemaphores[commandKey] = semaphore
        
        // 设置超时
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if retryCount < self.maxRetryCount {
                print("⏰ 命令[\(commandKey)]超时，重试第 \(retryCount + 1) 次")
                self.responseSemaphores.removeValue(forKey: commandKey)
                self.sendCommand(command, retryCount: retryCount + 1, completion: completion)
            } else {
                print("❌ 命令[\(commandKey)]超时，已达最大重试次数")
                self.responseSemaphores.removeValue(forKey: commandKey)
                completion(.failure(WiFiDeviceError.timeout))
            }
        }
        
        queue.asyncAfter(deadline: .now() + timeoutInterval, execute: timeoutWorkItem)
        
        // 发送命令
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            timeoutWorkItem.cancel()
            
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 命令[\(commandKey)]发送失败: \(error)")
                self.responseSemaphores.removeValue(forKey: commandKey)
                
                if retryCount < self.maxRetryCount {
                    self.sendCommand(command, retryCount: retryCount + 1, completion: completion)
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            print("✓ 命令[\(commandKey)]发送成功，等待响应...")
            
            // 等待响应
            DispatchQueue.global().async {
                let waitResult = semaphore.wait(timeout: .now() + self.timeoutInterval)
                
                defer {
                    self.responseSemaphores.removeValue(forKey: commandKey)
                }
                
                if waitResult == .timedOut {
                    print("❌ 等待命令[\(commandKey)]响应超时")
                    completion(.failure(WiFiDeviceError.timeout))
                    return
                }
                
                // 获取响应
                if let response = self.pendingResponses[commandKey] {
                    print("📥 命令[\(commandKey)]收到响应: \(response)")
                    self.pendingResponses.removeValue(forKey: commandKey)
                    completion(.success(response))
                } else {
                    print("❌ 命令[\(commandKey)]没有收到响应")
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            }
        })
    }
    
    // MARK: - 设备命令接口
    
    /// 一键收藏
    public func autoOff(completion: @escaping (Result<Bool, Error>) -> Void) {
        sendCommand("AUTOOFF") { result in
            switch result {
            case .success(let response):
                let success = parseSuccessResponse(response)
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 一键自动对星
    public func autoSatellite(mode: Int, completion: @escaping (Result<SatelliteAlignmentResult, Error>) -> Void) {
        var command = "AUTOSATALI,\(mode)"
        if !isNewVersionDeviece {
            command = "AUTOSATALI"
        }
        sendCommand(command) { result in
            switch result {
            case .success(let response):
                if let result = SatelliteAlignmentResult(from: response) {
                    completion(.success(result))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 一键半自动对星
    public func halfSatellite(longitude: Double, latitude: Double, altitude: Double, mode: Int,
                      completion: @escaping (Result<SatelliteAlignmentResult, Error>) -> Void) {
        var command = String(format: "HAFSATALI,%.6f,%.6f,%.2f,%d", longitude, latitude, altitude, mode)
        if !isNewVersionDeviece {
            command = String(format: "HAFSATALI,%.6f,%.6f,%.2f", longitude, latitude, altitude)
        }
        sendCommand(command) { result in
            switch result {
            case .success(let response):
                if let result = SatelliteAlignmentResult(from: response) {
                    completion(.success(result))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 低功耗模式开关
    public func deepSleep(enable: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        if isNewVersionDeviece {
            let command = enable ? "DEEPSLEEP,ON" : "DEEPSLEEP,OFF"
            sendCommand(command) { result in
                switch result {
                case .success(let response):
                    let expectedPrefix = enable ? "DEEPSLEEP,ON" : "DEEPSLEEP,OFF"
                    let success = response.hasPrefix(expectedPrefix) && parseSuccessResponse(response)
                    completion(.success(success))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }else {
            let command = enable ? "DEEPSLEEP_ON" : "DEEPSLEEP_OFF"
            sendCommand(command) { result in
                switch result {
                case .success(let response):
                    let expectedPrefix = enable ? "DEEPSLEEP_ON" : "DEEPSLEEP_OFF"
                    let success = response.hasPrefix(expectedPrefix) && parseSuccessResponse(response)
                    completion(.success(success))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 环境查询
    public func queryEnvironment(completion: @escaping (Result<EnvironmentInfo, Error>) -> Void) {
        sendCommand("REQENV") { result in
            switch result {
            case .success(let response):
                if let info = EnvironmentInfo(from: self.extractResponseContent(response)) {
                    completion(.success(info))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 终端状态查询
    public func queryLocation(completion: @escaping (Result<ProDeviceStatus, Error>) -> Void) {
        sendCommand("REQLOC") { result in
            switch result {
            case .success(let response):
                if let status = ProDeviceStatus(from: self.extractResponseContent(response)) {
                    completion(.success(status))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 老版终端状态查询
    public func queryLocation(completion: @escaping (Result<OldProDeviceStatus, Error>) -> Void) {
        sendCommand("REQLOC") { result in
            switch result {
            case .success(let response):
                if let status = OldProDeviceStatus(from: self.extractResponseContent(response)) {
                    completion(.success(status))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 全局复位重启
    public func reset(completion: @escaping (Result<Bool, Error>) -> Void) {
        sendCommand("RESET") { result in
            switch result {
            case .success(let response):
                let success = response.hasPrefix("RESET,ACK")
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 重启ACU
    public func resetACU(completion: @escaping (Result<Bool, Error>) -> Void) {
        sendCommand("RESET_ACU") { result in
            switch result {
            case .success(let response):
                let success = response.hasPrefix("RESET_ACU,ACK")
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 上传手机定位信息
    public func uploadPhoneLoc(longitude: Double, latitude: Double, altitude: Double,
                      completion: @escaping (Result<SatelliteAlignmentResult, Error>) -> Void) {
        let command = String(format: "REQAPPLOC,%.2f,%.6f,%.6f",altitude, longitude, latitude)
        sendCommand(command) { _ in
            
        }
    }
    
    /// 获取设备告警
    public func queryDeviceWarning(completion: @escaping (Result<FaultCodes, Error>) -> Void) {
        sendCommand("DEV_WARING") { result in
            switch result {
            case .success(let response):
                if let faultCodes = self.parseDeviceWarning(response) {
                    completion(.success(faultCodes))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 获取设备信息
    public func queryDeviceInfo(completion: @escaping (Result<ProDeviceInfo, Error>) -> Void) {
        sendCommand("REQDEV_INFO") { result in
            switch result {
            case .success(let response):
                if let info = ProDeviceInfo(from: self.extractResponseContent(response)) {
                    self.isNewVersionDeviece = true
                    self.onNewVersionDevice?(true)
                    NotificationCenter.default.post(
                        name: .proDeviceInfoData,
                        object: nil,
                        userInfo: [
                            "info": info
                        ]
                    )
                    completion(.success(info))
                } else {
                    self.isNewVersionDeviece = false
                    self.onNewVersionDevice?(false)
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                self.isNewVersionDeviece = false
                self.onNewVersionDevice?(false)
                completion(.failure(error))
            }
        }
    }
    
    /// 获取信标信号强度
    public func queryBeaconSignal(completion: @escaping (Result<Double, Error>) -> Void) {
        sendCommand("REQ_BEACON") { result in
            switch result {
            case .success(let response):
                let content = self.extractResponseContent(response)
                if let signal = Double(content) {
                    completion(.success(signal))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 获取ACU设备存储日志
    public func queryLog(completion: @escaping (Result<[String], Error>) -> Void) {
        sendCommand("REQ_LOG") { result in
            switch result {
            case .success(let response):
                var logs: [String] = []
                let lines = response.components(separatedBy: "\n")
                
                for line in lines {
                    if line.hasPrefix("$SHOW") {
                        logs.append(line)
                    } else if line.contains("REQ_LOG,OVER") {
                        break
                    }
                }
                
                completion(.success(logs))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    /// 获取ACU设备存储日志
    /// 命令: REQ_LOG\n
    /// 响应格式: REQ_LOG,$SHOW,...\n (多条)
    /// 结束符: REQ_LOG,OVER\n
    public func queryStoredLogs(completion: @escaping (Result<[String], Error>) -> Void) {
        // 清空缓冲区
        clearLogBuffer()
        
        // 创建信号量用于等待日志结束
        let semaphore = DispatchSemaphore(value: 0)
        self.setSemaphore(semaphore, forKey: "REQ_LOG")
        
        // 设置超时（例如60秒后超时）
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            print("存储日志接收超时")
            self.removeSemaphore(forKey: "REQ_LOG")
            
            let logs = self.getLogBuffer()
            if logs.isEmpty {
                completion(.failure(WiFiDeviceError.timeout))
            } else {
                print("存储日志接收超时，但已收到 \(logs.count) 条日志")
                completion(.success(logs))
            }
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 60.0, execute: timeoutWorkItem)
        
        // 保存原始日志回调
        let originalLogCallback = self.onLogReceived
        
        // 临时设置存储日志处理回调
        self.onLogReceived = { [weak self] message in
            guard let self = self else { return }
            
            if message.hasPrefix("REQ_LOG,$SHOW") {
                // 提取日志内容（移除REQ_LOG,前缀）
                let logContent = message.replacingOccurrences(of: "REQ_LOG,", with: "")
                print("收到存储日志: \(logContent)")
                self.appendToLogBuffer(logContent)
            } else if message.hasPrefix("REQ_LOG,OVER") {
                print("存储日志传输结束")
                
                // 取消超时
                timeoutWorkItem.cancel()
                
                // 恢复原始回调
                self.onLogReceived = originalLogCallback
                
                // 通知信号量
                if let semaphore = self.getSemaphore(forKey: "REQ_LOG") {
                    semaphore.signal()
                }
            }
        }
    }
    
    /// ACU设备实时日志传输打开
    public func enableLogStreaming(completion: @escaping (Result<Bool, Error>) -> Void) {
        sendCommand("LOG_SWON") { [weak self] result in
            switch result {
            case .success(let response):
                let success = response.hasPrefix("LOG_SWON,ACK")
                if success {
                    self?.isLogStreaming = true
                }
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// ACU设备实时日志传输关闭
    public func disableLogStreaming(completion: @escaping (Result<Bool, Error>) -> Void) {
        sendCommand("LOG_SWOFF") { [weak self] result in
            switch result {
            case .success(let response):
                let success = response.hasPrefix("LOG_SWOFF,ACK")
                if success {
                    self?.isLogStreaming = false
                }
                completion(.success(success))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

// MARK: - 响应解析辅助函数
public func parseSuccessResponse(_ response: String) -> Bool {
    let upperResponse = response.uppercased()
    
    // 成功标识
    let successIndicators = ["SUCCESS", "OK", "SUCCEED", "成功", "ACK", "YES"]
    let failureIndicators = ["FAILED", "FAIL", "FALLED", "ERROR", "失败", "错误", "NO"]
    
    // 检查成功标识
    for indicator in successIndicators {
        if upperResponse.contains(indicator) {
            return true
        }
    }
    
    // 检查失败标识
    for indicator in failureIndicators {
        if upperResponse.contains(indicator) {
            return false
        }
    }
    
    // 默认返回 true（假设响应格式正确）
    return true
}

// MARK: - 扩展用于调试
extension WiFiDeviceManager {
    func testConnection(completion: @escaping (Result<Bool, Error>) -> Void) {
        sendCommand("TEST") { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendRawCommand(_ command: String, completion: @escaping (Result<String, Error>) -> Void) {
        sendCommand(command, completion: completion)
    }
}


// 在 WiFiDeviceManager.swift 中添加
extension WiFiDeviceManager {
    
    /// 发送二进制数据
    func sendBinaryData(_ data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard isConnected, let connection = connection else {
            completion(.failure(WiFiDeviceError.disconnected))
            return
        }
        
        // 使用简短的命令键
        let commandKey = "BINARY_DATA"
        
        print("📤 发送二进制数据，大小: \(data.count) 字节")
        print("📤 发送二进制数据，内容: \(data.hexString)")
        
        // 创建信号量
        let semaphore = DispatchSemaphore(value: 0)
        responseSemaphores[commandKey] = semaphore
        
        // 设置超时
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.responseSemaphores.removeValue(forKey: commandKey)
            completion(.failure(WiFiDeviceError.timeout))
        }
        
        queue.asyncAfter(deadline: .now() + timeoutInterval, execute: timeoutWorkItem)
        
        // 发送二进制数据
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            timeoutWorkItem.cancel()
            
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 发送二进制数据失败: \(error)")
                self.responseSemaphores.removeValue(forKey: commandKey)
                completion(.failure(error))
                return
            }
            
            print("✓ 二进制数据发送成功，等待响应...")
            
            // 等待响应
            DispatchQueue.global().async {
                let waitResult = semaphore.wait(timeout: .now() + self.timeoutInterval)
                
                defer {
                    self.responseSemaphores.removeValue(forKey: commandKey)
                }
                
                if waitResult == .timedOut {
                    print("❌ 等待二进制数据响应超时")
                    completion(.failure(WiFiDeviceError.timeout))
                    return
                }
                
                // 获取响应
                if let response = self.pendingResponses[commandKey] {
                    print("📥 收到二进制数据响应: \(response)")
                    self.pendingResponses.removeValue(forKey: commandKey)
                    completion(.success(response))
                } else {
                    print("❌ 没有收到二进制数据响应")
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            }
        })
    }
    

}

extension WiFiDeviceManager {
    
    /// 获取当前Wi-Fi的BSSID（伪代码，实际需要获取真实BSSID）
    private func getCurrentBSSID() -> String? {
        // 注意：在iOS上获取BSSID需要特殊权限
        // 这里提供一个模拟实现
        
        // 实际项目中可以使用：
        // 1. NetworkExtension框架
        // 2. 使用设备的唯一标识（如序列号）
        // 3. 或者让用户手动输入/选择
        
        // 模拟返回一个基于IP地址的标识
        return "MAC_\(host.replacingOccurrences(of: ".", with: "_"))"
    }
    
    /// 连接成功后保存设备信息
    public func saveCurrentDeviceAfterConnection() {
        guard isConnected else {
            print("设备未连接，无法保存")
            return
        }
        
        // 获取设备标识（这里可以根据实际情况调整）
        guard let identifier = getCurrentBSSID() else {
            print("无法获取设备标识")
            return
        }
        
        // 更新或创建设备记录
        WiFiDeviceStorageManager.shared.updateConnectionInfo(
            identifier: identifier,
            host: host,
            port: port
        )
        
        // 更新连接状态
        WiFiDeviceStorageManager.shared.updateDeviceStatus(
            identifier: identifier,
            isConnected: true
        )
        
        print("设备连接信息已保存: \(identifier)")
    }
    
    /// 设备断开时更新状态
    public func updateDeviceOnDisconnect() {
        guard let identifier = getCurrentBSSID() else { return }
        
        WiFiDeviceStorageManager.shared.updateDeviceStatus(
            identifier: identifier,
            isConnected: false
        )
        
        print("设备断开状态已更新: \(identifier)")
    }
    
    /// 对星状态变化时更新
    public func updateSatelliteTrackingStatus(_ isTracking: Bool) {
        guard let identifier = getCurrentBSSID() else { return }
        
        WiFiDeviceStorageManager.shared.updateDeviceStatus(
            identifier: identifier,
            isTrackingSatellite: isTracking
        )
        
        let statusText = isTracking ? "对星成功" : "对星失败"
        print("设备对星状态已更新: \(statusText)")
    }
    
    /// 获取最近连接的设备（用于快速重连）
    public func getRecentDevice() -> (host: String, port: UInt16)? {
        let devices = WiFiDeviceStorageManager.shared.getAllDevices()
        
        // 优先返回最近连接过的已连接设备
        if let connectedDevice = devices.first(where: { $0.isConnected && !$0.host.isEmpty }) {
            return (connectedDevice.host, connectedDevice.port)
        }
        
        // 返回最近更新过的设备
        if let recentDevice = devices.first(where: { !$0.host.isEmpty }) {
            return (recentDevice.host, recentDevice.port)
        }
        
        return nil
    }
    
    /// 重连最近设备
    public func reconnectToRecentDevice(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let recentDevice = getRecentDevice() else {
            completion(.failure(WiFiDeviceError.disconnected))
            return
        }
        
        // 更新连接信息
        host = recentDevice.host
        port = recentDevice.port
        
        // 重新连接
        connect(completion: completion)
    }
}


public extension Notification.Name {
    static let proDeviceWarningData = Notification.Name("proDeviceWarningData")
    static let proDeviceInfoData = Notification.Name("proDeviceInfoData")
}
