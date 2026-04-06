//
//  userPublicPOILocalDBManager.swift
//  Pods
//
//  Created by TXTS on 2026/2/4.
//


import Foundation
import WCDBSwift

public class UserPublicPOIDBManager {
    
    public static let shared = UserPublicPOIDBManager()
    
    private let dbManager = DBManager.shared
    
    private init() {
        DBManager.shared.createTable(table: DBTableName.userPublicPOI.rawValue, of: PublicPOIData.self)
    }
    
    // MARK: - 数据操作
    
    /// 插入或更新用户POI数据
    /// - Parameter poiData: 要插入的用户POI数据
    /// - Returns: 是否成功
    @discardableResult
    public func insertOrUpdate(poiData: PublicPOIData) -> Bool {
        return dbManager.insertToDb(objects: [poiData], intoTable: DBTableName.userPublicPOI.rawValue)
    }
    
    /// 批量插入或更新用户POI数据
    /// - Parameter poiDatas: 要插入的用户POI数据数组
    /// - Returns: 是否成功
    @discardableResult
    public func insertOrUpdate(poiDatas: [PublicPOIData]) -> Bool {
        return dbManager.insertToDb(objects: poiDatas, intoTable: DBTableName.userPublicPOI.rawValue)
    }
    
    /// 根据ID更新用户POI数据（部分字段）
    /// - Parameters:
    ///   - poiData: 更新的数据
    ///   - id: 要更新的记录ID
    /// - Returns: 是否成功
    @discardableResult
    public func update(poiData: PublicPOIData, byId id: String) -> Bool {
        let condition = PublicPOIData.Properties.id == id
        return update(poiData: poiData, where: condition)
    }
    
    
    /// 通用更新方法
    /// - Parameters:
    ///   - poiData: 更新的数据
    ///   - condition: 更新条件
    /// - Returns: 是否成功
    @discardableResult
    private func update(poiData: PublicPOIData, where condition: Condition? = nil) -> Bool {
        // 指定要更新的字段，id不更新
        let properties: [PropertyConvertible] = [
            PublicPOIData.Properties.id,
            PublicPOIData.Properties.name,
            PublicPOIData.Properties.description,
            PublicPOIData.Properties.type,
            PublicPOIData.Properties.address,
            PublicPOIData.Properties.lon,
            PublicPOIData.Properties.lat,
            PublicPOIData.Properties.category,
            PublicPOIData.Properties.tel,
            PublicPOIData.Properties.wgsLon,
            PublicPOIData.Properties.wgsLat,
            PublicPOIData.Properties.images,
            PublicPOIData.Properties.isCollection,
            PublicPOIData.Properties.isIsCheck,
            PublicPOIData.Properties.altitude,
            PublicPOIData.Properties.minZoom,
            PublicPOIData.Properties.collectionTime,
            PublicPOIData.Properties.checkTime
        ]
        
        return dbManager.updateToDb(
            table: DBTableName.userPublicPOI.rawValue,
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
        let condition = PublicPOIData.Properties.id == id
        return dbManager.deleteFromDb(fromTable: DBTableName.userPublicPOI.rawValue, where: condition)
    }
    
    /// 删除所有用户POI数据
    /// - Returns: 是否成功
    @discardableResult
    public func deleteAll() -> Bool {
        return dbManager.deleteFromDb(fromTable: DBTableName.userPublicPOI.rawValue)
    }
    
    // MARK: - 查询操作
    
    /// 查询所有用户POI数据
    /// - Returns: 用户POI数据数组
    public func queryAll() -> [PublicPOIData]? {
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPublicPOI.rawValue,
            cls: PublicPOIData.self,
            orderBy: [PublicPOIData.Properties.id.order(.ascending)]
        )
    }
    
    /// 根据ID查询用户POI数据
    /// - Parameter id: 记录ID
    /// - Returns: 用户POI数据
    public func query(byId id: String) -> PublicPOIData? {
        let condition = PublicPOIData.Properties.id == id
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPublicPOI.rawValue,
            cls: PublicPOIData.self,
            where: condition
        )?.first
    }
    
    /// 根据打卡查询用户POI数据
    public func queryCheckData() -> [PublicPOIData]? {
        let condition = PublicPOIData.Properties.isIsCheck == true
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPublicPOI.rawValue,
            cls: PublicPOIData.self,
            where: condition
        )
    }
    
    /// 根据收藏查询用户POI数据
    public func queryCollectData() -> [PublicPOIData]? {
        let condition = PublicPOIData.Properties.isCollection == true
        return dbManager.queryFromDb(
            fromTable: DBTableName.userPublicPOI.rawValue,
            cls: PublicPOIData.self,
            where: condition,
            orderBy: [PublicPOIData.Properties.id.order(.ascending)]
        )
    }
    
    /// 统计记录数量
    /// - Returns: 记录总数
    public func count() -> Int {
        return queryAll()?.count ?? 0
    }
    
    /// 根据打卡记录数量
    public func countCheckout() -> Int {
        return queryCheckData()?.count ?? 0
    }
    
    /// 根据收藏记录数量
    public func countCollection() -> Int {
        return queryCollectData()?.count ?? 0
    }
    
    // MARK: - 业务方法
    
    /// 检查POI ID是否已存在
    /// - Parameter poiId: POI ID
    /// - Returns: 是否已存在
    public func exists(byId id: String) -> Bool {
        return query(byId: id) != nil
    }
    
    /// 获取所有分类的POI数据（按分类分组）
    /// - Returns: 按分类分组的POI数据字典
    public func queryGroupedByCategory() -> [Int: [PublicPOIData]]? {
        guard let allData = queryAll() else { return nil }
        
        var groupedData: [Int: [PublicPOIData]] = [:]
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
    public func batchInsertWithDuplicateCheck(poiDatas: [PublicPOIData]) -> Int {
        var successCount = 0
        var uniquePoiDatas: [PublicPOIData] = []
        
        // 过滤重复的POI ID
        for poiData in poiDatas {
            if let id = poiData.id {
                if !exists(byId: id) {
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

