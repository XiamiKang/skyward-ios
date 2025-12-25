//
//  MessageGenerator.swift
//  33333
//
//  Created by TXTS on 2025/12/17.
//

import Foundation

// MARK: - 扩展：字符串安全访问
extension String {
    subscript(safe index: Int) -> Character? {
        guard index >= 0, index < self.count else { return nil }
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}

public class MessageGenerator {
    
    // MARK: - 消息类型枚举
    enum MessageType: UInt8 {
        case emergencyNotifySend = 0x01
        case deviceBind = 0x02
        case bindEmergencyContact = 0x03
        case imSend = 0x04
        case requestFriendLocation = 0x05
        case receiveImMessage = 0x06
    }
    
    // MARK: - 0x01: 紧急通讯发送消息
    public static func generateEmergencyNotifySend(senderId: String, timestamp: Double, message: String) -> Data? {
        var data = Data()
        
        // 消息类型 (1字节) - 0x01
        data.append(MessageType.emergencyNotifySend.rawValue)
        
        // SenderID (8字节) - 从字符串转换为UInt64
        guard let senderIdUInt = UInt64(senderId) else {
            debugPrint("SenderID 转换失败")
            return nil
        }
        data.append(contentsOf: senderIdUInt.toBytes())
        
        // Timestamp (4字节) - 从Double转换为Int32
        let timestampInt = covertedInt32Timestamp(timestamp: timestamp)
        data.append(contentsOf: timestampInt.toBytes())
        
        // 处理消息内容
        let messageData = Data(message.utf8.prefix(70)) // 限制最大70字节
        let msgLen = UInt16(messageData.count)
        
        // MsgLen (2字节)
        data.append(contentsOf: msgLen.toBytes())
        
        // Msg (n字节)
        data.append(messageData)
        
        return data
    }
    
    // MARK: - 0x02: 设备绑定
    public static func generateDeviceBind(userId: String) -> Data? {
        var data = Data()
        
        // 消息类型 (1字节) - 0x02
        data.append(MessageType.deviceBind.rawValue)
        
        // UserID (8字节) - 从字符串转换为UInt64
        guard let userIdUInt = UInt64(userId) else {
            debugPrint("UserID 转换失败")
            return nil
        }
        data.append(contentsOf: userIdUInt.toBytes())
        
        return data
    }
    
    // MARK: - 0x03: 绑定紧急联系人
    public static func generateBindEmergencyContact(userId: String, phone: String, name: String) -> Data? {
        var data = Data()
        
        // 消息类型 (1字节) - 0x03
        data.append(MessageType.bindEmergencyContact.rawValue)
        
        // UserID (8字节) - 从字符串转换为UInt64
        guard let userIdUInt = UInt64(userId) else {
            debugPrint("UserID 转换失败")
            return nil
        }
        data.append(contentsOf: userIdUInt.toBytes())
        
        // PhoneBCD (6字节)
        let phoneBCD = phoneToBcd6(phone)
        data.append(phoneBCD)
        
        // NameLength (1字节)
        let nameData = name.data(using: .utf8) ?? Data()
        let nameLength = UInt8(min(nameData.count, 255)) // 限制最大长度为255
        data.append(nameLength)
        
        // Name (可变长度)
        data.append(nameData.prefix(Int(nameLength)))

        return data
    }
    
