//
//  String+Extensions.swift
//  TXKit
//
//  Created by TXTS on 2026/1/12.
//

import Foundation

extension String {
    public func compareVersion(_ other: String) -> ComparisonResult {
        let v1 = self.split(separator: ".").map { Int($0) ?? 0 }
        let v2 = other.split(separator: ".").map { Int($0) ?? 0 }
        
        let maxLength = max(v1.count, v2.count)
        
        for i in 0..<maxLength {
            let num1 = i < v1.count ? v1[i] : 0
            let num2 = i < v2.count ? v2[i] : 0
            
            if num1 < num2 {
                return .orderedAscending
            } else if num1 > num2 {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
    
    public func dataFromHexString() -> Data {
        var hex = self
        var data = Data()
        
        while hex.count > 0 {
            let index = hex.index(hex.startIndex, offsetBy: 2)
            let byteString = String(hex[..<index])
            hex = String(hex[index...])
            
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            }
        }
        return data
    }
}
