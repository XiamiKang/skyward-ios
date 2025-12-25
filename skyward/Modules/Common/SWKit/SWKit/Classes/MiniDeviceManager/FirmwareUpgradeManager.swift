//
//  FirmwareUpgradeManager.swift
//  test11
//
//  Created by yifan kang on 2025/11/13.
//

import Foundation

// 固件升级管理器
class FirmwareUpgradeManager {
    private var firmwareData: Data = Data()
    private var packetSize: Int = 238
    private var currentPacketIndex: UInt32 = 0
    private var packetsPerAck: Int = 10  // 2KB / 512字节 = 4包
    private var packetsSinceLastAck: Int = 0
    
    var totalPackets: Int {
        return Int(ceil(Double(firmwareData.count) / Double(packetSize)))
    }
    
    var progress: Float {
        return Float(currentPacketIndex) / Float(totalPackets)
    }
    
    var isUpgrading: Bool {
        return !firmwareData.isEmpty && currentPacketIndex < totalPackets
    }
    
    func startUpgrade(firmwareData: Data, packetSize: Int = 238) {
        self.firmwareData = firmwareData
        self.packetSize = packetSize
        self.currentPacketIndex = 0
        self.packetsSinceLastAck = 0
        print("固件升级开始: 总大小 \(firmwareData.count) 字节, 每包 \(packetSize) 字节, 每 \(packetsPerAck) 包应答一次")
    }
    
    func currentPacketInfo() -> (index: UInt32, data: Data)? {
        guard currentPacketIndex < totalPackets else { return nil }
        
        let startIndex = Int(currentPacketIndex) * packetSize
        let endIndex = min(startIndex + packetSize, firmwareData.count)
        let packetData = firmwareData.subdata(in: startIndex..<endIndex)
        
        return (index: currentPacketIndex, data: packetData)
    }
    
    func moveToNextPacket() {
        currentPacketIndex += 1
        packetsSinceLastAck += 1
    }
    
    func shouldWaitForAck() -> Bool {
        return packetsSinceLastAck >= packetsPerAck || currentPacketIndex >= totalPackets
    }
    
    func resetAckCounter() {
        packetsSinceLastAck = 0
    }
    
    func reset() {
        firmwareData = Data()
        currentPacketIndex = 0
        packetsSinceLastAck = 0
    }
    
    // 获取当前ACK状态信息
    func ackStatus() -> String {
        return "已发送 \(packetsSinceLastAck)/\(packetsPerAck) 包等待应答"
    }
}
