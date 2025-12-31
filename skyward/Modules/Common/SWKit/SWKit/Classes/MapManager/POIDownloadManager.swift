//
//  POIDownloadManager.swift
//  Pods
//
//  Created by TXTS on 2025/12/31.
//


import Foundation
import Moya
import WCDBSwift
import Combine
import Network
import SWNetwork

// MARK: - 公共兴趣点数据下载管理器
public class POIDownloadManager {
    public static let shared = POIDownloadManager()
    
    private let publicPOIService = PublicPOIService()
    private let databaseManager = POIDatabaseManager.shared
    private let operationQueue: DispatchQueue
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NWPathMonitor()
    
    // 配置常量
    private struct Config {
        static let pageSize = 1000
        static let maxRetryCount = 3
        static let initialDownloadKey = "isPOIInitialDownloadCompleted"
    }
    
    private var isDownloading = false
    
    private init() {
        // 初始化操作队列
        operationQueue = DispatchQueue(
            label: "com.poi.download.queue",
            qos: .utility,
            attributes: .concurrent
        )
        
        userDefaults = UserDefaults.standard
    }
    
    // MARK: - 启动下载
    /// 启动静默下载：只在首次启动时下载
    public func startSilentDownload() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否已经完成初始下载
            let isInitialDownloadCompleted = self.userDefaults.bool(forKey: Config.initialDownloadKey)
            
