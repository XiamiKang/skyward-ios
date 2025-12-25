//
//  WiFiDeviceError.swift
//  22222
//
//  Created by TXTS on 2025/12/10.
//


import Foundation
import Network

// MARK: - 错误枚举
enum WiFiDeviceError: Error, LocalizedError {
    case connectionFailed
    case timeout
    case invalidResponse
    case commandFailed(String)
    case disconnected
    case networkError(String)
    case invalidCommand
    case deviceBusy
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "连接设备失败"
        case .timeout:
            return "操作超时"
        case .invalidResponse:
            return "设备返回无效响应"
        case .commandFailed(let reason):
            return "命令执行失败: \(reason)"
        case .disconnected:
            return "设备未连接"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidCommand:
            return "无效命令格式"
        case .deviceBusy:
            return "设备繁忙，请稍后再试"
        }
    }
}


// MARK: - 天线锁定状态
enum LockStatus: Int {
    case unlocked = 0
    case locked = 1
    
    var description: String {
        return self == .locked ? "已锁定" : "未锁定"
    }
}

// MARK: - 天线运行状态
enum AntennaStatus: Int {
    case stored = 1
    case waitingGPS = 2
    case waitingIMU = 4
    case searching = 8
    case stableTracking = 10
    
    var description: String {
        switch self {
        case .stored: return "收藏"
        case .waitingGPS: return "等待GPS定位"
        case .waitingIMU: return "等待惯导信息"
        case .searching: return "搜索寻星"
        case .stableTracking: return "稳定跟踪"
        }
    }
}

// MARK: - 故障码结构
struct FaultCodes {
    let imu: Int
    let beidou: Int
    let beacon: Int
    let lnb: Int
    let buc: Int
    
    init(codes: [Int]) {
        self.imu = codes.count > 0 ? codes[0] : 0
        self.beidou = codes.count > 1 ? codes[1] : 0
        self.beacon = codes.count > 2 ? codes[2] : 0
        self.lnb = codes.count > 3 ? codes[3] : 0
        self.buc = codes.count > 4 ? codes[4] : 0
    }
    
    var description: String {
        var issues: [String] = []
        if imu == 1 { issues.append("惯导通信异常") }
        if beidou == 1 { issues.append("北斗通信异常") }
        if beacon == 1 { issues.append("信标机通信异常") }
        if lnb == 1 { issues.append("LNB通信异常") }
        if buc == 1 { issues.append("BUC通信异常") }
        return issues.isEmpty ? "设备正常" : issues.joined(separator: ", ")
    }
    
    var isNormal: Bool {
        return imu == 0 && beidou == 0 && beacon == 0 && lnb == 0 && buc == 0
    }
}

// MARK: - 设备信息
public struct ProDeviceInfo {
    let ACUVersion: String
    let deviceSN: String
    let catMAC: String
    let catSN: String
    
    init?(from response: String) {
        let components = response.components(separatedBy: ",")
        guard components.count >= 4 else { return nil }
        
        self.ACUVersion = components[0]
        self.deviceSN = components[1]
        self.catMAC = components[2]
        self.catSN = components[3]
    }
}

// MARK: - 设备状态信息
// MARK: - 完善设备状态
struct ProDeviceStatus: CustomStringConvertible {
    let lockStatus: LockStatus
    let antennaStatus: AntennaStatus
    let azimuth: Double
    let elevation: Double
    let altitude: Double
    let longitude: Double
    let latitude: Double
    let powerSavingMode: Bool
    let logStreaming: Bool
    let mode: Int // 0:地面, 1:车载
    
    init?(from response: String) {
        let components = response.components(separatedBy: ",")
        
        // REQLOC格式: 锁定状态,天线状态,方位角,俯仰角,海拔,经度,纬度,低功耗状态,日志状态,模式
        guard components.count >= 10,
              let lockStatusValue = Int(components[0]),
              let antennaStatusValue = Int(components[1]),
              let azimuth = Double(components[2]),
              let elevation = Double(components[3]),
              let altitude = Double(components[4]),
              let longitude = Double(components[5]),
              let latitude = Double(components[6]),
              let powerSaving = Int(components[7]),
              let logStreaming = Int(components[8]),
              let mode = Int(components[9]) else {
            return nil
        }
        
        self.lockStatus = LockStatus(rawValue: lockStatusValue) ?? .unlocked
        self.antennaStatus = AntennaStatus(rawValue: antennaStatusValue) ?? .stored
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
        self.powerSavingMode = powerSaving == 1
        self.logStreaming = logStreaming == 1
        self.mode = mode
    }
    
    var description: String {
        return """
        锁定状态: \(lockStatus.description)
        天线状态: \(antennaStatus.description)
        方位角: \(String(format: "%.2f", azimuth))°
        俯仰角: \(String(format: "%.2f", elevation))°
        海拔: \(String(format: "%.2f", altitude))m
        经度: \(String(format: "%.6f", longitude))
        纬度: \(String(format: "%.6f", latitude))
        低功耗: \(powerSavingMode ? "开启" : "关闭")
        日志流: \(logStreaming ? "开启" : "关闭")
        模式: \(mode == 1 ? "车载" : "地面")
        """
    }
}

// MARK: - 环境信息
struct EnvironmentInfo {
    let temperature: Double
    let humidity: Double
    
    init?(from response: String) {
        let components = response.components(separatedBy: ",")
        guard components.count >= 2,
              let temperature = Double(components[0]),
              let humidity = Double(components[1]) else {
            return nil
        }
        
        self.temperature = temperature
        self.humidity = humidity
    }
}

// MARK: - 对星结果
struct SatelliteAlignmentResult {
    let lockStatus: LockStatus
    let antennaStatus: AntennaStatus
    let azimuth: Double
    let elevation: Double
    let altitude: Double
    let longitude: Double
    let latitude: Double
    
