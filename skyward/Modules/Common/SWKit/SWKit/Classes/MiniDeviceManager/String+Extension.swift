//
//  String+Extension.swift
//  test11
//
//  Created by yifan kang on 2025/11/12.
//

import Foundation

extension String {
    func dataFromHexString() -> Data {
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
