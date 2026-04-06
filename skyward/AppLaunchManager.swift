//
//  AppLaunchManager.swift
//  skyward
//
//  Created by TXTS on 2026/1/13.
//

//import Foundation
//import ModulePersonal
//import SWNetwork
//import SWKit
//import ModuleMap
//
//// MARK: - 应用启动管理器
//class AppLaunchManager {
//    static let shared = AppLaunchManager()
//    
//    // MARK: - 私有属性
//    private let firmwareManager = FirmwareManager.shared
//    private let firmwareUpdater = DeviceFirmwareUpdater.shared
//    private let poiSyncManager = POISyncManager.shared
//    
//    private let mapViewModel = MapViewModel()
//    
//    // MARK: - 启动任务
//    func performLaunchTasks() {
//        print("应用启动，执行固件管理任务")
//        
//        // 1. 检查正样设备的固件
//        checkBaseFirmware()
//        
//        // 2. 检查初样设备的固件
//        checkPrototypeFirmware()
//        
//        // 3. 检查POI未同步数据
//        checkUnsyncedPOIData()
//        
//        // 4. 静默检查更新（如果有网络）
//        silentCheckForUpdates()
//    }
//    
//    private func checkBaseFirmware() {
//        // 1. 检查硬件型号是否设置
//        let hardwareModel = firmwareManager.getHardwareModel(for: .base)
//        print("当前硬件型号: \(hardwareModel)")
//        
//        // 2. 检查当前存储版本
//        let storedVersion = firmwareManager.getCurrentStoredVersion(for: .base)
//        print("当前存储版本: \(storedVersion)")
//        
//        // 3. 检查是否有已下载的固件
//        if firmwareManager.isFirmwareDownloaded(for: .base) {
//            let firmwareInfo = firmwareManager.getDownloadedFirmware(for: .base)
//            print("已有下载的固件: \(firmwareInfo?.versionName ?? "未知")")
//        } else {
//            print("没有已下载的固件")
//        }
//    }
//    
//    private func checkPrototypeFirmware() {
//        // 1. 检查硬件型号是否设置
//        let hardwareModel = firmwareManager.getHardwareModel(for: .prototype)
//        print("当前硬件型号: \(hardwareModel)")
//        
//        // 2. 检查当前存储版本
//        let storedVersion = firmwareManager.getCurrentStoredVersion(for: .prototype)
//        print("当前存储版本: \(storedVersion)")
//        
//        // 3. 检查是否有已下载的固件
//        if firmwareManager.isFirmwareDownloaded(for: .prototype) {
//            let firmwareInfo = firmwareManager.getDownloadedFirmware(for: .prototype)
//            print("已有下载的固件: \(firmwareInfo?.versionName ?? "未知")")
//        } else {
//            print("没有已下载的固件")
//        }
//    }
//    
//    private func checkWb02Firmware() {
//        // 1. 检查硬件型号是否设置
//        let hardwareModel = firmwareManager.getHardwareModel(for: .wb02)
//        print("当前硬件型号: \(hardwareModel)")
//        
//        // 2. 检查当前存储版本
//        let storedVersion = firmwareManager.getCurrentStoredVersion(for: .wb02)
//        print("当前存储版本: \(storedVersion)")
//        
//        // 3. 检查是否有已下载的固件
//        if firmwareManager.isFirmwareDownloaded(for: .wb02) {
//            let firmwareInfo = firmwareManager.getDownloadedFirmware(for: .wb02)
//            print("已有下载的固件: \(firmwareInfo?.versionName ?? "未知")")
//        } else {
//            print("没有已下载的固件")
//        }
//    }
//    
//    // MARK: - 静默检查更新
//    private func silentCheckForUpdates() {
//        print("开始静默检查更新...")
//        
//        // 检查网络连接
//        if !NetworkMonitor.shared.isConnected {
//            print("网络不可用，跳过静默检查")
//            return
//        }
//        
//        let hardwareModel = firmwareManager.getHardwareModel(for: .base)
//        
//        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .base, hardwareModel: hardwareModel) { success, message in
//            if success {
//                print("静默检查更新成功: \(message ?? "")")
//            } else {
//                print("静默检查更新失败: \(message ?? "")")
//                if let firmwareInfo = self.firmwareManager.getDownloadedFirmware(for: .base) {
//                    print(firmwareInfo.versionName)
//                    print(firmwareInfo.filePath)
//                }
//            }
//        }
//        
//        let prototypeHardwareModel = firmwareManager.getHardwareModel(for: .prototype)
//        
//        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .prototype, hardwareModel: prototypeHardwareModel) { success, message in
//            if success {
//                print("静默检查更新成功: \(message ?? "")")
//            } else {
//                print("静默检查更新失败: \(message ?? "")")
//                if let firmwareInfo = self.firmwareManager.getDownloadedFirmware(for: .prototype) {
//                    print(firmwareInfo.versionName)
//                    print(firmwareInfo.filePath)
//                }
//            }
//        }
//    }
//    
//    // MARK: - 检查未同步POI数据
//    private func checkUnsyncedPOIData() {
//        print("🔍 检查未同步的用户POI数据...")
//        
//        let hasUnsynced = poiSyncManager.checkUnsyncedStatus()
//        let unsyncedCount = poiSyncManager.getUnsyncedCount()
//        
//        if hasUnsynced {
//            print("⚠️ 发现 \(unsyncedCount) 条未同步的POI数据")
//            
//            // 可以在这里决定是否自动同步
//            // 如果网络可用，可以自动同步
//            if NetworkMonitor.shared.isConnected {
//                print("📤 网络可用，开始自动同步POI数据...")
//                syncUnsyncedPOIData()
//            }
//            
//            // 发送通知让UI显示同步提示
//            NotificationCenter.default.post(
//                name: .init("HasUnsyncedPOIData"),
//                object: nil,
//                userInfo: ["count": unsyncedCount]
//            )
//        } else {
//            print("✅ 所有POI数据已同步")
//        }
//    }
//    
//    /// 同步未同步的POI数据
//    private func syncUnsyncedPOIData() {
//        // 获取需要同步的数据
//        let toSave = poiSyncManager.getDataNeedingSync() ?? []
//        let toDelete = poiSyncManager.getDataNeedingDeleteSync() ?? []
//        
//        guard !toSave.isEmpty || !toDelete.isEmpty else {
//            print("📊 没有需要同步的POI数据")
//            return
//        }
//        
//        print("📤 开始同步POI数据 - 新增/更新: \(toSave.count)条, 删除: \(toDelete.count)条")
//        
//        
//    }
//    
//    // MARK: - 手动检查更新
//    func manualCheckForUpdates(completion: @escaping (Bool, String?) -> Void) {
//        print("手动检查更新")
//        
//        if !NetworkMonitor.shared.isConnected {
//            completion(false, "网络连接不可用")
//            return
//        }
//        
//        let hardwareModel = firmwareManager.getHardwareModel(for: .base)
//        
//        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .base, hardwareModel: hardwareModel, completion: completion)
//        
//        let prototypeHardwareModel = firmwareManager.getHardwareModel(for: .prototype)
//        
//        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .prototype, hardwareModel: prototypeHardwareModel, completion: completion)
//    }
//    
//    private func savePOI(poiData: UserPOILocalData) {
//        
//        let poiModel = UserPOIModel(poiId: poiData.poiId ?? "",
//                                    name: poiData.name ?? "",
//                                    description: poiData.description ?? "",
//                                    lon: poiData.lon ?? 00,
//                                    lat: poiData.lat ?? 00,
//                                    category: poiData.category ?? 1,
//                                    imgUrlList: nil,
//                                    state: poiData.isDelected ?? false ? 1 : 0,
//                                    userId: Int(UserManager.shared.userId) ?? 0,
//                                    address: poiData.address ?? nil,
//                                    altitude: "\(poiData.altitude ?? 0))")
//        mapViewModel.saveUserPoi(poiModel)
//            .sink { completion in
//                switch completion {
//                case .finished:
//                    print("操作完成")
//                case .failure(let error):
//                    print("发生错误: \(error.localizedDescription)")
//                }
//            } receiveValue: { data in
//                print("保存结果: \(data)")
//            }
//            .store(in: &mapViewModel.cancellables)
//    }
//}
//
//
//// MARK: - 扩展通知名称
//extension Notification.Name {
//    static let hasUnsyncedPOIData = Notification.Name("HasUnsyncedPOIData")
//    static let syncUnsyncedPOIData = Notification.Name("SyncUnsyncedPOIData")
//    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
//}


