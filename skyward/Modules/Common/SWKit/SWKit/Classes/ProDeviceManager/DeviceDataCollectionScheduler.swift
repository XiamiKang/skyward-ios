//
//  DeviceDataCollectionScheduler.swift
//  Pods
//
//  Created by TXTS on 2026/2/12.
//


import Foundation

public class DeviceDataCollectionScheduler {
    
    public static let shared = DeviceDataCollectionScheduler()
    
    private var collectionTimer: Timer?
    private var uploadTimer: Timer?
    private var isCollecting = false
    private var isUploading = false
    
    private let collectionInterval: TimeInterval = 60  // 1分钟采集一次
    private let uploadInterval: TimeInterval = 300     // 5分钟上传一次
    
    private init() {}
    
    // MARK: - 启动采集服务
    func startCollection() {
        guard !isCollecting else { return }
        
        isCollecting = true
        print("🚀 启动设备数据采集服务 - 采集间隔: \(collectionInterval)s, 上传间隔: \(uploadInterval)s")
        
        // 立即执行一次采集
        performCollection()
        
        
        DispatchQueue.main.async {
            // 定时采集
            self.collectionTimer = Timer.scheduledTimer(withTimeInterval: self.collectionInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.performCollection()
            }
            // 定时上传
            self.uploadTimer = Timer.scheduledTimer(withTimeInterval: self.uploadInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.checkAndUploadViaMQTT()
            }
        }
    }
    
    
    // MARK: - 停止采集服务
    func stopCollection() {
        collectionTimer?.invalidate()
        uploadTimer?.invalidate()
        collectionTimer = nil
        uploadTimer = nil
        isCollecting = false
        print("🛑 停止设备数据采集服务")
    }
    
    // MARK: - 执行采集
    @objc func performCollection() {
        guard WiFiDeviceManager.shared.isConnected else {
            print("⏸️ 设备未连接，跳过本次采集")
            return
        }
        
        print("📊 开始采集设备数据...")
        
        let group = DispatchGroup()
        var acuData: ACUDeviceData?
        var satelliteData: SatelliteDeviceData?
        
        // 采集ACU数据
        group.enter()
        WiFiDeviceManager.shared.collectAllACUData { data in
            acuData = data
            group.leave()
        }
        
        // 采集卫星数据
        group.enter()
        SatelliteDataCollector.shared.collectAllData { data in
            satelliteData = data
            group.leave()
        }
        
        group.notify(queue: .global(qos: .background)) {
            guard let acu = acuData, let satellite = satelliteData else {
                print("❌ 数据采集不完整，跳过存储")
                return
            }
            
            let collectedData = CollectedDeviceData(acuData: acu, satelliteData: satellite)
            
            do {
                try DeviceDataFileManager.shared.appendData(collectedData)
                print("✅ 采集完成 - 文件大小: \(DeviceDataFileManager.shared.getTodayFileSize())")
                
                // 发送通知
                NotificationCenter.default.post(
                    name: .deviceDataCollected,
                    object: nil,
                    userInfo: ["data": collectedData]
                )
            } catch {
                print("❌ 数据存储失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 检查并上传（使用MQTT）
    @objc public func checkAndUploadViaMQTT() {
        guard !isUploading else { return }
        
        let pendingFiles = DeviceDataFileManager.shared.getPendingUploadFiles()
        guard !pendingFiles.isEmpty else {
            print("⏸️ 没有待上传文件")
            return
        }
        
        guard let deviceSN = UserDefaults.standard.string(forKey: "last_device_sn") else {
            print("❌ 未获取到设备编号")
            return
        }
        
        print("📤 [MQTT] 开始上传文件，共 \(pendingFiles.count) 个")
        isUploading = true
        
        WiFiDeviceManager.shared.uploadTodayDataViaMQTT { result in
            self.isUploading = false
            
            switch result {
            case .success(let count):
                print("✅ [MQTT] 定时上传完成，共 \(count) 条记录")
            case .failure(let error):
                print("❌ [MQTT] 定时上传失败: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let deviceDataCollected = Notification.Name("deviceDataCollected")
}
