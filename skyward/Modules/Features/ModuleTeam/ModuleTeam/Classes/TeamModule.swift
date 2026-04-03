//
//  TeamModule.swift
//  Pods
//
//  Created by zhaobo on 2025/12/4.
//


import Foundation
import TXKit
import TXRouterKit
import SWKit

public class TeamModule: ModuleType {
    
    public static var name: String = "ModuleTeam"
    
    public init() {}
    
    /// 当前模块的路由
    public var routeSettings: [any RoutableType.Type] {
        return [TeamRouter.self]
    }
    
    public func moduleSetup() {
        DBManager.shared.createTable(table: DBTableName.conversation.rawValue, of: Conversation.self)
        DBManager.shared.createTable(table: DBTableName.message.rawValue, of: Message.self)
        DBManager.shared.createTable(table: DBTableName.team.rawValue, of: Team.self)
        TeamMessageManager.shared.startMonitorNewMessage()
    }
    
    public func loginSuccess() {
        moduleSetup()
    }
    
    public func logoutSuccess() {
        TeamMessageManager.shared.stopMonitorNewMessage()
    }
}
