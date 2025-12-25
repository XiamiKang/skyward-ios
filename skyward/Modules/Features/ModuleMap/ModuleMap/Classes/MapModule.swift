//
//  PersonalModule.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//


import Foundation
import TXKit
import TXRouterKit

public class MapModule: ModuleType {
    
    public static var name: String = "ModuleMap"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [MapRouter.self]
    }
}