//
//  AppLaunchManager.swift
//  skyward
//
//  Created by TXTS on 2026/1/13.
//

import Foundation
import ModulePersonal
import SWNetwork
import SWKit
import ModuleMap

// MARK: - 应用启动管理器
class AppLaunchManager {
    static let shared = AppLaunchManager()
    
    // MARK: - 私有属性
    private let firmwareManager = FirmwareManager.shared
    private let firmwareUpdater = DeviceFirmwareUpdater.shared
    private let poiSyncManager = POISyncManager.shared
    
    private let mapViewModel = MapViewModel()
    
    // MARK: - 启动任务
    func performLaunchTasks() {
        print("🚀 应用启动，执行固件管理任务")
        
        // 1. 检查基础版设备固件（正样）
        checkBaseFirmware()
        
        // 2. 检查样机版设备固件（初样）
        checkPrototypeFirmware()
        
        // 3. 检查自研版设备固件（WB-02）- 双固件
        checkWb02Firmware()
        
        // 4. 检查POI未同步数据
        checkUnsyncedPOIData()
        
        // 5. 静默检查更新（如果有网络）
        silentCheckForUpdates()
    }
    
    // MARK: - 基础版固件检查（正样）
    private func checkBaseFirmware() {
        print("📱 [基础版] 固件检查开始...")
        
        let hardwareModel = firmwareManager.getHardwareModel(for: .base)
        let storedVersion = firmwareManager.getCurrentStoredVersion(for: .base)
        let isDownloaded = firmwareManager.isFirmwareDownloaded(for: .base)
        
        print("  硬件型号: \(hardwareModel)")
        print("  当前版本: \(storedVersion)")
        print("  已下载固件: \(isDownloaded ? "是" : "否")")
        
        if isDownloaded, let firmwareInfo = firmwareManager.getDownloadedFirmware(for: .base) {
            print("  下载版本: \(firmwareInfo.versionName)")
            print("  文件路径: \(firmwareInfo.filePath)")
        }
    }
    
