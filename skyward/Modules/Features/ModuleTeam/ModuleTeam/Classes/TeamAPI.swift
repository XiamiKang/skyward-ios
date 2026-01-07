//
//  TeamAPI.swift
//  ModuleTeam
//
//  Created by zhaobo on 2025/12/4.
//

import Foundation
import Moya
import SWKit
import SWNetwork

public enum TeamAPI {
    // 会话列表
    public static var convList_pub: String {
        return "txts/im/apptoserver/conversation/list/\(UserManager.shared.userId)"
    }
    public static var convList_sub: String {
        return "txts/im/servertoapp/conversation/list/\(UserManager.shared.userId)"
    }
    
    // 队伍信息
    public static var teamInfo_pub: String {
        return "txts/im/apptoserver/team/info/\(UserManager.shared.userId)"
    }
    public static var teamInfo_sub: String {
        return "txts/im/servertoapp/team/info/\(UserManager.shared.userId)"
    }
    // 加入队伍
    public static var joinTeam_pub: String {
        return "txts/im/apptoserver/team/join/\(UserManager.shared.userId)"
    }
    // 移除队伍成员
    public static var removeMember_pub: String {
        return "txts/im/apptoserver/team/removeMember/\(UserManager.shared.userId)"
    }
    // 更新队伍信息
    public static var teamUpdate_pub: String {
        return "txts/im/apptoserver/team/update/\(UserManager.shared.userId)"
    }
    // 解散队伍
    public static var teamDisband_pub: String {
        return "txts/im/apptoserver/team/disband/\(UserManager.shared.userId)"
    }
    // 获取队伍成员定位
    public static var memberLoaction_pub: String {
        return "txts/im/apptoserver/team/friendLocation/\(UserManager.shared.userId)"
    }
    public static var memberLoaction_sub: String {
        return "txts/im/servertoapp/team/friendLocation/\(UserManager.shared.userId)"
    }
    
    // 消息列表
    public static var messagePage_pub: String {
        return "txts/im/apptoserver/message/page/\(UserManager.shared.userId)"
    }
    public static var messagePage_sub: String {
        return "txts/im/servertoapp/message/page/\(UserManager.shared.userId)"
    }
    // 发送消息
    public static var sendMessage_pub: String {
        return "txts/im/apptoserver/message/send/\(UserManager.shared.userId)"
    }
    // 接收消息
    public static var receiveMessage_sub: String {
        return "txts/im/servertoapp/message/receive/\(UserManager.shared.userId)"
    }
    
    case creatTeam(name: String)
}

extension TeamAPI: NetworkAPI {
    
    public var headers: [String: String]? {
        // 为所有请求添加默认的Accept头
        var defaultHeaders: [String: String] = [
            "Accept": "application/json"
        ]
        guard let token = TokenManager.shared.accessToken else {
            return defaultHeaders
        }
        defaultHeaders["Authorization"] = "Bearer \(token)"
        
        return defaultHeaders
    }
    
    public var path: String {
        switch self {
        case .creatTeam:
            return "/txts-user-center-app/api/v1/teams"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .creatTeam:
            return .post
        }
    }
    
    public var task: Moya.Task {
        switch self {
        case .creatTeam(let name):
            return .requestParameters(parameters: ["name": name], encoding: JSONEncoding.default)
        }
    }
}
