//
//  HomeModel.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/16.
//

import Foundation

/// 提醒类型
enum NoticeType: Int, Codable {
    case all = -1        // 所有
    case sos = 1         // SOS紧急求助
    case safety = 2      // 报平安
    case weather = 3     // 天气通知
    case service = 4     // 紧急联系人
    
    var title: String {
        switch self {
        case .all:
            return "全部"
        case .sos:
            return "SOS报警"
        case .safety:
            return "报平安"
        case .weather:
            return "天气预警"
        case .service:
            return "紧急联系人"
        }
    }
    
    var icon: String? {
        switch self {
        case .sos:
            return "chat_sos_icon"
        case .safety:
            return "chat_safety_icon"
        case .weather:
            return "chat_weather_icon"
        case .service:
            return "chat_service_icon"
        default:
            return ""
        }
    }
}

struct NoticeTypeItem {
    let noticeType: NoticeType
    var selected: Bool
    var count: Int
    var desc: String {
        return noticeType.title + " \(count)"
    }
}
 
struct HomeNoticeItem: Codable {
    public let noticeId: String?
    public let noticeType: NoticeType
    public let noticeContent: String?
    public let reportId: String?
    public let noticeTime: Int64?
    
    public init(
        noticeId: String?,
        noticeType: NoticeType,
        noticeContent: String?,
        reportId: String?,
        noticeTime: Int64?
    ) {
        self.noticeId = noticeId
        self.noticeType = noticeType
        self.noticeContent = noticeContent
        self.reportId = reportId
        self.noticeTime = noticeTime
    }
}

struct HomeNewMessageModel: Codable {
    public let message: String?
    public let sendTime: Int64?
    public let sendId: String?
}

 struct HomeNoticeModel: Codable {
    public let totalCount: Int
    public let safeCount: Int
    public let sosCount: Int
    public let weatherCount: Int
    public let safeList: [HomeNoticeItem]
    public let sosList: [HomeNoticeItem]
    public let weatherList: [HomeNoticeItem]
    
    public init(
        totalCount: Int,
        safeCount: Int,
        sosCount: Int,
        weatherCount: Int,
        safeList: [HomeNoticeItem],
        sosList: [HomeNoticeItem],
        weatherList: [HomeNoticeItem]
    ) {
        self.totalCount = totalCount
        self.safeCount = safeCount
        self.sosCount = sosCount
        self.weatherCount = weatherCount
        self.safeList = safeList
        self.sosList = sosList
        self.weatherList = weatherList
    }
    
    // 获取所有通知列表
    public var allNotices: [HomeNoticeItem] {
        return sosList + safeList + weatherList
    }
    
    // 根据类型获取通知列表
    public func notices(ofType type: NoticeType) -> [HomeNoticeItem] {
        switch type {
        case .sos:
            return sosList
        case .safety:
            return safeList
        case .weather:
            return weatherList
        default:
            return []
        }
    }
}

// MARK: - Mock响应数据

// MARK: - 响应模型
struct HomeResponseModel: Codable {
    public let code: String
    public let data: HomeNoticeModel
    public let msg: String
    
    public init(code: String, data: HomeNoticeModel, msg: String) {
        self.code = code
        self.data = data
        self.msg = msg
    }
}

