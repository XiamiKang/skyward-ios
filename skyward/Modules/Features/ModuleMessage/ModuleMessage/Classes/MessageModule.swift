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
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [ConvPageRouter.self]
    }
    
    public func moduleSetup() {
//        DBManager.shared.dropTable(table: DBTableName.conversation.rawValue)
//        DBManager.shared.dropTable(table: DBTableName.message.rawValue)
        
        DBManager.shared.createTable(table: DBTableName.conversation.rawValue, of: Conversation.self)
        DBManager.shared.createTable(table: DBTableName.message.rawValue, of: Message.self)
        MessageManager.shared.startMonitorMessage()
    }
    
    public func loginSuccess() {
        moduleSetup()
    }
    
    public func logoutSuccess() {
        MessageManager.shared.stopMonitorMessage()
    }
}
