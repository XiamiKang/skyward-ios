//
//  HomeModule.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

import Foundation
import TXKit
import TXRouterKit
import SWKit

public class HomeModule: ModuleType {
    
    public static var name: String = "ModuleHome"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [HomeRouter.self, HomeWeatherInfoRouter.self, HomeSyncLatestServiceMessageRouter.self]
    }
    
    public func moduleSetup() {
        DBManager.shared.createTable(table: DBTableName.homeNotice.rawValue, of: HomeNoticeItem.self)
    }
    
    public func loginSuccess() {
        moduleSetup()
    }
}
