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
    
    public init() {
        TeamMessageManager.shared.startMonitorNewMessage()
    }
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [TeamRouter.self]
    }
}
