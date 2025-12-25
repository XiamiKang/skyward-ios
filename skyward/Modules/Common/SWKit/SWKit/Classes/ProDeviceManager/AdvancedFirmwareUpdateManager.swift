//
//  AdvancedFirmwareUpdateManager.swift
//  22222
//
//  Created by yifan kang on 2025/12/20.
//


import Foundation
import UIKit

// MARK: - 固件升级错误
enum FirmwareUpdateError: Error {
    case notConnected
    case timeout
    case eraseFailed
    case infoFailed
    case dataFailed
    case endFailed
    case invalidResponse
    case invalidData
    case retryExceeded
    
    var errorDescription: String? {
        switch self {
        case .notConnected: return "设备未连接"
        case .timeout: return "操作超时"
        case .eraseFailed: return "擦除Flash失败"
        case .infoFailed: return "发送固件信息失败"
        case .dataFailed: return "发送固件数据失败"
        case .endFailed: return "升级结束失败"
        case .invalidResponse: return "无效响应"
        case .invalidData: return "无效固件数据"
        case .retryExceeded: return "重试次数超限"
        }
    }
}

enum OTAUpgradeError: Error, LocalizedError {
    case invalidFirmwareFile
    case fileReadError
    case invalidChecksum
    case invalidResponse
    case timeout
    case eraseFailed
    case infoFailed
    case dataFailed
    case endFailed
    case canceled
    case deviceDisconnected
    
    var errorDescription: String? {
        switch self {
        case .invalidFirmwareFile:
            return "无效的固件文件"
        case .fileReadError:
            return "读取固件文件失败"
        case .invalidChecksum:
            return "校验和错误"
        case .invalidResponse:
            return "设备响应无效"
        case .timeout:
            return "操作超时"
        case .eraseFailed:
            return "擦除Flash失败"
        case .infoFailed:
            return "发送固件信息失败"
        case .dataFailed:
            return "发送固件数据失败"
        case .endFailed:
            return "升级结束失败"
        case .canceled:
            return "升级已取消"
        case .deviceDisconnected:
            return "设备已断开连接"
        }
    }
}
// MARK: - 改进的固件升级管理器
class AdvancedFirmwareUpdateManager {
    
    // MARK: - 配置
    private let packetSize = 256 // 每包数据大小
    private let frameSize = 279 // 固定帧长度
    private let maxRetryCount = 3
    private let timeoutInterval: TimeInterval = 10.0
    
    // 命令类型
    private enum CommandType: UInt8 {
        case erase = 0xB0
        case info = 0xB1
        case data = 0xB2
    }
    
    // MARK: - 依赖
    weak var deviceManager: WiFiDeviceManager?
    
    // MARK: - 状态
    private(set) var isUpgrading = false
    private(set) var progress: Double = 0
    private(set) var currentPhase = ""
    private var firmwareInfo: FirmwareFileInfo?
    private var firmwareData: Data?
    
    // MARK: - 回调
    var onProgressUpdate: ((Double, String) -> Void)?
    var onUpgradeComplete: ((Result<Bool, Error>) -> Void)?
    var onLogReceived: ((String) -> Void)?
    
    // MARK: - 初始化
    init(deviceManager: WiFiDeviceManager) {
        self.deviceManager = deviceManager
    }
    
    // MARK: - 公共方法
    func startUpgrade(firmwarePath: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let deviceManager = deviceManager, deviceManager.isConnected else {
            completion(.failure(WiFiDeviceError.disconnected))
            return
        }
        
        guard !isUpgrading else {
            completion(.failure(WiFiDeviceError.deviceBusy))
            return
        }
        
        isUpgrading = true
        progress = 0
        currentPhase = "准备升级"
        onProgressUpdate?(progress, currentPhase)
        
        addLog("开始OTA固件升级")
        addLog("固件文件: \(firmwarePath)")
        
        // 异步执行升级流程
        DispatchQueue.global(qos: .userInitiated).async {
            self.performUpgrade(firmwarePath: firmwarePath, completion: completion)
        }
    }
    
    func cancelUpgrade() {
        isUpgrading = false
        addLog("升级已取消")
    }
    
    // MARK: - 私有方法
    
