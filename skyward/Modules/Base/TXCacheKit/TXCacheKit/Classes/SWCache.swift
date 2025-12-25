//
//  SWCache.swift
//  Pods-TXCacheKit_Example
//
//  Created by 赵波 on 2025/11/14.
//

import Foundation
import UIKit
import CommonCrypto
import TXCacheKit

public enum CacheModuleName {
    //缓存模块：具体在本地是文件夹名称
    //file:///var/mobile/Containers/Data/Application/4788A2CB-DFE3-49A6-BC63-813A360EC6BE/Library/Caches/HomeModule/
    case home
    case map
    case message
    case mine

    public var module: String {
        switch self {
        case .home:
            return "HomeModule"
        case .map:
            return "MapModule"
        case .message:
            return "MessageModule"
        case .mine:
            return "MineModule"
        }
    }
}

public enum SWCacheResult {
    case disk(Data)
    case memory(Data)
    case none
    
    public var data: Data? {
        switch self {
        case .disk(let data): return data
        case .memory(let data): return data
        case .none: return nil
        }
    }
    
    public var cacheType: CacheType {
        switch self {
        case .disk: return .disk
        case .memory: return .memory
        case .none: return .none
        }
    }
}

public class SWCache {
    
    @MainActor public static let `default` = try! SWCache(dirName: "Skyward")
    
    public let memoryStorage: MemoryStorage<Data>
    public let diskStorage: DiskStorage<Data>
    
    private let ioQueue: DispatchQueue
    
    public init(dirName: String, directoryURL: URL? = nil) throws {
        
        guard !dirName.isEmpty else {
            fatalError("Storage dirName can not be nil!")
        }
        
        ioQueue = DispatchQueue(label: "com.txts.CacheX.ioQueue\(UUID().uuidString)")
        
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let costLimit = totalMemory / 4
        memoryStorage = MemoryStorage<Data>(totalCostLimit: min(Int(costLimit), Int.max))
        
        if let directoryURL = directoryURL {
            diskStorage = try DiskStorage<Data>(dirName: dirName, directoryURL: directoryURL.appendingPathComponent(dirName, isDirectory: true))
        } else {
            diskStorage = try DiskStorage<Data>(dirName: dirName)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(clearMemoryCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cleanExpiredDiskCache), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundCleanExpiredDiskCache), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Set methods
    
    public func setValue(_ value: Data,
                         forKey key: String,
                         memoryCacheExpiration: Expiration = Expiration.seconds(CacheTimeConstant.secondsOneMinute * 10),
                         diskCacheExpiration: Expiration? = nil,
                         toDisk: Bool = true,
                         completionHandler: ((CacheStoreResult) -> Void)? = nil) {
        let key = key.cacheMd5
        
        memoryStorage.setValue(value, forKey: key, expiration: memoryCacheExpiration)
        
        guard toDisk else {
            if let completionHandler = completionHandler {
                let result = CacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
                completionHandler(result)
            }
            return
        }
        
        ioQueue.async {
            self.syncStoreToDisk(value, forKey: key, expriation: diskCacheExpiration, completionHandler: completionHandler)
        }
    }
    
    
    func syncStoreToDisk(_ value: Data,
                         forKey key: String,
                         expriation: Expiration? = nil,
                         completionHandler: ((CacheStoreResult) -> Void)? = nil) {

        let result: CacheStoreResult
        do {
            try self.diskStorage.setValue(value, forKey: key, expiration: expriation)
            result = CacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .success(()))
        } catch {
            let diskError: CacheError
            if let error = error as? CacheError {
                diskError = error
            } else {
                diskError = .notFound
            }
            result = CacheStoreResult(memoryCacheResult: .success(()), diskCacheResult: .failure(diskError))
        }
        
        if let completionHandler = completionHandler {
            completionHandler(result)
        }
    }
    
    // MARK: - Get methods
    ///
    public func value(forKey key: String,
                      completionHandler: ((Result<SWCacheResult, CacheError>) -> Void)?) {
        
        guard let completionHandler = completionHandler else { return }
        
        if let data = self.valueInMemory(forKey: key) {
            completionHandler(.success(.memory(data)))
        } else {
            self.valueInDisk(forKey: key) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        completionHandler(.success(.disk(data)))
                        return
                    }
                    completionHandler(.success(.none))
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        }
    }
    
    public func valueInMemory(forKey key: String) -> Data? {
        let key = key.cacheMd5
        return self.memoryStorage.value(forKey: key)
    }
    
    public func valueInDisk(forKey key: String,
                            completionHandler: @escaping (Result<Data?, CacheError>) -> Void) {
        let key = key.cacheMd5
        ioQueue.async {
            do {
                let data = try self.diskStorage.value(forKey: key)
                completionHandler(.success(data))
            } catch {
                if let error = error as? CacheError {
                    completionHandler(.failure(error))
                }
            }
        }
    }
    
    
    // MARK: - Cleaners
    
    public func cleanAllMemoryAndDiskCache(_ completionHandler: (() -> Void)? = nil) {
        clearMemoryCache()
        cleanDiskCache(completionHandler)
    }
    
    public func cleanMemoryAndDiskCache(forKey key: String) {
        let key = key.cacheMd5
        try? memoryStorage.removeValue(forKey: key)
        try? diskStorage.remove(forKey: key)
    }
    
    @objc public func clearMemoryCache() {
        try? memoryStorage.removeAll()
    }
    
    public func cleanDiskCache(_ completionHandler: (() -> Void)? = nil) {
        ioQueue.async {
            do {
                try self.diskStorage.removeAll()
            } catch {
            }
            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
    
    @objc func cleanExpiredDiskCache() {
        cleanExpiredDiskCache(completionHandler: nil)
    }
    
    public func cleanExpiredDiskCache(completionHandler: (() -> Void)? = nil) {
        ioQueue.async {
            do {
                var removed: [URL] = []
                let removedExpired = try self.diskStorage.removeExpiredValues()
                removed.append(contentsOf: removedExpired)
                
                let removedSizeExceeded = try self.diskStorage.removeSizeExceededValues()
                removed.append(contentsOf: removedSizeExceeded)
                if let completionHandler = completionHandler {
                    DispatchQueue.main.async { completionHandler() }
                }
            } catch {
//                print("cleanExpiredDiskCache error")
            }
        }
    }
    
    @MainActor @objc func backgroundCleanExpiredDiskCache() {

        guard let sharedApplication = UIApplication.shared else { return }
        
        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            #if swift(>=4.2)
            task = UIBackgroundTaskIdentifier.invalid
            #else
            task = UIBackgroundTaskInvalid
            #endif
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = sharedApplication.beginBackgroundTask {
            endBackgroundTask(&backgroundTask!)
        }
        
        cleanExpiredDiskCache {
            endBackgroundTask(&backgroundTask!)
        }
    }
    
}

extension UIApplication {
    fileprivate static var shared: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard self.responds(to: selector) else { return nil }
        return self.perform(selector).takeUnretainedValue() as? UIApplication
    }
}


/// 字符串的 md5 方法扩展。
extension String {
    internal var cacheMd5: String {
        guard let data = self.data(using: .utf8) else { return self }
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        #if swift(>=5.0)
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        #else
        _ = data.withUnsafeBytes { bytes in
            return CC_MD5(bytes, CC_LONG(data.count), &digest)
        }
        #endif

        return digest.reduce(into: "") { $0 += String(format: "%02x", $1) }
    }
}
