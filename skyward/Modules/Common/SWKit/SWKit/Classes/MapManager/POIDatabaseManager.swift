//
//  CodingKeys.swift
//  Pods
//
//  Created by TXTS on 2025/12/13.
//


import WCDBSwift
import Alamofire
import Combine
import BackgroundTasks
import Network
import SWNetwork

// MARK: - 数据库管理器
public class POIDatabaseManager {
    public static let shared = POIDatabaseManager()
    
    public let database: Database
    private let operationQueue: DispatchQueue
    private let maxBatchSize = 500 // 每批最多插入500条
    
    private init() {
        // 数据库路径
        let dbPath = FileManager.default.urls(for: .documentDirectory, 
                                             in: .userDomainMask)[0]
            .appendingPathComponent("poi_database.db")
        
        database = Database(at: dbPath.path)
        operationQueue = DispatchQueue(label: "com.poi.database.queue", 
                                      qos: .utility,
                                      attributes: .concurrent)
        
        setupDatabase()
    }
    
    // MARK: - 初始化数据库
    private func setupDatabase() {
        operationQueue.async(flags: .barrier) {
            do {
                // 创建主表
                try self.database.create(table: "poi_data", of: PublicPOIData.self)
                
                // 创建下载状态表
                try self.database.create(table: "download_status", 
                                        of: POIDownloadStatus.self)
                
                print("数据库初始化成功")
            } catch {
                print("数据库初始化失败: \(error)")
            }
        }
    }
    
    // MARK: - 批量插入数据（静默）（检查重复）
    public func batchInsertPOIs(_ items: [PublicPOIData], completion: ((Error?) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(nil)
            return
        }
        
        operationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                // 使用事务
                try self.database.run(transaction: { _ in
                    let chunks = items.chunked(into: self.maxBatchSize)
                    
                    for chunk in chunks {
                        // 过滤掉已存在的数据
                        let newItems = try self.filterExistingItems(chunk)
                        
                        if !newItems.isEmpty {
                            try self.database.insert(newItems, intoTable: "poi_data")
                        }
                    }
                })
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
                
                NotificationCenter.default.post(
                    name: .poiDataDidUpdate,
                    object: items.count
                )
                
            } catch {
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }

    // MARK: - 过滤已存在的项目
    private func filterExistingItems(_ items: [PublicPOIData]) throws -> [PublicPOIData] {
        guard !items.isEmpty else { return [] }
        
        // 假设每个POI有唯一ID，这里使用id字段
        // 如果你的唯一标识是其他字段，可以修改这里的逻辑
        let ids = items.map { $0.id }
        
        guard !ids.isEmpty else { return items }
        
        // 查询已存在的ID
        let condition = PublicPOIData.Properties.id.in(ids as! [any ExpressionConvertible])
        let existingItems: [PublicPOIData] = try self.database.getObjects(
            fromTable: "poi_data",
            where: condition
        )
        
        let existingIds = Set(existingItems.map { $0.id })
        
        // 返回不存在的数据
        return items.filter { !existingIds.contains($0.id) }
    }
    
    // MARK: - 查询数据（兼容现有UI）
    public func fetchPOIs(limit: Int = 100, 
                  offset: Int = 0,
                  category: Int? = nil,
                  completion: @escaping ([PublicPOIData]) -> Void) {
        operationQueue.async {
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
                    offset: offset)
                
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
                          completion: @escaping ([PublicPOIData]) -> Void) {
        operationQueue.async {
            do {
                let condition = PublicPOIData.Properties.wgsLat.between(minLat, maxLat) &&
                               PublicPOIData.Properties.wgsLon.between(minLon, maxLon)
                
                let items: [PublicPOIData] = try self.database.getObjects(
                    on: PublicPOIData.Properties.all,
                    fromTable: "poi_data",
                    where: condition,
                    limit: 200 // 限制数量，避免内存问题
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
    
    // MARK: - 统计数据
    public func getTotalCount(completion: @escaping (Int) -> Void) {
        operationQueue.async {
            do {
                let value = try self.database.getValue(
                    on: PublicPOIData.Properties.id.count(),
                    fromTable: "poi_data"
                )
                
                let count = value.intValue
                
                DispatchQueue.main.async {
                    completion(count)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(0)
                }
            }
        }
    }
    
    // MARK: - 清空数据
    func clearAllData(completion: ((Error?) -> Void)? = nil) {
        operationQueue.async(flags: .barrier) {
            do {
                try self.database.delete(fromTable: "poi_data")
                try self.database.delete(fromTable: "download_status")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
}

