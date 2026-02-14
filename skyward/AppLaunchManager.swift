//
//  AppLaunchManager.swift
//  skyward
//
//  Created by TXTS on 2026/1/13.
//

import Foundation
import ModulePersonal
import SWNetwork

// MARK: - 应用启动管理器
class AppLaunchManager {
    static let shared = AppLaunchManager()
    
    // MARK: - 私有属性
    private let firmwareManager = FirmwareManager.shared
    private let firmwareUpdater = DeviceFirmwareUpdater.shared
    
    // MARK: - 启动任务
    func performLaunchTasks() {
        print("应用启动，执行固件管理任务")
        
        // 1. 检查硬件型号是否设置
        let hardwareModel = firmwareManager.getHardwareModel()
        print("当前硬件型号: \(hardwareModel)")
        
        // 2. 检查当前存储版本
        let storedVersion = firmwareManager.getCurrentStoredVersion()
        print("当前存储版本: \(storedVersion)")
        
        // 3. 检查是否有已下载的固件
        if firmwareManager.isFirmwareDownloaded() {
            let firmwareInfo = firmwareManager.getDownloadedFirmware()
            print("已有下载的固件: \(firmwareInfo?.versionName ?? "未知")")
        } else {
            print("没有已下载的固件")
        }
        
        // 4. 静默检查更新（如果有网络）
        silentCheckForUpdates()
    }
    
    // MARK: - 静默检查更新
    private func silentCheckForUpdates() {
        print("开始静默检查更新...")
        
        // 检查网络连接
        if !NetworkMonitor.shared.isConnected {
            print("网络不可用，跳过静默检查")
            return
        }
        
        let hardwareModel = firmwareManager.getHardwareModel()
        
        firmwareUpdater.checkAndDownloadFirmware(hardwareModel: hardwareModel) { success, message in
            if success {
                print("静默检查更新成功: \(message ?? "")")
            } else {
                print("静默检查更新失败: \(message ?? "")")
                if let firmwareInfo = self.firmwareManager.getDownloadedFirmware() {
                    print(firmwareInfo.versionName)
                    print(firmwareInfo.filePath)
                }
            }
        }
    }
    
    // MARK: - 手动检查更新
    func manualCheckForUpdates(completion: @escaping (Bool, String?) -> Void) {
        print("手动检查更新")
        
        if !NetworkMonitor.shared.isConnected {
            completion(false, "网络连接不可用")
            return
        }
        
        let hardwareModel = firmwareManager.getHardwareModel()
        
        firmwareUpdater.checkAndDownloadFirmware(hardwareModel: hardwareModel, completion: completion)
    }
}
