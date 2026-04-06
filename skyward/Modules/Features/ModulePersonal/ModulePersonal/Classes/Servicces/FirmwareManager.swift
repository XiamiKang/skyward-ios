//
//  FirmwareManager.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/1/13.
//

import Combine
import Foundation
import SWKit

// MARK: - 固件管理器协议
protocol FirmwareManagerProtocol {
    // 检查更新（指定固件类型）
    func checkForUpdates(firmwareType: FirmwareType,
                        hardwareModel: String,
                        completion: @escaping (Result<FirmwareUpdateData?, FirmwareError>) -> Void)
    
    // 下载固件（指定固件类型）
    func downloadFirmware(_ firmware: FirmwareUpdateData,
                         firmwareType: FirmwareType,
                         progress: ((Double) -> Void)?,
                         completion: @escaping (Result<LocalFirmwareInfo, FirmwareError>) -> Void)
    
    // 本地版本管理（指定固件类型）
    func getCurrentStoredVersion(for type: FirmwareType) -> String
    func updateStoredVersion(_ versionName: String, for type: FirmwareType)
    func getHardwareModel(for type: FirmwareType) -> String
    func saveHardwareModel(_ model: String, for type: FirmwareType)
    
    // 本地固件管理（指定固件类型）
    func getDownloadedFirmware(for type: FirmwareType) -> LocalFirmwareInfo?
    func getDownloadedFirmwarePath(for type: FirmwareType) -> URL?
    func isFirmwareDownloaded(for type: FirmwareType) -> Bool
    
    // 版本比较
    func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult
    
    // 清理（指定固件类型或全部）
    func clearFirmwareFile(for type: FirmwareType?)
    func clearAllFirmwareFiles()
}

// MARK: - 固件管理器实现
public class FirmwareManager: FirmwareManagerProtocol {
    public static let shared = FirmwareManager()
    
