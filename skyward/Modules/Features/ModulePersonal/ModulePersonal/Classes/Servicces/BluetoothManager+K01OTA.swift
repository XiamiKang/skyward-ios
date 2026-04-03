//
//  AssociatedKeys.swift
//  Pods
//
//  Created by TXTS on 2026/3/24.
//

import SWKit

// MARK: - OTA 升级功能扩展
extension BluetoothManager {
    
    // 使用 Associated Object 存储 OTA 管理器
    private struct AssociatedKeys {
        static var otaManager = "otaManager"
        static var otaProgressHandler = "otaProgressHandler"
        static var otaCompletionHandler = "otaCompletionHandler"
    }
    
    private var otaManager: FRIUpdateOTAManager? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.otaManager) as? FRIUpdateOTAManager
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.otaManager, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var onOTAProgress: ((Double) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.otaProgressHandler) as? (Double) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.otaProgressHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var onOTACompletion: ((Error?) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.otaCompletionHandler) as? (Error?) -> Void
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.otaCompletionHandler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 开始 OTA 升级（使用已连接的设备）
    /// - Parameter binData: 固件数据
    public func startOTAUpgrade(with binData: Data) {
        // 检查设备连接状态
        guard let peripheral = connectedPeripheral,
              peripheral.state == .connected else {
            let error = NSError(domain: "BluetoothManager", 
                               code: -1, 
                               userInfo: [NSLocalizedDescriptionKey: "设备未连接"])
            onOTACompletion?(error)
            return
        }
        
        // 检查必要的特征
        guard let writeChar = writeCharacteristic ?? writeWithoutResponseCharacteristic,
              let notifyChar = notifyCharacteristic else {
            let error = NSError(domain: "BluetoothManager", 
                               code: -2, 
                               userInfo: [NSLocalizedDescriptionKey: "未找到必要的特征（写入特征或通知特征）"])
            onOTACompletion?(error)
            return
        }
        
        // 验证固件数据
        guard validateBinData(binData) else {
            let error = NSError(domain: "BluetoothManager", 
                               code: -3, 
                               userInfo: [NSLocalizedDescriptionKey: "固件文件无效，请检查文件格式"])
            onOTACompletion?(error)
            return
        }
        
        // 创建并配置 OTA 管理器
        let otaManager = FRIUpdateOTAManager()
        otaManager.delegate = self
        otaManager.binData = binData
        
        // 注意：FRIUpdateOTAManager 内部会使用 friBLE 来设置回调
        // 我们需要创建一个 FRIBluetooth 实例来支持这些回调
        guard let friBLE = FRIBluetooth.share() else { return }
        
        // 设置 FRIBluetooth 的回调，使其使用我们已有的连接
        setupFRIBluetoothCallbacks(friBLE, peripheral: peripheral, writeChar: writeChar, notifyChar: notifyChar)
        
        otaManager.friBLE = friBLE
        self.otaManager = otaManager
        
        // 开始 OTA 升级
        otaManager.startUpdateOTA(peripheral,
                                  write: writeChar,
                                  read: notifyChar)
        
    }
    
    /// 验证固件数据
    private func validateBinData(_ binData: Data) -> Bool {
        // 检查数据是否为空
        guard binData.count > 0 else { return false }
        
        // 这里可以添加更多的验证逻辑
        // 比如检查文件头、CRC 等
        
        return true
    }
    
    /// 设置 FRIBluetooth 的回调，使其与我们的现有连接协同工作
    private func setupFRIBluetoothCallbacks(_ friBLE: FRIBluetooth, 
                                           peripheral: CBPeripheral,
                                           writeChar: CBCharacteristic,
                                           notifyChar: CBCharacteristic) {
        
        // 设置写入回调
        friBLE.setBlockOnDidWriteValueForCharacteristic { characteristic, error in
            
            if let error = error {
                print("OTA 写入错误: \(error.localizedDescription)")
            } else {
                print("OTA 写入成功: \(characteristic?.uuid.uuidString ?? "unknown")")
            }
        }
        
        // 设置通知回调 - 这个很重要，因为 OTA 管理器需要通过 notify 接收响应
        // 注意：FRIUpdateOTAManager 内部会调用 friBLE.notify 来设置通知
        // 我们需要确保通知数据能够传递到 OTA 管理器
        friBLE.notify(peripheral, characteristic: notifyChar) { peripheral, characteristic, error in
            if let error = error {
                print("OTA 通知错误: \(error.localizedDescription)")
            } else if let data = characteristic?.value {
                // 数据会通过 FRIUpdateOTAManager 内部的通知机制处理
                // 这里不需要额外处理
                print("OTA 收到响应数据: \(data.count) bytes")
            }
        }
    }
    
    /// 开始 OTA 升级（使用文件路径）
    public func startOTAUpgrade(with filePath: String) {
        guard FileManager.default.fileExists(atPath: filePath),
              let binData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            let error = NSError(domain: "BluetoothManager", 
                               code: -4, 
                               userInfo: [NSLocalizedDescriptionKey: "固件文件不存在或无法读取"])
            onOTACompletion?(error)
            return
        }
        startOTAUpgrade(with: binData)
    }
    
    /// 取消 OTA 升级
    public func cancelOTAUpgrade() {
        otaManager?.cancelOTAUpdate()
    }
}

// MARK: - FRIUpdateOTAManagerDelegate
extension BluetoothManager: FRIUpdateOTAManagerDelegate {
    
    public func onOTAUpdateStart(_ ota: FRIUpdateOTAManager) {
        print("🚀 OTA 升级开始")
        DispatchQueue.main.async {
            self.onOTAProgress?(0)
        }
    }
    
    public func onOTAUpdateStatusDidChange(_ ota: FRIUpdateOTAManager, withProgress aProgress: Float) {
        let progress = Double(aProgress)
        print("📊 OTA 升级进度: \(String(format: "%.2f", progress))%")
        DispatchQueue.main.async {
            self.onOTAProgress?(progress)
        }
    }
    
    public func onOTAUpdateStatusCompletion(_ ota: FRIUpdateOTAManager) {
        print("✅ OTA 升级完成")
        DispatchQueue.main.async {
            self.onOTACompletion?(nil)
        }
        // 清理
        self.otaManager = nil
    }
    
    public func onOTAUpdateStatusFailure(_ ota: FRIUpdateOTAManager, error err: Error) {
        print("❌ OTA 升级失败: \(err.localizedDescription)")
        DispatchQueue.main.async {
            self.onOTACompletion?(err)
        }
        // 清理
        self.otaManager = nil
    }
}
