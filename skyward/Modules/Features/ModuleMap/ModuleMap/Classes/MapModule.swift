//
//  PersonalModule.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//


import Foundation
import TXKit
import TXRouterKit
import SWKit
import WCDBSwift

public class MapModule: ModuleType {
    
    public static var name: String = "ModuleMap"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [MapRouter.self, RouteListRouter.self, RoutesCountRouter.self, TracksCountRouter.self, POIListRouter.self, POICollectListRouter.self]
    }
    
    public func moduleSetup() {
        let key = "removedMapLocalData"
        if UserDefaults.standard.bool(forKey: key) == false {
            // 移除老表
            DBManager.shared.dropTable(table: DBTableName.track.rawValue)
            DBManager.shared.dropTable(table: DBTableName.route.rawValue)
            DBManager.shared.dropTable(table: DBTableName.routePoint.rawValue)
            
            UserDefaults.standard.setValue(true, forKey: key)
        }
        
        // 创建新表
        DBManager.shared.createTable(table: DBTableName.route.rawValue, of: Route.self)
        DBManager.shared.createTable(table: DBTableName.miniDevice.rawValue, of: MiniDeviceData.self)
        DBManager.shared.createTable(table: DBTableName.miniDeviceSendResult.rawValue, of: MiniDeviceSendResultData.self)
        DBManager.shared.createTable(table: DBTableName.userPOI.rawValue, of: UserPOILocalData.self)
        DBManager.shared.createTable(table: DBTableName.userPublicPOI.rawValue, of: PublicPOIData.self)
        // 静默上传本地的路线
        RouteDataManager.silentSaveLocalRoutesToServer(completion: nil)
    }
    
    public func loginSuccess() {
        moduleSetup()
    }
}
