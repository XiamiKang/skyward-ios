//
//  TeamModule.swift
//  Pods
//
//  Created by zhaobo on 2025/12/4.
//


import Foundation
import TXKit
import TXRouterKit

public class TeamModule: ModuleType {
    
    public static var name: String = "ModuleTeam"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [TeamRouter.self, TeamStartMonitorMessageRouter.self, TeamStopMonitorMessageRouter.self]
    }
}
