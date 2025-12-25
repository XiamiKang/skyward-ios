//
//  PersonalRouter.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//


import TXKit
import TXRouterKit
import SWKit
import SWTheme

class LoginRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        let launchVC = LaunchViewController()
        let navi = BaseNavigationViewController(rootViewController: launchVC)
        ScreenUtil.getKeyWindow()?.rootViewController = navi
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.loginPageUrl)[^\\s]*"]
    }
}
