//
//  FirmwareSubType.swift
//  Pods
//
//  Created by TXTS on 2026/4/3.
//

import Foundation
import SWKit

// MARK: - 固件类型（针对 wb02 的双固件）
public enum FirmwareSubType: String {
    case data = "data"      // 数据固件（必存在）
    case message = "msg"    // 信息固件（可选）
    
    public func getDownloadedInfoKey(for mainType: FirmwareType) -> String {
        switch self {
        case .data:
            return mainType.getDownloadedInfoKey()
        case .message:
            return mainType.getMsgDownloadedInfoKey()
        }
    }
    
    public func getFilePathKey(for mainType: FirmwareType) -> String {
        switch self {
        case .data:
            return mainType.getFilePathKey()
        case .message:
            return mainType.getMsgFilePathKey()
        }
    }
}

// MARK: - 扩展 FirmwareType 支持双固件
extension FirmwareType {
    // wb02 的信息固件相关 Key
    func getMsgDownloadedInfoKey() -> String {
        return "\(rawValue)_firmware_msg_downloaded_info"
    }
    
    func getMsgFilePathKey() -> String {
        return "\(rawValue)_firmware_msg_file_path"
    }
    
    // 获取子目录名（用于区分数据固件和信息固件）
    func subDirectoryName(for subType: FirmwareSubType) -> String {
        switch self {
        case .wb02:
            return subType == .data ? "Data" : "Message"
        default:
            return "" // 非 wb02 设备不使用子目录
        }
    }
}

// MARK: - 固件标识（唯一标识一个固件）
public struct FirmwareIdentifier: Hashable {
    public let mainType: FirmwareType
    public let subType: FirmwareSubType?
    
    public init(mainType: FirmwareType, subType: FirmwareSubType? = nil) {
        self.mainType = mainType
        self.subType = subType
    }
    
    // 是否为主要固件（非 wb02 设备只有一个固件，wb02 的数据固件是主要的）
    public var isPrimary: Bool {
        switch mainType {
        case .wb02:
            return subType == .data
        default:
            return true
        }
    }
    
    public var storageKey: String {
        if let subType = subType {
            return "\(mainType.rawValue)_\(subType.rawValue)"
        }
        return mainType.rawValue
    }
}

// MARK: - 统一固件管理器
public class UnifiedFirmwareManager {
    public static let shared = UnifiedFirmwareManager()
    
    private let fileManager = FileManager.default
    private let userDefaults: UserDefaults
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private let urlSession: URLSession
    private var progressHandlers: [String: (Double) -> Void] = [:]
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - 获取所有可用的固件标识
    public func getAllFirmwareIdentifiers(for type: FirmwareType) -> [FirmwareIdentifier] {
        switch type {
        case .wb02:
            return [
                FirmwareIdentifier(mainType: .wb02, subType: .data),
                FirmwareIdentifier(mainType: .wb02, subType: .message)
            ]
        default:
            return [FirmwareIdentifier(mainType: type, subType: nil)]
        }
    }
    
    // MARK: - 版本管理
    public func getCurrentStoredVersion(for identifier: FirmwareIdentifier) -> String {
        let key = "\(identifier.storageKey)_current_version"
        return userDefaults.string(forKey: key) ?? getDefaultVersion(for: identifier)
    }
    
    private func getDefaultVersion(for identifier: FirmwareIdentifier) -> String {
        switch identifier.mainType {
        case .wb02:
            return identifier.subType == .data ? "1.0.0.0" : "1.0.0.0"
        default:
            return identifier.mainType.getDefaultVersion()
        }
    }
    
    public func updateStoredVersion(_ version: String, for identifier: FirmwareIdentifier) {
        let key = "\(identifier.storageKey)_current_version"
        userDefaults.set(version, forKey: key)
        userDefaults.synchronize()
        print("更新存储版本 [\(identifier)]: \(version)")
    }
    
    // MARK: - 硬件型号管理
    public func getHardwareModel(for identifier: FirmwareIdentifier) -> String {
        let key = "\(identifier.storageKey)_hardware_model"
        return userDefaults.string(forKey: key) ?? getDefaultHardwareModel(for: identifier)
    }
    
    private func getDefaultHardwareModel(for identifier: FirmwareIdentifier) -> String {
        switch identifier.mainType {
        case .base:
            return "TX035"
        case .prototype:
            return "TX035-prototype"
        case .wb02:
            return "TXTS-WB-02"
        }
    }
    
    public func saveHardwareModel(_ model: String, for identifier: FirmwareIdentifier) {
        let key = "\(identifier.storageKey)_hardware_model"
        userDefaults.set(model, forKey: key)
        userDefaults.synchronize()
    }
    
