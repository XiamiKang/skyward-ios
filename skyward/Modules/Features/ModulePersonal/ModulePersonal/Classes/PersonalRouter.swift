//
//  PersonalRouter.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//


import TXRouterKit
import SWKit

class BindDevicePageRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        UIWindow.topViewController()?.navigationController?.pushViewController(DeviceListViewController(), animated: true)
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.bindDevicePageUrl)[^\\s]*"]
    }
}
