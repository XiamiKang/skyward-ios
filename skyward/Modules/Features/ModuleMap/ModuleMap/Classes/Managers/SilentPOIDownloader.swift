//
//  SilentPOIDownloader.swift
//  Pods
//
//  Created by TXTS on 2025/12/15.
//

import Foundation
import SWKit
import Combine
import BackgroundTasks
import SWNetwork

// MARK: - 静默下载管理器
class SilentPOIDownloader {
    static let shared = SilentPOIDownloader()
    
    private let mapService: MapService
    private var currentPage = 1
    private let pageSize = 200
    private var isDownloading = false
    private var cancellables = Set<AnyCancellable>()
    
    // 下载状态
    enum DownloadState {
        case idle
        case downloading(progress: Double, currentPage: Int, totalItems: Int)
        case completed(totalItems: Int)
        case failed(error: Error)
    }
    
    private let stateSubject = CurrentValueSubject<DownloadState, Never>(.idle)
    var statePublisher: AnyPublisher<DownloadState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    private init() {
        self.mapService = MapService() // 你的现有MapService
    }
    
    // MARK: - 开始静默下载
    func startSilentDownload() {
        guard !isDownloading else { return }
        
        // 检查是否已有数据
        POIDatabaseManager.shared.getTotalCount { [weak self] count in
            guard let self = self else { return }
            
            if count > 1000 { // 已有足够数据
                print("已有\(count)条数据，跳过下载")
                self.stateSubject.send(.completed(totalItems: count))
                return
            }
            
            // 开始下载
            self.isDownloading = true
            self.currentPage = 1
            self.downloadNextPage()
        }
    }
    
    // MARK: - 分页下载
    private func downloadNextPage() {
        let model = PublicPOIListModel(pageNum: currentPage, pageSize: pageSize, category: nil, id: nil, name: nil, baseCoordinateList: nil)
        
        // 使用Combine包装现有方法
        Future<[PublicPOIData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getPublicPOIList(model) { result in
                switch result {
                case .success(let response):
                    do {
                        let baseResponse = try JSONDecoder().decode(
                            BaseResponse<[PublicPOIData]>.self, 
                            from: response.data
                        )
                        
                        if baseResponse.success, let data = baseResponse.data {
                            promise(.success(data))
                        } else {
                            promise(.failure(.businessError(
                                message: baseResponse.msg,
                                code: baseResponse.code
                            )))
                        }
                    } catch {
                        promise(.failure(.parseError("数据解析失败")))
                    }
                    
                case .failure(let error):
                    promise(.failure(.networkError(error.localizedDescription)))
                }
            }
        }
        .receive(on: DispatchQueue.global(qos: .utility))
        .sink { [weak self] completion in
            guard let self = self else { return }
            
            if case .failure(let error) = completion {
                self.isDownloading = false
                self.stateSubject.send(.failed(error: error))
                print("下载失败: \(error)")
            }
        } receiveValue: { [weak self] items in
            guard let self = self else { return }
            
            // 保存到数据库
            POIDatabaseManager.shared.batchInsertPOIs(items) { error in
                if let error = error {
                    print("保存失败: \(error)")
                    self.isDownloading = false
                    self.stateSubject.send(.failed(error: error))
                    return
                }
                
                // 更新进度
                self.updateDownloadProgress(items.count)
                
                // 判断是否继续下载
                if items.count < self.pageSize {
                    // 没有更多数据了
                    self.downloadCompleted()
                } else {
                    // 继续下载下一页
                    self.currentPage += 1
                    self.downloadNextPage()
                }
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - 更新进度
    private func updateDownloadProgress(_ currentBatchCount: Int) {
        POIDatabaseManager.shared.getTotalCount { [weak self] total in
            guard let self = self else { return }
            
            // 估算总页数（假设每页200条，总共20000条）
            let estimatedTotal = 20000
            let progress = min(Double(total) / Double(estimatedTotal), 1.0)
            
            self.stateSubject.send(.downloading(
                progress: progress,
                currentPage: self.currentPage,
                totalItems: total
            ))
            
            // 静默通知UI（可选）
            if Int(progress * 100) % 10 == 0 { // 每10%更新一次
                print("下载进度: \(Int(progress * 100))%, 已下载: \(total)条")
            }
        }
    }
    
    // MARK: - 下载完成
    private func downloadCompleted() {
        POIDatabaseManager.shared.getTotalCount { [weak self] total in
            guard let self = self else { return }
            
            self.isDownloading = false
            self.stateSubject.send(.completed(totalItems: total))
            
            // 保存下载状态
//            self.saveDownloadStatus(totalPages: self.currentPage)
            
            print("静默下载完成，共下载\(total)条数据")
            
            // 发送完成通知（静默）
            NotificationCenter.default.post(
                name: .poiDownloadCompleted,
                object: total
            )
        }
    }
    
    // MARK: - 下载状态管理
//    private func saveDownloadStatus(totalPages: Int) {
//        let status = POIDownloadStatus(from: any Decoder)
//        status.lastDownloadTime = Date()
//        status.totalPages = totalPages
//        let value = try? POIDatabaseManager.shared.database.getValue(
//            on: PublicPOIData.Properties.id.count(),
//            fromTable: "poi_data"
//        )
//        status.totalItems = value.intValue
//        DispatchQueue.global(qos: .utility).async {
//            do {
//                try POIDatabaseManager.shared.database.insertOrReplace(status, intoTable: "download_status")
//            } catch {
//                print("保存下载状态失败: \(error)")
//            }
//        }
//    }
    
    // MARK: - 恢复上次下载
//    func resumeLastDownload() {
//        DispatchQueue.global(qos: .utility).async {
//            do {
//                if let status = try POIDatabaseManager.shared.database.getObject(
//                    on: POIDownloadStatus.Properties.all,
//                    fromTable: "download_status",
//                    orderBy: [POIDownloadStatus.Properties.lastDownloadTime.order(.ascending)]
//                ) {
//                    self.currentPage = status.totalPages + 1 // 从下一页开始
//                }
//                
//            } catch {
//                print("恢复下载状态失败: \(error)")
//            }
//            
//            // 开始下载
//            self.startSilentDownload()
//        }
//    }
    
    // MARK: - 智能启动
    func startSmartDownload() {
        // 检查网络状态
        let isWifi = NetworkMonitor.shared.isConnected
        
        // 检查是否在后台或电量低
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        let batteryLevel = UIDevice.current.batteryLevel
        
        // 智能决策
        if isWifi && !isLowPowerMode && batteryLevel > 0.3 {
            // 最佳条件：完整下载
            startSilentDownload()
        } else if isWifi {
            // 中等条件：只下载前50页
            downloadFirstPages(50)
        } else {
            // 移动网络：延迟到有WiFi或后台下载
            scheduleBackgroundDownload()
        }
    }
    
    private func downloadFirstPages(_ pageCount: Int) {
        // 只下载指定数量的页面
        let targetPage = min(currentPage + pageCount, 100) // 最多100页
        
        // 修改下载逻辑，只下载到指定页数
        // ... 具体实现类似 downloadNextPage，但有限制
    }
    
    private func scheduleBackgroundDownload() {
        if #available(iOS 13.0, *) {
            let request = BGProcessingTaskRequest(identifier: "com.app.poi.download")
            request.requiresNetworkConnectivity = true
            request.requiresExternalPower = false
            
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("后台任务调度失败: \(error)")
            }
        }
    }
    
    // MARK: - 暂停/取消
    func cancelDownload() {
        cancellables.forEach { $0.cancel() }
        isDownloading = false
        stateSubject.send(.idle)
    }
}
