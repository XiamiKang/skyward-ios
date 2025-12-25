//
//  Cache.swift
//  Pods-TXCacheKit_Example
//
//  Created by 赵波 on 2025/11/14.
//

import Foundation

public enum CacheTimeConstant {
    public static let secondsOneMinute: TimeInterval = 60
    public static let minutesOneHour: TimeInterval = 60
    public static let hoursOneDay: TimeInterval = 24
    public static let secondsOneDay: TimeInterval = secondsOneMinute * minutesOneHour * hoursOneDay
}

/// 过期时间
public enum Expiration {

    case seconds(TimeInterval)
    case days(Int)
    case date(Date)
    case never

    var timeInterval: TimeInterval {
        switch self {
        case .seconds(let seconds):
            return seconds
        case .days(let days):
            return CacheTimeConstant.secondsOneDay * TimeInterval(days)
        case .date(let date):
            return date.timeIntervalSinceNow
        case .never:
            return .infinity
        }
    }

    var isExpired: Bool {
        return timeInterval <= 0
    }

    func estimatedExpirationSince(_ date: Date) -> Date {
        switch self {
        case .never:
            return .distantFuture
        case .days(let days):
            return date.addingTimeInterval(CacheTimeConstant.secondsOneDay * TimeInterval(days))
        case .seconds(let seconds):
            return date.addingTimeInterval(seconds)
        case .date(let ref):
            return ref
        }
    }

    var estimatedExpirationSinceNow: Date {
        return estimatedExpirationSince(Date())
    }
}

/// 表示存储中使用的过期时间延长策略，在每次访问后生效。
///
/// - none: 项目按原始时间过期。
/// - cacheTime: 每次访问后，项目的过期时间按原始缓存时间延长。
/// - expirationTime: 每次访问后，项目的过期时间按提供的时间延长。
public enum ExpirationExtending {
    case none
    case cacheTime
    case expirationTime(expriation: Expiration)
}

/// 缓存错误类型
public enum CacheError: Error {

    enum DiskError {
        case fileNotFound
    }

    case notFound
}

public enum CacheType {
    case none, memory, disk
}

public struct CacheStoreResult {
    public let memoryCacheResult: Result<(), Never>
    public let diskCacheResult: Result<(), CacheError>
    
    public init(memoryCacheResult: Result<(), Never>, diskCacheResult: Result<(), CacheError>) {
        self.memoryCacheResult = memoryCacheResult
        self.diskCacheResult = diskCacheResult
    }
}
