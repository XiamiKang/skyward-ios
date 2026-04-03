//
//  POIDownloadManager.swift
//  Pods
//
//  Created by TXTS on 2025/12/31.
//

import Foundation
import Moya
import WCDBSwift
import Combine
import Network
import SWNetwork
import CommonCrypto

// MARK: - 公共兴趣点数据下载管理器
public class POIDownloadManager {
    public static let shared = POIDownloadManager()
    
    private let publicPOIService = PublicPOIService()
    private let databaseManager = POIDatabaseManager.shared
    private let operationQueue: DispatchQueue
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NWPathMonitor()
    private let fileManager = FileManager.default
    
    // 配置常量
    private struct Config {
        static let maxRetryCount = 3
        static let downloadBatchSize = 10000
        static let timeIntervalToReset: TimeInterval = 24 * 60 * 60 * 7 // 7天后重置状态
        
        // UserDefaults Keys
        static let downloadStateKey = "POIDownloadState"
        static let importStateKey = "POIImportState"
        static let downloadTaskInfoKey = "POIDownloadTaskInfo"
        static let importTaskInfoKey = "POIImportTaskInfo"
        static let lastDownloadTimeKey = "POILastDownloadTime"
        static let lastVersionKey = "POILastDownloadedVersion"
        static let lastFileMd5Key = "POILastFileMd5"
    }
    