    // MARK: - 本地固件管理
    public func getDownloadedFirmware(for identifier: FirmwareIdentifier) -> LocalFirmwareInfo? {
        let key = getDownloadedInfoKey(for: identifier)
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LocalFirmwareInfo.self, from: data)
    }
    
    public func getDownloadedFirmwarePath(for identifier: FirmwareIdentifier) -> URL? {
        guard let firmwareInfo = getDownloadedFirmware(for: identifier) else { return nil }
        
        if fileManager.fileExists(atPath: firmwareInfo.filePath) {
            return URL(fileURLWithPath: firmwareInfo.filePath)
        }
        
        // 尝试在标准目录中查找
        return searchFirmwareFile(for: identifier, version: firmwareInfo.versionName)
    }
    
    public func isFirmwareDownloaded(for identifier: FirmwareIdentifier) -> Bool {
        return getDownloadedFirmwarePath(for: identifier) != nil
    }
    
    // MARK: - 检查更新
    public func checkForUpdates(
        identifier: FirmwareIdentifier,
        completion: @escaping (Result<FirmwareUpdateData?, FirmwareError>) -> Void
    ) {
        let currentVersion = getCurrentStoredVersion(for: identifier)
        let hardwareModel = getHardwareModel(for: identifier)
        
        print("检查固件更新 [\(identifier)] - 硬件型号: \(hardwareModel), 当前版本: \(currentVersion)")
        
        let personalService = PersonalServer()
        let model = Wb02DeviceFirmwareModel(
            versionCode: currentVersion,
            hardwareModel: hardwareModel
        )
        
        personalService.getProDeviceFirmware(model) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                do {
                    let baseResponse = try JSONDecoder().decode(BaseResponse<FirmwareData>.self, from: response.data)
                    
                    if baseResponse.success, let firmwareData = baseResponse.data {
                        let updateData = self.createFirmwareUpdateData(from: firmwareData, identifier: identifier)
                        let versionName = updateData.versionName
                        if self.compareVersions(versionName, currentVersion) == .orderedDescending {
                            print("✅ 发现新版本 [\(identifier)]: \(versionName)")
                            completion(.success(updateData))
                        } else {
                            print("ℹ️ 当前已是最新版本 [\(identifier)]")
                            completion(.success(nil))
                        }
                    } else {
                        print("ℹ️ 服务器返回失败 [\(identifier)]")
                        completion(.success(nil))
                    }
                } catch {
                    print("❌ 数据解析失败 [\(identifier)]: \(error)")
                    completion(.failure(.versionParseError))
                }
                
            case .failure(let error):
                print("❌ 网络请求失败 [\(identifier)]: \(error)")
                completion(.failure(.downloadFailed))
            }
        }
    }
    
    // MARK: - 下载固件
    public func downloadFirmware(
        _ firmware: FirmwareUpdateData,
        identifier: FirmwareIdentifier,
        progress: ((Double) -> Void)? = nil,
        completion: @escaping (Result<LocalFirmwareInfo, FirmwareError>) -> Void
    ) {
        let taskId = "\(identifier.storageKey)_\(firmware.versionName)"
        progressHandlers[taskId] = progress
        
        guard let urlString = firmware.effectiveFirmwareUrl, let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 检查是否已下载
        if let downloaded = getDownloadedFirmware(for: identifier),
           downloaded.versionName == firmware.versionName,
           fileManager.fileExists(atPath: downloaded.filePath) {
            print("固件已存在 [\(identifier)]，使用本地文件")
            completion(.success(downloaded))
            return
        }
        
        print("开始下载固件 [\(identifier)]: \(firmware.versionName)")
        
        let request = URLRequest(url: url)
        let downloadTask = urlSession.downloadTask(with: request) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            self.progressHandlers.removeValue(forKey: taskId)
            
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.downloadFailed)) }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async { completion(.failure(.downloadFailed)) }
                return
            }
            
            do {
                let (destinationURL, fileSize) = try self.saveFirmwareFile(
                    from: tempURL,
                    firmware: firmware,
                    identifier: identifier
                )
                
                let localInfo = LocalFirmwareInfo(
                    versionName: firmware.versionName,
                    downloadURL: urlString,
                    forceUpdate: firmware.forceUpdate,
                    filePath: destinationURL.path,
                    downloadDate: Date(),
                    fileSize: fileSize,
                    deviceType: identifier.mainType.deviceType,
                    firmwareId: "\(identifier.storageKey)_\(firmware.versionName)_\(Date().timeIntervalSince1970)",
                    firmwareType: nil,
                    hardwareModel: firmware.hardwareModel,
                    versionCode: firmware.versionCode,
                    firmwareMd5: nil,
                    isNewApiFormat: firmware.isNewApiFormat
                )
                
                try self.saveDownloadedFirmwareInfo(localInfo, for: identifier)
                self.updateStoredVersion(firmware.versionName, for: identifier)
                
                print("✅ 固件下载完成 [\(identifier)]: \(firmware.versionName)")
                DispatchQueue.main.async { completion(.success(localInfo)) }
                
            } catch {
                print("❌ 保存文件失败 [\(identifier)]: \(error)")
                DispatchQueue.main.async { completion(.failure(.fileSaveFailed)) }
            }
        }
        
        downloadTasks[taskId] = downloadTask
        downloadTask.resume()
    }
    
    // MARK: - 私有方法
    private func getFirmwareDirectory(for identifier: FirmwareIdentifier) throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var firmwareDirectory = documentsDirectory.appendingPathComponent(FirmwareConstants.firmwareDirectory)
        
        // wb02 设备按子类型分子目录
        if identifier.mainType == .wb02, let subType = identifier.subType {
            firmwareDirectory = firmwareDirectory.appendingPathComponent(identifier.mainType.directoryName)
            firmwareDirectory = firmwareDirectory.appendingPathComponent(subType.rawValue.capitalized)
        } else if identifier.mainType != .wb02 {
            firmwareDirectory = firmwareDirectory.appendingPathComponent(identifier.mainType.directoryName)
        }
        
        if !fileManager.fileExists(atPath: firmwareDirectory.path) {
            try fileManager.createDirectory(at: firmwareDirectory, withIntermediateDirectories: true)
        }
        
        return firmwareDirectory
    }
    
    private func saveFirmwareFile(
        from tempURL: URL,
        firmware: FirmwareUpdateData,
        identifier: FirmwareIdentifier
    ) throws -> (URL, Int) {
        let firmwareDirectory = try getFirmwareDirectory(for: identifier)
        
        // 清理该目录下的旧固件
        try cleanupOldFirmwares(in: firmwareDirectory, keep: firmware.versionName)
        
        let fileName = firmware.getFirmwareFileName()
        let destinationURL = firmwareDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        
        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        
        return (destinationURL, fileSize)
    }
    
    private func cleanupOldFirmwares(in directory: URL, keep version: String) throws {
        let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    private func getDownloadedInfoKey(for identifier: FirmwareIdentifier) -> String {
        if let subType = identifier.subType {
            return subType.getDownloadedInfoKey(for: identifier.mainType)
        }
        return identifier.mainType.getDownloadedInfoKey()
    }
    
    private func saveDownloadedFirmwareInfo(_ info: LocalFirmwareInfo, for identifier: FirmwareIdentifier) throws {
        let key = getDownloadedInfoKey(for: identifier)
        let data = try JSONEncoder().encode(info)
        userDefaults.set(data, forKey: key)
        userDefaults.synchronize()
    }
    
    private func searchFirmwareFile(for identifier: FirmwareIdentifier, version: String) -> URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let firmwareDir = documentsURL.appendingPathComponent(FirmwareConstants.firmwareDirectory)
        let searchPattern = "_V\(version).bin"
        
        let enumerator = fileManager.enumerator(at: firmwareDir, includingPropertiesForKeys: nil)
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent.contains(searchPattern) {
                return fileURL
            }
        }
        
        return nil
    }
    
    private func createFirmwareUpdateData(from firmwareData: FirmwareData, identifier: FirmwareIdentifier) -> FirmwareUpdateData {
        return FirmwareUpdateData(
            versionCode: firmwareData.versionCode ?? 0,
            versionName: firmwareData.versionName ?? "",
            firmwareUrl: firmwareData.effectiveFirmwareUrl,
            description: "",
            forceUpdate: firmwareData.forceUpdate ?? false,
            releaseTime: "",
            hardwareModel: firmwareData.hardwareModel ?? getHardwareModel(for: identifier),
            deviceType: identifier.mainType.deviceType,
            firmwareFileAttributeList: firmwareData.firmwareFileAttributeList?.map { attr in
                FirmwareFileAttribute(
                    firmwareUrl: attr.firmwareUrl ?? "",
                    firmwareSize: attr.firmwareSize ?? 0,
                    firmwareMd5: attr.firmwareMd5 ?? "",
                    firmwareType: attr.firmwareType ?? 0
                )
            }
        )
    }
    
    // MARK: - 版本比较
    public func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let components1 = version1.split(separator: ".").compactMap { Int($0) }
        let components2 = version2.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(components1.count, components2.count)
        
        for i in 0..<maxCount {
            let v1 = i < components1.count ? components1[i] : 0
            let v2 = i < components2.count ? components2[i] : 0
            
            if v1 > v2 { return .orderedDescending }
            if v1 < v2 { return .orderedAscending }
        }
        
        return .orderedSame
    }
    
    // MARK: - 清理方法
    public func clearFirmware(for identifier: FirmwareIdentifier?) {
        if let identifier = identifier {
            userDefaults.removeObject(forKey: getDownloadedInfoKey(for: identifier))
            userDefaults.removeObject(forKey: "\(identifier.storageKey)_current_version")
            
            do {
                let directory = try getFirmwareDirectory(for: identifier)
                try cleanupOldFirmwares(in: directory, keep: "")
                print("已清理 [\(identifier)] 固件文件")
            } catch {
                print("清理 [\(identifier)] 失败: \(error)")
            }
        } else {
            // 清理所有
            for type in [FirmwareType.base, FirmwareType.prototype, FirmwareType.wb02] {
                for identifier in getAllFirmwareIdentifiers(for: type) {
                    clearFirmware(for: identifier)
                }
            }
        }
    }
}
