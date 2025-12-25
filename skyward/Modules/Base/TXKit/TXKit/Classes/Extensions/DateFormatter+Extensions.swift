//
//  DateFormatter+Extensions.swift
//
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024 Longfor. All rights reserved.
//

import Foundation

extension DateFormatter {
    
    public convenience init(format: String) {
        self.init()
//        self.locale = Locale(identifier: "zh_CN")
        self.timeZone = TimeZone.current
        self.dateFormat = format
    }
    
    // common
    static public let fullPretty = DateFormatter(format: "yyyy-MM-dd HH:mm:ss")
    static public let fullPretty1 = DateFormatter(format: "yyyy/MM/dd HH:mm:ss")
    static public let yearMonthDay = DateFormatter(format: "yyyy-MM-dd")
    static public let monthDay = DateFormatter(format: "MM-dd")
    
    // zh
    static public let zhFullPretty = DateFormatter(format: "yyyy年MM月dd HH:mm:ss")
    static public let zhYearMonthDay = DateFormatter(format: "yyyy年MM年dd")
    static public let zhMonthDay = DateFormatter(format: "MM月dd日")
}
