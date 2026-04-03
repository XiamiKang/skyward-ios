//
//  MessageRouter.swift
//  Alamofire
//
//  Created by zhaobo on 2025/11/27.
//

import TXRouterKit
import SWKit

class ConvPageRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        var params: [String : String] = [:]
        if let queryParameters = url.urlValue?.queryParameters {
            params = queryParameters
        }
        let convId = params["id"]
        let conv : Conversation
        if convId == UserManager.shared.userId {
            conv = Conversation.serviceConversation()
        } else {
            conv = Conversation(id: convId, name: nil, type: nil, createTimeTimestamp: nil, enable: true)
        }
        let vc = ConvViewController(conversation: conv)
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)

        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.convPageUrl)[^\\s]*"]
    }
}