    // MARK: - 0x04: 即时消息发送
    public static func generateImSend(senderId: String, targetId: String, timestamp: Double, message: String) -> Data? {
        var data = Data()
        
        // 消息类型 (1字节) - 0x04
        data.append(MessageType.imSend.rawValue)
        
        // SenderID (8字节) - 从字符串转换为UInt64
        guard let senderIdUInt = UInt64(senderId) else {
            debugPrint("SenderID 转换失败")
            return nil
        }
        data.append(contentsOf: senderIdUInt.toBytes())
        
        // TargetID (8字节) - 从字符串转换为UInt64
        guard let targetIdUInt = UInt64(targetId) else {
            debugPrint("TargetID 转换失败")
            return nil
        }
        data.append(contentsOf: targetIdUInt.toBytes())
        
        // Timestamp (4字节) - 从Double转换为Int32
        let timestampInt = covertedInt32Timestamp(timestamp: timestamp)
        data.append(contentsOf: timestampInt.toBytes())
        
        // 处理消息内容
        let messageData = Data(message.utf8)
        let msgLen = UInt16(messageData.count)
        
        // MsgLen (2字节)
        data.append(contentsOf: msgLen.toBytes())
        
        // Msg (n字节)
        data.append(messageData)
        
        return data
    }
    
    // MARK: - 0x05: 发送获取好友位置的请求
    public static func generateRequestFriendLocation(friendId: Int, conversationId: String, timestamp: Double) -> Data? {
        var data = Data()
        
        // 消息类型 (1字节) - 0x05
        data.append(MessageType.requestFriendLocation.rawValue)
        
        // FriendId (1字节) - 从字符串转换为UInt8
        data.append(UInt8(friendId))
        
        // conversationId (8字节) - 从字符串转换为UInt64
        guard let conversationIdUInt = UInt64(conversationId) else {
            debugPrint("ConversationId 转换失败")
            return nil
        }
        data.append(contentsOf: conversationIdUInt.toBytes())
        
        // Timestamp (4字节) - 从Double转换为Int32
        let timestampInt = covertedInt32Timestamp(timestamp: timestamp)
        data.append(contentsOf: timestampInt.toBytes())
        
        return data
    }
    
    // MARK: - 辅助方法
    
    // 将手机号字符串转成 6 字节 BCD（输入可包含 +, 空格, '-' 会被移除）
    private static func phoneToBcd6(_ phone: String) -> Data {
        guard phone != "" else {
            debugPrint("phone null")
            return Data(count: 6)
        }
        
        // 移除所有非数字字符
        let digits = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // 如果是11位，前面补0
        var processedDigits = digits
        if processedDigits.count == 11 {
            processedDigits = "0" + processedDigits
        }
        
        // 检查是否为12位
        guard processedDigits.count == 12 else {
            debugPrint("phone digits must be 11 or 12 after cleaning, got: \(processedDigits.count)")
            return Data(count: 6)
        }
        
        var bcdData = Data(count: 6)
        
        for i in 0..<6 {
            let startIndex = i * 2
            let endIndex = startIndex + 1
            
            if let hiChar = processedDigits[safe: startIndex],
               let loChar = processedDigits[safe: endIndex],
               let hi = UInt8(String(hiChar)),
               let lo = UInt8(String(loChar)) {
                
                let bcdByte = (hi << 4) | (lo & 0x0F)
                bcdData[i] = bcdByte
            }
        }
        
        return bcdData
    }
    
    // 从Double转换为Int32
    private static func covertedInt32Timestamp(timestamp: Double) -> Int32 {
        // 使用四舍五入处理小数部分，避免精度损失
        let roundedTimestamp = timestamp.rounded()
        
        // 检查是否在Int32的取值范围内
        guard roundedTimestamp >= Double(Int32.min) && roundedTimestamp <= Double(Int32.max) else {
            debugPrint("Timestamp 超出Int32取值范围: \(timestamp)")
            return 0
        }
        
        let timestampInt = Int32(roundedTimestamp)
        return timestampInt 
    }
}

// MARK: - 扩展：数据类型转换
extension UInt64 {
    func toBytes() -> [UInt8] {
        return [
            UInt8((self >> 56) & 0xFF),
            UInt8((self >> 48) & 0xFF),
            UInt8((self >> 40) & 0xFF),
            UInt8((self >> 32) & 0xFF),
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}

extension Int32 {
    func toBytes() -> [UInt8] {
        return [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}

extension UInt16 {
    func toBytes() -> [UInt8] {
        return [
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}
