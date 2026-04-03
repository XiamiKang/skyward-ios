//
//  POISyncManager.swift
//  Pods
//
//  Created by TXTS on 2026/2/27.
//


import Combine
import Foundation

/// POI同步管理器 - 负责管理本地数据的同步状态
public class POISyncManager {
    
    // MARK: - 单例
    public static let shared = POISyncManager()
    
    // MARK: - 属性
    private let dbManager = UserPOILocalDBManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 同步状态发布者
    public let hasUnsyncedDataPublisher = CurrentValueSubject<Bool, Never>(false)
    
    private init() {
        // 初始化时检查同步状态
        checkUnsyncedStatus()
    }
    
    // MARK: - 公共方法
    
    /// 检查是否有未同步的数据
    /// - Returns: 是否有未同步数据
    @discardableResult
    public func checkUnsyncedStatus() -> Bool {
        let hasUnsynced = hasUnsyncedData()
        hasUnsyncedDataPublisher.send(hasUnsynced)
        return hasUnsynced
    }
    
    /// 获取未同步的数据数量
    /// - Returns: 未同步的数据条数
    public func getUnsyncedCount() -> Int {
        return dbManager.queryUnsyncedData()?.count ?? 0
    }
    
    /// 获取需要同步到服务器的数据（未同步且未删除的）
    /// - Returns: 需要同步的POI数据
    public func getDataNeedingSync() -> [UserPOILocalData]? {
        return dbManager.getDataNeedingSync()
    }
    
    /// 获取需要删除同步的数据（本地标记删除但未同步的）
    /// - Returns: 需要删除同步的POI数据
    public func getDataNeedingDeleteSync() -> [UserPOILocalData]? {
        return dbManager.getDataNeedingDeleteSync()
    }
    
    /// 更新POI同步状态（成功同步后调用）
    /// - Parameters:
    ///   - poiId: POI ID
    ///   - isSynced: 同步状态
    public func updateSyncStatus(for poiId: String, isSynced: Bool) {
        dbManager.updateSyncStatus(for: poiId, isSynced: isSynced)
        checkUnsyncedStatus() // 更新后重新检查状态
    }
    
    /// 批量更新POI同步状态
    /// - Parameters:
    ///   - poiIds: POI ID数组
    ///   - isSynced: 同步状态
    public func updateSyncStatus(for poiIds: [String], isSynced: Bool) {
        dbManager.updateSyncStatus(for: poiIds, isSynced: isSynced)
        checkUnsyncedStatus() // 更新后重新检查状态
    }
    
    /// 标记数据为已同步（成功同步到服务器后调用）
    /// - Parameter poiId: POI ID
    public func markAsSynced(poiId: String) {
        updateSyncStatus(for: poiId, isSynced: true)
    }
    
    /// 标记数据为未同步（本地修改后调用）
    /// - Parameter poiId: POI ID
    public func markAsUnsynced(poiId: String) {
        updateSyncStatus(for: poiId, isSynced: false)
    }
    
    /// 重置同步状态（用于测试或特殊场景）
    public func resetAllSyncStatus() {
        guard let allData = dbManager.queryAll() else { return }
        let poiIds = allData.compactMap { $0.poiId }
        updateSyncStatus(for: poiIds, isSynced: false)
    }
    
    // MARK: - 私有方法
    
    /// 检查是否有未同步数据
    private func hasUnsyncedData() -> Bool {
        return getUnsyncedCount() > 0
    }
}