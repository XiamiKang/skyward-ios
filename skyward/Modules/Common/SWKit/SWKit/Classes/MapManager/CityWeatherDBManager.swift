//
//  MiniDeviceDBManager.swift
//  Pods
//
//  Created by TXTS on 2026/2/27.
//


import Foundation
import WCDBSwift

public class CityWeatherDBManager {
    
    public static let shared = CityWeatherDBManager.init()
    
    public let database: Database
    private let operationQueue: DispatchQueue
    private let writeQueue: DispatchQueue
    
    private init() {
        // 数据库路径
        let dbPath = FileManager.default.urls(for: .documentDirectory,
                                             in: .userDomainMask)[0]
            .appendingPathComponent("cityWeather_database.db")
        
        database = Database(at: dbPath.path)
        operationQueue = DispatchQueue(label: "com.cityWeather.database.queue",
                                      qos: .userInitiated,
                                      attributes: .concurrent)
        writeQueue = DispatchQueue(label: "com.cityWeather.database.write", qos: .userInitiated)
        
        setupDatabase()
    }
    
    // MARK: - 初始化数据库
    private func setupDatabase() {
        operationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            do {
                // 创建主表
                try self.database.create(table: "cityWeather_data", of: CityWeatherData.self)
                print("CityWeather数据库初始化成功，已创建索引")
            } catch {
                print("数据库初始化失败: \(error)")
            }
        }
    }
    
    // MARK: - 批量插入数据（标准模式，带冲突处理）
    public func batchInsertCityWeathers(_ items: [CityWeatherData], completion: ((Error?) -> Void)? = nil) {
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
                    
                    // 使用 INSERT OR REPLACE 自动处理重复数据
                    for item in items {
                        try self.database.insertOrReplace(item, intoTable: "cityWeather_data")
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
    
    
    // MARK: - 查询整个表
    public func fetchCityWeathers(completion: @escaping ([CityWeatherData]) -> Void) {
        
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                let query = CityWeatherData.Properties.all.count
                
                let items: [CityWeatherData] = try self.database.getObjects(
                    on: CityWeatherData.Properties.all,
                    fromTable: "cityWeather_data",
                    where: query
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
    
    public func fetchProvicialCityWeathers(completion: @escaping ([CityWeatherData]) -> Void) {
        
        operationQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
            do {
                var query = CityWeatherData.Properties.isProvincial == true
                
                let items: [CityWeatherData] = try self.database.getObjects(
                    on: CityWeatherData.Properties.all,
                    fromTable: "cityWeather_data",
                    where: query
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
    
    /// 删除整个表的所有数据
    public func deleteAllCityWeathers(completion: ((Error?) -> Void)? = nil) {
        writeQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion?(nil)
                }
                return
            }
            
            do {
                // 使用 DELETE 语句删除表中所有数据
                // 不指定 where 条件表示删除所有记录
                try self.database.delete(fromTable: "cityWeather_data", where: nil)
                
                print("成功删除所有城市天气数据")
                
                DispatchQueue.main.async {
                    completion?(nil)
                }
                
            } catch {
                print("删除所有数据失败: \(error)")
                DispatchQueue.main.async {
                    completion?(error)
                }
            }
        }
    }
    
}



