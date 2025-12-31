//
//  Flexible.swift
//  SWKit
//
//  Created by zhaobo on 2025/12/31.
//

import Foundation
import WCDBSwift

public protocol FlexibleDecodable {
    static func decode(from container: SingleValueDecodingContainer) throws -> Self
}

extension Int: FlexibleDecodable {
    public static func decode(from container: SingleValueDecodingContainer) throws -> Int {
        if let intValue = try? container.decode(Int.self) {
            return intValue
        } else if let stringValue = try? container.decode(String.self),
                  let intValue = Int(stringValue) {
            return intValue
        }
        throw DecodingError.typeMismatch(
            Int.self,
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "无法转换为Int"
            )
        )
    }
}

extension Int64: FlexibleDecodable {
    public static func decode(from container: SingleValueDecodingContainer) throws -> Int64 {
        if let int64Value = try? container.decode(Int64.self) {
            return int64Value
        } else if let stringValue = try? container.decode(String.self),
                  let int64Value = Int64(stringValue) {
            return int64Value
        }
        throw DecodingError.typeMismatch(
            Int64.self,
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "无法转换为Int64"
            )
        )
    }
}

extension Double: FlexibleDecodable {
    public static func decode(from container: SingleValueDecodingContainer) throws -> Double {
        if let doubleValue = try? container.decode(Double.self) {
            return doubleValue
        } else if let stringValue = try? container.decode(String.self),
                  let doubleValue = Double(stringValue) {
            return doubleValue
        }
        throw DecodingError.typeMismatch(
            Double.self,
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "无法转换为Double"
            )
        )
    }
}

extension String: FlexibleDecodable {
    public static func decode(from container: SingleValueDecodingContainer) throws -> String {
        if let stringValue = try? container.decode(String.self) {
            return stringValue
        } else if let intValue = try? container.decode(Int.self) {
            return String(intValue)
        } else if let int64Value = try? container.decode(Int64.self) {
            return String(int64Value)
        } else if let doubleValue = try? container.decode(Double.self) {
            // 处理超大数字，保留完整精度
            return String(format: "%.0f", doubleValue)
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "无法转换为String"
            )
        )
    }
}

// 为可选类型添加FlexibleDecodable支持
extension Optional: FlexibleDecodable where Wrapped: FlexibleDecodable {
    public static func decode(from container: SingleValueDecodingContainer) throws -> Wrapped? {
        // 尝试解码为nil（如果容器表示null）
        if container.decodeNil() {
            return nil
        }
        // 尝试解码为Wrapped类型
        return try Wrapped.decode(from: container)
    }
}

@propertyWrapper
public struct Flexible<T: Codable & FlexibleDecodable>: Codable, ColumnCodable {
    public var wrappedValue: T
    
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try T.decode(from: container)
    }
    
    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
    
    // MARK: - ColumnCodable 协议实现
    public static var columnType: WCDBSwift.ColumnType {
        return .text
    }
    
    public init?(with value: WCDBSwift.Value) {
        // 处理String?类型
        if T.self == Optional<String>.self {
            let stringValue = value.stringValue
            self.wrappedValue = (stringValue.isEmpty ? nil : stringValue) as! T
            return
        }
        
        // 处理String类型
        if T.self == String.self {
            self.wrappedValue = value.stringValue as! T
            return
        }
        
        // 尝试从JSON字符串解码
        let stringValue = value.stringValue
        if !stringValue.isEmpty,
           let data = stringValue.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                self.wrappedValue = try decoder.decode(T.self, from: data)
                return
            } catch {
                // JSON解码失败，尝试直接类型转换
            }
        }
        
        return nil
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        // 处理String?类型
        if let optionalString = wrappedValue as? String? {
            return FundamentalValue(optionalString ?? "")
        }
        
        // 处理String类型
        if let stringValue = wrappedValue as? String {
            return FundamentalValue(stringValue)
        }
        
        // 将wrappedValue编码为JSON字符串存储
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(wrappedValue)
            if let jsonString = String(data: data, encoding: .utf8) {
                return FundamentalValue(jsonString)
            }
        } catch {
            // 编码失败
        }
        
        // 默认返回空字符串
        return FundamentalValue("")
    }
}
