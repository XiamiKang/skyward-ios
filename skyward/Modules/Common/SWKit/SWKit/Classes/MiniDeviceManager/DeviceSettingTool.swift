//
//  File.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/20.
//

import Foundation

// 工作模式工具类
public class WorkModeHelper {
    public static func modeString(from value: UInt8) -> String {
        switch value {
        case 0: return "待机模式"
        case 1: return "工作模式"
        default: return "未知模式"
        }
    }
    
    public static func modeValue(from string: String) -> UInt8 {
        switch string {
        case "待机模式": return 0
        case "工作模式": return 1
        default: return 1
        }
    }
}

// 设备参数更新频率工具类
public class StatusReportFreqHelper {
    public static func freqString(from seconds: UInt8) -> String {
        switch seconds {
        case 0: return "查询上报"
        case 60: return "密集模式（1分钟）"
        case 120: return "常规模式（2分钟）"
        case 240: return "节能模式（4分钟）"
        default:
            if seconds < 60 {
                return "\(seconds)秒"
            } else {
                let minutes = seconds / 60
                return "\(minutes)分钟"
            }
        }
    }
    
    public static func freqValue(from string: String) -> UInt8 {
        switch string {
        case "查询上报": return 0
        case "密集模式（1分钟）": return 60
        case "常规模式（2分钟）": return 120
        case "节能模式（4分钟）": return 240
        default:
            // 处理自定义分钟数
            if string.hasSuffix("分钟") {
                let minuteString = string.replacingOccurrences(of: "分钟", with: "")
                if let minutes = UInt8(minuteString) {
                    return minutes * 60
                }
            }
            return 120 // 默认返回常规模式
        }
    }
    
    public static var allOptions: [String] {
        return ["查询上报", "密集模式（1分钟）", "常规模式（2分钟）", "节能模式（4分钟）"]
    }
    
    // 新增：验证传入的值是否在标准选项中
    static func isStandardOption(_ seconds: UInt8) -> Bool {
        return seconds == 0 || seconds == 60 || seconds == 120 || seconds == 240
    }
}

// 位置报告频率工具类
public class PositionReportHelper {
    public static func reportString(from value: UInt32) -> String {
        switch value {
        case 0: return "不上报"
        case 900: return "15分钟"
        case 1800: return "30分钟"
        case 3600: return "1小时"
        case 7200: return "2小时"
        default:
            let minutes = value / 60
            return minutes >= 60 ? "\(minutes/60)小时" : "\(minutes)分钟"
        }
    }
    
    public static func reportValue(from string: String) -> UInt32 {
        switch string {
        case "不上报": return 0
        case "15分钟": return 900
        case "30分钟": return 1800
        case "1小时": return 3600
        case "2小时": return 7200
        default: return 1800
        }
    }
    
    public static var allOptions: [String] {
        return ["不上报", "15分钟", "30分钟", "1小时", "2小时"]
    }
}

// 定位信息存储时间
public class SavePointTimeHelper {
    public static func reportString(from value: UInt32) -> String {
        switch value {
        case 600: return "10分钟"
        case 1200: return "20分钟"
        case 1800: return "30分钟"
        default:
            return "30分钟"
        }
    }
    
    public static func reportValue(from string: String) -> UInt32 {
        switch string {
        case "10分钟": return 600
        case "20分钟": return 1200
        case "30分钟": return 1800
        default: return 1800
        }
    }
    
    public static var allOptions: [String] {
        return ["10分钟", "20分钟", "30分钟"]
    }
}

// 时间转换工具类
public class TimeHelper {
    public static func secondsToMinutesString(_ seconds: UInt32) -> String {
        let minutes = seconds / 60
        if minutes == 0 {
            return "\(seconds)秒" // 如果小于1分钟，显示秒
        } else if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(remainingMinutes)分钟"
            }
        }
    }
    
    // 专门用于低功耗唤醒时间和定位存储时间的显示
    public static func formatFixedTime(_ seconds: UInt32) -> String {
        let minutes = seconds / 60
        return "\(minutes)分钟"
    }
}
