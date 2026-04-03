//
//  DeviceDataUploadService.swift
//  Pods
//
//  Created by TXTS on 2026/2/12.
//

import Foundation
import CocoaMQTT
import SWNetwork

class DeviceDataUploadService {
    
    static let shared = DeviceDataUploadService()
    
    // MQTT主题前缀
    private let mqttTopicPrefix = "txts/device/devicetoserver/broad/log/"
    
    // 上传队列（串行队列，确保顺序上传）
    private let uploadQueue = DispatchQueue(label: "com.device.upload.mqtt", qos: .utility)
    
    // 当前正在上传的任务计数器
    private var uploadingCount = 0
    private let countLock = NSLock()
    
    // 上传状态回调
    public var onUploadProgress: ((Int, Int, String) -> Void)?
    public var onUploadComplete: ((Int, Int) -> Void)?
    
    private init() {}
    
    // MARK: - 🚀 上传JSON文件（逐条记录发送）
    public func uploadJSONFileViaMQTT(
        fileURL: URL,
        deviceSN: String,
        progressHandler: ((Int, Int, CollectedDeviceData) -> Void)? = nil,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        uploadQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // 1. 读取JSON文件
                let fileData = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let dataFile = try decoder.decode(DeviceDataFile.self, from: fileData)
                
                let records = dataFile.records
                guard !records.isEmpty else {
                    DispatchQueue.main.async {
                        completion(.success(0))
                    }
                    return
                }
                
                print("📤 [MQTT] 开始上传文件: \(fileURL.lastPathComponent), 共 \(records.count) 条记录")
                
                // 2. 检查MQTT连接状态
                guard MQTTManager.shared.isConnected else {
                    throw NSError(domain: "MQTT未连接", code: -1, userInfo: nil)
                }
                
                // 3. 逐条上传
                var successCount = 0
                var failCount = 0
                let group = DispatchGroup()
                
                for (index, record) in records.enumerated() {
                    group.enter()
                    
                    // 上传单条记录
                    let success = self.publishDeviceData(deviceSN: deviceSN, record: record)
                    
                    if success {
                        successCount += 1
                        print("  ✅ [MQTT] 第 \(index + 1)/\(records.count) 条上传成功 - 时间: \(record.collectTime)")
                    } else {
                        failCount += 1
                        print("  ❌ [MQTT] 第 \(index + 1)/\(records.count) 条上传失败")
                    }
                    
                    // 报告进度
                    DispatchQueue.main.async {
                        progressHandler?(successCount + failCount, records.count, record)
                        self.onUploadProgress?(successCount + failCount, records.count, "\(record.collectTime)")
                    }
                    
                    // 每条消息间隔50ms，避免MQTT拥堵
                    Thread.sleep(forTimeInterval: 0.05)
                    group.leave()
                }
                
                group.notify(queue: .main) {
                    print("📤 [MQTT] 文件上传完成 - 成功: \(successCount), 失败: \(failCount)")
                    self.onUploadComplete?(successCount, failCount)
                    completion(.success(successCount))
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("❌ [MQTT] JSON文件读取失败: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - 🚀 发布设备数据（JSON格式）
    private func publishDeviceData(deviceSN: String, record: CollectedDeviceData) -> Bool {
        // 构建设备主题
        let topic = mqttTopicPrefix + deviceSN
        
        let beamListDict = record.satelliteData.beamList.map { beam -> [String: Any] in
            return [
                "beamDescription": beam.beamDescription,
                "beamNSID": beam.beamNSID,
                "beamID": beam.beamID,
                "beamPolarization": beam.beamPolarization,
                "beamLBLinkType": beam.beamLBLinkType,
                "beamFrequency": beam.beamFrequency,
                "beamSymbol": beam.beamSymbol,
                "beamSatLongitude": beam.beamSatLongitude
            ]
        }
        
        // 构建完整的设备数据JSON
        let payload: [String: Any] = [
            "acuData": [
                "lockStatus": record.acuData.lockStatus,
                "foldStatus": record.acuData.antennaStatus,
                "altitude": record.acuData.altitude,
                "longitude": record.acuData.longitude,
                "latitude": record.acuData.latitude,
                "lowPower": record.acuData.powerSavingMode,
                "currentMode": record.acuData.mode,
                "temperature": record.acuData.temperature,
                "humidity": record.acuData.humidity,
                "navigationErrorCode": record.acuData.imuFault,
                "beidouErrorCode": record.acuData.beidouFault,
                "beaconErrorCode": record.acuData.beaconFault,
                "LNBErrorCode": record.acuData.lnbFault,
                "BUCErrorCode": record.acuData.bucFault,
                "firmwareVersion": record.acuData.firmwareVersion,
                "deviceSn": record.acuData.deviceSN,
                "modernMac": record.acuData.catMAC,
                "modernSn": record.acuData.catSN
            ],
            "satelliteData": [
                "RFData": [
                    "rcst_current_status": record.satelliteData.rcstCurrentStatus,
                    "rf_rx_snr": record.satelliteData.rfRxSnr,
                    "rf_tx_snr": record.satelliteData.rfTxSnr,
                    "rx_bw_avg": record.satelliteData.rxBwAvg,
                    "tx_bw_avg": record.satelliteData.txBwAvg,
                    "beamList": beamListDict,
                    "satellite_name_main": record.satelliteData.satelliteName,
                    "antenna_name_main": record.satelliteData.antennaName,
                    "rx_freq_main": record.satelliteData.rxFreq,
                    "tx_power": record.satelliteData.txPower,
                    "tx_max_power": record.satelliteData.txMaxPower,
                    "long_type": record.satelliteData.longType,
                    "long_value": record.satelliteData.longValue,
                    "lat_type": record.satelliteData.latType,
                    "lat_value": record.satelliteData.latValue
                ],
                "diagnosisData": [
                    "u8_fwd_is_lock": record.satelliteData.fwdIsLock,
                    "u32_current_srate": record.satelliteData.fwdSrate,
                    "u32_current_freq": record.satelliteData.fwdFreq,
                    "s32_current_power": record.satelliteData.fwdPower,
                    "rf_rx_seachargo": record.satelliteData.fwdMode,
                    "u8_fwd_modcode": record.satelliteData.fwdModcode,
                    "s32_fwd_snr": record.satelliteData.fwdSnr,
                    "u32_current_ber": record.satelliteData.fwdBer,
                    "beamid_now": record.satelliteData.fwdBeamId,
                    "x509_auth_status": record.satelliteData.authStatus,
                    "u32_up_sig_rate": record.satelliteData.upSigRate,
                    "u32_up_trf_rate": record.satelliteData.upTrfRate,
                    "u32_up_sig_power": record.satelliteData.upSigPower,
                    "u32_up_trf_power": record.satelliteData.upTrfPower,
                    "u32_up_sig_modcod": record.satelliteData.upSigModcod,
                    "u32_up_trf_modcod": record.satelliteData.upTrfModcod,
                    "u8_up_sig_snr": record.satelliteData.upSigSnr,
                    "u8_up_trf_snr": record.satelliteData.upTrfSnr,
                    "rcst_xph_type": record.satelliteData.rcstXphType
                ]
            ],
            "timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // 使用MQTTManager发送消息
                let success = MQTTManager.shared.publish(message: jsonString, to: topic, qos: .qos1)
                
                if success {
                    print("  📤 [MQTT] 发送设备数据 - 时间: \(record.collectTime)")
                }
                
                return success
            }
        } catch {
            print("❌ [MQTT] JSON序列化失败: \(error)")
        }
        
        return false
    }
    
    // MARK: - 🚀 兼容旧版：发布CSV格式数据（如果需要）
    private func publishCSVLogMessage(deviceSN: String, record: String) -> Bool {
        let topic = mqttTopicPrefix + deviceSN
        let payload: [String: Any] = [
            "logUrl": record,
            "deviceSN": deviceSN,
            "timestamp": Date().timeIntervalSince1970,
            "format": "csv"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return MQTTManager.shared.publish(message: jsonString, to: topic, qos: .qos1)
            }
        } catch {
            print("❌ [MQTT] CSV序列化失败: \(error)")
        }
        return false
    }
    
    // MARK: - 🚀 批量上传所有待上传文件（JSON格式）
    public func uploadAllPendingFilesViaMQTT(
        deviceSN: String,
        progressHandler: ((String, Int, Int) -> Void)? = nil,
        completion: @escaping (Result<(success: Int, fail: Int), Error>) -> Void
    ) {
        let pendingFiles = DeviceDataFileManager.shared.getPendingUploadFiles()
        guard !pendingFiles.isEmpty else {
            completion(.success((0, 0)))
            return
        }
        
        print("📤 [MQTT] 开始批量上传，共 \(pendingFiles.count) 个JSON文件")
        
        var totalSuccess = 0
        var totalFail = 0
        let group = DispatchGroup()
        
        for (fileIndex, fileURL) in pendingFiles.enumerated() {
            group.enter()
            
            uploadJSONFileViaMQTT(fileURL: fileURL, deviceSN: deviceSN) { result in
                switch result {
                case .success(let count):
                    totalSuccess += count
                    // 上传成功，删除本地文件
                    try? DeviceDataFileManager.shared.deleteFile(at: fileURL)
                    print("  ✅ 文件 \(fileIndex + 1)/\(pendingFiles.count) 上传成功，共 \(count) 条记录")
                case .failure(let error):
                    totalFail += 1
                    print("  ❌ 文件 \(fileIndex + 1)/\(pendingFiles.count) 上传失败: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    progressHandler?(fileURL.lastPathComponent, fileIndex + 1, pendingFiles.count)
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("📤 [MQTT] 批量上传完成 - 成功: \(totalSuccess)条记录, 失败: \(totalFail)个文件")
            completion(.success((totalSuccess, totalFail)))
        }
    }
    
    // MARK: - 🚀 实时上传单条数据
    public func uploadRealtimeData(_ data: CollectedDeviceData, deviceSN: String) {
        guard MQTTManager.shared.isConnected else {
            print("⚠️ [MQTT] 未连接，无法实时上传")
            return
        }
        
        uploadQueue.async { [weak self] in
            _ = self?.publishDeviceData(deviceSN: deviceSN, record: data)
        }
    }
}

// MARK: - 🚀 扩展 DeviceDataFileManager 以支持 JSON 文件读取
extension DeviceDataFileManager {
    func readJSONFile(at url: URL) -> DeviceDataFile? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            return try decoder.decode(DeviceDataFile.self, from: data)
        } catch {
            print("❌ 读取JSON文件失败: \(error)")
            return nil
        }
    }
}

// MARK: - 🚀 定义 DeviceDataFile 结构体（与存储格式一致）
struct DeviceDataFile: Codable {
    let fileName: String
    let deviceId: String
    let createTime: TimeInterval
    var records: [CollectedDeviceData]
}
