//
//  WiFiDeviceManager+CollectAllACUData.swift
//  SWKit
//
//  Created by TXTS on 2026/2/12.
//

import Foundation
import SWNetwork

// MARK: - WiFiDeviceManager 扩展
extension WiFiDeviceManager {
    
    // 采集所有ACU数据
    func collectAllACUData(completion: @escaping (ACUDeviceData?) -> Void) {
        var acuData = ACUDeviceData()
        let group = DispatchGroup()
        var hasError = false
        
        // 1. 采集终端状态
        group.enter()
        self.queryLocation { (result: Result<ProDeviceStatus, Error>) in
            switch result {
            case .success(let status):
                acuData.lockStatus = status.lockStatus.rawValue
                acuData.antennaStatus = status.antennaStatus.rawValue
                acuData.altitude = status.altitude
                acuData.longitude = Int(status.longitude * 100000)
                acuData.latitude = Int(status.latitude * 100000)
                acuData.powerSavingMode = status.powerSavingMode ? 1 : 0
                acuData.mode = status.mode
            case .failure(let error):
                print("❌ 采集终端状态失败: \(error.localizedDescription)")
                hasError = true
            }
            group.leave()
        }
        
        // 2. 采集环境信息
        group.enter()
        self.queryEnvironment { result in
            switch result {
            case .success(let env):
                acuData.temperature = String(format: "%.2f", env.temperature)
                acuData.humidity = String(format: "%.2f", env.humidity)
            case .failure(let error):
                print("❌ 采集环境信息失败: \(error.localizedDescription)")
                hasError = true
            }
            group.leave()
        }
        
        // 3. 采集故障码
        group.enter()
        self.queryDeviceWarning { result in
            switch result {
            case .success(let warning):
                acuData.imuFault = warning.imu
                acuData.beidouFault = warning.beidou
                acuData.beaconFault = warning.beacon
                acuData.lnbFault = warning.lnb
                acuData.bucFault = warning.buc
            case .failure(let error):
                print("❌ 采集故障码失败: \(error.localizedDescription)")
                hasError = true
            }
            group.leave()
        }
        
        // 4. 采集设备信息
        group.enter()
        self.queryDeviceInfo { result in
            switch result {
            case .success(let info):
                acuData.firmwareVersion = info.ACUVersion
                acuData.deviceSN = info.deviceSN
                acuData.catMAC = info.catMAC
                acuData.catSN = info.catSN
                UserDefaults.standard.set(info.deviceSN, forKey: "last_device_sn")
            case .failure(let error):
                print("❌ 采集设备信息失败: \(error.localizedDescription)")
                hasError = true
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(hasError ? nil : acuData)
        }
    }
}


// MARK: - 在 WiFiDeviceManager 中集成 MQTT 上传
extension WiFiDeviceManager {
    
    /// 使用MQTT上传今日数据
    public func uploadTodayDataViaMQTT(completion: ((Result<Int, Error>) -> Void)? = nil) {
        // 获取设备SN
        guard let deviceSN = UserDefaults.standard.string(forKey: "last_device_sn") else {
            print("❌ 未获取到设备编号")
            completion?(.failure(NSError(domain: "未获取到设备编号", code: -1)))
            return
        }
        
        // 检查MQTT连接
        guard MQTTManager.shared.isConnected else {
            print("⚠️ MQTT未连接，尝试连接...")
            MQTTManager.shared.connect()
            
            // 等待连接
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if MQTTManager.shared.isConnected {
                    self.uploadTodayDataViaMQTT(completion: completion)
                } else {
                    completion?(.failure(NSError(domain: "MQTT连接失败", code: -2)))
                }
            }
            return
        }
        
        let pendingFiles = DeviceDataFileManager.shared.getPendingUploadFiles()
        guard !pendingFiles.isEmpty else {
            print("⏸️ 没有待上传文件")
            completion?(.success(0))
            return
        }
        
        print("📤 [MQTT] 开始上传 \(pendingFiles.count) 个文件，设备SN: \(deviceSN)")
        
        var totalSuccess = 0
        let group = DispatchGroup()
        
        for fileURL in pendingFiles {
            group.enter()
            
            DeviceDataUploadService.shared.uploadJSONFileViaMQTT(
                fileURL: fileURL,
                deviceSN: deviceSN,
                progressHandler: { current, total, record in
                    print("  📨 上传进度: \(current)/\(total)")
                }
            ) { result in
                switch result {
                case .success(let count):
                    totalSuccess += count
                    // 上传成功，删除本地文件
                    try? DeviceDataFileManager.shared.deleteFile(at: fileURL)
                    print("  ✅ 文件上传成功: \(fileURL.lastPathComponent), \(count)条记录")
                case .failure(let error):
                    print("  ❌ 文件上传失败: \(fileURL.lastPathComponent), 错误: \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("✅ [MQTT] 所有文件上传完成，共 \(totalSuccess) 条记录")
            completion?(.success(totalSuccess))
        }
    }
}

