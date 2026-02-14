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
    
    public init() {
        //地图本地数据是否已经迁移
        let key = "mapLocalDataHasMigrated"
        
        if UserDefaults.standard.bool(forKey: key) {
            DBManager.shared.createTable(table: DBTableName.route.rawValue, of: Route.self)
        } else {
            DBManager.shared.createTable(table: DBTableName.track.rawValue, of: TrackRecord.self)
            DBManager.shared.createTable(table: DBTableName.route.rawValue, of: RouteRecord.self)
            DBManager.shared.createTable(table: DBTableName.routePoint.rawValue, of: RoutePoint.self)
            
            //迁移老数据
            RouteDataManager().migrateLocalDataToNewPath()
            
            UserDefaults.standard.setValue(true, forKey: key)
        }
        
    }
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [MapRouter.self, RouteListRouter.self]
    }
}
