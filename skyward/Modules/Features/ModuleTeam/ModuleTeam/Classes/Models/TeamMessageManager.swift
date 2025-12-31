//
//  TeamMessageManager.swift
//  ModuleTeam
//
//  Created by zhaobo on 2025/12/11.
//

import Foundation
import SWNetwork
import SWKit

/**
 ● SenderID：发送者id
 ● TargetID: 会话id
 ● messageType: 消息类型（0-聊天消息 1-SOS消息 2-安全上报 3-系统提示 4-平台通知 5-快捷语 6-好友位置）
 ● lon：经度
 ● lat：维度
 ● Timestamp: 秒级时间戳
 ● MsgLen：文本长度：
 ● Msg：文本内容；
 */

class DeviceCustomMessage {
    var senderId: UInt64
    var targetId: UInt64
    var messageType: UInt8
    var lon: Double
    var lat: Double
    var timestamp: UInt32
    var msg: String
    
    init(senderId: UInt64, targetId: UInt64, messageType: UInt8, lon: Double, lat: Double, timestamp: UInt32, msg: String) {
        self.senderId = senderId
        self.targetId = targetId
        self.messageType = messageType
        self.lon = lon
        self.lat = lat
        self.timestamp = timestamp
        self.msg = msg
    }
    
    func convertMessage() -> Message {
        let senderId = String(senderId)
        let convId = String(targetId)
        let msgType = MessageType(rawValue: Int(messageType))
        let timestamp = Int64(self.timestamp)
        let conversation = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self)?.first(where: {$0.id == convId})
        let team = DBManager.shared.queryFromDb(fromTable: DBTableName.team.rawValue, cls: Team.self)?.first(where: {$0.id == conversation?.teamId})
        let member = team?.members?.first(where: {$0.userId == senderId})
        let sender = User(id: member?.userId, nickname: member?.nickname, avatar: member?.avatar, phone: member?.phone)
        
        if messageType == 1 || messageType == 2 || messageType == 6 {
            let location = ReportLocation(longitude: lon, latitude: lat, reportTime: Double(timestamp))
            return Message(id: "device", conversationId: convId, sender: sender, content: msg, sendTime: timestamp, messageType: msgType, location: location)
        }
        return Message(id: "device", conversationId: convId, sender: sender, content: msg, sendTime: timestamp, messageType: msgType, location: nil)
    }
}

class TeamMessageManager: MQTTManagerDelegate {
    
    static let shared = TeamMessageManager()
    
    init() {
        DBManager.shared.createTable(table: DBTableName.conversation.rawValue, of: Conversation.self)
        DBManager.shared.createTable(table: DBTableName.message.rawValue, of: Message.self)
        DBManager.shared.createTable(table: DBTableName.team.rawValue, of: Team.self)
    }
    
    func startMonitorNewMessage() {
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: TeamAPI.receiveMessage_sub , qos: .qos1)
        
