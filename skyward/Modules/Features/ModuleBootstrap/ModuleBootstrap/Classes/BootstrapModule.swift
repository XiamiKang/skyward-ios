//
//  BootstrapModule.swift
//  ModuleBootstrap
//
//  Created by zhaobo on 2025/11/28.
//

import Foundation
import TXKit
import TXRouterKit

public class BootstrapModule: ModuleType {
    
    public static var name: String = "ModuleBootstrap"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return []
    }
}
