//
//  MessageAPI.swift
//  Alamofire
//
//  Created by zhaobo on 2025/12/22.
//

import Foundation
import SWNetwork
import Moya
import SWKit

enum MessageAPI {
    case urgentMessages(page: Int, size: Int)
    case sendUrgentMessage(msg: String)
}

extension MessageAPI: NetworkAPI {
    
    var path: String {
        switch self {
        case .urgentMessages:
            return "/txts-user-center-app/api/v1/urgent-message/page/list"
        case .sendUrgentMessage:
            return "/txts-user-center-app/api/v1/urgent-message/sign/add"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .urgentMessages:
            return .get
        case .sendUrgentMessage:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .urgentMessages(let page, let size):
            // 将经纬度参数作为查询参数添加到URL中
            let parameters: [String: Any] = [
                "pageNum": page,
                "pageSize": size
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .sendUrgentMessage(let msg):
            return .requestParameters(parameters: ["content" : msg], encoding: JSONEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}

// 接收消息
// 将MQTT接口定义从let常量改为计算属性，确保每次访问都能获取最新的userId
var receiveUrgentMessage_sub: String {
    return "txts/home/servertoapp/urgentMessage/receive/\(UserManager.shared.userId)"
}
