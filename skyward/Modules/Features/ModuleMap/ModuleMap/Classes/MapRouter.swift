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

class RouteListRouter: RoutableActionType {

    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        var params: [String : String] = [:]
        if let queryParameters = url.urlValue?.queryParameters {
            params = queryParameters
        }
        guard let typeStr = params["type"], let type = RouteType(rawValue: Int(typeStr) ?? 0) else {
            return false
        }
        
        let vc = RouteListViewController(type: type)
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.routeListPageUrl)[^\\s]*"]
    }
}

class RoutesCountRouter: RoutableActionType {
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        let dataManager = RouteDataManager()
        var count = dataManager.getRoutes(type: .route, onlyUnUploaded: true).count
        dataManager.requestRouteList(req: RouteListReq(type: 0)) { rsp in
            count += rsp?.total ?? 0
            callback?(count)
        }
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.routeCountUrl)[^\\s]*"]
    }
}

class TracksCountRouter: RoutableActionType {

    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        let dataManager = RouteDataManager()
        var count = dataManager.getRoutes(type: .track, onlyUnUploaded: true).count
        dataManager.requestRouteList(req: RouteListReq(type: 1)) { rsp in
            count += rsp?.total ?? 0
            callback?(count)
        }
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.trackCountUrl)[^\\s]*"]
    }
}

class POIListRouter: RoutableActionType {

    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        let vc = POIListViewController()
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.POIListUrl)[^\\s]*"]
    }
}

class POICollectListRouter: RoutableActionType {

    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        var params: [String : String] = [:]
        if let queryParameters = url.urlValue?.queryParameters {
            params = queryParameters
        }
        guard let typeStr = params["type"], let type = PublicPOIChooseType(rawValue: Int(typeStr) ?? 0) else {
            return false
        }
        let vc = POICollectListViewController(type: type)
        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.POICollectListUrl)[^\\s]*"]
    }
}