    private func performUpgrade(firmwarePath: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            // 1. 准备固件数据
            addLog("准备固件数据...")
            let firmwareData = try Data(contentsOf: URL(fileURLWithPath: firmwarePath))
            let firmwareInfo = try parseFirmwareInfo(from: firmwarePath)
            
            self.firmwareData = firmwareData
            self.firmwareInfo = firmwareInfo
            
            addLog("固件版本: \(firmwareInfo.version)")
            addLog("固件大小: \(firmwareData.count) 字节")
            
            // 2. 发送OTA_START命令
            try startOTAProcess()
            
            // 3. 发送擦除指令
            try sendEraseCommand()
            
            // 4. 发送固件信息
            try sendFirmwareInfoCommand(firmwareInfo: firmwareInfo, firmwareSize: firmwareData.count)
            
            // 5. 发送固件数据
            try sendFirmwareData(firmwareData: firmwareData)
            
            // 6. 发送OTA_END命令
            try endOTAProcess()
            
            // 升级成功
            DispatchQueue.main.async {
                self.isUpgrading = false
                self.progress = 1.0
                self.currentPhase = "升级完成"
                self.onProgressUpdate?(self.progress, self.currentPhase)
                self.addLog("✅ OTA升级成功完成")
                completion(.success(true))
            }
            
        } catch {
            DispatchQueue.main.async {
                self.isUpgrading = false
                self.addLog("❌ 升级失败: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - 协议包生成
    
    private func createErasePacket() -> Data {
        var data = Data(count: frameSize)
        
        // 帧头
        data[0] = 0xAA
        data[1] = 0x55
        
        // 帧长度 (279 = 0x0117，低位在前)
        data[2] = 0x17  // 低位
        data[3] = 0x01  // 高位
        
        // 指令类型
        data[4] = CommandType.erase.rawValue
        
        // 升级程序地址 (0x0080)
        data[5] = 0x00
        data[6] = 0x80
        
        // 7-276字节: 固定为0x00 (已初始化)
        
        // 帧校验和 (0-276字节的和)
        let checksum = calculateChecksum(for: data.subdata(in: 0..<277))
        data[277] = UInt8(checksum & 0xFF)
        data[278] = UInt8((checksum >> 8) & 0xFF)
        
        return data
    }
    
    private func createInfoPacket(sequence: UInt16, firmwareInfo: FirmwareFileInfo, firmwareSize: Int) -> Data {
        var data = Data(count: frameSize)
        
        // 帧头
        data[0] = 0xAA
        data[1] = 0x55
        
        // 帧长度
        data[2] = 0x17
        data[3] = 0x01
        
        // 指令类型
        data[4] = CommandType.info.rawValue
        
        // 包序号 (从0开始)
        data[5] = UInt8(sequence & 0xFF)
        data[6] = UInt8((sequence >> 8) & 0xFF)
        
        // 固件信息结构体长度 (120 = 0x0078)
        data[7] = 0x00
        data[8] = 0x78
        
        // 9-12: 固定为0x01
        for i in 9...12 {
            data[i] = 0x01
        }
        
        // 固件程序地址 (0x80100000)
        let address: UInt32 = 0x80100000
        data[13] = UInt8(address & 0xFF)
        data[14] = UInt8((address >> 8) & 0xFF)
        data[15] = UInt8((address >> 16) & 0xFF)
        data[16] = UInt8((address >> 24) & 0xFF)
        
        // 升级日期时分 (例如: 12月2号15:25 -> "12021525")
//        let dateStr = "12021525" // 应该使用当前时间
        let dateData = generateDateTimeData()
        for (index, byte) in dateData.enumerated() {
            data[17 + index] = byte
        }
        
        // 升级年份 (例如: 2025 -> "20250000")
        let yearData = generateYearData()
        for (index, byte) in yearData.enumerated() {
            data[25 + index] = byte
        }
        
        // 固件版本号
        let versionData = firmwareInfo.version.data(using: .ascii)!
        for (index, byte) in versionData.prefix(4).enumerated() {
            data[33 + index] = byte
        }
        
        // 固件总长度
        let totalSize = UInt32(firmwareSize)
        data[37] = UInt8(totalSize & 0xFF)
        data[38] = UInt8((totalSize >> 8) & 0xFF)
        data[39] = UInt8((totalSize >> 16) & 0xFF)
        data[40] = UInt8((totalSize >> 24) & 0xFF)
        
        // 41-64: 保留，固定为0x00
        
        // 固件文件名 (不超过64字节)
        let fileNameData = firmwareInfo.fileName.data(using: .ascii)!
        for (index, byte) in fileNameData.prefix(64).enumerated() {
            data[65 + index] = byte
        }
        
        // 129-276: 固定为0x00
        
        // 计算校验和
        let checksum = calculateChecksum(for: data.subdata(in: 0..<277))
        data[277] = UInt8(checksum & 0xFF)
        data[278] = UInt8((checksum >> 8) & 0xFF)
        
        return data
    }
    
    private func createDataPacket(sequence: UInt16, packetData: Data, isLast: Bool) -> Data {
        var data = Data(count: frameSize)
        
        // 帧头
        data[0] = 0xAA
        data[1] = 0x55
        
        // 帧长度
        data[2] = 0x17
        data[3] = 0x01
        
        // 指令类型
        data[4] = CommandType.data.rawValue
        
        // 包序号
        data[5] = UInt8(sequence & 0xFF)
        data[6] = UInt8((sequence >> 8) & 0xFF)
        
        // 包长度
        let packetLength = UInt16(packetData.count)
        data[7] = UInt8(packetLength & 0xFF)
        data[8] = UInt8((packetLength >> 8) & 0xFF)
        
        // 数据 (9-264字节)
        if packetData.count > 0 {
            let dataStart = 9
            let dataEnd = min(dataStart + 256, dataStart + packetData.count)
            data.replaceSubrange(dataStart..<dataEnd, with: packetData)
        }
        
        // 265-272: 保留，固定为0x00
        
        // 数据包校验和 (9-272字节的和)
        let dataChecksum = calculateChecksum32(for: data.subdata(in: 9..<273))
        data[273] = UInt8(dataChecksum & 0xFF)
        data[274] = UInt8((dataChecksum >> 8) & 0xFF)
        data[275] = UInt8((dataChecksum >> 16) & 0xFF)
        data[276] = UInt8((dataChecksum >> 24) & 0xFF)
        
        // 帧校验和 (0-276字节的和)
        let frameChecksum = calculateChecksum(for: data.subdata(in: 0..<277))
        data[277] = UInt8(frameChecksum & 0xFF)
        data[278] = UInt8((frameChecksum >> 8) & 0xFF)
        
        return data
    }
    
    // MARK: - 升级步骤
    
    private func startOTAProcess() throws {
        currentPhase = "启动升级"
        progress = 0.1
        onProgressUpdate?(progress, currentPhase)
        addLog("发送OTA,START命令...")
        
        try sendCommandAndWait(command: "OTA,START", expectedResponse: "OTA,START,ACK")
        addLog("✅ 升级模式已进入")
    }
    
    public func sendEraseCommand() throws {
        currentPhase = "擦除Flash"
        progress = 0.2
        onProgressUpdate?(progress, currentPhase)
        addLog("发送擦除指令...")
        
        let erasePacket = createErasePacket()
        try sendBinaryPacketWithRetry(packet: erasePacket, expectedResponse: "$ACK,ER")
//        try sendBinaryPacketWithRetry(packet: erasePacket, expectedResponse: "")
        
        addLog("✅ Flash擦除成功")
    }
    
    public func sendFirmwareInfoCommand(firmwareInfo: FirmwareFileInfo, firmwareSize: Int) throws {
        currentPhase = "发送固件信息"
        progress = 0.3
        onProgressUpdate?(progress, currentPhase)
        addLog("发送固件信息...")
        
        let infoPacket = createInfoPacket(sequence: 0, firmwareInfo: firmwareInfo, firmwareSize: firmwareSize)
        try sendBinaryPacketWithRetry(packet: infoPacket, expectedResponse: "$ACK,IN")
//        try sendBinaryPacketWithRetry(packet: infoPacket, expectedResponse: "")
        addLog("✅ 固件信息发送成功")
    }
    
    public func sendFirmwareData(firmwareData: Data) throws {
        currentPhase = "发送固件数据"
        addLog("开始发送固件数据，共 \(firmwareData.count) 字节")
        
        let totalPackets = Int(ceil(Double(firmwareData.count) / Double(packetSize)))
        addLog("总共 \(totalPackets) 个数据包")
        
        for packetIndex in 0..<totalPackets {
            guard isUpgrading else {
                throw WiFiDeviceError.commandFailed("升级被取消")
            }
            
            let startIndex = packetIndex * packetSize
            let endIndex = min(startIndex + packetSize, firmwareData.count)
            let packetData = firmwareData.subdata(in: startIndex..<endIndex)
            let isLast = packetIndex == totalPackets - 1
            
            // 更新进度
            let packetProgress = Double(packetIndex) / Double(totalPackets)
            progress = 0.4 + packetProgress * 0.5
            onProgressUpdate?(progress, "发送数据包 \(packetIndex + 1)/\(totalPackets)")
            
            addLog("发送第 \(packetIndex + 1)/\(totalPackets) 包，长度: \(packetData.count) 字节")
            
            let dataPacket = createDataPacket(sequence: UInt16(packetIndex), 
                                            packetData: packetData, 
                                            isLast: isLast)
            
            let expectedResponse = "$ACK,DS,\(packetIndex + 1)"
            try sendBinaryPacketWithRetry(packet: dataPacket, expectedResponse: expectedResponse)
            
            // 小延迟，避免设备处理不过来
            if !isLast {
                Thread.sleep(forTimeInterval: 0.02)
            }
        }
        
        addLog("✅ 所有固件数据发送完成")
    }
    
    public func endOTAProcess() throws {
        currentPhase = "完成升级"
        progress = 0.95
        onProgressUpdate?(progress, currentPhase)
        addLog("发送OTA_END命令...")
        
        try sendCommandAndWait(command: "OTA,END", expectedResponse: "OTA,END,OK")
        addLog("✅ 升级结束成功")
    }
    
    // MARK: - 通信辅助方法
    
    private func sendCommandAndWait(command: String, expectedResponse: String) throws {
        let result = try sendWithRetry {
            try self.sendRawCommandAndWait(command)
        }
        
        switch result {
        case .success(let response):
            if response.contains(expectedResponse) {
                return
            } else {
                throw FirmwareUpdateError.invalidResponse
            }
        case .failure(let error):
            throw error
        }
    }

    private func sendBinaryPacketWithRetry(packet: Data, expectedResponse: String) throws {
        let result = try sendWithRetry {
            try self.sendBinaryPacketAndWait(packet)
        }
        
        switch result {
        case .success(let response):
            if response.contains(expectedResponse) {
                return
            } else {
                throw FirmwareUpdateError.invalidResponse
            }
        case .failure(let error):
            throw error
        }
//        return
    }

    private func sendWithRetry(operation: () throws -> String) throws -> Result<String, Error> {
        var lastError: Error?
        
        for retry in 0..<maxRetryCount {
            guard isUpgrading else {
                return .failure(WiFiDeviceError.commandFailed("升级被取消"))
            }
            
            do {
                let response = try operation()
                addLog("操作成功: \(response)")
                return .success(response)
                
            } catch {
                lastError = error
                addLog("操作失败(尝试 \(retry + 1)/\(maxRetryCount)): \(error.localizedDescription)")
                
                if retry < maxRetryCount - 1 {
                    Thread.sleep(forTimeInterval: 1.0)
                }
            }
        }
        
        return .failure(lastError ?? FirmwareUpdateError.timeout)
    }
    
    private func sendRawCommandAndWait(_ command: String) throws -> String {
        guard let deviceManager = deviceManager else {
            throw WiFiDeviceError.disconnected
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var responseResult: Result<String, Error>?
        
        deviceManager.sendCommand(command) { result in
            responseResult = result
            semaphore.signal()
        }
        
        let timeoutResult = semaphore.wait(timeout: .now() + timeoutInterval)
        
        if timeoutResult == .timedOut {
            throw FirmwareUpdateError.timeout
        }
        
        switch responseResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        case .none:
            throw FirmwareUpdateError.invalidResponse
        }
    }
    
    private func sendBinaryPacketAndWait(_ packet: Data) throws -> String {
        
        // 添加详细的调试信息
        addLog("准备发送二进制包，长度: \(packet.count) 字节")
        addLog("数据前32字节: \(packet.prefix(32).hexString)")
        addLog("数据后32字节: \(packet.suffix(32).hexString)")
           
        
        guard let deviceManager = deviceManager else {
            throw WiFiDeviceError.disconnected
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var responseResult: Result<String, Error>?
        
        // WiFiDeviceManager需要添加sendRawData方法
        deviceManager.sendBinaryData(packet) { result in
            responseResult = result
            semaphore.signal()
        }
        
        let timeoutResult = semaphore.wait(timeout: .now() + timeoutInterval)
        
        if timeoutResult == .timedOut {
            throw FirmwareUpdateError.timeout
        }
        
        switch responseResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        case .none:
            throw FirmwareUpdateError.invalidResponse
        }
    }
    
    // MARK: - 辅助方法
    
    private func parseFirmwareInfo(from filePath: String) throws -> FirmwareFileInfo {
        let url = URL(fileURLWithPath: filePath)
        let fileName = url.lastPathComponent
        
        // 检查文件扩展名是否为.bin
        guard fileName.lowercased().hasSuffix(".bin") else {
            throw OTAUpgradeError.invalidFirmwareFile
        }
        
        // 去掉.bin后缀，便于解析
        let fileNameWithoutExt = String(fileName.dropLast(4))
        
        // 按"_"分割文件名
        let components = fileNameWithoutExt.components(separatedBy: "_")
        guard components.count >= 2 else {
            throw OTAUpgradeError.invalidFirmwareFile
        }
        
        // 提取版本号部分（最后一部分）
        let versionPart = components.last ?? "V1.0"
        
        // 处理不同的版本号格式
        var version: String
        
        if versionPart.hasPrefix("V") {
            // 已经是V开头，直接处理
            if versionPart.contains(".") {
                // 格式2: V2.1.9 -> 去掉小数点 -> V219
                version = "V" + versionPart
                    .dropFirst() // 去掉开头的V
                    .replacingOccurrences(of: ".", with: "") // 去掉所有小数点
            } else {
                // 格式1: V219 -> 保持不变
                version = versionPart
            }
        } else {
            // 如果不是V开头，添加V前缀
            if versionPart.contains(".") {
                // 如: 2.1.9 -> V219
                version = "V" + versionPart.replacingOccurrences(of: ".", with: "")
            } else {
                // 如: 219 -> V219
                version = "V" + versionPart
            }
        }
        
        // 确保版本号是4个字符（不足补0，过长截断）
        if version.count > 4 {
            version = String(version.prefix(4))
        } else if version.count < 4 {
            version = version.padding(toLength: 4, withPad: "0", startingAt: 0)
        }
        
        print("✅  固件包名：\(fileName),固件版本：\(version)")
        return FirmwareFileInfo(
            fileName: fileName,  // 保持完整的文件名，包括.bin
            version: version
        )
    }
    
    private func calculateChecksum(for data: Data) -> UInt16 {
        var sum: UInt16 = 0
        for byte in data {
            sum = sum &+ UInt16(byte)
        }
        return sum
    }
    
    private func calculateChecksum32(for data: Data) -> UInt32 {
        var sum: UInt32 = 0
        for byte in data {
            sum = sum &+ UInt32(byte)
        }
        return sum
    }
    
    private func addLog(_ message: String) {
        print("[OTA] \(message)")
        DispatchQueue.main.async {
            self.onLogReceived?(message)
        }
    }
    
    /// 生成升级日期时分数据 (8字节 ASCII格式)
    private func generateDateTimeData() -> [UInt8] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddHHmm"
        let dateStr = dateFormatter.string(from: Date())
        
        // 转为ASCII字节数组
        return dateStr.utf8.map { $0 }
    }
    
    /// 生成升级年份数据 (8字节 ASCII格式)
    private func generateYearData() -> [UInt8] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let yearStr = dateFormatter.string(from: Date()) + "0000"
        
        // 转为ASCII字节数组
        return yearStr.utf8.map { $0 }
    }
}

// MARK: - 固件文件信息
struct FirmwareFileInfo {
    let fileName: String
    let version: String
}

// MARK: - WiFiDeviceManager扩展
extension WiFiDeviceManager {
    func sendRawData(_ data: Data, completion: @escaping (Result<String, Error>) -> Void) {
        // 实现二进制数据发送
        sendCommand(data.hexString, completion: completion)
    }
}





