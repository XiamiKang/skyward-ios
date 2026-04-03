//
//  CodingKeys.swift
//  Pods
//
//  Created by TXTS on 2025/12/13.
//

import Foundation
import WCDBSwift

// MARK: - 数据库管理器
public class POIDatabaseManager {
    public static let shared = POIDatabaseManager()
    
    public let database: Database
    private let operationQueue: DispatchQueue
    private let writeQueue: DispatchQueue
    private let maxBatchSize = 10000 // 每批最多插入10000条
    
    private var isDatabaseSetup = false
    
    private init() {
        // 数据库路径
        let dbPath = FileManager.default.urls(for: .documentDirectory,
                                             in: .userDomainMask)[0]
            .appendingPathComponent("poi_database.db")
        
        database = Database(at: dbPath.path)
        operationQueue = DispatchQueue(label: "com.poi.database.queue",
                                      qos: .userInitiated,
                                      attributes: .concurrent)
        writeQueue = DispatchQueue(label: "com.poi.database.write", qos: .userInitiated)
        
        configureDatabase()
        setupDatabase()
    }
    
    // MARK: - 配置数据库优化参数
    private func configureDatabase() {
        do {
            // 设置WAL模式，提高并发性能
            try database.exec(
                StatementPragma()
                    .pragma(.journalMode)
                    .to("WAL")
            )
            
            // 设置同步模式为NORMAL，提高写入速度
            try database.exec(
                StatementPragma()
                    .pragma(.synchronous)
                    .to("NORMAL")
            )
            
            // 增加缓存大小
            try database.exec(
                StatementPragma()
                    .pragma(.cacheSize)
                    .to(-20000)
            )
            
            // 设置内存映射大小
            try database.exec(
                StatementPragma()
                    .pragma(.mmapSize)
                    .to(30000000000)
            )
            
            // 设置临时存储为内存
            try database.exec(
                StatementPragma()
                    .pragma(.tempStore)
                    .to("MEMORY")
            )
            
            print("数据库配置优化完成")
        } catch {
            print("数据库配置优化失败: \(error)")
        }
    }
    
