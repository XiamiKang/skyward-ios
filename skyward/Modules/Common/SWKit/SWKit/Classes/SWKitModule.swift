//
//  SWKitModule.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/24.
//

import Foundation
import TXKit
import TXRouterKit

public class SWKitModule: ModuleType {
    
    public static var name: String = "SWKit"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return []
    }
}
