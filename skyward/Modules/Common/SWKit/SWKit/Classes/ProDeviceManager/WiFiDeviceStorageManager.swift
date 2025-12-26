//
//  DeviceStorageManager.swift
//  Pods
//
//  Created by TXTS on 2025/12/11.
//

import Foundation

// MARK: - 简化设备模型
public struct WiFiDevice: Codable {
    public let identifier: String          // 唯一标识（BSSID）
    public var nickname: String            // 昵称（格式：行者Pro_后5位）
    public var isConnected: Bool           // 是否在连接
    public var isTrackingSatellite: Bool   // 是否对星成功
    public var lastUpdateTime: Date        // 最后更新时间
    public var host: String                // IP地址（可选，用于重连）
    public var port: UInt16                // 端口（可选，用于重连）
    
    // 自动生成昵称
    static func generateNickname(for identifier: String) -> String {
        let suffix = identifier.suffix(3)  // 取后5位
        return "行者Pro_\(suffix)"
    }
    
    // 简化初始化
    public init(identifier: String, host: String = "", port: UInt16 = 0) {
        self.identifier = identifier
        self.nickname = WiFiDevice.generateNickname(for: identifier)
        self.isConnected = false
        self.isTrackingSatellite = false
        self.lastUpdateTime = Date()
        self.host = host
        self.port = port
    }
    
    // 更新状态
    public mutating func updateStatus(isConnected: Bool? = nil,
                                     isTrackingSatellite: Bool? = nil,
                                     host: String? = nil,
                                     port: UInt16? = nil) {
        if let isConnected = isConnected {
            self.isConnected = isConnected
        }
        if let isTrackingSatellite = isTrackingSatellite {
            self.isTrackingSatellite = isTrackingSatellite
        }
        if let host = host {
            self.host = host
        }
        if let port = port {
            self.port = port
        }
        self.lastUpdateTime = Date()
    }
}

// MARK: - 设备存储管理器
public class WiFiDeviceStorageManager {
    
    public static let shared = WiFiDeviceStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let devicesKey = "storedWiFiDevices"
    
    private var devices: [String: WiFiDevice] = [:] {
        didSet {
            saveToStorage()
        }
    }
    
    // 用于线程安全的队列
    private let accessQueue = DispatchQueue(label: "DeviceStorageManager.accessQueue", attributes: .concurrent)
    
    // MARK: - 初始化
    private init() {
        loadFromStorage()
    }
    
    // MARK: - 公共方法
    
    /// 保存或更新设备
    public func saveDevice(_ device: WiFiDevice) {
        accessQueue.async(flags: .barrier) {
            self.devices[device.identifier] = device
        }
    }
    
    /// 根据标识获取设备
    public func getDevice(identifier: String) -> WiFiDevice? {
        return accessQueue.sync {
            return self.devices[identifier]
        }
    }
    
    /// 获取所有设备（按最后更新时间排序）
    public func getAllDevices() -> [WiFiDevice] {
        return accessQueue.sync {
            return Array(self.devices.values)
                .sorted { $0.lastUpdateTime > $1.lastUpdateTime }
        }
    }
    
    /// 更新设备状态
    public func updateDeviceStatus(identifier: String, 
                                  isConnected: Bool? = nil,
                                  isTrackingSatellite: Bool? = nil) {
        accessQueue.async(flags: .barrier) {
            guard var device = self.devices[identifier] else {
                // 如果没有找到设备，创建一个新的
                var newDevice = WiFiDevice(identifier: identifier)
                if let isConnected = isConnected {
                    newDevice.isConnected = isConnected
                }
                if let isTrackingSatellite = isTrackingSatellite {
                    newDevice.isTrackingSatellite = isTrackingSatellite
                }
                self.devices[identifier] = newDevice
                return
            }
            
            if let isConnected = isConnected {
                device.isConnected = isConnected
            }
            if let isTrackingSatellite = isTrackingSatellite {
                device.isTrackingSatellite = isTrackingSatellite
            }
            device.lastUpdateTime = Date()
            
            self.devices[identifier] = device
        }
    }
    
    /// 更新设备连接信息（IP和端口）
    public func updateConnectionInfo(identifier: String, host: String, port: UInt16) {
        accessQueue.async(flags: .barrier) {
            if var device = self.devices[identifier] {
                device.host = host
                device.port = port
                device.lastUpdateTime = Date()
                self.devices[identifier] = device
            } else {
                // 创建新设备记录
                let device = WiFiDevice(identifier: identifier, host: host, port: port)
                self.devices[identifier] = device
            }
        }
    }
    
    /// 删除设备
    public func removeDevice(identifier: String) {
        accessQueue.async(flags: .barrier) {
            self.devices.removeValue(forKey: identifier)
        }
    }
    
    /// 清除所有设备
    public func clearAllDevices() {
        accessQueue.async(flags: .barrier) {
            self.devices.removeAll()
        }
    }
    
    /// 获取当前连接的设备
    public func getConnectedDevice() -> WiFiDevice? {
        return accessQueue.sync {
            return self.devices.values.first { $0.isConnected }
        }
    }
    
    /// 获取正在对星的设备
    public func getTrackingDevices() -> [WiFiDevice] {
        return accessQueue.sync {
            return self.devices.values.filter { $0.isTrackingSatellite }
        }
    }
    
    // MARK: - 存储管理
    
    private func saveToStorage() {
        accessQueue.async(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(self.devices)
                self.userDefaults.set(data, forKey: self.devicesKey)
            } catch {
                print("保存设备数据失败: \(error)")
            }
        }
    }
    
    private func loadFromStorage() {
        accessQueue.async(flags: .barrier) {
            guard let data = self.userDefaults.data(forKey: self.devicesKey) else {
                self.devices = [:]
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                self.devices = try decoder.decode([String: WiFiDevice].self, from: data)
            } catch {
                print("加载设备数据失败: \(error)")
                self.devices = [:]
            }
        }
    }
    
    // MARK: - 调试方法
    
    public func printAllDevices() {
        let allDevices = getAllDevices()
        print("=== 存储的设备列表 ===")
        if allDevices.isEmpty {
            print("没有存储任何设备")
        } else {
            for (index, device) in allDevices.enumerated() {
                print("设备 \(index + 1):")
                print("  标识: \(device.identifier)")
                print("  昵称: \(device.nickname)")
                print("  连接状态: \(device.isConnected ? "已连接" : "未连接")")
                print("  对星状态: \(device.isTrackingSatellite ? "对星中" : "未对星")")
                print("  最后更新: \(device.lastUpdateTime)")
                if !device.host.isEmpty {
                    print("  IP: \(device.host):\(device.port)")
                }
                print("---")
            }
        }
        print("===================")
    }
}