        // 监听窄带设备的自定义消息
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveDeviceCustomMessage(_:)),
            name: .didReceiveDeviceCustomMsg,
            object: nil
        )
    }
    
    func didRecevieMessage(_ message: Message) {
        let conversationId = message.conversationId
        // 1. 根据message的conversationId查询会话
        if var conversation = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self)?.first(where: {$0.id == conversationId}) {
            
            // 2. 更新未读消息数
            if let unreadCount = conversation.unreadCount {
                conversation.unreadCount = unreadCount + 1
            } else {
                conversation.unreadCount =  1
            }
            
            // 3. 更新会话的最后消息信息
            let latestMessage = LatestMessage(id: message.id,
                                              sendId: message.sender?.id,
                                              senderName: message.sender?.nickname,
                                              content: message.content,
                                              messageTime: message.sendTime)
            conversation.latestMessage = latestMessage
            
            // 4. 将更新后的会话保存到数据库
            DBManager.shared.insertToDb(objects: [conversation], intoTable: DBTableName.conversation.rawValue)
        }
        
        // 5. 将消息保存到数据库
        DBManager.shared.insertToDb(objects: [message], intoTable: DBTableName.message.rawValue)
        
        // 6. 发送通知
        NotificationCenter.default.post(name: .receiveTeamNewMessage, object: message)
    }
    
    // MARK:
    func mqttManager(_ manager: SWNetwork.MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == TeamAPI.receiveMessage_sub else {
            return
        }
        
        do {
            guard let jsonData = message.data(using: .utf8) else {
                print("[JSON解析] 消息转换为Data失败")
                return
            }
            let rsp = try JSONDecoder().decode(MQTTResponse<Message>.self, from: jsonData)
            guard rsp.isSuccess else {
                print("[MQTT] 响应失败: \(String(describing: rsp.msg))")
                return
            }
            if let msg = rsp.data {
                didRecevieMessage(msg)
            }
            
        } catch {
            print("[JSON解析] 解析失败: \(error)")
        }
    }
    
    // MARK: - 窄带设备自定义消息

    @objc private func receiveDeviceCustomMessage(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? Data else {
            return
        }
        
        if let deviceMessage = parseDeviceCustomMessage(data) {
            let msg = deviceMessage.convertMessage()
            didRecevieMessage(msg)
            print("IM消息解析结果: senderId=\(deviceMessage.senderId), targetId=\(deviceMessage.targetId), timestamp=\(deviceMessage.timestamp), msg=\(deviceMessage.msg)")
        }
    }
    
    func parseDeviceCustomMessage(_ data: Data) -> DeviceCustomMessage? {
        guard data.count >= 24 else {
            print("设备信息数据长度错误: \(data.count)")
            return nil
        }
        
        var offset = 0
        
        // 命令指令(1字节)
        let protocolVersion = data[offset]
        guard protocolVersion == 6 else {
            return nil
        }
        offset += 1
        
        // 发送者ID (8字节)
        var senderId: UInt64 = 0
        senderId |= UInt64(data[offset]) << 56
        senderId |= UInt64(data[offset + 1]) << 48
        senderId |= UInt64(data[offset + 2]) << 40
        senderId |= UInt64(data[offset + 3]) << 32
        senderId |= UInt64(data[offset + 4]) << 24
        senderId |= UInt64(data[offset + 5]) << 16
        senderId |= UInt64(data[offset + 6]) << 8
        senderId |= UInt64(data[offset + 7])
        offset += 8
        
        // 会话ID (8字节)
        var conversationId: UInt64 = 0
        conversationId |= UInt64(data[offset]) << 56
        conversationId |= UInt64(data[offset + 1]) << 48
        conversationId |= UInt64(data[offset + 2]) << 40
        conversationId |= UInt64(data[offset + 3]) << 32
        conversationId |= UInt64(data[offset + 4]) << 24
        conversationId |= UInt64(data[offset + 5]) << 16
        conversationId |= UInt64(data[offset + 6]) << 8
        conversationId |= UInt64(data[offset + 7])
        offset += 8
        
        // 会话类型 (1字节)
        let messageType = data[offset]
        offset += 1
        
        if messageType == 1 || messageType == 2 || messageType == 6 {
            // 1+8+8+1+4+4+4
            // 经度 (4字节)
            var lon: Int32 = 0
            lon |= Int32(data[offset]) << 24
            lon |= Int32(data[offset + 1]) << 16
            lon |= Int32(data[offset + 2]) << 8
            lon |= Int32(data[offset + 3])
            offset += 4
            
            // 纬度 (4字节)
            var lat: Int32 = 0
            lat |= Int32(data[offset]) << 24
            lat |= Int32(data[offset + 1]) << 16
            lat |= Int32(data[offset + 2]) << 8
            lat |= Int32(data[offset + 3])
            offset += 4
            
            // 时间戳 (4字节)
            var timestamp: Int32 = 0
            timestamp |= Int32(data[offset]) << 24
            timestamp |= Int32(data[offset + 1]) << 16
            timestamp |= Int32(data[offset + 2]) << 8
            timestamp |= Int32(data[offset + 3])
            offset += 4
            
            print("✅ 解析出来的数据:")
            print("  命令指令: 0x\(protocolVersion)")
            print("  用户ID: \(senderId)")
            print("  会话ID: \(conversationId)")
            print("  消息类型: \(messageType)")
            print("  经度: \(Double(lon)/1e7)")
            print("  纬度: \(Double(lat)/1e7)")
            print("  时间戳: \(timestamp)")
            return DeviceCustomMessage(senderId: senderId,
                                       targetId: conversationId,
                                       messageType: messageType,
                                       lon: (Double(lon)/1e7),
                                       lat: (Double(lat)/1e7),
                                       timestamp: UInt32(timestamp),
                                       msg: "")
        } else {
            // 1+8+8+1+4+2+n
            // 时间戳 (4字节)
            var timestamp: Int32 = 0
            timestamp |= Int32(data[offset]) << 24
            timestamp |= Int32(data[offset + 1]) << 16
            timestamp |= Int32(data[offset + 2]) << 8
            timestamp |= Int32(data[offset + 3])
            offset += 4
            
//            let msgLength = Int32(data[offset]) << 8 | Int32(data[offset + 1])
            offset += 2
            
            let msg = String(data: data[offset...], encoding: .utf8) ?? ""
            offset += msg.count
            
            print("✅ 解析出来的数据:")
            print("  命令指令: 0x\(protocolVersion)")
            print("  用户ID: \(senderId)")
            print("  会话ID: \(conversationId)")
            print("  消息类型: \(messageType)")
            print("  时间戳: \(timestamp)")
            print("  消息内容: \(msg)")
            return DeviceCustomMessage(senderId: senderId,
                                       targetId: conversationId,
                                       messageType: messageType,
                                       lon: 0.0,
                                       lat: 0.0,
                                       timestamp: UInt32(timestamp),
                                       msg: msg)
        }
    }
    
    
}
