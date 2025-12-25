//
//  WiFiDeviceModel.swift
//  SWKit
//
//  Created by TXTS on 2025/12/25.
//

import Foundation

// MARK: - 错误枚举
public enum WiFiDeviceError: Error, LocalizedError {
    case connectionFailed
    case timeout
    case invalidResponse
    case commandFailed(String)
    case disconnected
    case networkError(String)
    case invalidCommand
    case deviceBusy
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "连接设备失败"
        case .timeout:
            return "操作超时"
        case .invalidResponse:
            return "设备返回无效响应"
        case .commandFailed(let reason):
            return "命令执行失败: \(reason)"
        case .disconnected:
            return "设备未连接"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidCommand:
            return "无效命令格式"
        case .deviceBusy:
            return "设备繁忙，请稍后再试"
        }
    }
}


// MARK: - 天线锁定状态
public enum LockStatus: Int {
    case unlocked = 0
    case locked = 1
    
    public var description: String {
        return self == .locked ? "已锁定" : "未锁定"
    }
}

// MARK: - 天线运行状态
public enum AntennaStatus: Int {
    case stored = 1
    case waitingGPS = 2
    case waitingIMU = 4
    case searching = 8
    case stableTracking = 10
    
    public var description: String {
        switch self {
        case .stored: return "收藏"
        case .waitingGPS: return "等待GPS定位"
        case .waitingIMU: return "等待惯导信息"
        case .searching: return "搜索寻星"
        case .stableTracking: return "稳定跟踪"
        }
    }
    
    public var contentText: String {
        switch self {
        case .stored: return "设备处于非工作状态，天线收藏中..."
        case .waitingGPS: return "正在获取设备当前地理位置信息..."
        case .waitingIMU: return "正在获取设备姿态数据..."
        case .searching: return "正在主动扫描天空，尝试锁定目标卫星信号..."
        case .stableTracking: return "信号已成功锁定，连接稳定，Wi-Fi可以正常使用"
        }
    }
}

// MARK: - 故障码结构
public struct FaultCodes {
    public let imu: Int
    public let beidou: Int
    public let beacon: Int
    public let lnb: Int
    public let buc: Int
    
    public init(codes: [Int]) {
        self.imu = codes.count > 0 ? codes[0] : 0
        self.beidou = codes.count > 1 ? codes[1] : 0
        self.beacon = codes.count > 2 ? codes[2] : 0
        self.lnb = codes.count > 3 ? codes[3] : 0
        self.buc = codes.count > 4 ? codes[4] : 0
    }
    
    public var description: String {
        var issues: [String] = []
        if imu == 1 { issues.append("惯导通信异常") }
        if beidou == 1 { issues.append("北斗通信异常") }
        if beacon == 1 { issues.append("信标机通信异常") }
        if lnb == 1 { issues.append("LNB通信异常") }
        if buc == 1 { issues.append("BUC通信异常") }
        return issues.isEmpty ? "设备正常" : issues.joined(separator: ", ")
    }
    
    public var isNormal: Bool {
        return imu == 0 && beidou == 0 && beacon == 0 && lnb == 0 && buc == 0
    }
}

// MARK: - 设备信息
public struct ProDeviceInfo {
    public let ACUVersion: String
    public let deviceSN: String
    public let catMAC: String
    public let catSN: String
    
    public init?(from response: String) {
        let components = response.components(separatedBy: ",")
        guard components.count >= 4 else { return nil }
        
        self.ACUVersion = components[0]
        self.deviceSN = components[1]
        self.catMAC = components[2]
        self.catSN = components[3]
    }
}

// MARK: - 设备状态信息
public struct ProDeviceStatus: CustomStringConvertible {
    public let lockStatus: LockStatus
    public let antennaStatus: AntennaStatus
    public let azimuth: Double
    public let elevation: Double
    public let altitude: Double
    public let longitude: Double
    public let latitude: Double
    public let powerSavingMode: Bool
    public let logStreaming: Bool
    public let mode: Int // 0:地面, 1:车载
    
    public init(lockStatus: LockStatus, antennaStatus: AntennaStatus, azimuth: Double,
                elevation: Double, altitude: Double, longitude: Double, latitude: Double, powerSavingMode: Bool, logStreaming: Bool, mode: Int) {
        self.lockStatus = lockStatus
        self.antennaStatus = antennaStatus
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
        self.powerSavingMode = powerSavingMode
        self.logStreaming = logStreaming
        self.mode = mode
    }
    
    public init?(from response: String) {
        let components = response.components(separatedBy: ",")
        
        // REQLOC格式: 锁定状态,天线状态,方位角,俯仰角,海拔,经度,纬度,低功耗状态,日志状态,模式
        guard components.count >= 10,
              let lockStatusValue = Int(components[0]),
              let antennaStatusValue = Int(components[1]),
              let azimuth = Double(components[2]),
              let elevation = Double(components[3]),
              let altitude = Double(components[4]),
              let longitude = Double(components[5]),
              let latitude = Double(components[6]),
              let powerSaving = Int(components[7]),
              let logStreaming = Int(components[8]),
              let mode = Int(components[9]) else {
            return nil
        }
        
        self.lockStatus = LockStatus(rawValue: lockStatusValue) ?? .unlocked
        self.antennaStatus = AntennaStatus(rawValue: antennaStatusValue) ?? .stored
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
        self.powerSavingMode = powerSaving == 1
        self.logStreaming = logStreaming == 1
        self.mode = mode
    }
    
