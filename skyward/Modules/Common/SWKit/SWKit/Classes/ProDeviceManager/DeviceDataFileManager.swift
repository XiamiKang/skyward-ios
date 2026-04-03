//
//  DeviceDataFileManager.swift
//  Pods
//
//  Created by TXTS on 2026/2/12.
//


//
//  DeviceDataFileManager.swift
//  Pods
//
//  Created by TXTS on 2026/2/12.
//

import Foundation

class DeviceDataFileManager {
    
    static let shared = DeviceDataFileManager()
    private let fileManager = FileManager.default
    private let dateFormatter = DateFormatter()
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    private init() {
        dateFormatter.dateFormat = "yyyyMMdd"
        
        // 配置 JSON 编码器
        jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        
        // 配置 JSON 解码器
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
    }
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func getTodayFileName() -> String {
        let dateStr = dateFormatter.string(from: Date())
        return "device_data_\(dateStr).json"  // 🔧 修改为 .json 后缀
    }
    
    private func getTodayFileURL() -> URL {
        documentsDirectory.appendingPathComponent(getTodayFileName())
    }
    
    // MARK: - 🔧 JSON 文件结构
    private struct DeviceDataFile: Codable {
        let fileName: String
        let deviceId: String
        let createTime: TimeInterval
        var records: [CollectedDeviceData]
        
        init(fileName: String, deviceId: String) {
            self.fileName = fileName
            self.deviceId = deviceId
            self.createTime = Date().timeIntervalSince1970
            self.records = []
        }
    }
    
    // MARK: - 🔧 写入数据（JSON 格式）
    func appendData(_ collectedData: CollectedDeviceData) throws {
        let fileURL = getTodayFileURL()
        
        if fileManager.fileExists(atPath: fileURL.path) {
            // 读取现有文件
            let fileData = try Data(contentsOf: fileURL)
            var dataFile = try jsonDecoder.decode(DeviceDataFile.self, from: fileData)
            
            // 追加新记录
            dataFile.records.append(collectedData)
            
            // 写回文件
            let encodedData = try jsonEncoder.encode(dataFile)
            try encodedData.write(to: fileURL)
            
            print("✅ JSON数据已追加 - 文件: \(fileURL.lastPathComponent), 总记录数: \(dataFile.records.count)")
        } else {
            // 创建新文件
            var dataFile = DeviceDataFile(
                fileName: getTodayFileName(),
                deviceId: collectedData.deviceId
            )
            dataFile.records.append(collectedData)
            
            let encodedData = try jsonEncoder.encode(dataFile)
            try encodedData.write(to: fileURL)
            
            print("✅ JSON数据已创建 - 文件: \(fileURL.lastPathComponent), 首条记录: \(collectedData.collectTime)")
        }
    }
    
    // MARK: - 🔧 批量写入数据
    func appendBatchData(_ collectedDataList: [CollectedDeviceData]) throws {
        guard !collectedDataList.isEmpty else { return }
        
        let fileURL = getTodayFileURL()
        let firstData = collectedDataList[0]
        
        if fileManager.fileExists(atPath: fileURL.path) {
            // 读取现有文件
            let fileData = try Data(contentsOf: fileURL)
            var dataFile = try jsonDecoder.decode(DeviceDataFile.self, from: fileData)
            
            // 批量追加新记录
            dataFile.records.append(contentsOf: collectedDataList)
            
            // 写回文件
            let encodedData = try jsonEncoder.encode(dataFile)
            try encodedData.write(to: fileURL)
            
            print("✅ JSON批量数据已追加 - 文件: \(fileURL.lastPathComponent), 新增: \(collectedDataList.count)条, 总记录数: \(dataFile.records.count)")
        } else {
            // 创建新文件
            var dataFile = DeviceDataFile(
                fileName: getTodayFileName(),
                deviceId: firstData.deviceId
            )
            dataFile.records.append(contentsOf: collectedDataList)
            
            let encodedData = try jsonEncoder.encode(dataFile)
            try encodedData.write(to: fileURL)
            
            print("✅ JSON批量数据已创建 - 文件: \(fileURL.lastPathComponent), 记录数: \(collectedDataList.count)条")
        }
    }
    
