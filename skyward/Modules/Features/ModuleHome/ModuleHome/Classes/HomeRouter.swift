//
//  HomeRouter.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme

class HomeRouter: RoutableActionType {
    
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
        return ["\(RouteTable.minePageUrl)[^\\s]*"]
    }
}

/// 首页天气信息路由 - 从 HomeViewController 获取天气信息
class HomeWeatherInfoRouter: RoutableActionType {

    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        // 查找 HomeViewController
        if let homeVC = UIWindow.findViewController(ofType: HomeViewController.self),
           let weatherInfo = homeVC.viewModel.weatherInfo {
            callback?(weatherInfo)
            return true
        }
        callback?(nil)
        return false
    }

    static var patterns: [String] {
        return ["\(RouteTable.homeWeatherInfoUrl)[^\\s]*"]
    }
}

/// 首页同步最新服务消息
class HomeSyncLatestServiceMessageRouter: RoutableActionType {

    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        
        guard let params: [String : String] = url.urlValue?.queryParameters else {
            return false
        }

        if let homeVC = UIWindow.findViewController(ofType: HomeViewController.self) {
           homeVC.viewModel.syncLatestServiceMessage(params: params)
        }
        return true
    }

    static var patterns: [String] {
        return ["\(RouteTable.homeLatestServiceMessageUrl)[^\\s]*"]
    }
}
