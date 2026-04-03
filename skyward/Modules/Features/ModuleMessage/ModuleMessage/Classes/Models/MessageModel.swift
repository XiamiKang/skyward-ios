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
struct User: ColumnJSONCodable {
    @Flexible var id: String?
    let nickname: String?
    let avatar: String?
    let phone: String?
    /// 角色：（0-群主 1-紧急联系人 2-系统  3-救援队 4-保险公司）
    let role: Int?
}

// MARK: - 消息状态
enum MessageStatus: Int, ColumnCodable {
    case sending      // 发送中
    case sent         // 已发送
    case failed       // 发送失败
    
    // ColumnCodable Protocol
    static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

// MARK: - 消息内容类型（可扩展：文本、图片、语音、文件等）
//enum MessageType {
//    case text(String)
//    case image(URL)
//    case voice(duration: TimeInterval)
//    case systemNotice(String) // 如“XXX加入了群聊”
//    
//    var displayText: String {
//        switch self {
//        case .text(let text):
//            return text
//        case .image:
//            return "[图片]"
//        case .voice:
//            return "[语音消息]"
//        case .systemNotice(let notice):
//            return notice
//        }
//    }
//}

/// 消息类型 : "消息类型（0-聊天消息 1-SOS消息 2-安全上报 3-系统提示 4-平台通知 5-快捷语 6-定位）"
enum MessageType: Int, ColumnCodable {
    case chat = 0
    case sos = 1
    case safety = 2
    case system = 3
    case platform = 4
    case quickCommand = 5
    case location = 6
    
    // ColumnCodable Protocol
    static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

// MARK: - 会话类型
enum ConversationType: Int, ColumnCodable {
    case single = 1  // 单聊
    case group     // 群聊
    case system  // 系统通知
    case service   // 客服/服务号
    
    static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
    
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

// MARK: - 消息模型（核心）
struct Message: TableCodable, ColumnJSONCodable {
    var id: String?
    let conversationId: String?
    let sender: User?
    let content: String?
    var sendTimeTimestamp: Int64? // 后端取的名
    let messageType: MessageType?
    let location: IMLocation?
    
    // 非服务器字段
    // 消息发送状态
    var status: MessageStatus?
    // 是否是离线消息
    var offline: Bool?
    
    // 非服务器和数据库字段
    var previousMessageTimestamp: Int64?
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = Message

        case id
        case conversationId
        case sender
        case content
        case sendTimeTimestamp
        case messageType
        case location
        
        case status
        case offline
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
    }
}

// MARK: - 会话模型（核心）
struct Conversation: TableCodable {
    let id: String?
    let name: String?
    let type: ConversationType?
    let createTimeTimestamp: Int64? // 后端取的名
    var latestMessage: Message?
    var unreadCount: Int?
    let enable: Bool?
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = Conversation
        
        case id
        case name
        case type
        case createTimeTimestamp
        case latestMessage
        case unreadCount
        case enable
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
    }
    
    static func serviceConversation() -> Conversation {
        let date = DateFormatter.fullPretty.date(from: UserManager.shared.userInfo?.createTime ?? "2025-08-01 00:00:01") ?? Date()
        let timestamp = Int64(date.timeIntervalSince1970 * 1000)
        return Conversation(id: MessageManager.serviceConversationId,
                            name: "服务中心",
                            type: .group,
                            createTimeTimestamp: timestamp,
                            enable: true)
    }
}

struct MessageList: Codable {
    let list: [Message]?
    let total: Int?
}

struct IMLocation: ColumnJSONCodable {
    let longitude: Double?
    let latitude: Double?
    let address: String?
    let addressName: String?
}