    // MARK: - 样机版固件检查（初样）
    private func checkPrototypeFirmware() {
        print("📱 [样机版] 固件检查开始...")
        
        let hardwareModel = firmwareManager.getHardwareModel(for: .prototype)
        let storedVersion = firmwareManager.getCurrentStoredVersion(for: .prototype)
        let isDownloaded = firmwareManager.isFirmwareDownloaded(for: .prototype)
        
        print("  硬件型号: \(hardwareModel)")
        print("  当前版本: \(storedVersion)")
        print("  已下载固件: \(isDownloaded ? "是" : "否")")
        
        if isDownloaded, let firmwareInfo = firmwareManager.getDownloadedFirmware(for: .prototype) {
            print("  下载版本: \(firmwareInfo.versionName)")
            print("  文件路径: \(firmwareInfo.filePath)")
        }
    }
    
    // MARK: - 自研版固件检查（WB-02 双固件）
    private func checkWb02Firmware() {
        print("📡 [WB-02自研版] 双固件检查开始...")
        
        let hardwareModel = firmwareManager.getHardwareModel(for: .wb02)
        let storedVersion = firmwareManager.getCurrentStoredVersion(for: .wb02)
        
        print("  硬件型号: \(hardwareModel)")
        print("  当前版本: \(storedVersion)")
        
        // 检查数据固件（必存在）
        checkWb02DataFirmware()
        
        // 检查信息固件（可选）
        checkWb02MessageFirmware()
    }
    
    /// 检查 WB-02 数据固件（必存在）
    private func checkWb02DataFirmware() {
        let isDownloaded = firmwareManager.isFirmwareDownloaded(for: .wb02)
        
        print("  📦 [数据固件] 已下载: \(isDownloaded ? "是" : "否")")
        
        if isDownloaded, let firmwareInfo = firmwareManager.getDownloadedFirmware(for: .wb02) {
            print("     版本: \(firmwareInfo.versionName)")
            print("     大小: \(formatFileSize(firmwareInfo.fileSize))")
            print("     路径: \(firmwareInfo.filePath)")
        }
    }
    
