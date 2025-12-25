//
//  TeamModels.swift
//  ModuleTeam
//
//  Created by zhaobo on 2025/12/4.
//

import Foundation
import WCDBSwift

/// 网络响应模型
public struct MQTTResponse<T: Codable>: Codable {
    public let code: String?
    public let msg: String?
    public let data: T?
    public let requestId: String?
    
    /// 检查响应是否成功（code为00000）
    public var isSuccess: Bool {
        return code == "00000"
    }
}

/// 空响应模型
public struct MQTTEmptyResponse: Codable {
    public init() {}
}


// MARK: - 会话类型
public enum ConversationType: Int, Codable, CaseIterable, ColumnCodable {
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
    
    // MARK: - ColumnCodable Protocol
    public static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

//"messageType": "消息类型（0-聊天消息 1-SOS消息 2-安全上报 3-系统提示 4-平台通知 5-快捷语 6-定位）"
/// 消息类型
public enum MessageType: Int, Codable, ColumnCodable {
    case chat = 0
    case sos = 1
    case safety = 2
    case system = 3
    case platform = 4
    case quickCommand = 5
    case location = 6
    
    // MARK: - ColumnCodable Protocol
    public static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

// MARK: - 会话模型（核心）
public struct Conversation: TableCodable {
    let id: String?
    let teamId: String?
    let teamSize: Int?
    let name: String?
    let type: ConversationType?
    let createTime: Int64?
    var latestMessage: LatestMessage?
    var unreadCount: Int?
    
    // 使用CodingKeys枚举来控制哪些字段需要解析
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Conversation
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
        case id
        case teamId
        case teamSize
        case name
        case type
        case createTime
        case latestMessage
        case unreadCount
        // 要忽略的字段不添加到CodingKeys中
    }
}

// MARK: - 消息模型（核心）
public struct Message: TableCodable {
    let id: String?
    let conversationId: String?
    let sender: User?
    let content: String?
    let sendTime: Int64?
    let messageType: MessageType?
    let location: ReportLocation?
    
    // 使用CodingKeys枚举来控制哪些字段需要解析
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Message
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case id
        case conversationId
        case sender
        case content
        case sendTime
        case messageType
        case location
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id"),
                .conversationId: ColumnConstraintConfig(conversationId, isPrimary: true, defaultTo: "conversationId")
            ]
        }
    }
}

// MARK: - 最新消息模型
public struct LatestMessage: ColumnCodable {
    let id: String?
    let sendId: String?
    let senderName: String?
    let content: String?
    let messageTime: Int64?

    init(id: String? = nil, sendId: String? = nil, senderName: String? = nil, content: String? = nil, messageTime: Int64? = nil) {
        self.id = id
        self.sendId = sendId
        self.senderName = senderName
        self.content = content
        self.messageTime = messageTime
    }
    
    public static var columnType: WCDBSwift.ColumnType {
        return .BLOB
    }
    
    public init?(with value: WCDBSwift.Value) {
        let data = value.dataValue
        if data.isEmpty {
            // 允许空值，初始化为全 nil 的实例
            self.id = nil
            self.sendId = nil
            self.senderName = nil
            self.content = nil
            self.messageTime = nil
            return
        }
        
        guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            // 如果不是合法 JSON，也返回空实例（或 nil，根据需求）
            self.id = nil
            self.sendId = nil
            self.senderName = nil
            self.content = nil
            self.messageTime = nil
            return
        }
        
        self.id = jsonDict["id"] as? String
        self.sendId = jsonDict["sendId"] as? String
        self.senderName = jsonDict["senderName"] as? String
        self.content = jsonDict["content"] as? String
        self.messageTime = jsonDict["messageTime"] as? Int64
    }
    
//    public init?(with value: WCDBSwift.Value) {
//        let data = value.dataValue
//        guard data.count > 0,
//              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
//            return nil
//        }
//        
//        guard let id = jsonDict["id"] as? String else {
//            return nil
//        }
//        
//        self.id = id
//        self.sendId = jsonDict["sendId"] as? String
//        self.senderName = jsonDict["senderName"] as? String
//        self.content = jsonDict["content"] as? String
//        self.messageTime = jsonDict["messageTime"] as? Int64
//    }
    
    public func archivedValue() -> WCDBSwift.Value {
        var jsonDict: [String: Any] = [:]
        jsonDict["id"] = id
        jsonDict["sendId"] = sendId
        jsonDict["senderName"] = senderName
        jsonDict["content"] = content
        jsonDict["messageTime"] = messageTime
        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
            return FundamentalValue.init(Data())
        }
        
        return FundamentalValue.init(data)
    }
}

/**
 {
   "id": "队伍id",
   "number": "TEAM001",
   "name": "队伍名称",
   "ownerId": "队长id",
   "createdTime": "创建时间",
   "members": [
     {
       "userId": "用户id",
       "nickname": "用户昵称",
       "avatar": "用户头像",
       "shortId":"用户短Id"
       "type":"队员类型 0-员工 1-队长"
     }
   ],
   "conversationId": "会话id"
 }
 */

