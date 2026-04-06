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
        var params: [String : String] = [:]
        if let queryParameters = url.urlValue?.queryParameters {
            params = queryParameters
        }
        let selectedIndex = Int(params["selectedIndex"] ?? "0") ?? 0
        UIWindow.topViewController()?.navigationController?.pushViewController(DeviceListViewController(selectedDeviceType: selectedIndex), animated: true)
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.bindDevicePageUrl)[^\\s]*"]
    }
}


class ProDevicePageRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        UIWindow.topViewController()?.navigationController?.pushViewController(ProDeviceDetailViewController(), animated: true)
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.proDevicePageUrl)[^\\s]*"]
    }
}
