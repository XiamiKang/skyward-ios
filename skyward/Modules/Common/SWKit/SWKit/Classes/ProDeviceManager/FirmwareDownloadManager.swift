//
//  FirmwareDownloadStatus.swift
//  Pods
//
//  Created by yifan kang on 2025/12/25.
//


import Foundation
import Combine

// MARK: - 固件下载状态枚举
public enum FirmwareDownloadStatus {
    case idle
    case downloading(progress: Double)
    case paused(progress: Double)
    case completed(fileURL: URL)
    case failed(error: Error)
}

// MARK: - 固件下载错误
public enum FirmwareDownloadError: LocalizedError {
    case invalidURL
    case fileAlreadyExists
    case downloadFailed(String)
    case fileSaveFailed
    case networkError(Error)
    case noFirmwareData
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "固件URL无效"
        case .fileAlreadyExists:
            return "固件文件已存在"
        case .downloadFailed(let reason):
            return "下载失败: \(reason)"
        case .fileSaveFailed:
            return "文件保存失败"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .noFirmwareData:
            return "没有可用的固件数据"
        }
    }
}

public struct FirmwareData: Codable {
    public let versionCode: Int?                  // 设备版本号
    public let versionName: String?               // 设备版本名称
    public let firmwareUrl: String?               // 设备固件地址
    public let forceUpdate: Bool?                 // 是否强制更新
    public let hardwareModel: String?             // 设备型号
}

// MARK: - 固件下载管理器
public class FirmwareDownloadManager: NSObject, ObservableObject {
    
    // MARK: - 单例
    public static let shared = FirmwareDownloadManager()
    
    // MARK: - 发布属性
    @Published public var downloadStatus: FirmwareDownloadStatus = .idle
    @Published public var currentFirmwareData: FirmwareData?
    
    // MARK: - 私有属性
    private var downloadTask: URLSessionDownloadTask?
    private var resumeData: Data?
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300 // 5分钟超时
        configuration.timeoutIntervalForResource = 1800 // 30分钟资源超时
        configuration.httpMaximumConnectionsPerHost = 1
        configuration.allowsCellularAccess = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    private let fileManager = FileManager.default
    
    // MARK: - 初始化
    private override init() {
        super.init()
    }
    
    // MARK: - 公共方法
    
    /// 开始下载固件
    /// - Parameters:
    ///   - firmwareData: 固件数据
    ///   - forceDownload: 是否强制重新下载（如果文件已存在）
    public func downloadFirmware(_ firmwareData: FirmwareData, forceDownload: Bool = false) {
        guard let firmwareUrlString = firmwareData.firmwareUrl,
              let firmwareURL = URL(string: firmwareUrlString) else {
            downloadStatus = .failed(error: FirmwareDownloadError.invalidURL)
            return
        }
        
        self.currentFirmwareData = firmwareData
        
        // 检查本地是否已存在该固件文件
        if let localFileURL = getLocalFirmwareFileURL(firmwareData: firmwareData),
           fileManager.fileExists(atPath: localFileURL.path) {
            
            if forceDownload {
                // 强制重新下载，先删除旧文件
                try? fileManager.removeItem(at: localFileURL)
            } else {
                // 文件已存在，直接返回成功
                downloadStatus = .completed(fileURL: localFileURL)
                return
            }
        }
        
        // 开始下载
        let request = URLRequest(url: firmwareURL)
        downloadTask = urlSession.downloadTask(with: request)
        downloadTask?.resume()
        downloadStatus = .downloading(progress: 0.0)
    }
    
    /// 暂停下载
    public func pauseDownload() {
        downloadTask?.cancel { [weak self] resumeData in
            guard let self = self else { return }
            
            if let resumeData = resumeData {
                self.resumeData = resumeData
                if case .downloading(let progress) = self.downloadStatus {
                    self.downloadStatus = .paused(progress: progress)
                }
            } else {
                self.downloadStatus = .failed(error: FirmwareDownloadError.downloadFailed("暂停失败"))
            }
        }
    }
    
    /// 恢复下载
    public func resumeDownload() {
        guard let resumeData = resumeData else {
            downloadStatus = .failed(error: FirmwareDownloadError.downloadFailed("没有可恢复的下载数据"))
            return
        }
        
        downloadTask = urlSession.downloadTask(withResumeData: resumeData)
        downloadTask?.resume()
        if case .paused(let progress) = downloadStatus {
            downloadStatus = .downloading(progress: progress)
        }
        self.resumeData = nil
    }
    
