//
//  File.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/18.
//

import Foundation
import CoreBluetooth
import CryptoKit
import CommonCrypto


// MARK: - 协议命令实现扩展
public extension BluetoothManager {
    
    // MARK: - 5.0 获取设备信息 (0x0000)
    func requestDeviceInfo() {
        // 获取BLE MTU并计算最大数据长度
        let mtu = MTU
        let maxDataLength = UInt16(mtu - 3)
        
        var messageContent = Data()
        messageContent.append(maxDataLength.bigEndianData)
        
        sendCommand(.deviceInfo, messageContent: messageContent)
        
        print("请求设备信息，MTU: \(mtu), 最大数据长度: \(maxDataLength)")
    }
    
    // MARK: - 5.1 设备绑定状态设置 (0x0001)
    func setBindStatus(_ bonded: Bool) {
        let status: UInt8 = bonded ? 0x01 : 0x00
        var messageContent = Data()
        messageContent.append(status)
        
        sendCommand(.setBindStatus, messageContent: messageContent)
    }
    
    // MARK: - 5.2 状态信息上报 (0x0002)
    func requestStatusInfo() {
        var messageContent = Data()
        messageContent.append(0x00)
        
        sendCommand(.statusInfo, messageContent: messageContent)
    }
    
    // MARK: - 5.3 设置工作模式 (0x0003)
    func setWorkMode(_ mode: UInt8) {
        var messageContent = Data()
        messageContent.append(mode)
        
        sendCommand(.setWorkMode, messageContent: messageContent)
    }
    
    // MARK: - 5.4 设置设备状态上报时间 (0x0004)
    func setStatusReportFrequency(_ frequency: UInt8) {
        var messageContent = Data()
        messageContent.append(frequency)
        
        sendCommand(.setStatusReportTime, messageContent: messageContent)
    }
    
    // MARK: - 5.5 平台自定义内容信息下发 (0x0005)
    func sendPlatformCustomData(_ data: Data) {
        sendCommand(.platformCustomData, messageContent: data)
    }
    
    // MARK: - 5.6 APP自定义内容信息上报 (0x0006)
    func sendAppCustomData(_ data: Data) {
        sendCommand(.appCustomData, messageContent: data)
    }
    
    // MARK: - 5.8 APP触发报警报平安 (0x0008)
    func triggerAlarm(_ type: UInt8) {
        var messageContent = Data()
        messageContent.append(type)
        
        sendCommand(.appTriggerAlarm, messageContent: messageContent)
    }
    
    
    // MARK: - 5.9 设置设备定位信息上报后台时间间隔 (0x0009)
    func setPositionReportInterval(_ interval: UInt16) {
        var messageContent = Data()
        messageContent.append(interval.bigEndianData)
        
        sendCommand(.setPositionReport, messageContent: messageContent)
    }
    
    // MARK: - 5.11 获取手机定位及时间信息 (0x000B)
    func sendPhoneLocation(_ position: PositionInfo) {
        var messageContent = Data()
        messageContent.append(position.timestamp.bigEndianData)
        messageContent.append(position.latitude.bigEndianData)
        messageContent.append(position.latitudeHemisphere)
        messageContent.append(position.longitude.bigEndianData)
        messageContent.append(position.longitudeHemisphere)
        messageContent.append(position.altitude.bigEndianData)
        
        sendCommand(.getPhoneLocation, messageContent: messageContent)
    }
    
    // MARK: - 5.13 低功耗唤醒时间设置 (0x000D)
    func setLowPowerWakeTime(_ time: UInt32) {
        var messageContent = Data()
        messageContent.append(time.bigEndianData)
        
        sendCommand(.setLowPowerWakeTime, messageContent: messageContent)
    }
    
    // MARK: - 5.14 定位信息存储时间间隔设置 (0x000E)
    func setPositionStoreInterval(_ interval: UInt32) {
        var messageContent = Data()
        messageContent.append(interval.bigEndianData)
        
        sendCommand(.setPositionStoreInterval, messageContent: messageContent)
    }
    
    // MARK: - 5.15 APP读取存储的定位信息 (0x000F)
    func requestStoredPositions() {
        var messageContent = Data()
        messageContent.append(0x00)
        
        sendCommand(.readStoredPositions, messageContent: messageContent)
    }
    
