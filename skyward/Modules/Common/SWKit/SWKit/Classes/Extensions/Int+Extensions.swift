//
//  Int+Extensions.swift
//  SWKit
//
//  Created by zhaobo on 2026/2/4.
//

import Foundation

public extension Int {
    
    /// 格式化时长（秒）为 HH:mm:ss 或 mm:ss 格式
    func formatHMSDuration() -> String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