    // MARK: - 初始化数据库
    private func setupDatabase() {
        operationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                // 创建主表
                try self.database.create(table: "poi_data", of: PublicPOIData.self)
                
                // 创建下载状态表
                try self.database.create(table: "download_status",
                                         of: POIDownloadStatus.self)
                
                // 创建索引 - 直接创建，因为内部有 ifNotExists()
                try self.database.create(index: "idx_poi_id",
                                         with: PublicPOIData.Properties.id,
                                         forTable: "poi_data")
                
                try self.database.create(index: "idx_poi_category",
                                         with: PublicPOIData.Properties.category,
                                         forTable: "poi_data")
                
                try self.database.create(index: "idx_poi_name",
                                         with: PublicPOIData.Properties.name,
                                         forTable: "poi_data")
                
                try self.database.create(index: "idx_poi_location",
                                         with: [
                                            PublicPOIData.Properties.wgsLat,
                                            PublicPOIData.Properties.wgsLon
                                         ],
                                         forTable: "poi_data")
                
                // 创建收藏时间索引（用于倒序排序）
                try self.database.create(index: "idx_collection_time",
                                         with: PublicPOIData.Properties.collectionTime,
                                         forTable: "poi_data")
                
                // 创建打卡时间索引
                try self.database.create(index: "idx_check_time",
                                         with: PublicPOIData.Properties.checkTime,
                                         forTable: "poi_data")
                
                // 创建联合索引（用于快速筛选+排序）
                try self.database.create(index: "idx_collection_list",
                                         with: [
                                            PublicPOIData.Properties.isCollection,
                                            PublicPOIData.Properties.collectionTime,
                                            PublicPOIData.Properties.name
                                         ],
                                         forTable: "poi_data")
                
                try self.database.create(index: "idx_check_list",
                                         with: [
                                            PublicPOIData.Properties.isIsCheck,
                                            PublicPOIData.Properties.checkTime,
                                            PublicPOIData.Properties.name
                                         ],
                                         forTable: "poi_data")
                
                self.isDatabaseSetup = true
                print("数据库初始化成功，已创建索引")
            } catch {
                print("数据库初始化失败: \(error)")
            }
        }
    }
    
    // MARK: - 批量插入数据（标准模式，带冲突处理）
    public func batchInsertPOIs(_ items: [PublicPOIData], completion: ((Error?) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(nil)
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 使用事务和 INSERT OR REPLACE
                try self.database.run(transaction: { _ in
                    let chunks = items.chunked(into: self.maxBatchSize)
                    
                    for chunk in chunks {
                        // 使用 INSERT OR REPLACE 自动处理重复数据
                        for item in chunk {
                            try self.database.insertOrReplace(item, intoTable: "poi_data")
                        }
                    }
                })
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                print("批量插入 \(items.count) 条数据完成，耗时: \(String(format: "%.2f", timeElapsed))秒")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
                
            } catch {
                print("批量插入失败: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    // MARK: - 极速批量插入（跳过重复检查，适用于首次导入）
    public func batchInsertPOIsFast(_ items: [PublicPOIData], completion: ((Error?) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(nil)
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 临时禁用同步以提高插入速度
                try self.database.exec(StatementPragma().pragma(.synchronous).to("OFF"))
                
                // 开始事务
                try self.database.run(transaction: { _ in
                    let chunks = items.chunked(into: 10000) // 每批10000条
                    
                    for chunk in chunks {
                        try self.database.insert(chunk, intoTable: "poi_data")
                    }
                })
                
                // 恢复同步模式
                try self.database.exec(StatementPragma().pragma(.synchronous).to("NORMAL"))
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
//                print("快速插入 \(items.count) 条数据完成，耗时: \(String(format: "%.2f", timeElapsed))秒")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
                
            } catch {
                // 恢复同步模式
                try? self.database.exec(StatementPragma().pragma(.synchronous).to("NORMAL"))
                print("快速插入失败: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    // MARK: - 批量插入（带去重检查）
    public func batchInsertPOIsWithDeduplication(_ items: [PublicPOIData], completion: ((Error?) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(nil)
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        writeQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                var insertedCount = 0
                
                try self.database.run(transaction: { _ in
                    let chunks = items.chunked(into: self.maxBatchSize)
                    
                    for chunk in chunks {
                        // 过滤已存在的数据
                        let newItems = try self.filterExistingItems(chunk)
                        
                        if !newItems.isEmpty {
                            try self.database.insert(newItems, intoTable: "poi_data")
                            insertedCount += newItems.count
                        }
                    }
                })
                
                let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                print("批量插入完成，新增 \(insertedCount) 条，耗时: \(String(format: "%.2f", timeElapsed))秒")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
                
            } catch {
                print("批量插入失败: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    // MARK: - 过滤已存在的项目
    private func filterExistingItems(_ items: [PublicPOIData]) throws -> [PublicPOIData] {
        guard !items.isEmpty else { return [] }
        
        let ids = items.compactMap { $0.id }
        guard !ids.isEmpty else { return items }
        
        let condition = PublicPOIData.Properties.id.in(ids)
        let existingItems: [PublicPOIData] = try self.database.getObjects(
            fromTable: "poi_data",
            where: condition
        )
        
        let existingIds = Set(existingItems.compactMap { $0.id })
        
        return items.filter { item in
            guard let id = item.id else { return true }
            return !existingIds.contains(id)
        }
    }
    
    // MARK: - 查询数据
    public func fetchPOIs(limit: Int = 100,
                          offset: Int = 0,
                          category: Int? = nil,
                          completion: @escaping ([PublicPOIData]) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                var condition: Condition? = nil
                if let category = category {
                    condition = PublicPOIData.Properties.category == category
                }
                
                let items: [PublicPOIData] = try self.database.getObjects(
                    on: PublicPOIData.Properties.all,
                    fromTable: "poi_data",
                    where: condition,
                    orderBy: [PublicPOIData.Properties.name.asOrder()],
                    limit: limit,
                    offset: offset
                )
                
                DispatchQueue.main.async {
                    completion(items)
                }
            } catch {
                print("查询POI数据失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // MARK: - 根据坐标范围查询
    public func fetchPOIsInRegion(minLat: Double,
                                   maxLat: Double,
                                   minLon: Double,
                                   maxLon: Double,
                                   limit: Int = 2000,
                                   completion: @escaping ([PublicPOIData]) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                let condition = PublicPOIData.Properties.wgsLat.between(minLat, maxLat) &&
                               PublicPOIData.Properties.wgsLon.between(minLon, maxLon)
                
                let items: [PublicPOIData] = try self.database.getObjects(
                    on: PublicPOIData.Properties.all,
                    fromTable: "poi_data",
                    where: condition,
                    limit: limit
                )
                
                DispatchQueue.main.async {
                    completion(items)
                }
            } catch {
                print("区域查询失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // MARK: - 根据关键词搜索
    public func searchPOIs(keyword: String,
                          limit: Int = 100,
                          completion: @escaping ([PublicPOIData]) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                // 使用LIKE进行模糊搜索
                let condition = PublicPOIData.Properties.name.like("%\(keyword)%") ||
                               PublicPOIData.Properties.address.like("%\(keyword)%")
                
                let items: [PublicPOIData] = try self.database.getObjects(
                    on: PublicPOIData.Properties.all,
                    fromTable: "poi_data",
                    where: condition,
                    orderBy: [PublicPOIData.Properties.name.asOrder()],
                    limit: limit
                )
                
                DispatchQueue.main.async {
                    completion(items)
                }
            } catch {
                print("搜索POI失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // MARK: - 根据ID查询单个POI
    public func fetchPOI(by id: String, completion: @escaping (PublicPOIData?) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let condition = PublicPOIData.Properties.id == id
                
                let item: PublicPOIData? = try self.database.getObject(
                    on: PublicPOIData.Properties.all,
                    fromTable: "poi_data",
                    where: condition
                )
                
                DispatchQueue.main.async {
                    completion(item)
                }
            } catch {
                print("根据ID查询POI失败: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - 批量查询（根据ID列表）
    public func fetchPOIs(by ids: [String], completion: @escaping ([PublicPOIData]) -> Void) {
        guard !ids.isEmpty else {
            completion([])
            return
        }
        
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                let condition = PublicPOIData.Properties.id.in(ids)
                
                let items: [PublicPOIData] = try self.database.getObjects(
                    on: PublicPOIData.Properties.all,
                    fromTable: "poi_data",
                    where: condition
                )
                
                DispatchQueue.main.async {
                    completion(items)
                }
            } catch {
                print("批量查询POI失败: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    // MARK: - 更新POI
    public func updatePOI(_ poi: PublicPOIData, completion: ((Bool, Error?) -> Void)? = nil) {
        guard let id = poi.id else {
            completion?(false, NSError(domain: "POIDatabase", code: 400,
                                       userInfo: [NSLocalizedDescriptionKey: "ID不能为空"]))
            return
        }
        
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let condition = PublicPOIData.Properties.id == id
                try self.database.update(table: "poi_data",
                                        on: PublicPOIData.Properties.all,
                                        with: poi,
                                        where: condition)
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch {
                print("更新POI失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    // MARK: - 更新指定字段
    public func updatePOIFields(id: String,
                               isCollection: Bool? = nil,
                               isIsCheck: Bool? = nil,
                               completion: ((Bool, Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let condition = PublicPOIData.Properties.id == id
                
                if let isCollection = isCollection {
                    try self.database.update(table: "poi_data",
                                            on: [PublicPOIData.Properties.isCollection],
                                            with: [isCollection],
                                            where: condition)
                }
                
                if let isIsCheck = isIsCheck {
                    try self.database.update(table: "poi_data",
                                            on: [PublicPOIData.Properties.isIsCheck],
                                            with: [isIsCheck],
                                            where: condition)
                }
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch {
                print("更新POI字段失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    // MARK: - 批量更新用户状态
    public func batchUpdateUserStates(collectionUpdates: [String: Bool] = [:],
                                      checkUpdates: [String: Bool] = [:],
                                      completion: ((Bool, Error?) -> Void)? = nil) {
        guard !collectionUpdates.isEmpty || !checkUpdates.isEmpty else {
            completion?(true, nil)
            return
        }
        
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.database.run(transaction: { _ in
                    // 更新收藏状态
                    for (id, isCollected) in collectionUpdates {
                        let condition = PublicPOIData.Properties.id == id
                        try self.database.update(table: "poi_data",
                                                on: [PublicPOIData.Properties.isCollection],
                                                with: [isCollected],
                                                where: condition)
                    }
                    
                    // 更新检查状态
                    for (id, isChecked) in checkUpdates {
                        let condition = PublicPOIData.Properties.id == id
                        try self.database.update(table: "poi_data",
                                                on: [PublicPOIData.Properties.isIsCheck],
                                                with: [isChecked],
                                                where: condition)
                    }
                })
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch {
                print("批量更新用户状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    // MARK: - 删除POI
    public func deletePOI(by id: String, completion: ((Bool, Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let condition = PublicPOIData.Properties.id == id
                try self.database.delete(fromTable: "poi_data", where: condition)
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch {
                print("删除POI失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    // MARK: - 批量删除
    public func deletePOIs(by ids: [String], completion: ((Bool, Error?) -> Void)? = nil) {
        guard !ids.isEmpty else {
            completion?(true, nil)
            return
        }
        
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let condition = PublicPOIData.Properties.id.in(ids)
                try self.database.delete(fromTable: "poi_data", where: condition)
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch {
                print("批量删除POI失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    // MARK: - 统计数据
    public func getTotalCount(completion: @escaping (Int) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(0) }
                return
            }
            
            do {
                let count = try self.database.getValue(on: PublicPOIData.Properties.id.count(),
                                                      fromTable: "poi_data")
                DispatchQueue.main.async {
                    completion(count.intValue)
                }
            } catch {
                print("获取总数失败: \(error)")
                DispatchQueue.main.async {
                    completion(0)
                }
            }
        }
    }
    
    // MARK: - 按分类统计
    public func getCountByCategory(completion: @escaping ([Int: Int]) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([:]) }
                return
            }
            
            do {
                // 方法1：使用 getObjects 获取所有数据然后手动统计
                let allPOIs: [PublicPOIData] = try self.database.getObjects(
                    on: [PublicPOIData.Properties.category],
                    fromTable: "poi_data"
                )
                
                var categoryCounts: [Int: Int] = [:]
                for poi in allPOIs {
                    if let category = poi.category {
                        categoryCounts[category, default: 0] += 1
                    }
                }
                
                DispatchQueue.main.async {
                    completion(categoryCounts)
                }
                
            } catch {
                print("按分类统计失败: \(error)")
                DispatchQueue.main.async {
                    completion([:])
                }
            }
        }
    }
    
    // MARK: - 清空数据
    public func clearAllData(completion: ((Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.database.delete(fromTable: "poi_data")
                try self.database.delete(fromTable: "download_status")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch {
                print("清空数据失败: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    // MARK: - 下载状态管理
    
    /// 获取最新的下载状态
    public func getLatestDownloadStatus(completion: @escaping (POIDownloadStatus?) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let status: POIDownloadStatus? = try self.database.getObject(
                    fromTable: "download_status",
                    orderBy: [POIDownloadStatus.CodingKeys.lastDownloadTime.asOrder()]
                )
                
                DispatchQueue.main.async {
                    completion(status)
                }
            } catch {
                print("获取下载状态失败: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /// 保存下载状态
    public func saveDownloadStatus(_ status: POIDownloadStatus, completion: ((Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                // 清空旧的状态
                try self.database.delete(fromTable: "download_status")
                try self.database.insert(status, intoTable: "download_status")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch {
                print("保存下载状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
    /// 更新下载状态
    public func updateDownloadStatus(version: String,
                                     fileUrl: String,
                                     fileMd5: String,
                                     totalCount: Int,
                                     completion: ((Error?) -> Void)? = nil) {
        let status = POIDownloadStatus(
            id: nil,
            lastDownloadTime: Date(),
            fileVersion: version,
            fileUrl: fileUrl,
            fileMd5: fileMd5,
            totalCount: totalCount
        )
        
        saveDownloadStatus(status, completion: completion)
    }
}

// MARK: - 更新操作时间
extension POIDatabaseManager {
    
    /// 更新收藏状态和收藏时间
    public func updateCollectionStatus(id: String,
                                       isCollection: Bool,
                                       completion: ((Bool, Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let condition = PublicPOIData.Properties.id == id
                let collectionTime = isCollection ? Date() : nil
                
                try self.database.update(
                    table: "poi_data",
                    on: [
                        PublicPOIData.Properties.isCollection,
                        PublicPOIData.Properties.collectionTime
                    ],
                    with: [
                        isCollection,
                        collectionTime
                    ],
                    where: condition
                )
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                    
                    // 发送通知
                    NotificationCenter.default.post(
                        name: .collectionStatusChanged,
                        object: nil,
                        userInfo: ["id": id, "isCollection": isCollection]
                    )
                }
            } catch {
                print("更新收藏状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    /// 更新打卡状态和打卡时间
    public func updateCheckStatus(id: String,
                                  isCheck: Bool,
                                  completion: ((Bool, Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let condition = PublicPOIData.Properties.id == id
                let checkTime = isCheck ? Date() : nil
                
                try self.database.update(
                    table: "poi_data",
                    on: [
                        PublicPOIData.Properties.isIsCheck,
                        PublicPOIData.Properties.checkTime
                    ],
                    with: [
                        isCheck,
                        checkTime
                    ],
                    where: condition
                )
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                    
                    // 发送通知
                    NotificationCenter.default.post(
                        name: .checkStatusChanged,
                        object: nil,
                        userInfo: ["id": id, "isCheck": isCheck]
                    )
                }
            } catch {
                print("更新打卡状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
    
    /// 批量更新（用于同步服务器数据）
    public func batchUpdateUserStatus(updates: [(id: String,
                                                 isCollection: Bool?,
                                                 isCheck: Bool?)],
                                      completion: ((Bool, Error?) -> Void)? = nil) {
        writeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.database.run(transaction: { _ in
                    for update in updates {
                        let condition = PublicPOIData.Properties.id == update.id
                        
                        if let isCollection = update.isCollection {
                            let collectionTime = isCollection ? Date() : nil
                            try self.database.update(
                                table: "poi_data",
                                on: [
                                    PublicPOIData.Properties.isCollection,
                                    PublicPOIData.Properties.collectionTime
                                ],
                                with: [isCollection, collectionTime],
                                where: condition
                            )
                        }
                        
                        if let isCheck = update.isCheck {
                            let checkTime = isCheck ? Date() : nil
                            try self.database.update(
                                table: "poi_data",
                                on: [
                                    PublicPOIData.Properties.isIsCheck,
                                    PublicPOIData.Properties.checkTime
                                ],
                                with: [isCheck, checkTime],
                                where: condition
                            )
                        }
                    }
                })
                
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch {
                print("批量更新状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        }
    }
}

// MARK: - 数据库文件信息
extension POIDatabaseManager {
    
    /// 获取数据库文件大小（格式化后的字符串）
    public func getDatabaseFileSize(completion: @escaping (String) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion("0B") }
                return
            }
            
            do {
                let dbPath = self.database.path
                let fileManager = FileManager.default
                
                // 获取主数据库文件大小
                var totalSize: UInt64 = 0
                
                if fileManager.fileExists(atPath: dbPath) {
                    let attributes = try fileManager.attributesOfItem(atPath: dbPath)
                    totalSize += attributes[.size] as? UInt64 ?? 0
                }
                
                // 获取 WAL 文件大小（如果有）
                let walPath = dbPath + "-wal"
                if fileManager.fileExists(atPath: walPath) {
                    let attributes = try fileManager.attributesOfItem(atPath: walPath)
                    totalSize += attributes[.size] as? UInt64 ?? 0
                }
                
                // 获取 SHM 文件大小（如果有）
                let shmPath = dbPath + "-shm"
                if fileManager.fileExists(atPath: shmPath) {
                    let attributes = try fileManager.attributesOfItem(atPath: shmPath)
                    totalSize += attributes[.size] as? UInt64 ?? 0
                }
                
                let formattedSize = self.formatFileSize(totalSize)
                
                DispatchQueue.main.async {
                    completion(formattedSize)
                }
                
            } catch {
                print("获取数据库文件大小失败: \(error)")
                DispatchQueue.main.async {
                    completion("0B")
                }
            }
        }
    }
    
    /// 获取数据库文件修改时间
    public func getDatabaseModificationTime(completion: @escaping (String) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion("未知") }
                return
            }
            
            do {
                let dbPath = self.database.path
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: dbPath) {
                    let attributes = try fileManager.attributesOfItem(atPath: dbPath)
                    if let modificationDate = attributes[.modificationDate] as? Date {
                        let formattedDate = self.formatDate(modificationDate)
                        DispatchQueue.main.async {
                            completion(formattedDate)
                        }
                        return
                    }
                }
                
                DispatchQueue.main.async {
                    completion("未知")
                }
                
            } catch {
                print("获取数据库修改时间失败: \(error)")
                DispatchQueue.main.async {
                    completion("未知")
                }
            }
        }
    }
    
    /// 获取数据库记录总数
    public func getDatabaseRecordCount(completion: @escaping (Int) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(0) }
                return
            }
            
            do {
                let count = try self.database.getValue(
                    on: PublicPOIData.Properties.id.count(),
                    fromTable: "poi_data"
                ).intValue
                
                DispatchQueue.main.async {
                    completion(count)
                }
            } catch {
                print("获取记录总数失败: \(error)")
                DispatchQueue.main.async {
                    completion(0)
                }
            }
        }
    }
    
    /// 获取数据库完整信息（大小、时间、记录数）
    public func getDatabaseInfo(completion: @escaping (_ size: String, _ time: String, _ count: Int) -> Void) {
        let group = DispatchGroup()
        
        var fileSize = "0B"
        var modifyTime = "未知"
        var recordCount = 0
        
        group.enter()
        getDatabaseFileSize { size in
            fileSize = size
            group.leave()
        }
        
        group.enter()
        getDatabaseModificationTime { time in
            modifyTime = time
            group.leave()
        }
        
        group.enter()
        getDatabaseRecordCount { count in
            recordCount = count
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(fileSize, modifyTime, recordCount)
        }
    }
    
    // MARK: - 私有辅助方法
    
    private func formatFileSize(_ size: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var convertedSize = Double(size)
        var unitIndex = 0
        
        while convertedSize >= 1024 && unitIndex < units.count - 1 {
            convertedSize /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.2f%@", convertedSize, units[unitIndex])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
