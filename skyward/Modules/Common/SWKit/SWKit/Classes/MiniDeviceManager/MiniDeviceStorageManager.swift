//
//  DeviceStorageManager.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/19.
//

import Foundation

public class MiniDeviceStorageManager {
    
    public static let shared = MiniDeviceStorageManager()
    
    public let savedDevicesKey = "SavedBluetoothDevices"
    public let connectedDeviceKey = "LastConnectedDevice"
    
    public init() {}
    
    // MARK: - 保存连接的设备
    public func saveConnectedDevice(_ deviceInfo: BluetoothDeviceInfo) {
        var savedDevices = getAllSavedDevices()
        
        // 移除重复的设备（基于 UUID）
        savedDevices.removeAll { $0.uuid == deviceInfo.uuid }
        
        // 更新最后连接时间
        var updatedDeviceInfo = deviceInfo
        updatedDeviceInfo.lastConnectedDate = Date()
        
        // 添加到列表
        savedDevices.append(updatedDeviceInfo)
        
        // 保存到 UserDefaults
        if let encoded = try? JSONEncoder().encode(savedDevices) {
            UserDefaults.standard.set(encoded, forKey: savedDevicesKey)
        }
        
        // 同时保存为最后连接的设备
        saveLastConnectedDevice(deviceInfo)
        
        print("✅ 设备信息已保存: \(deviceInfo.displayName) - IMEI: \(deviceInfo.imei)")
    }
    
    // MARK: - 获取所有保存的设备
    public func getAllSavedDevices() -> [BluetoothDeviceInfo] {
        guard let data = UserDefaults.standard.data(forKey: savedDevicesKey),
              let devices = try? JSONDecoder().decode([BluetoothDeviceInfo].self, from: data) else {
            return []
        }
        
        // 按最后连接时间排序
        return devices.sorted { $0.lastConnectedDate > $1.lastConnectedDate }
    }
    
    // MARK: - 根据 UUID 查找设备
    public func findDeviceByUUID(_ uuid: String) -> BluetoothDeviceInfo? {
        let devices = getAllSavedDevices()
        return devices.first { $0.uuid == uuid }
    }
    
    // MARK: - 根据 IMEI 查找设备
    public func findDeviceByIMEI(_ imei: String) -> BluetoothDeviceInfo? {
        let devices = getAllSavedDevices()
        return devices.first { $0.imei == imei }
    }
    
    // MARK: - 删除设备
    public func removeDevice(_ uuid: String) {
        var devices = getAllSavedDevices()
        devices.removeAll { $0.uuid == uuid }
        
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: savedDevicesKey)
        }
        
        // 如果删除的是最后连接的设备，也清除最后连接记录
        if let lastConnected = getLastConnectedDevice(), lastConnected.uuid == uuid {
            removeLastConnectedDevice()
        }
    }
    
    // MARK: - 最后连接的设备管理
    public func saveLastConnectedDevice(_ deviceInfo: BluetoothDeviceInfo) {
        if let encoded = try? JSONEncoder().encode(deviceInfo) {
            UserDefaults.standard.set(encoded, forKey: connectedDeviceKey)
        }
    }
    
    public func getLastConnectedDevice() -> BluetoothDeviceInfo? {
        guard let data = UserDefaults.standard.data(forKey: connectedDeviceKey),
              let device = try? JSONDecoder().decode(BluetoothDeviceInfo.self, from: data) else {
            return nil
        }
        return device
    }
    
    public func removeLastConnectedDevice() {
        UserDefaults.standard.removeObject(forKey: connectedDeviceKey)
    }
    
    // MARK: - 清空所有设备
    public func clearAllDevices() {
        UserDefaults.standard.removeObject(forKey: savedDevicesKey)
        UserDefaults.standard.removeObject(forKey: connectedDeviceKey)
    }
    
    // MARK: - 检查设备是否存在
    func deviceExists(uuid: String) -> Bool {
        return findDeviceByUUID(uuid) != nil
    }
    
    func deviceExists(imei: String) -> Bool {
        return findDeviceByIMEI(imei) != nil
    }
}