    /// 检查 WB-02 信息固件（可选）
    private func checkWb02MessageFirmware() {
        // 注意：信息固件需要单独的方法获取，这里示意
        // 实际可能需要扩展 FirmwareManager 来支持子固件
        
        // 检查是否有信息固件下载记录
        let msgDownloadedKey = "wb02_firmware_msg_downloaded_info"
        if let data = UserDefaults.standard.data(forKey: msgDownloadedKey),
           let msgInfo = try? JSONDecoder().decode(LocalFirmwareInfo.self, from: data) {
            print("  💬 [信息固件] 已下载: 是")
            print("     版本: \(msgInfo.versionName)")
            print("     大小: \(formatFileSize(msgInfo.fileSize))")
        } else {
            print("  💬 [信息固件] 已下载: 否（可选固件，可能不存在）")
        }
    }
    
    // MARK: - 静默检查更新
    private func silentCheckForUpdates() {
        print("🔍 开始静默检查更新...")
        
        guard NetworkMonitor.shared.isConnected else {
            print("❌ 网络不可用，跳过静默检查")
            return
        }
        
        // 检查基础版固件更新
        checkBaseFirmwareUpdate()
        
        // 检查样机版固件更新
        checkPrototypeFirmwareUpdate()
        
        // 检查自研版固件更新（双固件）
        checkWb02FirmwareUpdate()
    }
    
