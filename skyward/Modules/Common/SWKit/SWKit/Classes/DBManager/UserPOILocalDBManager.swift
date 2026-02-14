//
//  UserPOILocalDBManager.swift
//  Pods
//
//  Created by TXTS on 2026/2/4.
//


import Foundation
import WCDBSwift

// 添加这个辅助扩展

public class UserPOILocalDBManager {
    
    public static let shared = UserPOILocalDBManager()
    
    private let dbManager = DBManager.shared
    
    private init() {
        DBManager.shared.createTable(table: DBTableName.userPOI.rawValue, of: UserPOILocalData.self)
    }
    
    // MARK: - 数据操作
    
    /// 插入或更新用户POI数据
    /// - Parameter poiData: 要插入的用户POI数据
    /// - Returns: 是否成功
    @discardableResult
    public func insertOrUpdate(poiData: UserPOILocalData) -> Bool {
        return dbManager.insertToDb(objects: [poiData], intoTable: DBTableName.userPOI.rawValue)
    }
    
    /// 批量插入或更新用户POI数据
    /// - Parameter poiDatas: 要插入的用户POI数据数组
    /// - Returns: 是否成功
    @discardableResult
    public func insertOrUpdate(poiDatas: [UserPOILocalData]) -> Bool {
        return dbManager.insertToDb(objects: poiDatas, intoTable: DBTableName.userPOI.rawValue)
    }
    
    /// 根据ID更新用户POI数据（部分字段）
    /// - Parameters:
    ///   - poiData: 更新的数据
    ///   - id: 要更新的记录ID
    /// - Returns: 是否成功
    @discardableResult
    public func update(poiData: UserPOILocalData, byId id: Int) -> Bool {
        let condition = UserPOILocalData.Properties.id == id
        return update(poiData: poiData, where: condition)
    }
    
    /// 根据POI ID更新用户POI数据（部分字段）
    /// - Parameters:
    ///   - poiData: 更新的数据
    ///   - poiId: 要更新的记录POI ID
    /// - Returns: 是否成功
    @discardableResult
    public func update(poiData: UserPOILocalData, byPoiId poiId: String) -> Bool {
        let condition = UserPOILocalData.Properties.poiId == poiId
        return update(poiData: poiData, where: condition)
    }
    
    /// 通用更新方法
    /// - Parameters:
    ///   - poiData: 更新的数据
    ///   - condition: 更新条件
    /// - Returns: 是否成功
    @discardableResult
    private func update(poiData: UserPOILocalData, where condition: Condition? = nil) -> Bool {
        // 指定要更新的字段，id不更新
        let properties: [PropertyConvertible] = [
            UserPOILocalData.Properties.poiId,
            UserPOILocalData.Properties.name,
            UserPOILocalData.Properties.description,
            UserPOILocalData.Properties.lon,
            UserPOILocalData.Properties.lat,
            UserPOILocalData.Properties.category,
            UserPOILocalData.Properties.imageData1,
            UserPOILocalData.Properties.imageData2,
            UserPOILocalData.Properties.imageData3
        ]
        
        return dbManager.updateToDb(
            table: DBTableName.userPOI.rawValue,
            on: properties,
            with: poiData,
            where: condition
        )
    }
    
    /// 根据ID删除用户POI数据
    /// - Parameter id: 要删除的记录ID
    /// - Returns: 是否成功
    @discardableResult
    public func delete(byId id: Int) -> Bool {
        let condition = UserPOILocalData.Properties.id == id
        return dbManager.deleteFromDb(fromTable: DBTableName.userPOI.rawValue, where: condition)
    }
    
    /// 根据POI ID删除用户POI数据
    /// - Parameter poiId: 要删除的记录POI ID
    /// - Returns: 是否成功
    @discardableResult
    public func delete(byPoiId poiId: String) -> Bool {
        let condition = UserPOILocalData.Properties.poiId == poiId
        return dbManager.deleteFromDb(fromTable: DBTableName.userPOI.rawValue, where: condition)
    }
    
    /// 根据分类删除用户POI数据
    /// - Parameter category: 分类ID
    /// - Returns: 是否成功
    @discardableResult
    public func delete(byCategory category: Int) -> Bool {
        let condition = UserPOILocalData.Properties.category == category
        return dbManager.deleteFromDb(fromTable: DBTableName.userPOI.rawValue, where: condition)
    }
    
    /// 删除所有用户POI数据
    /// - Returns: 是否成功
    @discardableResult
    public func deleteAll() -> Bool {
        return dbManager.deleteFromDb(fromTable: DBTableName.userPOI.rawValue)
    }
    
    // MARK: - 查询操作
    