    // MARK: - 私有属性
    private let fileManager = FileManager.default
    private let userDefaults: UserDefaults
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]  // 支持多个下载任务
    private let urlSession: URLSession
    private var progressHandlers: [String: (Double) -> Void] = [:]
    
    // MARK: - 初始化
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - 硬件型号管理
    public func getHardwareModel(for type: FirmwareType) -> String {
        return userDefaults.string(forKey: type.getHardwareModelKey()) ?? type.getDefaultHardwareModel()
    }
    
    func saveHardwareModel(_ model: String, for type: FirmwareType) {
        userDefaults.set(model, forKey: type.getHardwareModelKey())
        userDefaults.synchronize()
        print("保存硬件型号 [\(type)]: \(model)")
    }
    
    // MARK: - 版本管理
    public func getCurrentStoredVersion(for type: FirmwareType) -> String {
        return userDefaults.string(forKey: type.getCurrentVersionKey()) ?? type.getDefaultVersion()
    }
    
    func updateStoredVersion(_ versionName: String, for type: FirmwareType) {
        userDefaults.set(versionName, forKey: type.getCurrentVersionKey())
        userDefaults.synchronize()
        print("更新存储版本 [\(type)]: \(versionName)")
    }
    
    func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        guard !version1.isEmpty, !version2.isEmpty else {
            return version1.isEmpty ? .orderedAscending : .orderedDescending
        }
        
        let components1 = version1.split(separator: ".").compactMap { Int($0) }
        let components2 = version2.split(separator: ".").compactMap { Int($0) }
        
        guard !components1.isEmpty, !components2.isEmpty else {
            return .orderedSame
        }
        
        let maxCount = max(components1.count, components2.count)
        
        for i in 0..<maxCount {
            let v1 = i < components1.count ? components1[i] : 0
            let v2 = i < components2.count ? components2[i] : 0
            
            if v1 > v2 {
                return .orderedDescending
            } else if v1 < v2 {
                return .orderedAscending
            }
        }
        
        return .orderedSame
    }
    
    // MARK: - 检查更新（支持双固件）
    func checkForUpdates(firmwareType: FirmwareType = .base,
                        hardwareModel: String,
                        completion: @escaping (Result<FirmwareUpdateData?, FirmwareError>) -> Void) {
        
        let currentVersion = getCurrentStoredVersion(for: firmwareType)
        
        print("检查固件更新 [\(firmwareType)] - 设备类型: \(firmwareType.deviceType), 硬件型号: \(hardwareModel), 当前版本: \(currentVersion)")
        
        // 创建PersonalServer
        let personalService = PersonalServer()
        
        // 创建请求模型
        let model = Wb02DeviceFirmwareModel(
            versionCode: currentVersion,
            hardwareModel: hardwareModel
        )
        
        personalService.getProDeviceFirmware(model) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                do {
                    print("宽带获取固件信息----\(response)")
                    let baseResponse = try JSONDecoder().decode(BaseResponse<FirmwareData>.self, from: response.data)
                    print("宽带获取固件信息----\(baseResponse)")
                    if baseResponse.success {
                        if let firmwareData = baseResponse.data,
                           let versionName = firmwareData.versionName,
                           !versionName.isEmpty {
                            
                            let updateData = FirmwareUpdateData(
                                versionCode: firmwareData.versionCode ?? 0,
                                versionName: versionName,
                                firmwareUrl: firmwareData.firmwareUrl ?? "",
                                description: "",
                                forceUpdate: firmwareData.forceUpdate ?? false,
                                releaseTime: "",
                                hardwareModel: firmwareData.hardwareModel,
                                deviceType: firmwareType.deviceType,
                                firmwareFileAttributeList: nil
                            )
                            
                            // 比较版本
                            if self.compareVersions(versionName, currentVersion) == .orderedDescending {
                                print("✅ 发现新版本 [\(firmwareType)]: \(versionName)")
                                
                                // 检查本地是否已下载
                                if let downloaded = self.getDownloadedFirmware(for: firmwareType),
                                   downloaded.versionName == versionName {
                                    print("ℹ️ 新版本已下载 [\(firmwareType)]")
                                }
                                
                                completion(.success(updateData))
                            } else {
                                print("ℹ️ 当前已是最新版本 [\(firmwareType)]: \(currentVersion)")
                                completion(.success(nil))
                            }
                        } else {
                            print("ℹ️ 没有新版本数据 [\(firmwareType)]")
                            completion(.success(nil))
                        }
                    } else {
                        print("ℹ️ 服务器返回失败 [\(firmwareType)]: \(baseResponse.msg)")
                        completion(.success(nil))
                    }
                } catch {
                    print("❌ 数据解析失败 [\(firmwareType)]: \(error)")
                    completion(.failure(.versionParseError))
                }
                
            case .failure(let error):
                print("❌ 网络请求失败 [\(firmwareType)]: \(error)")
                completion(.failure(.downloadFailed))
            }
        }
    }
    
    // MARK: - 下载固件（支持双固件）
    func downloadFirmware(_ firmware: FirmwareUpdateData,
                         firmwareType: FirmwareType = .base,
                         progress: ((Double) -> Void)? = nil,
                         completion: @escaping (Result<LocalFirmwareInfo, FirmwareError>) -> Void) {
        
        let taskId = "\(firmwareType.rawValue)_\(firmware.versionName)"
        progressHandlers[taskId] = progress
        
        // 检查URL
        guard let url = URL(string: firmware.firmwareUrl ?? "") else {
            completion(.failure(.invalidURL))
            return
        }
        
        // 检查本地版本
        if let downloadedFirmware = getDownloadedFirmware(for: firmwareType) {
            if downloadedFirmware.versionName == firmware.versionName {
                // 验证文件是否存在
                if fileManager.fileExists(atPath: downloadedFirmware.filePath) {
                    print("固件已下载 [\(firmwareType)]，使用本地文件: \(firmware.versionName)")
                    completion(.success(downloadedFirmware))
                    return
                } else {
                    // 文件不存在，清理记录
                    userDefaults.removeObject(forKey: firmwareType.getDownloadedInfoKey())
                }
            }
        }
        
        print("开始下载固件 [\(firmwareType)]: \(firmware.versionName)")
        print("下载URL: \(firmware.firmwareUrl)")
        
        let request = URLRequest(url: url)
        let downloadTask = urlSession.downloadTask(with: request) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            // 清理进度回调
            self.progressHandlers.removeValue(forKey: taskId)
            
            if let error = error {
                print("下载失败 [\(firmwareType)]: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed))
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed))
                }
                return
            }
            
            // 验证HTTP响应
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(.downloadFailed))
                    }
                    return
                }
            }
            
            // 保存文件
            do {
                let (destinationURL, fileSize) = try self.saveDownloadedFirmware(
                    from: tempURL,
                    firmware: firmware,
                    firmwareType: firmwareType
                )
                
                // 生成固件ID
                let firmwareId = "\(firmware.hardwareModel ?? "TX035")_\(firmware.versionName)_\(Date().timeIntervalSince1970)"
                
                let localInfo = LocalFirmwareInfo(
                    versionName: firmware.versionName,
                    downloadURL: firmware.firmwareUrl ?? "",
                    forceUpdate: firmware.forceUpdate,
                    filePath: destinationURL.path,
                    downloadDate: Date(),
                    fileSize: fileSize,
                    deviceType: firmwareType.deviceType,
                    firmwareId: firmwareId
                )
                
                // 保存下载记录
                try self.saveDownloadedFirmwareInfo(localInfo, for: firmwareType)
                
                // 更新当前版本
                self.updateStoredVersion(firmware.versionName, for: firmwareType)
                
                print("✅ 固件下载完成 [\(firmwareType)]: \(firmware.versionName), 大小: \(fileSize) bytes")
                
                DispatchQueue.main.async {
                    completion(.success(localInfo))
                }
            } catch {
                print("❌ 保存文件失败 [\(firmwareType)]: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.fileSaveFailed))
                }
            }
        }
        
        downloadTasks[taskId] = downloadTask
        downloadTask.resume()
    }
    
    // MARK: - 文件管理（按类型分离）
    private func getFirmwareDirectory(for type: FirmwareType) throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let firmwareDirectory = documentsDirectory
            .appendingPathComponent(FirmwareConstants.firmwareDirectory)
            .appendingPathComponent(type.directoryName)
        
        if !fileManager.fileExists(atPath: firmwareDirectory.path) {
            try fileManager.createDirectory(at: firmwareDirectory,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
        }
        
        return firmwareDirectory
    }
    
    private func saveDownloadedFirmware(from tempURL: URL,
                                       firmware: FirmwareUpdateData,
                                       firmwareType: FirmwareType) throws -> (URL, Int) {
        let firmwareDirectory = try getFirmwareDirectory(for: firmwareType)
        
        // 清理旧文件（只清理相同类型的）
        try cleanupOldFirmwares(in: firmwareDirectory, keep: firmware.versionName)
        
        // 生成文件名
        let hardwarePrefix = firmware.hardwareModel ?? firmwareType.getDefaultHardwareModel()
        let fileName = "\(hardwarePrefix)_V\(firmware.versionName).bin"
        let destinationURL = firmwareDirectory.appendingPathComponent(fileName)
        
        // 如果目标文件已存在，先删除
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // 移动文件
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        
        // 获取文件大小
        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        
        return (destinationURL, fileSize)
    }
    
    private func cleanupOldFirmwares(in directory: URL, keep currentVersion: String) throws {
        let fileURLs = try fileManager.contentsOfDirectory(at: directory,
                                                         includingPropertiesForKeys: nil,
                                                         options: [])
        
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - 本地固件管理（按类型）
    public func getDownloadedFirmware(for type: FirmwareType) -> LocalFirmwareInfo? {
        guard let data = userDefaults.data(forKey: type.getDownloadedInfoKey()) else {
            return nil
        }
        
        return try? JSONDecoder().decode(LocalFirmwareInfo.self, from: data)
    }
    
    func getDownloadedFirmwarePath(for type: FirmwareType) -> URL? {
        guard let firmwareInfo = getDownloadedFirmware(for: type) else {
            return nil
        }
        print("本地存储的固件数据：类型-\(type);数据-\(firmwareInfo)")
        
        // 获取当前应用的Documents目录
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // 从存储的完整路径中提取相对路径部分（从Documents之后开始）
        if let range = firmwareInfo.filePath.range(of: "/Documents/") {
            let relativePath = String(firmwareInfo.filePath[range.upperBound...])
            // 构建新的完整路径
            let newPath = documentsURL.appendingPathComponent(relativePath)
            
            print("重建的路径: \(newPath.path)")
            
            if FileManager.default.fileExists(atPath: newPath.path) {
                print("✓ 文件存在")
                return newPath
            } else {
                print("✗ 文件不存在于重建路径")
            }
        }
        
        // 如果上述方法失败，尝试在Firmware目录下搜索
        let firmwareDir = documentsURL.appendingPathComponent("Firmware")
        let fileName = (firmwareInfo.filePath as NSString).lastPathComponent
        
        // 递归搜索文件
        if let foundURL = searchForFile(name: fileName, in: firmwareDir) {
            return foundURL
        }
        
        return nil
    }
    
    func searchForFile(name: String, in directory: URL) -> URL? {
        let enumerator = FileManager.default.enumerator(at: directory,
                                                       includingPropertiesForKeys: nil,
                                                       options: [.skipsHiddenFiles])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent == name {
                print("在目录中找到文件: \(fileURL.path)")
                return fileURL
            }
        }
        
        return nil
    }

    
    public func isFirmwareDownloaded(for type: FirmwareType) -> Bool {
        return getDownloadedFirmwarePath(for: type) != nil
    }
    
    private func saveDownloadedFirmwareInfo(_ firmwareInfo: LocalFirmwareInfo, for type: FirmwareType) throws {
        let data = try JSONEncoder().encode(firmwareInfo)
        userDefaults.set(data, forKey: type.getDownloadedInfoKey())
        userDefaults.synchronize()
        
        print("保存固件信息 [\(type)]: \(firmwareInfo.versionName)")
    }
    
    // MARK: - 清理方法
    func clearFirmwareFile(for type: FirmwareType?) {
        if let type = type {
            // 清理指定类型
            userDefaults.removeObject(forKey: type.getDownloadedInfoKey())
            userDefaults.removeObject(forKey: type.getFilePathKey())
            
            do {
                let firmwareDirectory = try getFirmwareDirectory(for: type)
                try clearFirmwareFiles(in: firmwareDirectory)
                print("已清理 [\(type)] 固件文件")
            } catch {
                print("清理 [\(type)] 固件文件失败: \(error)")
            }
        } else {
            // 清理所有类型
            clearAllFirmwareFiles()
        }
    }
    
    func clearAllFirmwareFiles() {
        // 清理所有类型的UserDefaults
        for type in [FirmwareType.base, FirmwareType.prototype] {
            userDefaults.removeObject(forKey: type.getDownloadedInfoKey())
            userDefaults.removeObject(forKey: type.getFilePathKey())
            
            do {
                let firmwareDirectory = try getFirmwareDirectory(for: type)
                try clearFirmwareFiles(in: firmwareDirectory)
            } catch {
                print("清理 [\(type)] 固件文件失败: \(error)")
            }
        }
        
        print("已清理所有固件文件")
    }
    
    private func clearFirmwareFiles(in directory: URL) throws {
        guard fileManager.fileExists(atPath: directory.path) else { return }
        
        let fileURLs = try fileManager.contentsOfDirectory(at: directory,
                                                         includingPropertiesForKeys: nil,
                                                         options: [])
        
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - 取消下载
    func cancelDownload(for type: FirmwareType, version: String) {
        let taskId = "\(type.rawValue)_\(version)"
        downloadTasks[taskId]?.cancel()
        downloadTasks.removeValue(forKey: taskId)
        progressHandlers.removeValue(forKey: taskId)
    }
    
    func cancelAllDownloads() {
        downloadTasks.values.forEach { $0.cancel() }
        downloadTasks.removeAll()
        progressHandlers.removeAll()
    }
    
    // MARK: - 验证方法
    func validateLocalFirmware(for type: FirmwareType) -> Bool {
        guard let firmware = getDownloadedFirmware(for: type) else {
            return false
        }
        
        guard fileManager.fileExists(atPath: firmware.filePath) else {
            return false
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: firmware.filePath)
            let actualSize = attributes[.size] as? Int ?? 0
            return actualSize == firmware.fileSize
        } catch {
            return false
        }
    }
    
    func getFirmwareData(for type: FirmwareType) -> Data? {
        guard let path = getDownloadedFirmwarePath(for: type) else {
            return nil
        }
        
        return try? Data(contentsOf: path)
    }
    
    // MARK: - 获取所有固件信息
    func getAllFirmwareInfo() -> [FirmwareType: LocalFirmwareInfo?] {
        return [
            .base: getDownloadedFirmware(for: .base),
            .prototype: getDownloadedFirmware(for: .prototype)
        ]
    }
}
