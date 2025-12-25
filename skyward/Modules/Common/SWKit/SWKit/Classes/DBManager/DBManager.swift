//
//  DBManager.swift
//  SWKit
//
//  Created by zhaobo on 2025/12/10.
//

import Foundation
import WCDBSwift

struct DBPath {
    let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! + "/\(UserManager.shared.userId).db"
}

public enum DBTableName: String {
    case conversation = "conversationTable"
    case message = "messageTable"
    case urgentMessage = "urgentMessageTable"
    case team = "teamTable"
    case track = "trackTable"
    case route = "routeTable"
    case routePoint = "routePointTable"
}


public class DBManager: NSObject {
    public static let shared  = DBManager()
    var dataBase: Database?
    
    
    private override init() {
        super.init()
        dataBase = createDb()
    }
    
    /// 创建db
    private func createDb() -> Database {
        debugPrint("数据库路径==\(DBPath().dbPath)")
        return Database(at: DBPath().dbPath)
    }
    
    /// 创建表
    public func createTable<T: TableDecodable>(table: String, of ttype:T.Type) -> Void {
        do {
            try dataBase?.create(table: table, of:ttype)
            debugPrint("db: 创建表\(table)成功")
        } catch let error {
            debugPrint("db: 创建表\(table)错误 \(error.localizedDescription)")
        }
    }
    
    /// 插入或替换（处理重复数据）
    public func insertToDb<T: TableEncodable>(objects: [T] ,intoTable table: String) -> Void {
        do {
            // 使用insertOrReplace来处理重复数据，如果主键已存在则更新
            try dataBase?.insertOrReplace(objects, intoTable: table)
            debugPrint("db: 向表\(table)插入\(objects.count)条数据成功")
        } catch let error {
            debugPrint("db: 向表\(table)插入数据错误 \(error.localizedDescription)")
        }
    }
    
    /// 修改
    @discardableResult
    public func updateToDb<T: TableEncodable>(table: String, on propertys:[PropertyConvertible],with object:T,where condition: Condition? = nil) -> Bool{
        do {
            try dataBase?.update(table: table, on: propertys, with: object,where: condition)
            debugPrint("db: 更新表\(table)数据成功")
            return true
        } catch let error {
            debugPrint("db: 更新表\(table)数据错误 \(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除
    public func deleteFromDb(fromTable: String, where condition: Condition? = nil) -> Bool {
        do {
            try dataBase?.delete(fromTable: fromTable, where:condition)
            debugPrint("db: 从表\(fromTable)删除数据成功")
            return true
        } catch let error {
            debugPrint("db: 从表\(fromTable)删除数据错误 \(error.localizedDescription)")
            return false
        }
    }
    
    /// 查询
    public func queryFromDb<T: TableDecodable>(fromTable: String, cls cName: T.Type, where condition: Condition? = nil, orderBy orderList:[OrderBy]? = nil) -> [T]? {
        do {
            let allObjects: [T] = try (dataBase?.getObjects(fromTable: fromTable, where:condition, orderBy:orderList))!
            debugPrint("db: 查询表\(fromTable)成功，返回\(allObjects.count)条数据")
            return allObjects
        } catch let error {
            debugPrint("db: no data find \(error.localizedDescription)")
        }
        return nil
    }
    
    /// 删除数据表
    public func dropTable(table: String) -> Void {
        do {
            try dataBase?.drop(table: table)
        } catch let error {
            debugPrint("db: drop table error \(error)")
        }
    }
    
    /// 删除所有与该数据库相关的文件
    public func removeDbFile() -> Void {
        do {
            try dataBase?.close(onClosed: {
                try self.dataBase?.removeFiles()
            })
        } catch let error {
            debugPrint("db: not close db \(error)")
        }
    }
}