    /// 查询所有用户POI数据
    /// - Returns: 用户POI数据数组
    public func queryAll() -> [UserPOILocalData]? {
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPOI.rawValue,
            cls: UserPOILocalData.self,
            orderBy: [UserPOILocalData.Properties.id.order(.ascending)]
        )
    }
    
    /// 根据ID查询用户POI数据
    /// - Parameter id: 记录ID
    /// - Returns: 用户POI数据
    public func query(byId id: Int) -> UserPOILocalData? {
        let condition = UserPOILocalData.Properties.id == id
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPOI.rawValue,
            cls: UserPOILocalData.self,
            where: condition
        )?.first
    }
    
    /// 根据POI ID查询用户POI数据
    /// - Parameter poiId: POI ID
    /// - Returns: 用户POI数据
    public func query(byPoiId poiId: String) -> UserPOILocalData? {
        let condition = UserPOILocalData.Properties.poiId == poiId
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPOI.rawValue,
            cls: UserPOILocalData.self,
            where: condition
        )?.first
    }
    
    /// 根据分类查询用户POI数据
    /// - Parameter category: 分类ID
    /// - Returns: 用户POI数据数组
    public func query(byCategory category: Int) -> [UserPOILocalData]? {
        let condition = UserPOILocalData.Properties.category == category
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPOI.rawValue,
            cls: UserPOILocalData.self,
            where: condition,
            orderBy: [UserPOILocalData.Properties.id.order(.ascending)]
        )
    }
    
    /// 根据名称模糊查询用户POI数据
    /// - Parameter name: 名称关键词
    /// - Returns: 用户POI数据数组
    public func query(byName name: String) -> [UserPOILocalData]? {
        let condition = UserPOILocalData.Properties.name.like("%\(name)%")
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPOI.rawValue,
            cls: UserPOILocalData.self,
            where: condition,
            orderBy: [UserPOILocalData.Properties.id.order(.ascending)]
        )
    }
    
    /// 根据地理范围查询用户POI数据
    /// - Parameters:
    ///   - minLon: 最小经度
    ///   - maxLon: 最大经度
    ///   - minLat: 最小纬度
    ///   - maxLat: 最大纬度
    /// - Returns: 用户POI数据数组
    public func query(byRegion minLon: Double, maxLon: Double, minLat: Double, maxLat: Double) -> [UserPOILocalData]? {
        let condition = UserPOILocalData.Properties.lon >= minLon
            && UserPOILocalData.Properties.lon <= maxLon
            && UserPOILocalData.Properties.lat >= minLat
            && UserPOILocalData.Properties.lat <= maxLat
        
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPOI.rawValue,
            cls: UserPOILocalData.self,
            where: condition,
            orderBy: [UserPOILocalData.Properties.id.order(.ascending)]
        )
    }
    
    /// 统计记录数量
    /// - Returns: 记录总数
    public func count() -> Int {
        return queryAll()?.count ?? 0
    }
    
    /// 根据分类统计记录数量
    /// - Parameter category: 分类ID
    /// - Returns: 该分类的记录数量
    public func count(byCategory category: Int) -> Int {
        return query(byCategory: category)?.count ?? 0
    }
    
    // MARK: - 业务方法
    
    /// 检查POI ID是否已存在
    /// - Parameter poiId: POI ID
    /// - Returns: 是否已存在
    public func exists(byPoiId poiId: String) -> Bool {
        return query(byPoiId: poiId) != nil
    }
    
    /// 获取所有分类的POI数据（按分类分组）
    /// - Returns: 按分类分组的POI数据字典
    public func queryGroupedByCategory() -> [Int: [UserPOILocalData]]? {
        guard let allData = queryAll() else { return nil }
        
        var groupedData: [Int: [UserPOILocalData]] = [:]
        for data in allData {
            if let category = data.category {
                if groupedData[category] == nil {
                    groupedData[category] = []
                }
                groupedData[category]?.append(data)
            }
        }
        
        return groupedData
    }
    
    /// 批量添加用户POI数据，自动过滤重复的POI ID
    /// - Parameter poiDatas: POI数据数组
    /// - Returns: 成功添加的数量
    @discardableResult
    public func batchInsertWithDuplicateCheck(poiDatas: [UserPOILocalData]) -> Int {
        var successCount = 0
        var uniquePoiDatas: [UserPOILocalData] = []
        
        // 过滤重复的POI ID
        for poiData in poiDatas {
            if let poiId = poiData.poiId {
                if !exists(byPoiId: poiId) {
                    uniquePoiDatas.append(poiData)
                }
            } else {
                // 如果没有POI ID，直接添加
                uniquePoiDatas.append(poiData)
            }
        }
        
        // 批量插入
        if insertOrUpdate(poiDatas: uniquePoiDatas) {
            successCount = uniquePoiDatas.count
        }
        
        return successCount
    }
}
