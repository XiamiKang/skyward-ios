//
//  Date+CacheX.swift
//  Pods-TXCacheKit_Example
//
//  Created by 赵波 on 2025/11/14.
//

import Foundation

extension Date {

    var isPastDate: Bool {
        return isPastDate(referenceDate: Date())
    }

    var isFutureDate: Bool {
        return !isPastDate
    }

    func isPastDate(referenceDate: Date) -> Bool {
        return timeIntervalSince(referenceDate) <= 0
    }

    func isFutureDate(referenceDate: Date) -> Bool {
        return !isPastDate(referenceDate: referenceDate)
    }
    
}