    // MARK: - 🔧 读取今日数据
    func readTodayData() -> [CollectedDeviceData] {
        let fileURL = getTodayFileURL()
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let dataFile = try jsonDecoder.decode(DeviceDataFile.self, from: fileData)
            return dataFile.records
        } catch {
            print("❌ 读取JSON数据失败: \(error)")
            return []
        }
    }
    
    // MARK: - 🔧 获取今日文件信息
    func getTodayFileInfo() -> (recordCount: Int, fileSize: String)? {
        let fileURL = getTodayFileURL()
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            let dataFile = try jsonDecoder.decode(DeviceDataFile.self, from: fileData)
            
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let fileSize = formatter.string(fromByteCount: size)
            
            return (dataFile.records.count, fileSize)
        } catch {
            print("❌ 获取文件信息失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 🔧 获取今日文件大小
    func getTodayFileSize() -> String {
        return getTodayFileInfo()?.fileSize ?? "0 KB"
    }
    
    // MARK: - 🔧 获取今日记录数
    func getTodayRecordCount() -> Int {
        return getTodayFileInfo()?.recordCount ?? 0
    }
    
    // MARK: - 🔧 获取所有待上传文件
    func getPendingUploadFiles() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return files.filter { $0.lastPathComponent.hasPrefix("device_data_") && $0.lastPathComponent.hasSuffix(".json") }
        } catch {
            return []
        }
    }
    
    // MARK: - 🔧 删除已上传文件
    func deleteFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
        print("✅ JSON文件已删除: \(url.lastPathComponent)")
    }
    
    // MARK: - 🔧 按日期范围查询数据
    func queryData(from startDate: Date, to endDate: Date) -> [CollectedDeviceData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        var allRecords: [CollectedDeviceData] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let fileName = "device_data_\(dateFormatter.string(from: currentDate)).json"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let fileData = try Data(contentsOf: fileURL)
                    let dataFile = try jsonDecoder.decode(DeviceDataFile.self, from: fileData)
                    allRecords.append(contentsOf: dataFile.records)
                } catch {
                    print("❌ 读取文件失败 \(fileName): \(error)")
                }
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return allRecords.sorted(by: { $0.collectTime < $1.collectTime })
    }
    
    // MARK: - 🔧 导出为CSV格式（兼容旧系统）
    func exportToCSV(for date: Date = Date()) -> String? {
        let records = queryData(from: date, to: date)
        guard !records.isEmpty else { return nil }
        
        var csvString = ""
        
        // 添加表头
        csvString += "lockStatus,antennaStatus,altitude,longitude,latitude,powerSavingMode,mode,"
        csvString += "temperature,humidity,"
        csvString += "imuFault,beidouFault,beaconFault,lnbFault,bucFault,"
        csvString += "firmwareVersion,deviceSN,catMAC,catSN,"
        csvString += "rcstCurrentStatus,rfRxSnr,rfTxSnr,"
        csvString += "rxBwAvg,txBwAvg,"
        csvString += "beamDescription,beamNSID,beamID,beamPolarization,beamLBLinkType,beamFrequency,beamSymbol,beamSatLongitude,"
        csvString += "satelliteName,antennaName,rxFreq,"
        csvString += "txPower,txMaxPower,"
        csvString += "longType,longValue,latType,latValue,"
        csvString += "fwdIsLock,fwdSrate,fwdFreq,fwdPower,fwdMode,fwdModcode,fwdSnr,fwdBer,fwdBeamId,"
        csvString += "authStatus,upSigRate,upTrfRate,upSigPower,upTrfPower,upSigModcod,upTrfModcod,upSigSnr,upTrfSnr,"
        csvString += "rcstXphType,collectTime\n"
        
        // 添加数据行
        for record in records {
            csvString += convertToDataLine(record) + "\n"
        }
        
        return csvString
    }
    
    // MARK: - 🔧 保留原有的CSV格式转换方法（用于兼容）
    public func convertToDataLine(_ data: CollectedDeviceData) -> String {
        var values: [String] = []
        
        // ============ ACU数据 (18个字段) ============
        values.append(String(data.acuData.lockStatus))
        values.append(String(data.acuData.antennaStatus))
        values.append(String(format: "%.2f", data.acuData.altitude))
        values.append(String(data.acuData.longitude))
        values.append(String(data.acuData.latitude))
        values.append(String(data.acuData.powerSavingMode))
        values.append(String(data.acuData.mode))
        
        values.append(String(format: "%.1f", data.acuData.temperature))
        values.append(String(format: "%.1f", data.acuData.humidity))
        
        values.append(String(data.acuData.imuFault))
        values.append(String(data.acuData.beidouFault))
        values.append(String(data.acuData.beaconFault))
        values.append(String(data.acuData.lnbFault))
        values.append(String(data.acuData.bucFault))
        
        values.append(data.acuData.firmwareVersion)
        values.append(data.acuData.deviceSN)
        values.append(data.acuData.catMAC)
        values.append(data.acuData.catSN)
        
        // ============ 卫星数据 (39个字段) ============
        values.append(String(data.satelliteData.rcstCurrentStatus))
        values.append(String(data.satelliteData.rfRxSnr))
        values.append(String(data.satelliteData.rfTxSnr))
        
        values.append(String(format: "%.2f", data.satelliteData.rxBwAvg))
        values.append(String(format: "%.2f", data.satelliteData.txBwAvg))
        
        for beamData in data.satelliteData.beamList {
            values.append(beamData.beamDescription)
            values.append(beamData.beamNSID)
            values.append(beamData.beamID)
            values.append(beamData.beamPolarization)
            values.append(beamData.beamLBLinkType)
            values.append(beamData.beamFrequency)
            values.append(beamData.beamSymbol)
            values.append(String(beamData.beamSatLongitude))
        }
        
        values.append(data.satelliteData.satelliteName)
        values.append(data.satelliteData.antennaName)
        values.append(data.satelliteData.rxFreq)
        
        values.append(data.satelliteData.txPower)
        values.append(data.satelliteData.txMaxPower)
        
        values.append(data.satelliteData.longType)
        values.append(String(data.satelliteData.longValue))
        values.append(data.satelliteData.latType)
        values.append(String(data.satelliteData.latValue))
        
        values.append(data.satelliteData.fwdIsLock)
        values.append(data.satelliteData.fwdSrate)
        values.append(data.satelliteData.fwdFreq)
        values.append(data.satelliteData.fwdPower)
        values.append(data.satelliteData.fwdMode)
        values.append(data.satelliteData.fwdModcode)
        values.append(data.satelliteData.fwdSnr)
        values.append(data.satelliteData.fwdBer)
        values.append(data.satelliteData.fwdBeamId)
        
        values.append(data.satelliteData.authStatus)
        values.append(data.satelliteData.upSigRate)
        values.append(data.satelliteData.upTrfRate)
        values.append(data.satelliteData.upSigPower)
        values.append(data.satelliteData.upTrfPower)
        values.append(data.satelliteData.upSigModcod)
        values.append(data.satelliteData.upTrfModcod)
        values.append(data.satelliteData.upSigSnr)
        values.append(data.satelliteData.upTrfSnr)
        
        values.append(data.satelliteData.rcstXphType)
        
        // ============ 时间戳 ============
        values.append(String(format: "%.0f", data.collectTime))
        
        return values.joined(separator: ",")
    }
}
