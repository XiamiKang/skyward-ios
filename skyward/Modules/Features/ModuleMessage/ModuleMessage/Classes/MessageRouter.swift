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
        let vc = ConvViewController()
        vc.title = "服务中心"
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)

        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.convPageUrl)[^\\s]*"]
    }
}

class UrgentMessagePageRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        let vc = UrgentMessageViewController()
        vc.title = "服务中心"
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)

        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.urgentMessagePageUrl)[^\\s]*"]
    }
}
