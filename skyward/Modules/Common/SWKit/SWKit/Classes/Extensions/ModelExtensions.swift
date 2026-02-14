//
//  ModelExtensions.swift
//  SWKit
//
//  Created by zhaobo on 2026/1/30.
//  Mirror 反射

import Foundation

/// 模型扩展，提供通用的模型转字典方法
public extension Encodable {
    /// 将模型转换为字典
    /// - Returns: 转换后的字典
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        let mirror = Mirror(reflecting: self)
        
        for case let (label?, value) in mirror.children {
            // 处理可选类型
            if let unwrappedValue = unwrap(value) {
                dict[label] = unwrappedValue
            }
        }
        
        return dict
    }
    
    /// 解包可选类型
    /// - Parameter value: 可能是可选类型的值
    /// - Returns: 解包后的值
    private func unwrap(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle != .optional {
            return value
        }
        
        if mirror.children.isEmpty {
            return nil
        }
        
        for (_, unwrapped) in mirror.children {
            return unwrapped
        }
        
        return nil
    }
}
