//
//  DBManager.swift
//  SWKit
//
//  Created by zhaobo on 2025/12/10.
//

import Foundation
import WCDBSwift

struct DBPath {
    let dbPath: String
    
    init(userId: String) {
        self.dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! + "/\(userId).db"
    }
}

public enum DBTableName: String {
    case conversation = "conversationTable"
    case message = "messageTable"
    case urgentMessage = "urgentMessageTable"
    case team = "teamTable"
    case track = "trackTable"
    case route = "routeTable"
    case routePoint = "routePointTable"
    case miniDevice = "miniDeviceTable"
    case userPOI = "userPOITable"
}


public class DBManager: NSObject {
    public static let shared  = DBManager()
    var dataBase: Database?
    
    /// 初始化数据库
    public func initDb(userId: String) {
        dataBase = createDb(userId: userId)
    }
    
    /// 关闭数据库
    public func closeDb() {
        if let dataBase = dataBase {
            dataBase.close()
            self.dataBase = nil
            
            debugPrint("[DataBase] 关闭数据库")
        }
    }
    
    /// 创建db
    private func createDb(userId: String) -> Database? {
        guard !userId.isEmpty else {
            debugPrint("[DataBase] 用户ID为空，无法创建数据库")
            return nil
        }
        
        let dbPath = DBPath(userId: userId).dbPath
        debugPrint("[DataBase] 创建数据库，路径==\(dbPath)")
        return Database(at: dbPath)
    }
    
    /// 创建表
    public func createTable<T: TableDecodable>(table: String, of ttype:T.Type) -> Void {
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法创建表\(table)")
            return
        }
        
        do {
            try dataBase.create(table: table, of:ttype)
            debugPrint("[DataBase] 创建表\(table)成功")
        } catch let error {
            debugPrint("[DataBase] 创建表\(table)错误 \(error.localizedDescription)")
        }
    }
    
    // MARK: - 增删改查
    
    /// 插入或替换（处理重复数据）
    @discardableResult
    public func insertToDb<T: TableEncodable>(objects: [T] ,intoTable table: String) -> Bool {
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法向表\(table)插入数据")
            return false
        }
        
        guard !objects.isEmpty else {
            debugPrint("[DataBase] 插入数据为空，跳过插入操作")
            return false
        }
        
        do {
            // 使用insertOrReplace来处理重复数据，如果主键已存在则更新
            try dataBase.insertOrReplace(objects, intoTable: table)
            debugPrint("[DataBase] 向表\(table)插入\(objects.count)条数据成功")
            return true
        } catch let error {
            debugPrint("[DataBase] 向表\(table)插入数据错误 \(error.localizedDescription)")
            return false
        }
    }
    
    /// 修改
    @discardableResult
    public func updateToDb<T: TableEncodable>(table: String, on propertys:[PropertyConvertible],with object:T,where condition: Condition? = nil) -> Bool{
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法更新表\(table)数据")
            return false
        }
        
        do {
            try dataBase.update(table: table, on: propertys, with: object,where: condition)
            debugPrint("[DataBase] 更新表\(table)数据成功")
            return true
        } catch let error {
            debugPrint("[DataBase] 更新表\(table)数据错误 \(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除
    @discardableResult
    public func deleteFromDb(fromTable: String, where condition: Condition? = nil) -> Bool {
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法从表\(fromTable)删除数据")
            return false
        }
        
        do {
            try dataBase.delete(fromTable: fromTable, where:condition)
            debugPrint("[DataBase] 从表\(fromTable)删除数据成功")
            return true
        } catch let error {
            debugPrint("[DataBase] 从表\(fromTable)删除数据错误 \(error.localizedDescription)")
            return false
        }
    }
    
    /// 查询
    public func queryFromDb<T: TableDecodable>(fromTable: String, cls cName: T.Type, where condition: Condition? = nil, orderBy orderList:[OrderBy]? = nil) -> [T]? {
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法查询")
            return nil
        }
        
        do {
            let allObjects: [T] = try dataBase.getObjects(fromTable: fromTable, where:condition, orderBy:orderList)
            debugPrint("[DataBase] 查询表\(fromTable)成功，返回\(allObjects.count)条数据")
            return allObjects
        } catch let error {
            debugPrint("[DataBase] 查询表\(fromTable)失败 \(error.localizedDescription)")
        }
        return nil
    }
    
    /// 删除数据表
    public func dropTable(table: String) -> Void {
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法删除表\(table)")
            return
        }
        
        do {
            try dataBase.drop(table: table)
            debugPrint("[DataBase] 删除表\(table)成功")
        } catch let error {
            debugPrint("[DataBase] 删除表\(table)错误 \(error.localizedDescription)")
        }
    }
    
    /// 删除所有与该数据库相关的文件
    public func removeDbFile() -> Void {
        guard let dataBase = dataBase else {
            debugPrint("[DataBase] 数据库未初始化，无法删除数据库文件")
            return
        }
        
        do {
            try dataBase.close(onClosed: {
                do {
                    try dataBase.removeFiles()
                    debugPrint("[DataBase] 数据库文件已删除")
                    self.dataBase = nil
                } catch let error {
                    debugPrint("[DataBase] 删除数据库文件失败 \(error.localizedDescription)")
                }
            })
        } catch let error {
            debugPrint("[DataBase] 关闭数据库失败 \(error.localizedDescription)")
        }
    }
}