enum MemberType: Int, ColumnCodable {
    case employee = 0
    case captain = 1
    
    public static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

// MARK: - 团队数据模型
struct Team: TableCodable {
    let id: String?
    let number: String?
    let teamAvatar: String?
    let name: String?
    let ownerId: String?
    let createdTime: Int64?
    let members: [Member]?
    let conversationId: String?
    let isDisband: Bool?
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Team
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case number
        case teamAvatar
        case name
        case ownerId
        case createdTime
        case members
        case conversationId
        case isDisband
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id")
            ]
        }
    }
}

// MARK: - 成员数据模型
struct Member: ColumnCodable {
    let userId: String?
    let nickname: String?
    let avatar: String?
    let phone: String?
    let shortId: Int?
    let type: MemberType?
    
    var selected: Bool = false
    
    // 定义CodingKeys枚举，只包含需要从JSON解析的字段
    enum CodingKeys: String, CodingKey {
        case userId
        case nickname
        case avatar
        case phone
        case shortId
        case type
        // 不要包含selected字段，这样JSON解析时就会忽略它
    }
    
    public static var columnType: WCDBSwift.ColumnType {
        return .BLOB
    }
    
    public init?(with value: WCDBSwift.Value) {
        let data = value.dataValue
        guard data.count > 0,
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        guard let userId = jsonDict["userId"] as? String else {
            return nil
        }
        
        self.userId = userId
        self.nickname = jsonDict["nickname"] as? String
        self.avatar = jsonDict["avatar"] as? String
        self.phone = jsonDict["phone"] as? String
        self.shortId = jsonDict["shortId"] as? Int
        self.type = MemberType(rawValue: jsonDict["type"] as? Int ?? 0)
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        var jsonDict: [String: Any] = [:]
        jsonDict["userId"] = userId
        jsonDict["nickname"] = nickname
        jsonDict["avatar"] = avatar
        jsonDict["phone"] = phone
        jsonDict["shortId"] = shortId
        jsonDict["type"] = type?.rawValue
        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
            return FundamentalValue.init(Data())
        }
        
        return FundamentalValue.init(data)
    }
}

struct User: ColumnCodable {
    let id: String?
    let nickname: String?
    let avatar: String?
    let phone: String?
    
    public static var columnType: WCDBSwift.ColumnType {
        return .BLOB
    }
    
    // 添加默认初始化方法
    public init(id: String? = nil, nickname: String? = nil, avatar: String? = nil, phone: String? = nil) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.phone = phone
    }
    
    public init?(with value: WCDBSwift.Value) {
        let data = value.dataValue
        guard data.count > 0,
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        guard let id = jsonDict["id"] as? String else {
            return nil
        }
        
        self.id = id
        self.nickname = jsonDict["nickname"] as? String
        self.avatar = jsonDict["avatar"] as? String
        self.phone = jsonDict["phone"] as? String
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        var jsonDict: [String: Any] = [:]
        jsonDict["id"] = id
        jsonDict["nickname"] = nickname
        jsonDict["avatar"] = avatar
        jsonDict["phone"] = phone
        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
            return FundamentalValue.init(Data())
        }
        
        return FundamentalValue.init(data)
    }
}

struct MessagePage: Codable {
    let records: [Message]?
    let total: String?
    let size: String?
    let current: String?
}


/*
{
  "mode": "模式 0-获取位置 1-返回结果",
   "userId":"用户Id",
  "coordinate": {
    "longitude": "经度",
    "latitude": "纬度"
  }
*/
struct Coordinate: Codable {
    let longitude: Double?
    let latitude: Double?
}

struct UserLocation: Codable {
    let mode: Int?
    let userId: String?
    let coordinate: Coordinate?
}

struct ReportLocation: ColumnCodable {
    let longitude: Double?
    let latitude: Double?
    let reportTime: TimeInterval?
    
    public static var columnType: WCDBSwift.ColumnType {
        return .BLOB
    }
    
    // 添加默认初始化方法
    public init(longitude: Double? = nil, latitude: Double? = nil, reportTime: TimeInterval? = nil) {
        self.longitude = longitude
        self.latitude = latitude
        self.reportTime = reportTime
    }
    
    public init?(with value: WCDBSwift.Value) {
        let data = value.dataValue
        guard data.count > 0,
              let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        self.longitude = jsonDict["longitude"] as? Double
        self.latitude = jsonDict["latitude"] as? Double
        self.reportTime = jsonDict["reportTime"] as? TimeInterval
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        var jsonDict: [String: Any] = [:]
        jsonDict["longitude"] = longitude
        jsonDict["latitude"] = latitude
        jsonDict["reportTime"] = reportTime
        guard let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) else {
            return FundamentalValue.init(Data())
        }
        
        return FundamentalValue.init(data)
    }
}

/*
{
  "conversationId": "会话ID",
  "messageId": "消息Id"
}
*/
 struct NewMessage: Codable {
    let conversationId: String?
    let messageId: String?
}
