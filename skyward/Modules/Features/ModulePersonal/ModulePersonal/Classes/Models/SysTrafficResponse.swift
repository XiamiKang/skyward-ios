//
//  SysTrafficResponse.swift
//  Pods
//
//  Created by TXTS on 2026/2/10.
//


import Foundation

// MARK: - 系统流量响应模型
struct SysTrafficResponse: Codable {
    let code: String
    let sysTraffic: String
    
    // 解析流量数据为数组
    var trafficValues: [Double] {
        return sysTraffic
            .split(separator: " ")
            .compactMap { Double($0) }
    }
    
    // 接收带宽（num_string[2]）
    var receiveBandwidth: Double {
        guard trafficValues.count >= 3 else { return 0 }
        return trafficValues[2]
    }
    
    // 发送带宽（num_string[3]）
    var transmitBandwidth: Double {
        guard trafficValues.count >= 4 else { return 0 }
        return trafficValues[3]
    }
    
    enum CodingKeys: String, CodingKey {
        case code
        case sysTraffic = "sysTraffic"
    }
}

// MARK: - 带宽单位枚举
enum BandwidthUnit: String {
    case bytesPerSecond = "B/s"
    case kilobytesPerSecond = "KB/s"
    case megabytesPerSecond = "MB/s"
    
    var description: String {
        return self.rawValue
    }
}

// MARK: - 格式化带宽数据
struct FormattedBandwidth {
    let value: Double
    let unit: BandwidthUnit
    
    var displayString: String {
        return String(format: "%.2f %@", value, unit.description)
    }
    
    // 根据字节数格式化
    static func format(bytes: Double) -> FormattedBandwidth {
        let kb = bytes / 1024.0
        
        if kb >= 1024 {
            let mb = kb / 1024.0
            return FormattedBandwidth(value: mb, unit: .megabytesPerSecond)
        } else if kb >= 1 {
            return FormattedBandwidth(value: kb, unit: .kilobytesPerSecond)
        } else {
            return FormattedBandwidth(value: bytes, unit: .bytesPerSecond)
        }
    }
}
