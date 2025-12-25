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
}

extension MessageAPI: NetworkAPI {
    
    var path: String {
        return "/txts-user-center-app/api/v1/urgent-message/page/list"
    }
    
    var method: Moya.Method {
        return .get
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

// 发送消息
let sendUrgentMessage_pub = "txts/home/apptoserver/urgentMessage/send/\(UserManager.shared.userId)"
// 接收消息
let receiveUrgentMessage_sub = "txts/home/servertoapp/urgentMessage/receive/\(UserManager.shared.userId)"

let urgentMessageList_pub = "txts/home/apptoserver/urgentMessage/list/\(UserManager.shared.userId)"
let urgentMessageList_sub = "txts/home/servertoapp/urgentMessage/list/\(UserManager.shared.userId)"
