//
//  HomeModel.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/16.
//

import Foundation
import WCDBSwift

/// 提醒类型
enum NoticeType: Int, ColumnCodable {
    case unknown = 0     // 未知类型
    case sos = 1         // SOS紧急求助
    case safety = 2      // 报平安
    case weather = 3     // 天气通知
    case service = 4     // 紧急联系人
    case disarmSOS = 5   // 解除SOS
    
    static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    init?(with value: WCDBSwift.Value) {
        let rawValue = Int(value.int32Value)
        if let type = Self(rawValue: rawValue) {
            self = type
        } else {
            self = .unknown
        }
    }
    
    func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        if let type = Self(rawValue: rawValue) {
            self = type
        } else {
            self = .unknown
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
    
    var title: String {
        switch self {
        case .unknown:
            return "其他"
        case .sos:
            return "SOS报警"
        case .safety:
            return "报平安"
        case .weather:
            return "天气预警"
        case .service:
            return "紧急联系人消息"
        case .disarmSOS:
            return "解除SOS报警"
        }
    }
    
    var icon: String {
        switch self {
        case .unknown:
            return "chat_service_new_icon"
        case .sos:
            return "chat_sos_new_icon"
        case .safety:
            return "chat_safety_new_icon"
        case .weather:
            return "chat_weather_new_icon"
        case .service:
            return "chat_service_new_icon"
        case .disarmSOS:
            return "chat_disarmSos_new_icon"
        }
    }
}
 
struct HomeNoticeItem: TableCodable, Codable {
    public let noticeId: String?
    public let noticeType: NoticeType?
    public let noticeContent: String?
    public let reportId: String?
    public let noticeTimeTimestamp: Int64?
    
    enum CodingKeys: String, CodingTableKey, CodingKey {
        typealias Root = HomeNoticeItem
        
        case noticeId
        case noticeType
        case noticeContent
        case reportId
        case noticeTimeTimestamp
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(noticeId, isPrimary: true)
        }
    }
}
