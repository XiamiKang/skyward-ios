//
//  DeviceManager.swift
//  Pods
//
//  Created by TXTS on 2026/1/13.
//

import Combine
import SWKit

// MARK: - 设备固件更新器
public class DeviceFirmwareUpdater: ObservableObject {
    public static let shared = DeviceFirmwareUpdater()
    
    // MARK: - 发布属性
    @Published var updateStatus: UpdateStatus = .idle
    @Published var downloadProgress: Double = 0
    @Published var updateProgress: Double = 0
    @Published var lastError: String?
    
    enum UpdateStatus {
        case idle
        case checking
        case downloading
        case readyToUpdate  // 固件已下载，等待连接设备
        case updating
        case success
        case failed
    }
    
    // MARK: - 私有属性
    private let firmwareManager = FirmwareManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    private init() {
        print("设备固件更新器初始化")
    }
    
    // MARK: - 网络环境下的操作
    
    /// 检查并下载最新固件（有网络时调用）
    public func checkAndDownloadFirmware(firmwareType: FirmwareType, hardwareModel: String? = nil, completion: ((Bool, String?) -> Void)? = nil) {
        guard updateStatus != .downloading else {
            completion?(false, "正在下载中，请稍候")
            return
        }
        
        updateStatus = .checking
        lastError = nil
        
        let model = hardwareModel ?? firmwareManager.getHardwareModel(for: firmwareType)
        
        print("开始检查并下载固件，硬件型号: \(model)")
        
        firmwareManager.checkForUpdates(firmwareType: firmwareType, hardwareModel: model) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let firmwareData):
                    if let firmware = firmwareData {
                        print("发现新固件，开始下载: \(firmware.versionName)")
                        self.downloadFirmware(firmwareType: firmwareType,firmware: firmware, completion: completion)
                    } else {
//                        print("当前已是最新版本")
                        self.updateStatus = .idle
                        completion?(false, "当前已是最新版本")
                    }
                    
                case .failure(let error):
                    print("检查更新失败: \(error)")
                    self.updateStatus = .failed
                    self.lastError = error.localizedDescription
                    completion?(false, "检查更新失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 下载固件
    private func downloadFirmware(firmwareType: FirmwareType, firmware: FirmwareUpdateData, completion: ((Bool, String?) -> Void)? = nil) {
        updateStatus = .downloading
        downloadProgress = 0
        
        firmwareManager.downloadFirmware(firmware, firmwareType: firmwareType, progress: { [weak self] progress in
            DispatchQueue.main.async {
                self?.downloadProgress = progress
                print("下载进度: \(Int(progress * 100))%")
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let localInfo):
                    print("固件下载完成: \(localInfo.versionName)")
                    self.updateStatus = .readyToUpdate
                    self.downloadProgress = 1.0
                    
                    // 更新本地存储的版本号
                    self.firmwareManager.updateStoredVersion(localInfo.versionName, for: firmwareType)
                    
                    completion?(true, "固件下载完成: \(localInfo.versionName)")
                    
                case .failure(let error):
                    print("固件下载失败: \(error)")
                    self.updateStatus = .failed
                    self.lastError = error.localizedDescription
                    completion?(false, "下载失败: \(error.localizedDescription)")
                }
            }
        })
    }
    
    // MARK: - 离线环境下的操作
    
    /// 检查是否需要更新设备（无网络时调用）
    public func checkIfDeviceNeedsUpdate(firmwareType: FirmwareType, deviceVersion: String) -> Bool {
        guard let downloadedFirmware = firmwareManager.getDownloadedFirmware(for: firmwareType) else {
            print("没有已下载的固件")
            return false
        }
        
        let comparison = firmwareManager.compareVersions(downloadedFirmware.versionName, deviceVersion)
        
        if comparison == .orderedDescending {
            print("需要更新: 本地版本 \(downloadedFirmware.versionName) > 设备版本 \(deviceVersion)")
            return true
        } else {
            print("无需更新: 本地版本 \(downloadedFirmware.versionName) <= 设备版本 \(deviceVersion)")
            return false
        }
    }
    
    /// 获取本地存储的版本号
    func getStoredVersion(for type: FirmwareType) -> String {
        return firmwareManager.getCurrentStoredVersion(for: type)
    }
    
    /// 获取已下载的固件信息
    func getDownloadedFirmwareInfo(for type: FirmwareType) -> LocalFirmwareInfo? {
        return firmwareManager.getDownloadedFirmware(for: type)
    }
    
    // MARK: - 重置
    func reset() {
        updateStatus = .idle
        downloadProgress = 0
        updateProgress = 0
        lastError = nil
    }
    
    // MARK: - 硬件型号设置
    func setHardwareModel(_ model: String, type: FirmwareType) {
        firmwareManager.saveHardwareModel(model, for: type)
        print("设置硬件型号: \(model)")
    }
}