            if !isInitialDownloadCompleted {
                print("首次启动，开始静默下载")
                self.startFullDownload()
            } else {
                print("已下载过POI数据，跳过下载")
            }
        }
    }
    
    // MARK: - 手动刷新
    /// 手动刷新数据
    public func manualRefresh(completion: ((Bool) -> Void)? = nil) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            print("开始手动刷新POI数据")
            self.startFullDownload { success in
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }
    
    // MARK: - 完整下载
    private func startFullDownload(completion: ((Bool) -> Void)? = nil) {
        startFullDownload(retryCount: 0, completion: completion)
    }
    
    private func startFullDownload(retryCount: Int = 0, completion: ((Bool) -> Void)? = nil) {
        guard !isDownloading else {
            print("已经在下载中，跳过")
            completion?(false)
            return
        }
        
//        guard !NetworkMonitor.shared.isConnected else {
//            print("网络不可用，无法下载")
//            completion?(false)
//            return
//        }
        
        guard retryCount < Config.maxRetryCount else {
            print("达到最大重试次数")
            completion?(false)
            return
        }
        
        isDownloading = true
        
        print("开始完整下载POI数据")
        
        // 开始分页下载
        downloadPage(page: 1, retryCount: retryCount) { [weak self] success in
            guard let self = self else {
                completion?(false)
                return
            }
            
            self.isDownloading = false
            
            if success {
                // 标记初始下载完成
                self.userDefaults.set(true, forKey: Config.initialDownloadKey)
                self.userDefaults.synchronize()
                
                print("POI数据下载完成")
                
                // 保存下载状态
                self.saveDownloadStatus(completed: true)
                self.notifyDownloadCompleted()
            } else {
                // 失败重试
                print("下载失败，准备重试 (已尝试: \(retryCount + 1))")
                DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                    self.startFullDownload(retryCount: retryCount + 1, completion: completion)
                }
            }
            
            completion?(success)
        }
    }
    
    // MARK: - 分页下载
    private func downloadPage(page: Int, retryCount: Int = 0, completion: @escaping (Bool) -> Void) {
        let model = PublicPOIListModel(
            pageNum: page,
            pageSize: Config.pageSize
        )
        
        print("正在下载第 \(page) 页")
        
        
        publicPOIService.getPublicPOIList(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    do {
                        let baseResponse = try JSONDecoder().decode(SWResponse<[PublicPOIData]>.self, from: response.data)
                        
                        if baseResponse.code == "00000", let data = baseResponse.data {
                            
                            // 保存数据
                            self.savePOIData(data)
                            
                            // 更新下载状态
                            self.updateDownloadStatus(
                                page: page,
                                itemsCount: data.count
                            )
                            
                            print("下载的条数-----\(data.count)")
                            // 检查是否有更多页
                            if data.count == Config.pageSize*2 {
                                // 短暂延迟后下载下一页
                                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                                    self.downloadPage(page: page + 1, retryCount: retryCount, completion: completion)
                                }
                            } else {
                                // 下载完成
                                completion(true)
                            }
                            
                        } else {
                            print("服务器返回错误: \(baseResponse.msg)")
                            completion(false)
                        }
                    } catch {
                        print("解析失败: \(error)")
                        completion(false)
                    }
                    
                case .failure(let error):
                    print("网络请求失败失败: \(error)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - 保存数据
    private func savePOIData(_ items: [PublicPOIData]) {
        // 在保存新数据前，先查询已有的收藏和检查状态
        self.getExistingUserStates { existingStates in
            // 合并用户状态到新数据中
            let mergedItems = self.mergeUserStates(items: items, existingStates: existingStates)
            
            self.databaseManager.batchInsertPOIs(mergedItems) { error in
                if let error = error {
                    print("批量插入失败: \(error)")
                } else {
                    print("成功保存 \(mergedItems.count) 条数据")
                }
            }
        }
    }
    
    // MARK: - 合并用户状态
    private func getExistingUserStates(completion: @escaping ([String: (isCollection: Bool?, isIsCheck: Bool?)]) -> Void) {
        operationQueue.async {
            do {
                // 查询数据库中已有的所有POI的用户状态
                let allPOIs: [PublicPOIData] = try self.databaseManager.database.getObjects(
                    on: [
                        PublicPOIData.Properties.id,
                        PublicPOIData.Properties.isCollection,
                        PublicPOIData.Properties.isIsCheck
                    ],
                    fromTable: "poi_data"
                )
                
                var states: [String: (isCollection: Bool?, isIsCheck: Bool?)] = [:]
                for poi in allPOIs {
                    if let id = poi.id {
                        states[id] = (poi.isCollection, poi.isIsCheck)
                    }
                }
                
                DispatchQueue.main.async {
                    completion(states)
                }
            } catch {
                print("查询用户状态失败: \(error)")
                DispatchQueue.main.async {
                    completion([:])
                }
            }
        }
    }
    
    private func mergeUserStates(
        items: [PublicPOIData],
        existingStates: [String: (isCollection: Bool?, isIsCheck: Bool?)]
    ) -> [PublicPOIData] {
        return items.map { poi -> PublicPOIData in
            guard let id = poi.id else { return poi }
            
            if let existingState = existingStates[id] {
                // 保留用户已有的收藏和检查状态
                return PublicPOIData(
                    id: poi.id,
                    name: poi.name,
                    description: poi.description,
                    type: poi.type,
                    address: poi.address,
                    lon: poi.lon,
                    lat: poi.lat,
                    category: poi.category,
                    tel: poi.tel,
                    wgsLon: poi.wgsLon,
                    wgsLat: poi.wgsLat,
                    images: poi.images,
                    isCollection: existingState.isCollection,
                    isIsCheck: existingState.isIsCheck
                )
            } else {
                // 新数据，保持原有状态
                return poi
            }
        }
    }
    
    // MARK: - 更新用户收藏状态
    /// 更新POI的收藏状态
    public func updateCollectionState(poiId: String, isCollected: Bool, completion: ((Bool) -> Void)? = nil) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            do {
                // 使用WCDB更新指定POI的收藏状态
                try self.databaseManager.database.update(
                    table: "poi_data",
                    on: [PublicPOIData.Properties.isCollection],
                    with: [isCollected],
                    where: PublicPOIData.Properties.id == poiId
                )
                
                print("已更新POI \(poiId) 收藏状态: \(isCollected)")
                
                DispatchQueue.main.async {
                    completion?(true)
                }
            } catch {
                print("更新收藏状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - 更新用户检查状态
    /// 更新POI的检查状态
    public func updateCheckState(poiId: String, isChecked: Bool, completion: ((Bool) -> Void)? = nil) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            do {
                // 使用WCDB更新指定POI的检查状态
                try self.databaseManager.database.update(
                    table: "poi_data",
                    on: [PublicPOIData.Properties.isIsCheck],
                    with: [isChecked],
                    where: PublicPOIData.Properties.id == poiId
                )
                
                print("已更新POI \(poiId) 检查状态: \(isChecked)")
                
                DispatchQueue.main.async {
                    completion?(true)
                }
            } catch {
                print("更新检查状态失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - 批量更新用户状态
    /// 批量更新多个POI的状态
    public func batchUpdateUserStates(
        collectionUpdates: [String: Bool] = [:],
        checkUpdates: [String: Bool] = [:],
        completion: ((Bool) -> Void)? = nil
    ) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            do {
                try self.databaseManager.database.run(transaction: { _ in
                    // 批量更新收藏状态
                    for (poiId, isCollected) in collectionUpdates {
                        try self.databaseManager.database.update(
                            table: "poi_data",
                            on: [PublicPOIData.Properties.isCollection],
                            with: [isCollected],
                            where: PublicPOIData.Properties.id == poiId
                        )
                    }
                    
                    // 批量更新检查状态
                    for (poiId, isChecked) in checkUpdates {
                        try self.databaseManager.database.update(
                            table: "poi_data",
                            on: [PublicPOIData.Properties.isIsCheck],
                            with: [isChecked],
                            where: PublicPOIData.Properties.id == poiId
                        )
                    }
                })
                
                print("批量更新完成: 收藏更新 \(collectionUpdates.count) 条，检查更新 \(checkUpdates.count) 条")
                
                DispatchQueue.main.async {
                    completion?(true)
                }
            } catch {
                print("批量更新失败: \(error)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - 获取POI的用户状态
    /// 获取指定POI的用户状态
    public func getUserState(poiId: String, completion: @escaping (_ isCollection: Bool?, _ isIsCheck: Bool?) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                completion(nil, nil)
                return
            }
            
            do {
                let poi: PublicPOIData? = try self.databaseManager.database.getObject(
                    on: [
                        PublicPOIData.Properties.isCollection,
                        PublicPOIData.Properties.isIsCheck
                    ],
                    fromTable: "poi_data",
                    where: PublicPOIData.Properties.id == poiId
                )
                
                DispatchQueue.main.async {
                    completion(poi?.isCollection, poi?.isIsCheck)
                }
            } catch {
                print("获取用户状态失败: \(error)")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }
    }
    
    // MARK: - 下载状态管理
    private func updateDownloadStatus(
        page: Int,
        itemsCount: Int
    ) {
        let status = getDownloadStatus() ?? POIDownloadStatus()
        
        status.lastDownloadTime = Date()
        status.lastSuccessfulPage = page
        status.totalItems += itemsCount
        
        saveDownloadStatusObject(status)
    }
    
    private func saveDownloadStatus(completed: Bool) {
        let status = getDownloadStatus() ?? POIDownloadStatus()
        
        status.lastDownloadTime = Date()
        status.isCompleted = completed
        
        if completed {
            print("所有数据下载完成，总计: \(status.totalItems) 条")
        }
        
        saveDownloadStatusObject(status)
    }
    
    private func getDownloadStatus() -> POIDownloadStatus? {
        do {
            let status: POIDownloadStatus? = try self.databaseManager.database.getObject(
                fromTable: "download_status",
                where: POIDownloadStatus.Properties.id == 0
            )
            return status
        } catch {
            print("获取下载状态失败: \(error)")
            return nil
        }
    }
    
    private func saveDownloadStatusObject(_ status: POIDownloadStatus) {
        do {
            try self.databaseManager.database.insertOrReplace(
                status,
                intoTable: "download_status"
            )
        } catch {
            print("保存下载状态失败: \(error)")
        }
    }
    
    // MARK: - 通知下载完成
    private func notifyDownloadCompleted() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .poiDownloadCompleted,
                object: nil,
                userInfo: ["timestamp": Date()]
            )
        }
    }
    
    // MARK: - 公开方法
    /// 检查数据是否已下载
    public func isDataDownloaded() -> Bool {
        return userDefaults.bool(forKey: Config.initialDownloadKey)
    }
    
    /// 获取下载状态
    public func getDownloadStatusInfo() -> (isDownloading: Bool, isDownloaded: Bool) {
        return (isDownloading, isDataDownloaded())
    }
    
    /// 重置下载状态（用于测试或用户手动清空）
    public func resetDownloadStatus() {
        userDefaults.removeObject(forKey: Config.initialDownloadKey)
        userDefaults.synchronize()
        
        // 清空下载状态表
        do {
            try self.databaseManager.database.delete(fromTable: "download_status")
            print("下载状态已重置")
        } catch {
            print("清空下载状态失败: \(error)")
        }
    }
    
    deinit {
        networkMonitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 响应模型包装器
struct SWResponse<T: Codable>: Codable {
    let code: String
    let msg: String
    let data: T?
    let requestId: String?
}

// MARK: - 通知名称扩展
public extension Notification.Name {
    static let poiDataDidUpdate = Notification.Name("poiDataDidUpdate")
    static let poiDownloadCompleted = Notification.Name("poiDownloadCompleted")
}

// MARK: - 使用示例
/*
 使用方法：
 
 1. 在App启动时调用（建议延迟2秒）：
 
 DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
     POIDownloadManager.shared.startSilentDownload()
 }
 
 2. 在界面中更新收藏状态：
 
 POIDownloadManager.shared.updateCollectionState(
     poiId: "123",
     isCollected: true
 ) { success in
     if success {
         print("收藏状态更新成功")
     }
 }
 
 3. 在界面中更新检查状态：
 
 POIDownloadManager.shared.updateCheckState(
     poiId: "123",
     isChecked: true
 ) { success in
     if success {
         print("检查状态更新成功")
     }
 }
 
 4. 手动刷新数据：
 
 POIDownloadManager.shared.manualRefresh { success in
     if success {
         print("数据刷新成功")
     }
 }
 
 5. 获取POI的用户状态：
 
 POIDownloadManager.shared.getUserState(poiId: "123") { isCollection, isIsCheck in
     print("收藏状态: \(isCollection ?? false), 检查状态: \(isIsCheck ?? false)")
 }
 
 6. 监听下载完成通知：
 
 NotificationCenter.default.addObserver(
     self,
     selector: #selector(handleDownloadComplete),
     name: .poiDownloadCompleted,
     object: nil
 )
 
 @objc func handleDownloadComplete() {
     print("POI数据下载完成")
 }
 */