    /// 检查基础版固件更新
    private func checkBaseFirmwareUpdate() {
        let hardwareModel = firmwareManager.getHardwareModel(for: .base)
        
        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .base, hardwareModel: hardwareModel) { [weak self] success, message in
            if success {
                print("✅ [基础版] 静默检查成功: \(message ?? "")")
                if let firmwareInfo = self?.firmwareManager.getDownloadedFirmware(for: .base) {
                    print("   已下载版本: \(firmwareInfo.versionName)")
                }
            } else {
                print("⚠️ [基础版] 静默检查失败: \(message ?? "")")
            }
        }
    }
    
    /// 检查样机版固件更新
    private func checkPrototypeFirmwareUpdate() {
        let hardwareModel = firmwareManager.getHardwareModel(for: .prototype)
        
        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .prototype, hardwareModel: hardwareModel) { [weak self] success, message in
            if success {
                print("✅ [样机版] 静默检查成功: \(message ?? "")")
                if let firmwareInfo = self?.firmwareManager.getDownloadedFirmware(for: .prototype) {
                    print("   已下载版本: \(firmwareInfo.versionName)")
                }
            } else {
                print("⚠️ [样机版] 静默检查失败: \(message ?? "")")
            }
        }
    }
    
    /// 检查自研版固件更新（双固件）
    private func checkWb02FirmwareUpdate() {
        let hardwareModel = firmwareManager.getHardwareModel(for: .wb02)
        
        // 检查数据固件更新（必选）
        checkWb02DataFirmwareUpdate(hardwareModel: hardwareModel)
        
        // 检查信息固件更新（可选）
        checkWb02MessageFirmwareUpdate(hardwareModel: hardwareModel)
    }
    
    /// 检查 WB-02 数据固件更新
    private func checkWb02DataFirmwareUpdate(hardwareModel: String) {
        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .wb02, hardwareModel: hardwareModel) { [weak self] success, message in
            if success {
                print("✅ [WB-02数据固件] 静默检查成功: \(message ?? "")")
                if let firmwareInfo = self?.firmwareManager.getDownloadedFirmware(for: .wb02) {
                    print("   已下载版本: \(firmwareInfo.versionName)")
                }
            } else {
                print("⚠️ [WB-02数据固件] 静默检查失败: \(message ?? "")")
            }
        }
    }
    
    /// 检查 WB-02 信息固件更新（可选固件，失败不影响主流程）
    private func checkWb02MessageFirmwareUpdate(hardwareModel: String) {
        // 信息固件需要单独的接口，这里示意
        // 实际可能需要调用不同的 API 或使用不同的参数
        print("💬 [WB-02信息固件] 开始检查（可选固件）...")
        
        // 示例：如果信息固件有专门的检查方法
        // firmwareUpdater.checkAndDownloadMessageFirmware(hardwareModel: hardwareModel) { success, message in
        //     if success {
        //         print("✅ [WB-02信息固件] 检查成功: \(message ?? "")")
        //     } else {
        //         // 信息固件可能不存在，这是正常的
        //         print("ℹ️ [WB-02信息固件] 无可用更新或不存在")
        //     }
        // }
    }
    
    // MARK: - POI 数据同步
    private func checkUnsyncedPOIData() {
        print("🔍 检查未同步的用户POI数据...")
        
        let hasUnsynced = poiSyncManager.checkUnsyncedStatus()
        let unsyncedCount = poiSyncManager.getUnsyncedCount()
        
        if hasUnsynced {
            print("⚠️ 发现 \(unsyncedCount) 条未同步的POI数据")
            
            if NetworkMonitor.shared.isConnected {
                print("📤 网络可用，开始自动同步POI数据...")
                syncUnsyncedPOIData()
            }
            
            NotificationCenter.default.post(
                name: .hasUnsyncedPOIData,
                object: nil,
                userInfo: ["count": unsyncedCount]
            )
        } else {
            print("✅ 所有POI数据已同步")
        }
    }
    
    private func syncUnsyncedPOIData() {
        let toSave = poiSyncManager.getDataNeedingSync() ?? []
        let toDelete = poiSyncManager.getDataNeedingDeleteSync() ?? []
        
        guard !toSave.isEmpty || !toDelete.isEmpty else {
            print("📊 没有需要同步的POI数据")
            return
        }
        
        print("📤 开始同步POI数据 - 新增/更新: \(toSave.count)条, 删除: \(toDelete.count)条")
        
        // 处理需要保存的POI
        for poiData in toSave {
            savePOI(poiData: poiData)
        }
    }
    
    // MARK: - 手动检查更新
    func manualCheckForUpdates(completion: @escaping (Bool, String?) -> Void) {
        print("🔍 手动检查更新")
        
        guard NetworkMonitor.shared.isConnected else {
            completion(false, "网络连接不可用")
            return
        }
        
        let group = DispatchGroup()
        var hasError = false
        var lastMessage = ""
        
        // 检查基础版
        group.enter()
        let baseHardware = firmwareManager.getHardwareModel(for: .base)
        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .base, hardwareModel: baseHardware) { success, message in
            if !success {
                hasError = true
                lastMessage = message ?? "基础版固件检查失败"
            }
            group.leave()
        }
        
        // 检查样机版
        group.enter()
        let prototypeHardware = firmwareManager.getHardwareModel(for: .prototype)
        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .prototype, hardwareModel: prototypeHardware) { success, message in
            if !success {
                hasError = true
                lastMessage = message ?? "样机版固件检查失败"
            }
            group.leave()
        }
        
        // 检查自研版
        group.enter()
        let wb02Hardware = firmwareManager.getHardwareModel(for: .wb02)
        firmwareUpdater.checkAndDownloadFirmware(firmwareType: .wb02, hardwareModel: wb02Hardware) { success, message in
            if !success {
                hasError = true
                lastMessage = message ?? "自研版固件检查失败"
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(!hasError, hasError ? lastMessage : "所有固件检查完成")
        }
    }
    
    // MARK: - 私有辅助方法
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - POI 操作
    private func savePOI(poiData: UserPOILocalData) {
        let poiModel = UserPOIModel(
            poiId: poiData.poiId ?? "",
            name: poiData.name ?? "",
            description: poiData.description ?? "",
            lon: poiData.lon ?? 0,
            lat: poiData.lat ?? 0,
            category: poiData.category ?? 1,
            imgUrlList: nil,
            state: poiData.isDelected ?? false ? 1 : 0,
            userId: Int(UserManager.shared.userId) ?? 0,
            address: poiData.address ?? nil,
            altitude: "\(poiData.altitude ?? 0)"
        )
        
        mapViewModel.saveUserPoi(poiModel)
            .sink { completion in
                switch completion {
                case .finished:
                    print("✅ POI保存成功: \(poiData.name ?? "")")
                    // 保存成功后标记为已同步
                    self.poiSyncManager.markAsSynced(poiId: poiData.poiId ?? "")
                case .failure(let error):
                    print("❌ POI保存失败: \(error.localizedDescription)")
                }
            } receiveValue: { data in
                print("📊 POI保存结果: \(data)")
            }
            .store(in: &mapViewModel.cancellables)
    }
}

// MARK: - 扩展通知名称
extension Notification.Name {
    static let hasUnsyncedPOIData = Notification.Name("HasUnsyncedPOIData")
    static let syncUnsyncedPOIData = Notification.Name("SyncUnsyncedPOIData")
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}