    public init?(from oldStatus: OldProDeviceStatus) {
        self.lockStatus = oldStatus.lockStatus
        self.antennaStatus = oldStatus.antennaStatus
        self.azimuth = oldStatus.azimuth
        self.elevation = oldStatus.elevation
        self.altitude = oldStatus.altitude
        self.longitude = oldStatus.longitude
        self.latitude = oldStatus.latitude
        self.powerSavingMode = false
        self.logStreaming = false
        self.mode = 1
    }
    
    public var description: String {
        return """
        锁定状态: \(lockStatus.description)
        天线状态: \(antennaStatus.description)
        方位角: \(String(format: "%.2f", azimuth))°
        俯仰角: \(String(format: "%.2f", elevation))°
        海拔: \(String(format: "%.2f", altitude))m
        经度: \(String(format: "%.6f", longitude))
        纬度: \(String(format: "%.6f", latitude))
        低功耗: \(powerSavingMode ? "开启" : "关闭")
        日志流: \(logStreaming ? "开启" : "关闭")
        模式: \(mode == 1 ? "车载" : "地面")
        """
    }
}

public struct OldProDeviceStatus: CustomStringConvertible {
    public let lockStatus: LockStatus
    public let antennaStatus: AntennaStatus
    public let azimuth: Double
    public let elevation: Double
    public let altitude: Double
    public let longitude: Double
    public let latitude: Double
    
    public init(lockStatus: LockStatus, antennaStatus: AntennaStatus, azimuth: Double,
                elevation: Double, altitude: Double, longitude: Double, latitude: Double) {
        self.lockStatus = lockStatus
        self.antennaStatus = antennaStatus
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
    }
    
    init?(from response: String) {
        let components = response.components(separatedBy: ",")
        
        // REQLOC格式: 锁定状态,天线状态,方位角,俯仰角,海拔,经度,纬度,低功耗状态,日志状态,模式
        guard components.count >= 10,
              let lockStatusValue = Int(components[0]),
              let antennaStatusValue = Int(components[1]),
              let azimuth = Double(components[2]),
              let elevation = Double(components[3]),
              let altitude = Double(components[4]),
              let longitude = Double(components[5]),
              let latitude = Double(components[6]) else {
            return nil
        }
        
        self.lockStatus = LockStatus(rawValue: lockStatusValue) ?? .unlocked
        self.antennaStatus = AntennaStatus(rawValue: antennaStatusValue) ?? .stored
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
    }
    
    public var description: String {
        return """
        锁定状态: \(lockStatus.description)
        天线状态: \(antennaStatus.description)
        方位角: \(String(format: "%.2f", azimuth))°
        俯仰角: \(String(format: "%.2f", elevation))°
        海拔: \(String(format: "%.2f", altitude))m
        经度: \(String(format: "%.6f", longitude))
        纬度: \(String(format: "%.6f", latitude))
        """
    }
}

// MARK: - 环境信息
public struct EnvironmentInfo {
    public let temperature: Double
    public let humidity: Double
    
    public init?(from response: String) {
        let components = response.components(separatedBy: ",")
        guard components.count >= 2,
              let temperature = Double(components[0]),
              let humidity = Double(components[1]) else {
            return nil
        }
        
        self.temperature = temperature
        self.humidity = humidity
    }
}

// MARK: - 对星结果
public struct SatelliteAlignmentResult {
    public let lockStatus: LockStatus
    public let antennaStatus: AntennaStatus
    public let azimuth: Double
    public let elevation: Double
    public let altitude: Double
    public let longitude: Double
    public let latitude: Double
    
    public init?(from response: String) {
        // 支持 AUTOSATALI 和 HAFSATALI 两种格式
        var responseToParse = response
        if response.hasPrefix("AUTOSATALI,") {
            responseToParse = response.replacingOccurrences(of: "AUTOSATALI,", with: "")
        } else if response.hasPrefix("HAFSATALI,") {
            responseToParse = response.replacingOccurrences(of: "HAFSATALI,", with: "")
        }
        
        let components = responseToParse.components(separatedBy: ",")
        guard components.count >= 7,
              let lockStatusValue = Int(components[0]),
              let antennaStatusValue = Int(components[1]),
              let azimuth = Double(components[2]),
              let elevation = Double(components[3]),
              let altitude = Double(components[4]),
              let longitude = Double(components[5]),
              let latitude = Double(components[6]) else {
            return nil
        }
        
        self.lockStatus = LockStatus(rawValue: lockStatusValue) ?? .unlocked
        self.antennaStatus = AntennaStatus(rawValue: antennaStatusValue) ?? .stored
        self.azimuth = azimuth
        self.elevation = elevation
        self.altitude = altitude
        self.longitude = longitude
        self.latitude = latitude
    }
}
