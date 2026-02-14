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
    // 检查更新（使用PersonalViewModel）
    func checkForUpdates(hardwareModel: String, completion: @escaping (Result<FirmwareUpdateData?, FirmwareError>) -> Void)
    
    // 下载固件
    func downloadFirmware(_ firmware: FirmwareUpdateData,
                         progress: ((Double) -> Void)?,
                         completion: @escaping (Result<LocalFirmwareInfo, FirmwareError>) -> Void)
    
    // 本地版本管理
    func getCurrentStoredVersion() -> String
    func updateStoredVersion(_ versionName: String)
    func getHardwareModel() -> String
    func saveHardwareModel(_ model: String)
    
    // 本地固件管理
    func getDownloadedFirmware() -> LocalFirmwareInfo?
    func getDownloadedFirmwarePath() -> URL?
    func isFirmwareDownloaded() -> Bool
    
    // 版本比较
    func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult
    
    // 清理
    func clearFirmwareFile()
}

// MARK: - 固件管理器实现
public class FirmwareManager: FirmwareManagerProtocol {
    public static let shared = FirmwareManager()
    
    // MARK: - 私有属性
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    private var downloadTask: URLSessionDownloadTask?
    private let urlSession: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - 硬件型号管理
    public func getHardwareModel() -> String {
        return userDefaults.string(forKey: FirmwareConstants.hardwareModelKey) ?? FirmwareConstants.defaultHardwareModel
    }
    
    func saveHardwareModel(_ model: String) {
        userDefaults.set(model, forKey: FirmwareConstants.hardwareModelKey)
        userDefaults.synchronize()
        print("保存硬件型号: \(model)")
    }
    
    // MARK: - 版本管理
    public func getCurrentStoredVersion() -> String {
        return userDefaults.string(forKey: FirmwareConstants.currentVersionKey) ?? FirmwareConstants.defaultVersion
    }
    
    func updateStoredVersion(_ versionName: String) {
        userDefaults.set(versionName, forKey: FirmwareConstants.currentVersionKey)
        userDefaults.synchronize()
        print("更新存储版本: \(versionName)")
    }
    
    func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
        let components1 = version1.split(separator: ".").compactMap { Int($0) }
        let components2 = version2.split(separator: ".").compactMap { Int($0) }
        
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
    
