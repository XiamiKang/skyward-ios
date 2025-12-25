//
//  DataConvertible.swift
//  Pods-TXCacheKit_Example
//
//  Created by 赵波 on 2025/11/14.
//

import Foundation

public protocol DataConvertible {
    var dataValue: Data? { get }
    static func fromData(_ data: Data) throws -> Self
    static var empty: Self { get }
}

extension String: DataConvertible {
    public var dataValue: Data? {
        return self.data(using: .utf8)
    }

    public static func fromData(_ data: Data) throws -> String {
        return String(data: data, encoding: .utf8)!
    }

    public static var empty: String {
        return ""
    }
}

extension Array: DataConvertible {
    public var dataValue: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }

    public static func fromData(_ data: Data) throws -> Array<Element> {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? Array<Element> ?? []
        } catch {
            throw CacheError.notFound
        }
    }

    public static var empty: Array<Element> {
        return []
    }
}

extension Dictionary: DataConvertible {
    public var dataValue: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }

    public static func fromData(_ data: Data) throws -> Dictionary<Key, Value> {
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<Key, Value> ?? [:]
        } catch {
            throw CacheError.notFound
        }
    }

    public static var empty: Dictionary<Key, Value> {
        return [:]
    }
}

extension Data: DataConvertible {
    public var dataValue: Data? {
        return self
    }
    
    public static func fromData(_ data: Data) throws -> Data {
        return data
    }
    
    public static var empty: Data {
        return Data()
    }
}
