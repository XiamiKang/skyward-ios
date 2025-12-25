//
//  NetworkCacher.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

import Foundation

public class NetworkCacherCacher {
    
    public static let shared = NetworkCacherCacher()

    public var urlCache: URLCache?
    public var cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataDontLoad
    
    init() {
        defaultConfig()
        addObserver()
    }
    
    func defaultConfig() {
        let cacheDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheURL = cacheDirectoryURL.appendingPathComponent("NetworkCache")
        
        urlCache = URLCache(
            memoryCapacity: 4 * 1024 * 1024,
            diskCapacity: 20 * 1024 * 1024,
            directory: cacheURL
        )
    }
    
    func addObserver() {
        // 移除UIKit依赖，改为定时清理缓存
        // 在实际应用中，这个清理操作应该在应用生命周期管理中调用
        // 这里只是提供一个清理方法，由调用者决定何时清理
    }
    
   public func cleanCacheIfNeed() {
        let cache = URLCache.shared
        let maxCacheSize = 20 * 1024 * 1024
        let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60
        
        if cache.currentDiskUsage > maxCacheSize {
            cache.removeCachedResponses(since: Date(timeIntervalSinceNow: -maxCacheAge))
        }
    }
}
