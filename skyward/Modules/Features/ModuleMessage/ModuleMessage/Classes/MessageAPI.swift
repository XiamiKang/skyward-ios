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
    case conversationList(_ pageNum: Int = 1)
    case messageList(params: [String : Any])
    case sendMessage(params: [String : Any])
    case checkPOIWithAround(location: String)
    
    // 会话列表
    static var convList_sub: String {
        return "txts/im/servertoapp/conversation/list/\(UserManager.shared.userId)"
    }
    // 接收消息
    static var receiveMessage_sub: String {
        return "txts/im/servertoapp/message/receive/\(UserManager.shared.userId)"
    }
}

extension MessageAPI: NetworkAPI {
    
    var path: String {
        switch self {
        case .conversationList:
            return "/txts-user-center-app/api/v1/conversations/list"
        case . messageList:
            return "/txts-user-center-app/api/v1/messages/page"
        case .sendMessage:
            return "/txts-user-center-app/api/v1/messages/send"
        case .checkPOIWithAround:
            return "/txts-data-app/api/v1/data/map/poi/around"
        }
    }
    
    var method: Moya.Method {
        switch self {

        case .conversationList,
              .messageList,
              .checkPOIWithAround:
            return .get
        case .sendMessage:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .conversationList(let pageNum):
            let parameters: [String: Any] = [
                "userId": UserManager.shared.userId,
                "pageNum" : pageNum,
                "pageSize": -1
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .messageList(let params):
            
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .sendMessage(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .checkPOIWithAround(let location):
            return .requestParameters(parameters: ["location" : location, "radius": 5000], encoding: URLEncoding.default)
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
