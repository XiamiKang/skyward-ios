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

// MARK: - WCDB 表映射扩展
public struct PublicPOIData: Codable {
    public let id: String?
    public let name: String?
    public let description: String?
    public let type: String?
    public let address: String?
    public let lon: Double?
    public let lat: Double?
    public let category: Int?
    public let tel: String?
    public let wgsLon: Double?
    public let wgsLat: Double?
    public let images: String?
    public let isCollection: Bool?
    public let isIsCheck: Bool?
}

extension PublicPOIData: TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = PublicPOIData
        
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case name
        case description
        case type
        case address
        case lon
        case lat
        case category
        case tel
        case wgsLon
        case wgsLat
        case images
        case isCollection
        case isIsCheck
        
        // 列约束
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id"),
                .wgsLon: ColumnConstraintConfig(wgsLon, isPrimary: true, defaultTo: 0.0),
                .wgsLat: ColumnConstraintConfig(wgsLat, isPrimary: true, defaultTo: 0.0),
                .category: ColumnConstraintConfig(category, isPrimary: true, defaultTo: 0),
            ]
        }
    }
    
    public var isAutoIncrement: Bool { false }
    public init() { self.init(id: nil, name: nil, description: nil, type: nil, address: nil, lon: nil, lat: nil, category: nil, tel: nil, wgsLon: nil, wgsLat: nil, images: nil, isCollection: nil, isIsCheck: nil) }
}

// MARK: - 分页响应模型
struct POIPageResponse: Codable {
    let items: [PublicPOIData]
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalCount: Int
    let hasMore: Bool
}

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
    
    // MARK: - 批量插入数据（静默）
    public func batchInsertPOIs(_ items: [PublicPOIData], completion: ((Error?) -> Void)? = nil) {
        guard !items.isEmpty else {
            completion?(nil)
            return
        }
        
        operationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                // 使用事务，提高插入性能
                try self.database.run(transaction: { _ in
                    // 分批插入，避免单次事务过大
                    let chunks = items.chunked(into: self.maxBatchSize)
                    for chunk in chunks {
                        // 使用 insertOrReplace 避免重复数据
                        try self.database.insertOrReplace(chunk, intoTable: "poi_data")
                    }
                })
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
                
                // 发送数据更新通知（静默）
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
    func fetchPOIsInRegion(minLat: Double, 
                          maxLat: Double, 
                          minLon: Double, 
                          maxLon: Double,
                          completion: @escaping ([PublicPOIData]) -> Void) {
        operationQueue.async {
            do {
                let condition = PublicPOIData.Properties.lat.between(minLat, maxLat) &&
                               PublicPOIData.Properties.lon.between(minLon, maxLon)
                
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


// MARK: - 下载状态模型
public class POIDownloadStatus: TableCodable {
    var id: Int = 0
    var lastDownloadTime: Date = Date()
    var totalPages: Int = 0
    var totalItems: Int = 0
    var lastSuccessfulPage: Int = 0
    var isCompleted: Bool = false
    
    // 必需的无参初始化器
    required init() {}
    
    // 便利初始化器
    convenience init(lastDownloadTime: Date = Date(),
                     totalPages: Int = 0,
                     totalItems: Int = 0,
                     lastSuccessfulPage: Int = 0,
                     isCompleted: Bool = false) {
        self.init()
        self.lastDownloadTime = lastDownloadTime
        self.totalPages = totalPages
        self.totalItems = totalItems
        self.lastSuccessfulPage = lastSuccessfulPage
        self.isCompleted = isCompleted
    }
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = POIDownloadStatus
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case lastDownloadTime
        case totalPages
        case totalItems
        case lastSuccessfulPage
        case isCompleted
        
        static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: 0)
            ]
        }
    }
}

// MARK: - 通知扩展
public extension Notification.Name {
    static let poiDataDidUpdate = Notification.Name("poiDataDidUpdate")
    static let poiDownloadCompleted = Notification.Name("poiDownloadCompleted")
}

