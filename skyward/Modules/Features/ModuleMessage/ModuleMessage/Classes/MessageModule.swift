//
//  MessageModule.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import Foundation
import TXKit
import TXRouterKit
import SWKit

public class MessageModule: ModuleType {
    
    public static var name: String = "ModuleMessage"
    
    public init() {
        DBManager.shared.createTable(table: DBTableName.urgentMessage.rawValue, of: UrgentMessage.self)
    }
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [ConvPageRouter.self, UrgentMessagePageRouter.self]
    }
}