    // 状态属性（使用 UserDefaults 持久化）
    private var downloadState: DownloadState {
        get {
            if let rawValue = userDefaults.string(forKey: Config.downloadStateKey),
               let state = DownloadState(rawValue: rawValue) {
                return state
            }
            return .notDownloaded
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Config.downloadStateKey)
            userDefaults.synchronize()
        }
    }
    
    private var importState: ImportState {
        get {
            if let rawValue = userDefaults.string(forKey: Config.importStateKey),
               let state = ImportState(rawValue: rawValue) {
                return state
            }
            return .notImported
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Config.importStateKey)
            userDefaults.synchronize()
        }
    }
    
    private var downloadTaskInfo: DownloadTaskInfo? {
        get {
            guard let data = userDefaults.data(forKey: Config.downloadTaskInfoKey) else { return nil }
            return try? JSONDecoder().decode(DownloadTaskInfo.self, from: data)
        }
        set {
            if let newValue = newValue {
                if let data = try? JSONEncoder().encode(newValue) {
                    userDefaults.set(data, forKey: Config.downloadTaskInfoKey)
                }
            } else {
                userDefaults.removeObject(forKey: Config.downloadTaskInfoKey)
            }
            userDefaults.synchronize()
        }
    }
    
    private var importTaskInfo: ImportTaskInfo? {
        get {
            guard let data = userDefaults.data(forKey: Config.importTaskInfoKey) else { return nil }
            return try? JSONDecoder().decode(ImportTaskInfo.self, from: data)
        }
        set {
            if let newValue = newValue {
                if let data = try? JSONEncoder().encode(newValue) {
                    userDefaults.set(data, forKey: Config.importTaskInfoKey)
                }
            } else {
                userDefaults.removeObject(forKey: Config.importTaskInfoKey)
            }
            userDefaults.synchronize()
        }
    }
    
    public var lastDownloadTime: Date? {
        get { return userDefaults.object(forKey: Config.lastDownloadTimeKey) as? Date }
        set {
            userDefaults.set(newValue, forKey: Config.lastDownloadTimeKey)
            userDefaults.synchronize()
        }
    }
    
    private init() {
        operationQueue = DispatchQueue(
            label: "com.poi.download.queue",
            qos: .utility,
            attributes: .concurrent
        )
        
        userDefaults = UserDefaults.standard
        
        // 启动时检查状态
        checkAndResetStaleStates()
    }
    
    // MARK: - 状态检查
    private func checkAndResetStaleStates() {
        // 检查下载状态
        if downloadState == .downloading {
            print("检测到上次下载未完成，重置下载状态")
            cleanupFailedDownload()
            downloadState = .notDownloaded
        }
        
        // 检查导入状态 - 需要验证文件是否存在
        if importState == .importing {
            print("检测到上次导入未完成，检查文件是否存在")
            
            if let taskInfo = importTaskInfo {
                // 动态获取 Documents 目录路径
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                let filePath = (documentsPath as NSString).appendingPathComponent(taskInfo.fileName)
                
                if fileManager.fileExists(atPath: filePath) {
                    print("文件存在，准备断点续导")
                    // 可以在这里更新 taskInfo 或使用动态路径
                    resumeImport()
                } else {
                    print("文件不存在，重置导入状态")
                    // 文件不存在，重置状态
                    importState = .notImported
                    importTaskInfo = nil
                    
                    // 同时检查下载状态
                    if downloadState == .downloaded {
                        print("文件丢失，下载状态也需要重置")
                        downloadState = .notDownloaded
                        downloadTaskInfo = nil
                        lastDownloadTime = nil
                    }
                }
            } else {
                print("没有导入任务信息，重置导入状态")
                importState = .notImported
            }
        }
    }
    
    // MARK: - 清理失败的下载
    private func cleanupFailedDownload() {
        // 删除临时文件
        if let taskInfo = downloadTaskInfo {
            let fileURL = URL(fileURLWithPath: taskInfo.localFilePath)
            try? fileManager.removeItem(at: fileURL)
        }
        downloadTaskInfo = nil
    }
    
    // MARK: - 启动下载
    public func startSilentDownload() {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查当前状态
            switch self.downloadState {
            case .downloading:
                print("下载正在进行中，跳过")
                return
                
            case .downloaded:
                print("已经下载完成，检查是否需要重置")
                self.checkAndResetStaleStates()
                return
                
            case .notDownloaded:
                print("未下载，开始下载流程")
                self.startDownloadProcess()
            }
        }
    }
    
    // MARK: - 手动刷新
    public func manualRefresh(completion: ((Bool) -> Void)? = nil) {
        operationQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 强制重置状态（但保留用户数据）
            self.downloadState = .notDownloaded
            self.importState = .notImported
            self.downloadTaskInfo = nil
            self.importTaskInfo = nil
            
            self.startDownloadProcess(completion: completion)
        }
    }
    
    // MARK: - 下载流程
    private func startDownloadProcess(completion: ((Bool) -> Void)? = nil) {
        startDownloadProcess(retryCount: 0, completion: completion)
    }
    
    // MARK: - 下载流程
    private func startDownloadProcess(retryCount: Int = 0, completion: ((Bool) -> Void)? = nil) {
        guard retryCount < Config.maxRetryCount else {
            print("达到最大重试次数")
            downloadState = .notDownloaded
            completion?(false)
            return
        }
        
        // 更新状态
        downloadState = .downloading
        let startTime = Date()
        
        print("开始下载POI数据文件 (尝试次数: \(retryCount + 1))")
        
        // 请求导出接口获取文件URL
        publicPOIService.getPublicPOIList { [weak self] result in
            guard let self = self else {
                completion?(false)
                return
            }
            
            switch result {
            case .success(let response):
                do {
                    let exportResponse = try JSONDecoder().decode(POIExportResponse.self, from: response.data)
                    
                    guard exportResponse.code == "00000" else {
                        print("服务器返回错误: \(exportResponse.msg)")
                        self.handleDownloadFailure(retryCount: retryCount, completion: completion)
                        return
                    }
                    
                    let exportData = exportResponse.data
                    
                    // 检查MD5是否与上次相同
                    let lastMd5 = self.userDefaults.string(forKey: Config.lastFileMd5Key)
                    let lastVersion = self.userDefaults.string(forKey: Config.lastVersionKey)
                    
                    if lastMd5 == exportData.fileMd5 && lastVersion == exportData.version {
                        print("文件版本和MD5与上次相同，无需下载")
                        self.downloadState = .downloaded
                        self.lastDownloadTime = Date()
                        completion?(true)
                        return
                    }
                    
                    // 下载文件（fileName将在下载完成后确定）
                    self.downloadFile(from: exportData.fileUrl, md5: exportData.fileMd5, version: exportData.version) { downloadResult in
                        switch downloadResult {
                        case .success(let localURL):
                            // 创建下载任务信息，使用下载完成的文件名
                            let fileName = localURL.lastPathComponent
                            let taskInfo = DownloadTaskInfo(
                                fileUrl: exportData.fileUrl,
                                fileMd5: exportData.fileMd5,
                                version: exportData.version,
                                fileName: fileName,
                                downloadStartTime: startTime,
                                downloadEndTime: Date()
                            )
                            self.downloadTaskInfo = taskInfo
                            
                            // 下载完成，状态更新
                            self.downloadState = .downloaded
                            self.lastDownloadTime = Date()
                            
                            // 开始导入
                            self.startImportProcess(fileURL: localURL, exportData: exportData, completion: completion)
                            
                        case .failure(let error):
                            print("文件下载失败: \(error)")
                            self.handleDownloadFailure(retryCount: retryCount, completion: completion)
                        }
                    }
                    
                } catch {
                    print("解析导出响应失败: \(error)")
                    self.handleDownloadFailure(retryCount: retryCount, completion: completion)
                }
                
            case .failure(let error):
                print("网络请求失败: \(error)")
                self.handleDownloadFailure(retryCount: retryCount, completion: completion)
            }
        }
    }
    
    // MARK: - 处理下载失败
    private func handleDownloadFailure(retryCount: Int, completion: ((Bool) -> Void)? = nil) {
        // 失败重试
        print("下载失败，准备重试 (已尝试: \(retryCount + 1))")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            
            if retryCount + 1 < Config.maxRetryCount {
                self.startDownloadProcess(retryCount: retryCount + 1, completion: completion)
            } else {
                self.cleanupFailedDownload()
                self.downloadState = .notDownloaded
                completion?(false)
            }
        }
    }
    
    // MARK: - 下载文件
    private func downloadFile(from urlString: String, md5: String, version: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "POIDownloadManager", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "无效的文件URL"])))
            return
        }
        
        print("开始下载文件: \(urlString)")
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] localURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let localURL = localURL else {
                completion(.failure(NSError(domain: "POIDownloadManager", code: -2,
                                           userInfo: [NSLocalizedDescriptionKey: "下载失败，没有返回文件"])))
                return
            }
            
            do {
                // 验证MD5
                let fileData = try Data(contentsOf: localURL)
                let fileMD5 = self.md5(data: fileData)
                
                print("文件MD5: \(fileMD5), 期望MD5: \(md5)")
                
                guard fileMD5.lowercased() == md5.lowercased() else {
                    completion(.failure(NSError(domain: "POIDownloadManager", code: -3,
                                               userInfo: [NSLocalizedDescriptionKey: "文件MD5校验失败"])))
                    return
                }
                
                // 移动到持久化目录
                let documentsURL = try self.fileManager.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: true)
                let fileName = "poi_data_\(version).txt"
                let destinationURL = documentsURL.appendingPathComponent(fileName)
                
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }
                
                try self.fileManager.moveItem(at: localURL, to: destinationURL)
                
                print("文件下载完成，保存至: \(destinationURL.path)")
                completion(.success(destinationURL))
                
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - 开始导入流程
    private func startImportProcess(fileURL: URL, exportData: POIExportData, completion: ((Bool) -> Void)? = nil) {
        // 检查导入状态
        if importState == .importing {
            print("检测到未完成的导入任务，继续导入")
            resumeImport(completion: completion)
            return
        }
        
        // 创建新的导入任务 - 只保存文件名
        let fileName = fileURL.lastPathComponent
        let importTaskInfo = ImportTaskInfo(
            fileName: fileName,
            fileMd5: exportData.fileMd5,
            version: exportData.version,
            importStartTime: Date()
        )
        self.importTaskInfo = importTaskInfo
        importState = .importing
        
        // 开始导入
        continueImport(completion: completion)
    }
    
    // MARK: - 继续导入（断点续导）
    private func resumeImport(completion: ((Bool) -> Void)? = nil) {
        guard let taskInfo = importTaskInfo else {
            print("没有找到导入任务信息")
            importState = .notImported
            completion?(false)
            return
        }
        
        // 验证文件是否存在 - 使用动态路径
        let fileURL = URL(fileURLWithPath: taskInfo.filePath)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("导入文件不存在，无法继续导入")
            // 文件不存在，清理状态
            importTaskInfo = nil
            importState = .notImported
            
            // 检查是否需要重置下载状态
            if downloadState == .downloaded {
                print("文件丢失，重置下载状态")
                downloadState = .notDownloaded
                downloadTaskInfo = nil
                lastDownloadTime = nil
            }
            
            completion?(false)
            return
        }
        
        importState = .importing
        continueImport(completion: completion)
    }
    
    /// MARK: - 继续导入
    private func continueImport(completion: ((Bool) -> Void)? = nil) {
        guard let taskInfo = importTaskInfo else {
            print("导入任务信息为空")
            importState = .notImported
            completion?(false)
            return
        }
        
        // 使用动态路径
        let fileURL = URL(fileURLWithPath: taskInfo.filePath)
        
        operationQueue.async { [weak self] in
            guard let self = self else {
                completion?(false)
                return
            }
            
            do {
                // 读取文件内容
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                
                // 确定起始行（从上次导入的位置继续）
                let startLine = taskInfo.importedCount > 0 ? taskInfo.importedCount + 1 : 1
                
                // 解析数据行
                var poiRows: [POITextRow] = []
                var currentLine = 0
                
                for i in startLine..<lines.count {
                    let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    if line.isEmpty { continue }
                    
                    let components = line.components(separatedBy: "|").filter { !$0.isEmpty }
                    
                    if components.count >= 7 {
                        let row = POITextRow(
                            id: components[0],
                            wgsLon: Double(components[1]) ?? 0,
                            wgsLat: Double(components[2]) ?? 0,
                            name: components[3],
                            address: components.count > 4 ? components[4] : "",
                            category: components.count > 5 ? Int(components[5]) ?? 0 : 0,
                            altitude: components.count > 6 ? Double(components[6]) : nil,
                            minZoom: components.count > 7 ? Int(components[7]) ?? 0 : 0,
                        )
                        poiRows.append(row)
                        currentLine = i
                    }
                    
                    // 每500条导入一次
                    if poiRows.count >= Config.downloadBatchSize {
                        self.importBatch(poiRows, taskInfo: taskInfo, currentLine: currentLine) { success in
                            if success {
                                // 继续下一批
                                self.continueImport(completion: completion)
                            } else {
                                completion?(false)
                            }
                        }
                        return
                    }
                }
                
                // 导入剩余的数据
                if !poiRows.isEmpty {
                    self.importBatch(poiRows, taskInfo: taskInfo, currentLine: currentLine) { success in
                        if success {
                            self.finishImport(taskInfo: taskInfo, totalCount: lines.count - 1, completion: completion)
                        } else {
                            completion?(false)
                        }
                    }
                } else {
                    // 没有数据需要导入，直接完成
                    self.finishImport(taskInfo: taskInfo, totalCount: taskInfo.totalCount, completion: completion)
                }
                
            } catch {
                print("文件读取失败: \(error)")
                self.handleImportFailure(completion: completion)
            }
        }
    }
    
    // MARK: - 导入一批数据
    private func importBatch(_ rows: [POITextRow], taskInfo: ImportTaskInfo, currentLine: Int, completion: @escaping (Bool) -> Void) {
        // 获取用户状态
        self.getExistingUserStates { existingStates in
            let poiDataArray = rows.map { row -> PublicPOIData in
                let basePOI = row.toPublicPOIData()
                
                if let existingState = existingStates[row.id] {
                    return PublicPOIData(
                        id: basePOI.id,
                        name: basePOI.name,
                        description: basePOI.description,
                        type: basePOI.type,
                        address: basePOI.address,
                        lon: basePOI.lon,
                        lat: basePOI.lat,
                        category: basePOI.category,
                        tel: basePOI.tel,
                        wgsLon: basePOI.wgsLon,
                        wgsLat: basePOI.wgsLat,
                        images: basePOI.images,
                        isCollection: existingState.isCollection,
                        isIsCheck: existingState.isIsCheck,
                        minZoom: basePOI.minZoom
                    )
                } else {
                    return basePOI
                }
            }
            
            // 批量插入
            self.databaseManager.batchInsertPOIsFast(poiDataArray) { error in
                if error == nil {
                    // 更新导入任务信息
                    var updatedTaskInfo = taskInfo
                    updatedTaskInfo.importedCount = currentLine
                    updatedTaskInfo.lastImportedId = rows.last?.id
                    updatedTaskInfo.currentBatch += 1
                    self.importTaskInfo = updatedTaskInfo
                    
//                    print("已导入 \(updatedTaskInfo.importedCount) 条数据")
                    completion(true)
                } else {
                    print("批量导入失败: \(error!)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - 完成导入
    private func finishImport(taskInfo: ImportTaskInfo, totalCount: Int, completion: ((Bool) -> Void)? = nil) {
        var updatedTaskInfo = taskInfo
        updatedTaskInfo.totalCount = totalCount
        updatedTaskInfo.importEndTime = Date()
        self.importTaskInfo = updatedTaskInfo
        
        self.importState = .imported
        
        // 更新版本信息
        self.userDefaults.set(taskInfo.version, forKey: Config.lastVersionKey)
        self.userDefaults.set(taskInfo.fileMd5, forKey: Config.lastFileMd5Key)
        self.userDefaults.synchronize()
        
        // 保存下载状态
        self.saveDownloadStatus(
            version: taskInfo.version,
            fileUrl: taskInfo.filePath,
            fileMd5: taskInfo.fileMd5,
            totalCount: totalCount
        )
        
        print("导入完成，总计: \(totalCount) 条")
        
        // 导入完成后，下载状态变为已下载
        self.downloadState = .downloaded
        
        self.notifyDownloadCompleted(count: totalCount)
        
        DispatchQueue.main.async {
            completion?(true)
        }
    }
    
    // MARK: - 处理导入失败
    private func handleImportFailure(completion: ((Bool) -> Void)? = nil) {
        print("导入失败")
        
        // 检查文件是否存在
        if let taskInfo = importTaskInfo {
            let fileURL = URL(fileURLWithPath: taskInfo.filePath)
            if !fileManager.fileExists(atPath: fileURL.path) {
                print("导入文件不存在，重置下载状态")
                downloadState = .notDownloaded
                downloadTaskInfo = nil
                lastDownloadTime = nil
            }
        }
        
        // 清理导入任务信息
        importTaskInfo = nil
        importState = .notImported
        
        completion?(false)
    }
    
    // MARK: - 获取已有用户状态
    private func getExistingUserStates(completion: @escaping ([String: (isCollection: Bool?, isIsCheck: Bool?)]) -> Void) {
        operationQueue.async { [weak self] in
            guard let self = self else {
                completion([:])
                return
            }
            
            do {
                let allPOIs: [PublicPOIData] = try self.databaseManager.database.getObjects(
                    on: [
                        PublicPOIData.Properties.id,
                        PublicPOIData.Properties.isCollection,
                        PublicPOIData.Properties.isIsCheck
                    ],
                    fromTable: "poi_data"
                )
                
                var states: [String: (isCollection: Bool?, isIsCheck: Bool?)] = [:]
                for poi in allPOIs {
                    if let id = poi.id {
                        states[id] = (poi.isCollection, poi.isIsCheck)
                    }
                }
                
                DispatchQueue.main.async {
                    completion(states)
                }
            } catch {
                print("查询用户状态失败: \(error)")
                DispatchQueue.main.async {
                    completion([:])
                }
            }
        }
    }
    
    // MARK: - 保存下载状态
    private func saveDownloadStatus(version: String, fileUrl: String, fileMd5: String, totalCount: Int) {
        let status = POIDownloadStatus(
            id: nil,
            lastDownloadTime: Date(),
            fileVersion: version,
            fileUrl: fileUrl,
            fileMd5: fileMd5,
            totalCount: totalCount
        )
        
        operationQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.databaseManager.database.delete(fromTable: "download_status")
                try self.databaseManager.database.insert(status, intoTable: "download_status")
            } catch {
                print("保存下载状态失败: \(error)")
            }
        }
    }
    
    // MARK: - MD5计算
    private func md5(data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - 通知
    private func notifyDownloadCompleted(count: Int) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .poiDownloadCompleted,
                object: nil,
                userInfo: [
                    "timestamp": Date(),
                    "count": count
                ]
            )
        }
    }
    
    // MARK: - 公开方法
    
    /// 获取当前状态
    public func getCurrentState() -> (downloadState: DownloadState, importState: ImportState) {
        return (downloadState, importState)
    }
    
    /// 获取导入进度
    public func getImportProgress() -> (current: Int, total: Int, progress: Float) {
        guard let taskInfo = importTaskInfo, taskInfo.totalCount > 0 else {
            return (0, 0, 0)
        }
        let progress = Float(taskInfo.importedCount) / Float(taskInfo.totalCount)
        return (taskInfo.importedCount, taskInfo.totalCount, progress)
    }
    
    /// 检查是否已下载
    public func isDataDownloaded() -> Bool {
        return downloadState == .downloaded
    }
    
    /// 检查是否正在下载
    public func isDownloading() -> Bool {
        return downloadState == .downloading
    }
    
    /// 检查是否正在导入
    public func isImporting() -> Bool {
        return importState == .importing
    }
    
    /// 获取当前版本
    public func getCurrentVersion() -> String? {
        return userDefaults.string(forKey: Config.lastVersionKey)
    }
    
    /// 强制重置所有状态
    public func forceResetAllStates() {
        // 清理文件
        if let taskInfo = downloadTaskInfo {
            try? fileManager.removeItem(at: URL(fileURLWithPath: taskInfo.localFilePath))
        }
        
        if let taskInfo = importTaskInfo {
            try? fileManager.removeItem(at: URL(fileURLWithPath: taskInfo.filePath))
        }
        
        // 重置所有状态
        downloadState = .notDownloaded
        importState = .notImported
        downloadTaskInfo = nil
        importTaskInfo = nil
        lastDownloadTime = nil
        
        print("所有状态已重置")
    }
    
    deinit {
        networkMonitor.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 获取版本信息
extension POIDownloadManager {
    
    /// 获取下载状态信息
    public func getDownloadStatusInfo(completion: @escaping (_ version: String?,
                                                             _ downloadTime: Date?,
                                                             _ fileSize: String?) -> Void) {
        var version = getCurrentVersion()
        var downloadTime = lastDownloadTime
        var fileSize: String?
        
        let group = DispatchGroup()
        
        // 从数据库获取更详细的信息
        group.enter()
        POIDatabaseManager.shared.getLatestDownloadStatus { status in
            if let status = status {
                version = version ?? status.fileVersion
                downloadTime = downloadTime ?? status.lastDownloadTime
            }
            group.leave()
        }
        
        // 获取文件大小
        group.enter()
        POIDatabaseManager.shared.getDatabaseFileSize { size in
            fileSize = size
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(version, downloadTime, fileSize)
        }
    }
}


public extension Notification.Name {
    static let poiDownloadCompleted = Notification.Name("poiDownloadCompleted")                      //公共兴趣点txt下载完成
    static let collectionStatusChanged = Notification.Name("collectionStatusChanged")                //收藏
    static let checkStatusChanged = Notification.Name("checkStatusChanged")                          //打卡
}