    /// 取消下载
    public func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        resumeData = nil
        downloadStatus = .idle
        currentFirmwareData = nil
    }
    
    /// 获取本地固件文件URL
    /// - Parameter firmwareData: 固件数据
    /// - Returns: 本地文件URL（如果存在）
    public func getLocalFirmwareFileURL(firmwareData: FirmwareData) -> URL? {
        guard let hardwareModel = firmwareData.hardwareModel,
              let versionCode = firmwareData.versionCode else {
            return nil
        }
        
        let fileName = "\(hardwareModel)_\(versionCode).bin"
        return getFirmwareDirectoryURL()?.appendingPathComponent(fileName)
    }
    
    /// 检查固件文件是否已存在
    /// - Parameter firmwareData: 固件数据
    /// - Returns: 文件是否已存在
    public func firmwareFileExists(firmwareData: FirmwareData) -> Bool {
        guard let localFileURL = getLocalFirmwareFileURL(firmwareData: firmwareData) else {
            return false
        }
        return fileManager.fileExists(atPath: localFileURL.path)
    }
    
    /// 清理旧的固件文件（保留最新的3个）
    public func cleanupOldFirmwareFiles() {
        guard let firmwareDirectory = getFirmwareDirectoryURL(),
              let files = try? fileManager.contentsOfDirectory(at: firmwareDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        // 按创建时间排序
        let sortedFiles = files.sorted { url1, url2 in
            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
            return date1 > date2
        }
        
        // 删除除最新3个以外的所有文件
        if sortedFiles.count > 3 {
            for file in sortedFiles[3...] {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    /// 删除特定的固件文件
    /// - Parameter firmwareData: 固件数据
    public func deleteFirmwareFile(firmwareData: FirmwareData) throws {
        guard let localFileURL = getLocalFirmwareFileURL(firmwareData: firmwareData) else {
            throw FirmwareDownloadError.invalidURL
        }
        
        if fileManager.fileExists(atPath: localFileURL.path) {
            try fileManager.removeItem(at: localFileURL)
        }
    }
    
    /// 获取固件文件大小
    /// - Parameter firmwareData: 固件数据
    /// - Returns: 文件大小（字节），如果文件不存在返回nil
    public func getFirmwareFileSize(firmwareData: FirmwareData) -> Int64? {
        guard let localFileURL = getLocalFirmwareFileURL(firmwareData: firmwareData),
              fileManager.fileExists(atPath: localFileURL.path),
              let attributes = try? fileManager.attributesOfItem(atPath: localFileURL.path),
              let fileSize = attributes[.size] as? NSNumber else {
            return nil
        }
        return fileSize.int64Value
    }
    
    // MARK: - 私有方法
    
    /// 获取固件存储目录URL
    private func getFirmwareDirectoryURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let firmwareDirectory = documentsDirectory.appendingPathComponent("Firmware")
        
        // 创建目录（如果不存在）
        if !fileManager.fileExists(atPath: firmwareDirectory.path) {
            try? fileManager.createDirectory(at: firmwareDirectory, withIntermediateDirectories: true)
        }
        
        return firmwareDirectory
    }
    
    /// 生成唯一的文件名
    private func generateUniqueFileName(firmwareData: FirmwareData, response: URLResponse) -> String {
        let originalName = response.suggestedFilename ?? "firmware.bin"
        let fileExtension = (originalName as NSString).pathExtension
        
        if let hardwareModel = firmwareData.hardwareModel,
           let versionCode = firmwareData.versionCode {
            return "\(hardwareModel)_\(versionCode).\(fileExtension)"
        }
        
        // 如果没有型号和版本号，使用时间戳
        let timestamp = Int(Date().timeIntervalSince1970)
        return "firmware_\(timestamp).\(fileExtension)"
    }
}

// MARK: - URLSessionDownloadDelegate
extension FirmwareDownloadManager: URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0.0
        DispatchQueue.main.async {
            self.downloadStatus = .downloading(progress: progress)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let firmwareData = currentFirmwareData else {
            DispatchQueue.main.async {
                self.downloadStatus = .failed(error: FirmwareDownloadError.noFirmwareData)
            }
            return
        }
        
        guard let response = downloadTask.response as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            DispatchQueue.main.async {
                self.downloadStatus = .failed(error: FirmwareDownloadError.downloadFailed("服务器响应错误"))
            }
            return
        }
        
        guard let firmwareDirectory = getFirmwareDirectoryURL() else {
            DispatchQueue.main.async {
                self.downloadStatus = .failed(error: FirmwareDownloadError.fileSaveFailed)
            }
            return
        }
        
        let fileName = generateUniqueFileName(firmwareData: firmwareData, response: response)
        let destinationURL = firmwareDirectory.appendingPathComponent(fileName)
        
        do {
            // 如果目标文件已存在，先删除
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // 移动文件到目标位置
            try fileManager.moveItem(at: location, to: destinationURL)
            
            DispatchQueue.main.async {
                self.downloadStatus = .completed(fileURL: destinationURL)
                self.cleanupOldFirmwareFiles() // 清理旧文件
            }
        } catch {
            DispatchQueue.main.async {
                self.downloadStatus = .failed(error: FirmwareDownloadError.fileSaveFailed)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            // 如果不是用户取消的错误
            if nsError.code != NSURLErrorCancelled {
                DispatchQueue.main.async {
                    self.downloadStatus = .failed(error: FirmwareDownloadError.networkError(error))
                }
            }
        }
    }
}