    // MARK: - 5.16 开始固件升级 (0x0010)
    func startFirmwareUpgrade(version: String, firmwareData: Data) {
        // 解析版本号
        let versionBytes = parseVersionString(version)
//        print("固件数据--\(firmwareData.hexString)")
        // 计算MD5
        let md5 = md5Hash(from: firmwareData.hexString)
        print("MD5 字符串--\(md5)")
        guard let md5Data = md5.data(using: .ascii) else {
            print("MD5 字符串转换失败")
            return
        }
        
        var messageContent = Data()
        
        // 固件版本号 (4字节)
        messageContent.append(versionBytes)
        
        // 固件长度 (4字节)
        let length = UInt32(firmwareData.count)
        messageContent.append(UInt8((length >> 24) & 0xFF))
        messageContent.append(UInt8((length >> 16) & 0xFF))
        messageContent.append(UInt8((length >> 8) & 0xFF))
        messageContent.append(UInt8(length & 0xFF))
        
        // MD5值 (32字节)
        messageContent.append(md5Data)
        
        sendCommand(.startFirmwareUpgrade, messageContent: messageContent)
        
        print("发送固件升级开始命令:")
        print("  版本: \(version)")
        print("  长度: \(length) 字节")
        print("  MD5: \(md5)")
    }
    
    // MARK: - 5.17 发送固件数据 (0x0011)
    func sendFirmwareData(packetIndex: UInt32, packetData: Data) {
        var messageContent = Data()
        
        // 数据包索引 (4字节)
        messageContent.append(UInt8((packetIndex >> 24) & 0xFF))
        messageContent.append(UInt8((packetIndex >> 16) & 0xFF))
        messageContent.append(UInt8((packetIndex >> 8) & 0xFF))
        messageContent.append(UInt8(packetIndex & 0xFF))
        
        // 当前数据包长度 (2字节)
        let length = UInt16(packetData.count)
        messageContent.append(UInt8((length >> 8) & 0xFF))
        messageContent.append(UInt8(length & 0xFF))
        
        // 固件数据
        messageContent.append(packetData)
        
        sendCommand(.firmwareData, messageContent: messageContent)
        
        print("发送固件数据包 \(packetIndex): \(length) 字节")
    }
    
    // MARK: - 5.18 固件升级结束 (0x0012)
    func endFirmwareUpgrade(success: Bool) {
        let result: UInt8 = success ? 0x00 : 0x01
        var messageContent = Data()
        messageContent.append(result)
        
        sendCommand(.endFirmwareUpgrade, messageContent: messageContent)
        
        print("发送固件升级结束命令: \(success ? "成功" : "失败")")
    }
    
    // MARK: - 5.19 获取卫星信号质量 (0x0014)
    func getSatelliteSignal() {
        let result: UInt8 = 0x00
        var messageContent = Data()
        messageContent.append(result)
        
        sendCommand(.getSatelliteSignal, messageContent: messageContent)
        
        print("发送获取卫星信号质量命令")
    }
    
    // MARK: - 5.20 获取卫星收发记录 (0x0015)
    func getSatelliteRecords() {
        let result: UInt8 = 0x00
        var messageContent = Data()
        messageContent.append(result)
        
        sendCommand(.getSatelliteRecords, messageContent: messageContent)
        
        print("发送获取卫星收发记录命令")
    }
    
    func resetDevice() {
        let result: UInt8 = 0x00
        var messageContent = Data()
        messageContent.append(result)
        
        sendCommand(.resetDevice, messageContent: messageContent)
        
        print("发送复位命令")
    }
    
    // MARK: - 工具方法
    private func parseVersionString(_ version: String) -> Data {
        let components = version.split(separator: ".").map { String($0) }
        var versionBytes = Data()
        
        for i in 0..<4 {
            if i < components.count, let number = UInt8(components[i]) {
                versionBytes.append(number)
            } else {
                versionBytes.append(0) // 补零
            }
        }
        
        return versionBytes
    }
    
    func md5Hash(from string: String) -> String {
        // 2. 将输入字符串转换为 Data，使用 UTF-8 编码
        guard let data = string.data(using: .utf8) else {
            return "" // 转换失败返回空字符串
        }
        
        // 3. 使用 Insecure.MD5 计算哈希摘要
        let digest = Insecure.MD5.hash(data: data)
        
        // 4. 将摘要（digest）转换为 32 字符的十六进制字符串
        let hashString = digest.map {
            String(format: "%02hhx", $0) // %02hhx 确保每个字节都格式化为两位十六进制数
        }.joined()
        
        return hashString
    }
}

// MARK: - 固件升级扩展
extension BluetoothManager {
    
