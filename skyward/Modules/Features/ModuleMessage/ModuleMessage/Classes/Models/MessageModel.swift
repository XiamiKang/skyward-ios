//
//  MessageModel.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import Foundation
import WCDBSwift
import SWKit

// MARK: - 用户模型
struct User: Equatable, Hashable {
    let id: String
    let name: String
    let avatarUrl: String?
    
    // 用于标识是否是当前用户（可选，也可在业务层处理）
    var isCurrentUser: Bool = false
}

// MARK: - 消息内容类型（可扩展：文本、图片、语音、文件等）
enum MessageType {
    case text(String)
    case image(URL)
    case voice(duration: TimeInterval)
    case systemNotice(String) // 如“XXX加入了群聊”
    
    var displayText: String {
        switch self {
        case .text(let text):
            return text
        case .image:
            return "[图片]"
        case .voice:
            return "[语音消息]"
        case .systemNotice(let notice):
            return notice
        }
    }
}

// MARK: - 消息状态
enum MessageStatus {
    case sending      // 发送中
    case sent         // 已发送
    case delivered    // 已送达
    case read         // 已读
    case failed       // 发送失败
}

// MARK: - 消息模型
struct Message {
    let id: String
    let conversationId: String?
    let conversationType: ConversationType?
    let content: String
    let sender: User?
    let messageType: MessageType?
    let timestamp: Date?
    let status: MessageStatus?
    
    // 便捷初始化方法，提供默认值
    init(id: String, 
         conversationId: String? = nil, 
         conversationType: ConversationType? = nil, 
         content: String, 
         sender: User? = nil, 
         messageType: MessageType? = nil, 
         timestamp: Date? = Date(), 
         status: MessageStatus? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.conversationType = conversationType
        self.content = content
        self.sender = sender
        self.messageType = messageType
        self.timestamp = timestamp
        self.status = status
    }
    
    // 用于列表显示的简化内容
    var previewText: String {
        messageType?.displayText ?? ""
    }
}

// MARK: - 会话类型
enum ConversationType: Int, Codable, CaseIterable {
    case single   // 单聊
    case group     // 群聊
    case system  // 系统通知
    case service   // 客服/服务号
    
    var displayName: String {
        switch self {
        case .single:
            return "私聊"
        case .group:
            return "群聊"
        case .system:
            return "系统通知"
        case .service:
            return "客服"
        }
    }
}

// MARK: - 会话模型（核心）
struct Conversation {
    let id: String                    // 会话唯一 ID（如：user_123 或 group_abc）
    let type: ConversationType        // 会话类型
    let title: String                 // 会话标题（群名 / 对方昵称 / "系统通知"）
    let avatarUrl: String?            // 会话头像（群头像 / 对方头像 / 默认图标）
    let lastMessage: Message?         // 最后一条消息（可能为空）
    var unreadCount: Int?             // 未读消息数
    let muted: Bool?                   // 是否免打扰
    let pinned: Bool?                  // 是否置顶
    let lastInteractionTime: Date?     // 最后互动时间（用于排序）
    
    // 可选：群聊时的成员列表（单聊时通常只有对方）
    let participants: [User]?         // nil 表示不加载完整成员（按需加载）
    
    // 便捷初始化方法，提供默认值
    init(id: String, 
         type: ConversationType, 
         title: String, 
         avatarUrl: String? = nil, 
         lastMessage: Message? = nil, 
         unreadCount: Int? = 0, 
         muted: Bool? = false, 
         pinned: Bool? = false, 
         lastInteractionTime: Date? = Date(), 
         participants: [User]? = []) {
        self.id = id
        self.type = type
        self.title = title
        self.avatarUrl = avatarUrl
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.muted = muted
        self.pinned = pinned
        self.lastInteractionTime = lastInteractionTime
        self.participants = participants
    }
}

struct UrgentMessageList: Codable {
    public let list: [UrgentMessage]? 
    public let total: Int?
}

struct UrgentMessage: TableCodable, Codable {
    @Flexible var id: String?
    @Flexible var sendId: String?
    @Flexible var receiverId: String?
    let content: String?
    let sendTime: String?
    // 通知类型  1：SOS报警 2：报平安 3：天气 4:紧急通讯 5:紧急通讯消息成功通知
    let type: Int?
    let sendUserBaseInfoVO: UrgentUser?
    let receiveUserBaseInfoVO: UrgentUser?
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = UrgentMessage
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case sendId
        case receiverId
        case content
        case sendTime
        case type
        case sendUserBaseInfoVO
        case receiveUserBaseInfoVO
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id")
            ]
        }
    }
}


struct UrgentUser: ColumnCodable {
    @Flexible var id: String?
    let nickname: String?
    let avatar: String?
    let phone: String?
    // 聊天用户类型 1-普通用户 2-紧急联系人 9-平台
    let imUserType: Int?
    
    public static var columnType: WCDBSwift.ColumnType {
        return .BLOB
    }
    
    // 添加默认初始化方法
    public init(id: String? = nil, nickname: String? = nil, avatar: String? = nil, phone: String? = nil, imUserType: Int? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.phone = phone
        self.imUserType = imUserType
    }
    
    public init?(with value: WCDBSwift.Value) {
        let data = value.dataValue
        guard data.count > 0,
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        self.id = jsonDict["id"] as? String
        self.nickname = jsonDict["nickname"] as? String
        self.avatar = jsonDict["avatar"] as? String
        self.phone = jsonDict["phone"] as? String
        self.imUserType = jsonDict["imUserType"] as? Int
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        let jsonDict: [String: Any] = [
            "id": id ?? "",
            "nickname": nickname ?? "",
            "avatar": avatar ?? "",
            "phone": phone ?? "",
            "imUserType": imUserType ?? 0
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
            return FundamentalValue.init(Data())
        }
        
        return FundamentalValue.init(data)
    }
}
