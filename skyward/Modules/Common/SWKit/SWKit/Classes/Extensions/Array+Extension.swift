//
//  Array+Extension.swift
//  SWKit
//
//  Created by TXTS on 2025/12/15.
//

import Foundation

// MARK: - 数组分块扩展
extension Array {
    /// 将数组分块成指定大小的子数组
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