    init?(from response: String) {
        // 支持 AUTOSATALI 和 HAFSATALI 两种格式
        var responseToParse = response
        if response.hasPrefix("AUTOSATALI,") {
            responseToParse = response.replacingOccurrences(of: "AUTOSATALI,", with: "")
        } else if response.hasPrefix("HAFSATALI,") {
            responseToParse = response.replacingOccurrences(of: "HAFSATALI,", with: "")
        }
        
        let components = responseToParse.components(separatedBy: ",")
        guard components.count >= 7,
              let lockStatusValue = Int(components[0]),
              let antennaStatusValue = Int(components[1]),
              let azimuth = Double(components[2]),
              let elevation = Double(components[3]),
              let altitude = Double(components[4]),
              let longitude = Double(components[5]),
              let latitude = Double(components[6]) else {
            return nil
        }
        
        self.lockStatus = LockStatus(rawValue: lockStatusValue) ?? .unlocked
        self.antennaStatus = AntennaStatus(rawValue: antennaStatusValue) ?? .stored
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
    }
}

// MARK: - WiFi设备管理器
class WiFiDeviceManager {
    
    // MARK: - 配置
    let host: String = "192.168.0.7"
    let port: UInt16 = 2018
    private let maxRetryCount = 5
    private let timeoutInterval: TimeInterval = 10.0
    
    // MARK: - 网络连接
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "WiFiDeviceManagerQueue", qos: .userInitiated)
    
    // MARK: - 数据接收
    private var isReceiving = false
    private var receiveBuffer = Data()
    private var pendingResponses: [String: String] = [:] // [command: response]
    private var responseSemaphores: [String: DispatchSemaphore] = [:]
    private var lastCommandId = 0
    
    // MARK: - 状态
    public private(set) var isConnected = false
    public private(set) var isLogStreaming = false
    
    // MARK: - 回调
    var onConnectionStatusChanged: ((Bool) -> Void)?
    var onLogReceived: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    var onDeviceWarning: ((FaultCodes) -> Void)?
    var onStatusUpdate: ((DeviceStatus) -> Void)?
    
    // MARK: - 初始化
    init() {}
    
    deinit {
        disconnect()
    }
    
    // MARK: - 连接管理
    func connect(completion: ((Result<Bool, Error>) -> Void)? = nil) {
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
    
    func disconnect() {
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
            }
            return
        }
        
        if message.hasPrefix("REQAPPLOC") {
            print("设备请求手机定位: \(message)")
            DispatchQueue.main.async {
                self.onLogReceived?("📱 设备请求手机定位")
                self.uploadPhoneLoc(longitude: 106.778488, latitude: 32.8884995, altitude: 50.0) { ruselt in
                    
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
        if let status = DeviceStatus(from: extractResponseContent(message)) {
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
    func autoOff(completion: @escaping (Result<Bool, Error>) -> Void) {
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
    func autoSatellite(completion: @escaping (Result<SatelliteAlignmentResult, Error>) -> Void) {
        sendCommand("AUTOSATALI,1") { result in
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
    func halfSatellite(longitude: Double, latitude: Double, altitude: Double,
                      completion: @escaping (Result<SatelliteAlignmentResult, Error>) -> Void) {
        let command = String(format: "HAFSATALI,%.6f,%.6f,%.2f,0", longitude, latitude, altitude)
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
    func deepSleep(enable: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
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
    }
    
    /// 环境查询
    func queryEnvironment(completion: @escaping (Result<EnvironmentInfo, Error>) -> Void) {
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
    func queryLocation(completion: @escaping (Result<DeviceStatus, Error>) -> Void) {
        sendCommand("REQLOC") { result in
            switch result {
            case .success(let response):
                if let status = DeviceStatus(from: self.extractResponseContent(response)) {
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
    func reset(completion: @escaping (Result<Bool, Error>) -> Void) {
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
    func resetACU(completion: @escaping (Result<Bool, Error>) -> Void) {
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
    func uploadPhoneLoc(longitude: Double, latitude: Double, altitude: Double,
                      completion: @escaping (Result<SatelliteAlignmentResult, Error>) -> Void) {
        let command = String(format: "REQAPPLOC,%.2f,%.6f,%.6f",altitude, longitude, latitude)
        sendCommand(command) { _ in
            
        }
    }
    
    /// 获取设备告警
    func queryDeviceWarning(completion: @escaping (Result<FaultCodes, Error>) -> Void) {
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
    func queryDeviceInfo(completion: @escaping (Result<DeviceInfo, Error>) -> Void) {
        sendCommand("REQDEV_INFO") { result in
            switch result {
            case .success(let response):
                if let info = DeviceInfo(from: self.extractResponseContent(response)) {
                    completion(.success(info))
                } else {
                    completion(.failure(WiFiDeviceError.invalidResponse))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// 获取信标信号强度
    func queryBeaconSignal(completion: @escaping (Result<Double, Error>) -> Void) {
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
    func queryLog(completion: @escaping (Result<[String], Error>) -> Void) {
        sendCommand("REQ_LOG") { result in
            switch result {
            case .success(let response):
                var logs: [String] = []
                let lines = response.components(separatedBy: "\n")
                
                for line in lines {
                    if line.hasPrefix("$SHOW") {
//                        let logContent = line.replacingOccurrences(of: "REQ_LOG,", with: "")
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
    
    /// ACU设备实时日志传输打开
    func enableLogStreaming(completion: @escaping (Result<Bool, Error>) -> Void) {
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
    func disableLogStreaming(completion: @escaping (Result<Bool, Error>) -> Void) {
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
private func parseSuccessResponse(_ response: String) -> Bool {
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
