//
//  MessageManager.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/1/8.
//

import Foundation
import SWKit
import SWNetwork
import WCDBSwift

class MessageManager: MQTTManagerDelegate {    
    
    static let shared = MessageManager()
    
    /// 服务中心会话ID
    public static var serviceConversationId: String {
        return UserManager.shared.userId
    }
    /// 发送者本人
    public static var sender: User = {
        let sender = User(id: UserManager.shared.userId,
                          nickname: UserManager.shared.userInfo?.nickname,
                          avatar: UserManager.shared.userInfo?.avatar,
                          phone: UserManager.shared.userInfo?.phone,
                          role: 0)
        return sender
    }()
    
    func startMonitorMessage() {
        // 监听窄带设备的自定义消息
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveDeviceCustomMessage(_:)),
            name: .didReceiveDeviceCustomMsg,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveOfflineReportState(_:)),
            name: .offlineReportState,
            object: nil
        )
        
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: MessageAPI.receiveMessage_sub)
    }
    
    func stopMonitorMessage() {
        //MQTTManager 统一处理退出登录 remove Delegate 和 remove Subscribe
        NotificationCenter.default.removeObserver(self, name: .didReceiveDeviceCustomMsg, object: nil)
        
        MQTTManager.shared.removeDelegate(self)
        MQTTManager.shared.unsubscribe(from: MessageAPI.receiveMessage_sub)
    }
    
    func didRecevieMessage(_ message: Message) {
        guard let convId = message.conversationId else {
            return
        }
        // 1. 根据message的conversationId查询会话
        if var conversation = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self, where: Conversation.Properties.id == convId)?.first {
            
            // 2. 更新未读消息数
            if let unreadCount = conversation.unreadCount {
                conversation.unreadCount = unreadCount + 1
            } else {
                conversation.unreadCount =  1
            }
            
            // 3. 更新会话的最后消息信息
            conversation.latestMessage = message
            
            // 4. 将更新后的会话保存到数据库
            DBManager.shared.insertToDb(objects: [conversation], intoTable: DBTableName.conversation.rawValue)
        }
        
        // 5. 将消息保存到数据库
        DBManager.shared.insertToDb(objects: [message], intoTable: DBTableName.message.rawValue)
        
        // 6. 发送通知
        NotificationCenter.default.post(name: .receiveNewMessage, object: message)
    }
    
    // MARK: - Notification
    
    /// 收到离线上报状态的通知（SOS/报平安）
    @objc private func receiveOfflineReportState(_ notification: Notification) {
        Logger.debug("[离线上报] 收到通知: \(notification.object ?? "未知")")

        // 如果 ReportType 是枚举，可能需要用 rawValue 或者从 userInfo 中获取
        guard let type = notification.object as? ReportType else {
            // 如果类型转换失败，尝试其他方式
            Logger.debug("[离线上报] 类型转换失败")
            return
        }

        guard var message = MessageManager.generateTxtMessage(convId: MessageManager.serviceConversationId, content: type.reportStateTip) else {
            return
        }
        
        message.offline = true

        didRecevieMessage(message)
    }

    /// 窄带设备自定义消息(用于无网络接收消息)
    @objc private func receiveDeviceCustomMessage(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? Data else {
            return
        }

        print("获取到的自定义消息0---\(data.hexString)")
        if var message = parseDeviceCustomMessage(data) {
            // 设置为离线，代表离线接收的，以便后面标识同步服务端
            message.offline = true

            didRecevieMessage(message)
        }
    }
    
    // MARK: - Tool
    
    private func parseDeviceCustomMessage(_ data: Data) -> Message? {
        /**
         Payload:
         06 [ SenderID(8) | TargetID(8)|messageType(1)|role(1) | Timestamp(4)|lon(4) | lat(4)  | MsgLen(2) | Msg(n) ]
         */
        guard data.count > 23 else {
            Logger.debug("设备信息数据长度错误: \(data.count)")
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
        
        // 发送者角色（1字节）
        let role = data[offset]
        offset += 1
        
        // 时间戳 (4字节)
        var timestamp: Int32 = 0
        timestamp |= Int32(data[offset]) << 24
        timestamp |= Int32(data[offset + 1]) << 16
        timestamp |= Int32(data[offset + 2]) << 8
        timestamp |= Int32(data[offset + 3])
        offset += 4
        
        let sendTimestamp = Int64(timestamp) * 1000
        
        var nickname: String?
        if [1, 2, 3, 4].contains(messageType) {
            nickname = "天行探索平台"
        }
        if role == 1 {
            nickname = (UserManager.shared.emergencyContact?.first?.name ?? UserManager.shared.emergencyContact?.first?.phone) ?? "紧急联系人"
        }
        
        let sender = User(id: String(senderId),
                          nickname: nickname,
                          avatar: nil,
                          phone: nil,
                          role: Int(role))
        
        if messageType == 1 || messageType == 2 || messageType == 6 {
            // 1+8+8+1+1+4+4+4 = 31
            guard data.count >= 31 else {
                Logger.debug("设备信息数据长度错误: \(data.count)")
                return nil
            }

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
            
            Logger.debug("✅ 解析出来的数据:")
            Logger.debug("  命令指令: 0x\(protocolVersion)")
            Logger.debug("  用户ID: \(senderId)")
            Logger.debug("  会话ID: \(conversationId)")
            Logger.debug("  消息类型: \(messageType)")
            Logger.debug("  用户角色: \(role)")
            Logger.debug("  经度: \(Double(lon)/1e7)")
            Logger.debug("  纬度: \(Double(lat)/1e7)")
            Logger.debug("  时间戳: \(timestamp)")
            
            
            let location = IMLocation(longitude: Double(lon)/1e7,
                                      latitude: Double(lat)/1e7,
                                      address: nil,
                                      addressName: nil)
            
            return  Message(id: String(-timestamp),
                            conversationId: String(conversationId),
                            sender: sender,
                            content: nil,
                            sendTimeTimestamp: sendTimestamp,
                            messageType: MessageType(rawValue: Int(messageType)),
                            location: location)
        } else {
            // 1+8+8+1+1+4+2+n >= 25
            
            guard data.count > 25 else {
                Logger.debug("设备信息数据长度错误: \(data.count)")
                return nil
            }
            
            // msgLength (2字节)
            offset += 2
            
            let msg = String(data: data[offset...], encoding: .utf8) ?? ""
            offset += msg.count
            
            Logger.debug("✅ 解析出来的数据:")
            Logger.debug("  命令指令: 0x\(protocolVersion)")
            Logger.debug("  用户ID: \(senderId)")
            Logger.debug("  会话ID: \(conversationId)")
            Logger.debug("  消息类型: \(messageType)")
            Logger.debug("  用户角色: \(role)")
            Logger.debug("  时间戳: \(timestamp)")
            Logger.debug("  消息内容: \(msg)")
            
            return  Message(id: String(-timestamp),
                            conversationId: String(conversationId),
                            sender: sender,
                            content: msg,
                            sendTimeTimestamp: sendTimestamp,
                            messageType: MessageType(rawValue: Int(messageType)),
                            location: nil)
        }
    }
    
    public static func generateTxtMessage(convId: String, content: String) -> Message? {
        guard !convId.isEmpty else {
            return nil
        }
        
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        let message = Message(id: String(-timestamp),
                              conversationId: convId,
                              sender: self.sender,
                              content: content,
                              sendTimeTimestamp: timestamp,
                              messageType: .chat,
                              location: nil,)
        return message
    }
    
    
    //MARK: - MQTT (用于有网络接收消息)
    
    func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == MessageAPI.receiveMessage_sub else {
            return
        }
        do {
            guard let jsonData = message.data(using: .utf8) else {
                Logger.debug("[JSON解析] 消息转换为Data失败")
                return
            }
            
            let rsp = try JSONDecoder().decode(NetworkResponse<Message>.self, from: jsonData)
            if let msg = rsp.data {
                didRecevieMessage(msg)
            }
        } catch {
            Logger.debug("[JSON解析] 解析失败: \(error)")
        }
    }
    
}



