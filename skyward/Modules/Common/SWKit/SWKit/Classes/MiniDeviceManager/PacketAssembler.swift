//
//  PacketAssembler.swift
//  test11
//
//  Created by yifan kang on 2025/11/13.
//

import Foundation

// 组包管理器
class PacketAssembler {
    private var currentPacketId: UInt32 = 0
    private var receivedPackets: [UInt32: Data] = [:]
    private var totalPackets: Int = 0
    private var isAssembling: Bool = false
    
    func processPacket(_ packet: PacketData) -> Data? {
        switch packet.status {
        case .noPacket:
            return packet.data
            
        case .packetStart:
            reset()
            currentPacketId = packet.packetId
            receivedPackets[packet.packetId] = packet.data
            isAssembling = true
            return nil
            
        case .packetMiddle:
            if isAssembling && packet.packetId == currentPacketId + UInt32(receivedPackets.count) {
                receivedPackets[packet.packetId] = packet.data
            } else {
                reset()
            }
            return nil
            
        case .packetEnd:
            if isAssembling {
                receivedPackets[packet.packetId] = packet.data
                let completeData = assembleCompleteData()
                reset()
                return completeData
            }
            return nil
        }
    }
    
    private func assembleCompleteData() -> Data {
        var completeData = Data()
        let sortedKeys = receivedPackets.keys.sorted()
        for key in sortedKeys {
            if let packetData = receivedPackets[key] {
                completeData.append(packetData)
            }
        }
        return completeData
    }
    
    private func reset() {
        receivedPackets.removeAll()
        currentPacketId = 0
        isAssembling = false
    }
}