    // MARK: - 检查更新（核心方法）
    func checkForUpdates(hardwareModel: String, completion: @escaping (Result<FirmwareUpdateData?, FirmwareError>) -> Void) {
        let currentVersion = getCurrentStoredVersion()
        
        print("检查固件更新 - 设备类型: 2, 硬件型号: \(hardwareModel), 当前版本: \(currentVersion)")
        
        // 创建PersonalServer
        let personalService = PersonalServer()
        
        // 创建请求模型
        let model = DeviceFirmwareModel(
            deviceType: 2,
            versionCode: currentVersion,
            hardwareModel: hardwareModel
        )
        
        // 直接调用服务层
        personalService.getDeviceFirmware(model) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                do {
                    let baseResponse = try JSONDecoder().decode(BaseResponse<FirmwareData>.self, from: response.data)
                    
                    if baseResponse.success, let firmwareData = baseResponse.data {
                        // 检查是否有版本信息
                        if let versionName = firmwareData.versionName,
                           !versionName.isEmpty {
                            
                            // 转换为FirmwareUpdateData
                            let updateData = FirmwareUpdateData(
                                versionCode: firmwareData.versionCode ?? 0,
                                versionName: versionName,
                                firmwareUrl: firmwareData.firmwareUrl ?? "",
                                description: "",
                                forceUpdate: firmwareData.forceUpdate ?? false,
                                releaseTime: "",
                                hardwareModel: firmwareData.hardwareModel,
                                deviceType: 2
                            )
                            
                            // 比较版本
                            if self.compareVersions(versionName, currentVersion) == .orderedDescending {
                                print("✅ 发现新版本: \(versionName) > \(currentVersion)")
                                
                                // 保存最新版本信息
                                let latestKey = "\(FirmwareConstants.currentVersionKey)_2"
                                self.userDefaults.set(versionName, forKey: latestKey)
                                
                                completion(.success(updateData))
                            } else {
                                print("ℹ️ 没有新版本或版本相同")
                                completion(.success(nil))
                            }
                        } else {
                            print("ℹ️ 没有新版本数据")
                            completion(.success(nil))
                        }
                    } else {
                        // 服务器返回了成功，但没有数据，说明已是最新版本
                        print("ℹ️ 当前已是最新版本")
                        completion(.success(nil))
                    }
                } catch {
                    print("❌ 数据解析失败: \(error)")
                    completion(.failure(.versionParseError))
                }
                
            case .failure(let error):
                print("❌ 网络请求失败: \(error)")
                completion(.failure(.fileSaveFailed))
            }
        }
        
    }
    
    // MARK: - 下载固件
    func downloadFirmware(_ firmware: FirmwareUpdateData,
                         progress: ((Double) -> Void)? = nil,
                         completion: @escaping (Result<LocalFirmwareInfo, FirmwareError>) -> Void) {
        
        // 检查是否已下载相同版本
        if let downloadedFirmware = getDownloadedFirmware(),
           downloadedFirmware.versionName == firmware.versionName {
            print("固件已下载，使用本地文件: \(firmware.versionName)")
            completion(.success(downloadedFirmware))
            return
        }
        
        guard let url = URL(string: firmware.firmwareUrl) else {
            completion(.failure(.invalidURL))
            return
        }
        
        print("开始下载固件: \(firmware.versionName)")
        print("下载URL: \(firmware.firmwareUrl)")
        
        downloadTask = urlSession.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("下载失败: \(error)")
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
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completion(.failure(.downloadFailed))
                }
                return
            }
            
            // 保存文件到本地
            do {
                let (destinationURL, fileSize) = try self.saveDownloadedFirmware(from: tempURL, firmware: firmware)
                
                // 创建本地固件信息
                let localInfo = LocalFirmwareInfo(
                    versionName: firmware.versionName,
                    downloadURL: firmware.firmwareUrl,
                    forceUpdate: firmware.forceUpdate,
                    filePath: destinationURL.path,
                    downloadDate: Date(),
                    fileSize: fileSize,
                    deviceType: 2,
                    firmwareId: "",
                )
                
                // 保存下载记录
                try self.saveDownloadedFirmwareInfo(localInfo)
                
                print("固件下载完成: \(firmware.versionName), 大小: \(fileSize) bytes")
                
                DispatchQueue.main.async {
                    completion(.success(localInfo))
                }
            } catch {
                print("保存文件失败: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(.fileSaveFailed))
                }
            }
        }
        
        downloadTask?.resume()
    }
    
    // MARK: - 文件管理
    private func saveDownloadedFirmware(from tempURL: URL, firmware: FirmwareUpdateData) throws -> (URL, Int) {
        let firmwareDirectory = try getFirmwareDirectory()
        
        // 清理旧文件
        try clearFirmwareFiles(in: firmwareDirectory)
        
        // 使用简单文件名  TX035_V1223
        let fileName = "TX035_V\(firmware.versionName).bin"
        let destinationURL = firmwareDirectory.appendingPathComponent(fileName)
        
        // 移动文件
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        
        // 获取文件大小
        let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        
        return (destinationURL, fileSize)
    }
    
    private func getFirmwareDirectory() throws -> URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let firmwareDirectory = documentsDirectory.appendingPathComponent(FirmwareConstants.firmwareDirectory)
        
        if !fileManager.fileExists(atPath: firmwareDirectory.path) {
            try fileManager.createDirectory(at: firmwareDirectory,
                                          withIntermediateDirectories: true,
                                          attributes: nil)
        }
        
        return firmwareDirectory
    }
    
    // MARK: - 本地固件管理
    public func getDownloadedFirmware() -> LocalFirmwareInfo? {
        guard let data = userDefaults.data(forKey: FirmwareConstants.firmwareDownloadedKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(LocalFirmwareInfo.self, from: data)
    }
    
    func getDownloadedFirmwarePath() -> URL? {
        guard let firmwareInfo = getDownloadedFirmware(),
              fileManager.fileExists(atPath: firmwareInfo.filePath) else {
            return nil
        }
        
        return URL(fileURLWithPath: firmwareInfo.filePath)
    }
    
    public func isFirmwareDownloaded() -> Bool {
        return getDownloadedFirmwarePath() != nil
    }
    
    private func saveDownloadedFirmwareInfo(_ firmwareInfo: LocalFirmwareInfo) throws {
        let data = try JSONEncoder().encode(firmwareInfo)
        userDefaults.set(data, forKey: FirmwareConstants.firmwareDownloadedKey)
        userDefaults.synchronize()
        
        print("保存固件信息: \(firmwareInfo.versionName)")
    }
    
    // MARK: - 清理
    func clearFirmwareFile() {
        // 清理本地存储信息
        userDefaults.removeObject(forKey: FirmwareConstants.firmwareDownloadedKey)
        
        // 清理文件
        do {
            let firmwareDirectory = try getFirmwareDirectory()
            try clearFirmwareFiles(in: firmwareDirectory)
        } catch {
            print("清理固件文件失败: \(error)")
        }
        
        print("已清理所有固件文件")
    }
    
    private func clearFirmwareFiles(in directory: URL) throws {
        let fileURLs = try fileManager.contentsOfDirectory(at: directory,
                                                         includingPropertiesForKeys: nil,
                                                         options: [])
        
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
    }
    
    // MARK: - 辅助方法
    func getLatestDownloadedVersion() -> String? {
        return getDownloadedFirmware()?.versionName
    }
}
