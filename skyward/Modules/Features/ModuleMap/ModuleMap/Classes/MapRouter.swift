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

class MapRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        let vc = BaseViewController()
        vc.view.backgroundColor = ThemeManager.current.lightGrayBGColor
        var params: [String : String] = [:]
        if let queryParameters = url.urlValue?.queryParameters {
            params = queryParameters
        }
        vc.title = params["title"]
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.mapPageUrl)[^\\s]*"]
    }
}
