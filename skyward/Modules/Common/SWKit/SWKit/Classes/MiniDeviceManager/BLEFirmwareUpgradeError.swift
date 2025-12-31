//
//  BLEFirmwareUpgradeError.swift
//  Pods
//
//  Created by TXTS on 2025/12/26.
//


import Foundation
import CoreBluetooth

enum BLEFirmwareUpgradeError: Error {
    case deviceNotConnected
    case invalidFirmwareData
    case upgradeTimeout
    case transmissionFailed
    case deviceRejected
    
    var localizedDescription: String {
        switch self {
        case .deviceNotConnected:
            return "蓝牙设备未连接"
        case .invalidFirmwareData:
            return "无效的固件数据"
        case .upgradeTimeout:
            return "升级超时"
        case .transmissionFailed:
            return "数据传输失败"
        case .deviceRejected:
            return "设备拒绝升级"
        }
    }
}

public class BLEFirmwareUpgradeManager {
    
    private let bluetoothManager: BluetoothManager
    private var upgradeProgressCallback: ((Double) -> Void)?
    private var upgradeCompletion: ((Result<Bool, Error>) -> Void)?
    private var isUpgrading = false
    
    public init(bluetoothManager: BluetoothManager = .shared) {
        self.bluetoothManager = bluetoothManager
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBluetoothDisconnect),
            name: .bluetoothDeviceDisconnected,
            object: nil
        )
    }
    
    /// 开始固件升级
    public func startUpgrade(
        version: String,
        firmwarePath: String,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard !isUpgrading else {
            onComplete(.failure(BLEFirmwareUpgradeError.transmissionFailed))
            return
        }
        
        guard bluetoothManager.isConnected else {
            onComplete(.failure(BLEFirmwareUpgradeError.deviceNotConnected))
            return
        }
        
        do {
            let firmwareData = try Data(contentsOf: URL(fileURLWithPath: firmwarePath))
            isUpgrading = true
            upgradeProgressCallback = onProgress
            upgradeCompletion = onComplete
            
            bluetoothManager.startFirmwareUpgradeFlow(
                version: version,
                firmwareData: firmwareData,
                progressCallback: { [weak self] progress in
                    print("升级控制器中----\(progress)")
                    self?.handleUpgradeProgress(progress)
                },
                completion: { [weak self] success, error in
                    self?.handleUpgradeCompletion(success: success, error: error)
                }
            )
            
        } catch {
            onComplete(.failure(error))
        }
    }
    
    /// 取消升级
    public func cancelUpgrade() {
        isUpgrading = false
        upgradeProgressCallback = nil
        upgradeCompletion = nil
    }
    
    private func handleUpgradeProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.upgradeProgressCallback?(progress)
        }
    }
    
    private func handleUpgradeCompletion(success: Bool, error: String?) {
        isUpgrading = false
        
        DispatchQueue.main.async {
            if success {
                self.upgradeCompletion?(.success((true)))
            } else {
                let errorMsg = error ?? "升级失败"
                self.upgradeCompletion?(.failure(NSError(
                    domain: "BLEFirmwareUpgrade",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: errorMsg]
                )))
            }
            
            self.upgradeProgressCallback = nil
            self.upgradeCompletion = nil
        }
    }
    
    @objc private func handleBluetoothDisconnect() {
        if isUpgrading {
            handleUpgradeCompletion(success: false, error: "蓝牙连接断开")
        }
    }
}