    // MARK: - 完整固件升级流程（安卓逻辑）
    public func startFirmwareUpgradeFlow(
        version: String,
        firmwareData: Data,
        progressCallback: @escaping (Double) -> Void,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard isConnected else {
            completion(false, "设备未连接")
            return
        }
        
        // 创建升级管理器
        let upgradeManager = FirmwareUpgradeManager()
        upgradeManager.prepareFirmware(version: version, firmwareData: firmwareData)
        
        // 开始升级流程
        startFirmwareUpgradeAsync(
            version: version,
            firmwareData: firmwareData,
            upgradeManager: upgradeManager,
            progressCallback: progressCallback,
            completion: completion
        )
    }
    
    // MARK: - 异步升级流程
    private func startFirmwareUpgradeAsync(
        version: String,
        firmwareData: Data,
        upgradeManager: FirmwareUpgradeManager,
        progressCallback: @escaping (Double) -> Void,
        completion: @escaping (Bool, String?) -> Void
    ) {
        Task {
            do {
                // Step 1: 发送开始升级命令
                let startSuccess = try await sendStartUpgradeCommand(
                    version: version,
                    firmwareData: firmwareData
                )
                
                guard startSuccess else {
                    completion(false, "开始升级失败")
                    return
                }
                
                progressCallback(10) // 开始升级，进度10%
                
                // Step 2: 发送固件数据
                let sendSuccess = try await sendFirmwareDataInChunks(
                    firmwareData: firmwareData,
                    upgradeManager: upgradeManager,
                    progressCallback: progressCallback
                )
                
                guard sendSuccess else {
                    completion(false, "数据传输失败")
                    return
                }
                
                // Step 3: 发送结束升级命令
                let endSuccess = try await sendEndUpgradeCommand()
                
                if endSuccess {
                    completion(true, nil)
                    progressCallback(100)
                } else {
                    completion(false, "结束升级失败")
                }
                
            } catch {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    private func sendStartUpgradeCommand(
        version: String,
        firmwareData: Data
    ) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            var notificationObserver: NSObjectProtocol?
            
            // 安全的 resume 辅助方法
            let safeResume: (Bool) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                
                // 移除观察者
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                continuation.resume(returning: result)
            }
            
            // 构建开始升级数据包（和安卓一致）
            let versionBytes = parseVersionString(version)
            let md5 = md5Hash(from: firmwareData.hexString)
            guard let md5Data = md5.data(using: .ascii) else {
                safeResume(false)
                return
            }
            
            var messageContent = Data()
            messageContent.append(versionBytes) // 4字节版本
            messageContent.append(UInt32(firmwareData.count).bigEndianData) // 4字节长度
            messageContent.append(md5Data) // 32字节MD5
            
            // 监听响应
            notificationObserver = NotificationCenter.default.addObserver(
                forName: .didReceiveResponseFrame,
                object: nil,
                queue: .main
            ) { notification in
                guard let userInfo = notification.userInfo,
                      let frame = userInfo["frame"] as? ResponseFrame,
                      frame.commandCode == .startFirmwareUpgrade,
                      let responseStatus = userInfo["responseStatus"] as? ResponseStatus else {
                    return
                }
                
                safeResume(responseStatus == .success)
            }
            
            // 发送命令
            sendCommand(.startFirmwareUpgrade, messageContent: messageContent)
            
            // 等待响应（超时处理）
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                safeResume(false) // 超时
            }
        }
    }
    
    private func sendFirmwareDataInChunks(
        firmwareData: Data,
        upgradeManager: FirmwareUpgradeManager,
        progressCallback: @escaping (Double) -> Void
    ) async throws -> Bool {
        let fileChunkSize = 2048
        let fileChunkCount = Int(ceil(Double(firmwareData.count) / Double(fileChunkSize)))
        
        print("📦 开始发送固件数据")
        print("   总数据大小: \(firmwareData.count) 字节")
        print("   分块大小: \(fileChunkSize) 字节")
        print("   总分块数: \(fileChunkCount)")
        
        for i in 0..<fileChunkCount {
            guard isConnected else {
                print("❌ 发送数据块 \(i) 时设备已断开连接")
                throw NSError(domain: "BluetoothManager", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "设备连接已断开"])
            }
            
            let fileStart = i * fileChunkSize
            let fileEnd = min(fileStart + fileChunkSize, firmwareData.count)
            let fileChunk = firmwareData.subdata(in: fileStart..<fileEnd)
            
            // 构建带索引的数据包
            var chunkWithIndex = Data()
            chunkWithIndex.append(UInt32(i).bigEndianData) // 4字节索引
            chunkWithIndex.append(fileChunk) // 数据
            
            // 构建命令数据
            let messageContent = buildFileChunkData(chunkIndex: i, chunkData: chunkWithIndex)
            
            // 发送数据包（带重试）
            let success = try await sendChunkWithRetry(
                chunkIndex: i,
                messageContent: messageContent,
                maxRetries: 2,
                retryDelay: 300
            )
            
            if !success {
                print("❌ 数据块 \(i) 发送失败")
                return false
            }
            
            let progress = Double(i + 1) / Double(fileChunkCount)
            progressCallback(progress)
            
            print("✅ 数据块 \(i+1)/\(fileChunkCount) 发送成功")
        }
        
        return true
    }
    
    // MARK: - Step 3: 发送结束升级命令
    private func sendEndUpgradeCommand() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            var messageContent = Data()
            messageContent.append(0x00) // 成功标志
            
            sendCommand(.endFirmwareUpgrade, messageContent: messageContent)
            
            // 等待响应
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                continuation.resume(returning: false)
            }
            
            NotificationCenter.default.addObserver(
                forName: .didReceiveResponseFrame,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let frame = userInfo["frame"] as? ResponseFrame,
                      frame.commandCode == .endFirmwareUpgrade,
                      let responseStatus = userInfo["responseStatus"] as? ResponseStatus else {
                    return
                }
                
                NotificationCenter.default.removeObserver(self, name: .didReceiveResponseFrame, object: nil)
                
                if responseStatus == .success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 构建文件块数据（模拟安卓的 buildFileContent）
    private func buildFileChunkData(chunkIndex: Int, chunkData: Data) -> Data {
        var data = Data()
        
        // 构建类似安卓的协议格式
        // 这里需要根据你的实际协议来调整
        data.append(UInt32(chunkIndex).bigEndianData) // 块索引
        data.append(UInt16(chunkData.count).bigEndianData) // 块长度
        data.append(chunkData) // 实际数据
        
        return data
    }
    
    /// 发送数据块（带重试机制）
    private func sendChunkWithRetry(
        chunkIndex: Int,
        messageContent: Data,
        maxRetries: Int,
        retryDelay: UInt64
    ) async throws -> Bool {
        var attempt = 0
        
        while attempt <= maxRetries {
            attempt += 1
            
            print("📤 发送数据块 \(chunkIndex)，尝试 \(attempt)/\(maxRetries + 1)")
            
            let success = try await sendSingleChunk(
                chunkIndex: chunkIndex,
                messageContent: messageContent
            )
            
            if success {
                return true
            } else if attempt <= maxRetries {
                print("🔄 重试数据块 \(chunkIndex)，等待 \(retryDelay)ms")
                try await Task.sleep(nanoseconds: retryDelay * 1_000_000)
            }
        }
        
        return false
    }
    
    /// 发送单个数据块
//    private func sendSingleChunk(chunkIndex: Int, messageContent: Data) async throws -> Bool {
//        return try await withCheckedThrowingContinuation { continuation in
//            // 先分包处理
//            let chunkSize = MTU - 14 // 考虑协议开销
//            let chunkCount = Int(ceil(Double(messageContent.count) / Double(chunkSize)))
//            
//            print("  分包发送: \(chunkCount) 个小包，MTU: \(MTU)")
//            
//            var pkgNumber = 0
//            var lastPacketSuccess = false
//            
//            for j in 0..<chunkCount {
//                let start = j * chunkSize
//                let end = min(start + chunkSize, messageContent.count)
//                let chunk = messageContent.subdata(in: start..<end)
//                
//                // 确定包状态（和安卓一致）
//                let pkgStatus: UInt8
//                if chunkCount == 1 {
//                    pkgStatus = 0x00 // 不分包
//                } else {
//                    switch j {
//                    case 0:
//                        pkgStatus = 0x01 // 分包开始
//                    case chunkCount - 1:
//                        pkgStatus = 0x03 // 分包结束
//                    default:
//                        pkgStatus = 0x02 // 分包中
//                    }
//                }
//                
//                // 构建分包数据
//                let pkgData = buildPacketData(data: chunk, status: pkgStatus, number: pkgNumber)
//                
//                // 如果是最后一个包，等待响应
//                if j == chunkCount - 1 {
//                    // 发送并等待响应
//                    sendCommand(.firmwareData, messageContent: chunk)
//                    
//                    // 监听响应
//                    NotificationCenter.default.addObserver(
//                        forName: .didReceiveResponseFrame,
//                        object: nil,
//                        queue: .main
//                    ) { [weak self] notification in
//                        guard let self = self,
//                              let userInfo = notification.userInfo,
//                              let frame = userInfo["frame"] as? ResponseFrame,
//                              frame.commandCode == .firmwareData,
//                              let responseStatus = userInfo["responseStatus"] as? ResponseStatus else {
//                            return
//                        }
//                        
//                        NotificationCenter.default.removeObserver(self, name: .didReceiveResponseFrame, object: nil)
//                        
//                        if responseStatus == .success {
//                            lastPacketSuccess = true
//                            continuation.resume(returning: true)
//                        } else {
//                            lastPacketSuccess = false
//                            continuation.resume(returning: false)
//                        }
//                    }
//                    
//                    // 超时处理
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                        if !lastPacketSuccess {
//                            continuation.resume(returning: false)
//                        }
//                    }
//                    
//                } else {
//                    // 发送中间包（不等待响应）
//                    sendRawData(pkgData)
//                }
//                
//                pkgNumber += 1
//            }
//        }
//    }
    private func sendSingleChunk(chunkIndex: Int, messageContent: Data) async throws -> Bool {
        // 先分包处理
        let chunkSize = MTU - 14 // 考虑协议开销
        let chunkCount = Int(ceil(Double(messageContent.count) / Double(chunkSize)))
        
        print("  分包发送: \(chunkCount) 个小包，MTU: \(MTU)")
        
        // 存储观察者引用
        var notificationObserver: NSObjectProtocol?
        
        // 使用 Task 来处理异步操作和超时
        return try await withCheckedThrowingContinuation { continuation in
            var pkgNumber = 0
            var lastPacketSuccess = false
            
            // 创建响应处理器
            let responseHandler: (Notification) -> Void = { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let frame = userInfo["frame"] as? ResponseFrame,
                      frame.commandCode == .firmwareData,
                      let responseStatus = userInfo["responseStatus"] as? ResponseStatus else {
                    return
                }
                
                // 移除观察者
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                if responseStatus == .success {
                    lastPacketSuccess = true
                    continuation.resume(returning: true)
                } else {
                    lastPacketSuccess = true // 这里设为 true 避免超时逻辑触发
                    continuation.resume(returning: false)
                }
            }
            
            // 注册通知观察者（只在最后一个包前注册）
            notificationObserver = NotificationCenter.default.addObserver(
                forName: .didReceiveResponseFrame,
                object: nil,
                queue: .main,
                using: responseHandler
            )
            
            // 设置超时
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self, !lastPacketSuccess else { return }
                
                // 移除观察者
                if let observer = notificationObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                
                // 如果还没有得到响应，返回失败
                // 检查 continuation 是否已经被 resume
                Task {
                    continuation.resume(returning: false)
                }
            }
            
            // 发送所有包
            for j in 0..<chunkCount {
                let start = j * chunkSize
                let end = min(start + chunkSize, messageContent.count)
                let chunk = messageContent.subdata(in: start..<end)
                
                // 确定包状态（和安卓一致）
                let pkgStatus: UInt8
                if chunkCount == 1 {
                    pkgStatus = 0x00 // 不分包
                } else {
                    switch j {
                    case 0:
                        pkgStatus = 0x01 // 分包开始
                    case chunkCount - 1:
                        pkgStatus = 0x03 // 分包结束
                    default:
                        pkgStatus = 0x02 // 分包中
                    }
                }
                
                // 构建分包数据
                let pkgData = buildPacketData(data: chunk, status: pkgStatus, number: pkgNumber)
                
                // 如果是最后一个包，发送命令（会期待响应）
                if j == chunkCount - 1 {
                    sendCommand(.firmwareData, messageContent: chunk)
                } else {
                    // 发送中间包（不等待响应）
                    sendRawData(pkgData)
                }
                
                // 如果不是最后一个包，添加小的延迟避免发送过快
                if j < chunkCount - 1 {
                    Thread.sleep(forTimeInterval: 0.05)
                }
                
                pkgNumber += 1
            }
        }
    }
    
    /// 构建分包数据
    private func buildPacketData(data: Data, status: UInt8, number: Int) -> Data {
        var packet = Data()
        
        // 帧头 (2字节)
        packet.append(0xFA)
        packet.append(0xF5)
        
        // 分包状态 (1字节)
        packet.append(status)
        
        // 分包编号 (4字节)
        packet.append(UInt32(number).bigEndianData)
        
        // 数据长度 (2字节)
        packet.append(UInt16(data.count).bigEndianData)
        
        // 数据
        packet.append(data)
        
        return packet
    }
}


