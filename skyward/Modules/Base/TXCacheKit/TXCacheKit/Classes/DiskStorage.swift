//
//  DiskStorage.swift
//  Pods-TXCacheKit_Example
//
//  Created by 赵波 on 2025/11/14.
//

import Foundation
import CommonCrypto

public class DiskStorage<T: DataConvertible> {

    let dirName: String
    let directoryURL: URL

    var sizeLimit: Int = Int.max
    var expiration: Expiration

    let metaChangeQueue: DispatchQueue
    let fileManager = FileManager.default

    /// 使用给定参数创建一个 `DiskStorage`。
///
/// - 参数:
    /// ///   - dirName: 存储目录名，即文件夹名称
///   - directoryURL: DiskStorage 基础目录，默认为 `.cachesDirectory`
///   - sizeLimit: 此存储的磁盘空间。
///   - expiration: 此存储的过期策略，默认为 7 天。
    public init(dirName: String, directoryURL: URL? = nil, sizeLimit: Int = Int.max, expiration: Expiration = .days(7)) throws {

        self.dirName = dirName
        self.sizeLimit = sizeLimit
        self.expiration = expiration
        
        if let directoryURL = directoryURL {
            self.directoryURL = directoryURL
        } else {
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            self.directoryURL = cachesDirectory.appendingPathComponent(dirName, isDirectory: true)
        }
        
        let queueLabel = "com.txts.cache.disk.\(dirName)"
        metaChangeQueue =  DispatchQueue(label: queueLabel, attributes: .concurrent)

        try touchDirectory()
    }

    /// 将对象存储到此存储中
    public func setValue(_ value: T, forKey key: String, expiration: Expiration? = nil) throws {
        
        let expiration = expiration ?? self.expiration

        guard !expiration.isExpired else { return }

        guard let data = value.dataValue else { return }

        let filePath = self.fileURL(forKey: key).path

        let now = Date()
        let attributes: [FileAttributeKey: Any] = [
            .creationDate: now,
            .modificationDate: expiration.estimatedExpirationSinceNow
        ]

        fileManager.createFile(atPath: filePath, contents: data, attributes: attributes)
    }

    /// 从此存储中检索对象。
    public func value(forKey key: String, referenceDate: Date = Date()) throws -> T? {

        let fileURL = self.fileURL(forKey: key)
        let filePath = fileURL.path
        guard fileManager.fileExists(atPath: filePath) else { return nil }

        let file: FileMeta
        do {
            file = try FileMeta(url: fileURL)
        } catch {
            throw CacheError.notFound
        }

        guard !file.expired(referenceDate: referenceDate) else { return nil }

        do {
            let data = try Data(contentsOf: fileURL)
            let obj = try T.fromData(data)
            metaChangeQueue.async { file.extendExpiration() }
            return obj
        } catch {
            throw CacheError.notFound
        }
    }

    /// 存储是否包含指定 `key` 的值。
    public func containsValue(forKey key: String, referenceDate: Date = Date()) -> Bool {
        do {
            guard let _ = try value(forKey: key, referenceDate: referenceDate) else {
                return false
            }
            return true
        } catch {
            return false
        }
    }

    /// 移除指定 `key` 的值
    public func remove(forKey key: String) throws {
        let fileURL = self.fileURL(forKey: key)
        try removeFile(at: fileURL)
    }

    /// 移除指定文件 `url` 的值
    func removeFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    /// 从此存储中移除所有值。
    public func removeAll(skipCreatingDirectory: Bool = false) throws {
        try fileManager.removeItem(at: directoryURL)
        if !skipCreatingDirectory {
            try touchDirectory()
        }
    }

    /// 从此存储中移除已过期的对象。
///
/// - 参数 referenceDate: 参考日期，默认为今天
/// - 返回: 被移除的文件 URL 数组。
    @discardableResult
    public func removeExpiredValues(referenceDate: Date = Date()) throws -> [URL] {
        let propertyKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .contentModificationDateKey
        ]
        let urls = try allFileURLs(for: propertyKeys)

