//
//  WiFiManager.swift
//  22222
//
//  Created by TXTS on 2025/12/25.
//

import SystemConfiguration.CaptiveNetwork
import Foundation

class WiFiManager {
    
    /// 获取当前连接的 WiFi 名称（SSID）
    static func getCurrentSSID() -> String? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        
        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else {
                continue
            }
            
            if let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String {
                return ssid
            }
        }
        
        return nil
    }
    
    /// 获取 WiFi 详细信息（包括 BSSID、SSID 等）
    static func getCurrentWiFiInfo() -> [String: Any]? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            return nil
        }
        
        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else {
                continue
            }
            
            return interfaceInfo
        }
        
        return nil
    }
    
    /// 获取 SSID 和 BSSID
    static func getSSIDAndBSSID() -> (ssid: String?, bssid: String?) {
        guard let info = getCurrentWiFiInfo() else {
            return (nil, nil)
        }
        
        let ssid = info[kCNNetworkInfoKeySSID as String] as? String
        let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String
        
        return (ssid, bssid)
    }
}
