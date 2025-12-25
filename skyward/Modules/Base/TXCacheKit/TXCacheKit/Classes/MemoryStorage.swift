//
//  MemoryStorage.swift
//  Pods-TXCacheKit_Example
//
//  Created by 赵波 on 2025/11/14.
//

import Foundation

public class MemoryStorage<T> {

    var cache = NSCache<NSString, MemoryObject<T>>()
    var keys = Set<String>()

    var totalCostLimit: Int
    var countLimit: Int = Int.max
    var cleanInterval: TimeInterval
    
    /// 此 `MemoryStorage` 的默认过期时间
    /// 如果 `setValue(_:forkey:expiration:)` 的过期值为 nil，则使用此默认值。
    var expiration: Expiration
    
    var cleanTimer: Timer? = nil
    let lock = NSLock()
    
    /// 使用给定的 `totalCostLimit` 和 `expiration` 创建一个 `MemoryStorage`
    public init(totalCostLimit: Int, expiration: Expiration = .seconds(CacheTimeConstant.secondsOneMinute * 5), cleanInterval: TimeInterval = 120) {
        self.totalCostLimit = totalCostLimit
        self.expiration = expiration
        self.cleanInterval = cleanInterval
        cache.totalCostLimit = totalCostLimit
        cache.countLimit = self.countLimit
        
        cleanTimer = Timer.scheduledTimer(timeInterval: cleanInterval, target: self, selector: #selector(removeExpired), userInfo: nil, repeats: true)
    }
    
    /// `MemoryStorage` 的下标访问
    public subscript(key: String) -> T? {
        get {
            return value(forKey: key)
        }
        set {
            guard let value = newValue else { return }
            setValue(value, forKey: key)
        }
    }
    
    /// 设置带过期时间的值到 `MemoryStorage`。
    ///
    /// - 参数:
    ///   - value: 要存储的值
    ///   - key: 用于查找值的键
    ///   - expiration: 存储过期时间，默认为 nil，使用 `self` 的默认过期值
    public func setValue(_ value: T, forKey key: String, expiration: Expiration? = nil) {
        
        lock.lock()
        defer { lock.unlock() }
        
        let expiration = expiration ?? self.expiration
        guard !expiration.isExpired else { return }
        
        let memoryObject = MemoryObject(value, key: key, expiration: expiration)
        cache.setObject(memoryObject, forKey: key as NSString)
        keys.insert(key)
    }
    
    /// 获取指定键的值的方法
    ///
    /// - 参数:
    ///   - key: 用于查找值的键
    ///   - extendingExpiration: `ExpirationExtending` 策略
    /// - 返回: 缓存的对象或 nil
    public func value(forKey key: String, extendingExpiration: ExpirationExtending = .cacheTime) -> T? {
        guard let object = cache.object(forKey: key as NSString) else { return nil }
        guard !object.expired else { return nil }
        
        object.extendExpiration(extendingExpiration)
        return object.value
    }
    
    /// 存储是否包含指定 `key` 的值。
    public func containsValue(forKey key: String) -> Bool {
        guard let _ = value(forKey: key, extendingExpiration: .none) else { return false }
        return true
    }
    
    /// 移除指定 `key` 的值
    public func removeValue(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeObject(forKey: key as NSString)
        keys.remove(key)
    }
    
    /// 从此存储中移除所有值。
    public func removeAll() throws {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAllObjects()
        keys.removeAll()
    }
    
    /// 从此存储中移除已过期的对象。
    @objc public func removeExpired() {
        lock.lock()
        defer { lock.unlock() }
        
        for key in keys {
            guard let object = cache.object(forKey: key as NSString) else {
                keys.remove(key)
                continue
            }
            if object.expired {
                cache.removeObject(forKey: key as NSString)
                keys.remove(key)
            }
        }
    }
}

class MemoryObject<T> {
    
    let key: String
    let value: T
    let expiration: Expiration
    
    private(set) var estimatedExpiration: Date

    init(_ value: T, key: String, expiration: Expiration) {
        self.key = key
        self.value = value
        self.expiration = expiration
        
        self.estimatedExpiration = expiration.estimatedExpirationSinceNow
    }
    
    /// 延长过期时间
    func extendExpiration(_ extendExpiration: ExpirationExtending = .cacheTime) {
        switch extendExpiration {
        case .none:
            return
        case .cacheTime:
            self.estimatedExpiration = expiration.estimatedExpirationSinceNow
        case .expirationTime(let expriationTime):
            self.estimatedExpiration = expriationTime.estimatedExpirationSinceNow
        }
    }
    
    var expired: Bool {
        return self.estimatedExpiration.isPastDate
    }
}