        let expiredFileURLs = urls.filter { url -> Bool in
            do {
                let meta = try FileMeta(url: url)
                guard !meta.isDirectory else { return false }

                return meta.expired(referenceDate: referenceDate)
            } catch {
                return true
            }
        }
        try expiredFileURLs.forEach { url in
            try self.removeFile(at: url)
        }
        return expiredFileURLs
    }

    /// 移除溢出的值，如果大小溢出则除以 2 并递归移除。
    @discardableResult
    public func removeSizeExceededValues() throws -> [URL] {
        if sizeLimit == 0 { return [] }

        var totalSize = try self.totalSize()

        let propertyKeys: [URLResourceKey] = [
            .fileSizeKey,
            .creationDateKey
        ]
        guard totalSize > sizeLimit else { return [] }

        let urls = try allFileURLs(for: propertyKeys)

        var metas: [FileMeta] = urls.compactMap { url in
            do {
                let meta = try FileMeta(url: url)
                return meta
            } catch {
                return nil
            }
        }

        _ = metas.sorted { lhs, rhs -> Bool in
            return lhs.modificationDate ?? .distantPast > rhs.modificationDate ?? .distantPast
        }

        var removed: [URL] = []
        let target = sizeLimit / 2
        while totalSize > target, let meta = metas.popLast() {
            totalSize -= UInt(meta.size)
            try removeFile(at: meta.url)
            removed.append(meta.url)
        }
        return removed
    }
}

extension DiskStorage {

    /// 获取 `key` 对应的文件完整路径。
    func fileURL(forKey key: String) -> URL {
        let filedirName = key
        let url = directoryURL.appendingPathComponent(filedirName)
        return url
    }
    
    /// 如果 `directoryURL` 不存在则创建。
    fileprivate func touchDirectory() throws {
        let path = directoryURL.path
        guard !fileManager.fileExists(atPath: path) else { return }
        do {
            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw CacheError.notFound
        }
    }

    /// `directoryURL` 的文件 URL 数组。
    func allFileURLs(for propertyKeys: [URLResourceKey]) throws -> [URL] {

        guard let directoryEnumerator = fileManager.enumerator(
            at: directoryURL, includingPropertiesForKeys: propertyKeys, options: .skipsHiddenFiles) else
        {
            throw CacheError.notFound
        }

        guard let urls = directoryEnumerator.allObjects as? [URL] else {
            throw CacheError.notFound
        }
        return urls
    }

    /// `directoryURL` 的文件总大小。
    func totalSize() throws -> UInt {
        let propertyKeys: [URLResourceKey] = [.fileSizeKey]
        let urls = try allFileURLs(for: propertyKeys)
        let totalSize: UInt = urls.reduce(0) { size, fileURL in
            do {
                let meta = try FileMeta(url: fileURL)
                return size + UInt(meta.size)
            } catch {
                return size
            }
        }
        return totalSize
    }
}

/// 文件元数据结构
struct FileMeta {
    
    let url: URL
    let modificationDate: Date?
    let expirationDate: Date?
    let size: Int
    let isDirectory: Bool
    
    init(url: URL) throws {
        let resourceKeys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey, .fileSizeKey, .isDirectoryKey]
        let meta = try url.resourceValues(forKeys: resourceKeys)
        self.init(url: url,
                  modificationDate: meta.creationDate,
                  expirationDate: meta.contentModificationDate,
                  size: meta.fileSize ?? 0,
                  isDirectory: meta.isDirectory ?? false)
    }
    
    init(url: URL, modificationDate: Date?, expirationDate: Date?, size: Int, isDirectory: Bool) {
        self.url = url
        self.modificationDate = modificationDate
        self.expirationDate = expirationDate
        self.size = size
        self.isDirectory = isDirectory
    }
    
    func expired(referenceDate: Date) -> Bool {
        return expirationDate?.isPastDate(referenceDate: referenceDate) ?? true
    }
    
    func extendExpiration() {
        guard let modificationDate = self.modificationDate,
            let expirationDate = self.expirationDate else {
                return
        }
        
        let originalExpiration: Expiration = .seconds(expirationDate.timeIntervalSince(modificationDate))
        
        let now = Date()
        let attributes: [FileAttributeKey : Any] = [
            .creationDate: now,
            .modificationDate: originalExpiration.estimatedExpirationSinceNow
        ]
        
        try? FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
    }
}

