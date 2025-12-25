//
//  TrackManager.swift
//  ModuleTeam
//
//  Created by zhaobo on 2025/12/11.
//

import Foundation
import CoreLocation
import UIKit
import TXKit
import SWKit


public class TrackManager: NSObject {
    
    // MARK: - Properties
    var recording: Bool = false
    let locationManager = CLLocationManager()
    var locationTimer: Timer?
    var lastLocation: CLLocation?
    var currentRecord: TrackRecord?
    
    // 定位更新的回调
    var locationUpdateCompletion: ((CLLocationCoordinate2D?, Error?) -> Void)?
    
    // data
    private var _dataManager: TrackDataManager?
    var dataManager: TrackDataManager {
        if _dataManager == nil {
            _dataManager = TrackDataManager()
        }
        return _dataManager!
    }
    
    private lazy var uploadManager: UploadManager = {
        let mgr = UploadManager()
        return mgr
    }()
    
    private lazy var mapService: MapService = {
        let mapService = MapService()
        return mapService
    }()
    
    // 后台保活相关
    var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initializer
    override init() {
        super.init()
        setupLocationManager()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 3
        
        // 减少电池消耗的设置
        locationManager.pausesLocationUpdatesAutomatically = false // 禁用自动暂停
        locationManager.activityType = .otherNavigation // 导航类型，更适合持续追踪
        
        // 设置后台定位权限 - 只有在确认有权限时才启用
        // 注意：需要在Xcode项目中配置"Background Modes"中的"Location updates"
        if UIApplication.shared.backgroundRefreshStatus == .available, locationManager.authorizationStatus == .authorizedAlways {
           locationManager.allowsBackgroundLocationUpdates = true
           locationManager.showsBackgroundLocationIndicator = true
       } else {
           debugPrint("警告: 应用程序未配置后台定位模式，后台定位更新已禁用")
           locationManager.allowsBackgroundLocationUpdates = false
       }
    }
    
    // MARK: - Location Tracking
    func startRecord() {
        // 检查权限
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            UIWindow.topWindow?.sw_showWarningToast("定位权限被拒绝")
            return
        }
        guard recording == false else {
            return
        }
        recording = true
        
        // 创建新的轨迹记录
        guard let record = dataManager.createNewRecord() else {
            recording = false
            return
        }
        
        currentRecord = record
        
        // 设置定时器，确保每5秒记录一次位置
        locationTimer?.invalidate()
        locationTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(requestLoaction), userInfo: nil, repeats: true)
        
        // 立即触发一次定位
        requestLoaction()
        
        // 注册App进入后台和前台的通知
        registerAppStateNotifications()
    }
    
    func stopRecord() {
        recording = false
        locationTimer?.invalidate()
        locationManager.stopUpdatingLocation()
        
        // 停止后台保活
        stopBackgroundKeepAlive()
        
        // 移除通知监听
        unregisterAppStateNotifications()
    }
    
    func deleteRecords() {
        if let record = currentRecord, dataManager.deleteRecord(record) {
            _dataManager = nil
        }
    }
    
    @objc func requestLoaction() {
        if locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    // MARK: - Location Processing

    private func saveNewLocation(_ location: CLLocation) {
        guard let trackFileURL = currentRecord?.fileFullURL() else {
            return
        }
        // 创建定位点
        let point = RecordPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, timestamp: location.timestamp)
        if dataManager.writeRecordPoint(point, to: trackFileURL) {
            locationUpdateCompletion?(location.coordinate, nil)
        }
    }
    
    // MARK: - Data Upload
    func uploadRecords(recordName: String?) {
        guard let recordName = recordName?.trimmingCharacters(in: .whitespacesAndNewlines), !recordName.isEmpty else {
            UIWindow.topWindow?.sw_showWarningToast("轨迹记录名称不能为空")
            return
        }
        guard let record = currentRecord else {
            return
        }
        
        if recordName != record.name {
            //修改本地文件夹名称
            currentRecord?.name = recordName
            dataManager.renameRecord(record)
        }
        
        guard let data = dataManager.getTrackRecordGPXData(from: record) else {
            return
        }

        UIWindow.topWindow?.sw_showLoading()
        uploadManager.uploadFile(fileData: data, fileName: recordName, mimeType: "gpx") { progress in
            debugPrint("上传进度： \(progress)")
        } completion: {[weak self] result in
            DispatchQueue.main.async {
                UIWindow.topWindow?.sw_hideLoading()
                switch result {
                case .success(let response):
                    if response.isSuccess, let fileUrl = response.data?.fileUrl {
                        UIWindow.topWindow?.sw_showLoading()
                        self?.mapService.saveUserTrack(name: recordName, fileUrl: fileUrl) { result in
                            DispatchQueue.main.async {
                                UIWindow.topWindow?.sw_hideLoading()
                                switch result {
                                case .success(let response):
                                    if response.statusCode == 200 {
                                        UIWindow.topWindow?.sw_showSuccessToast("保存成功")
                                        self?.currentRecord?.uploadStatus = .uploaded
                                        if let record = self?.currentRecord {
                                            self?.dataManager.updateUploadStatusRecord(record)
                                        }
                                    } else {
                                        UIWindow.topWindow?.sw_showWarningToast("保存失败：\(response.description)")
                                    }
                                case .failure(let error):
                                    UIWindow.topWindow?.sw_showWarningToast("保存失败：\(error.localizedDescription)")
                                }
                            }
                        }
                    } else {
                        UIWindow.topWindow?.sw_showWarningToast("上传失败: \(response.msg ?? "未知错误")")
                    }
                case .failure(let error):
                    UIWindow.topWindow?.sw_showWarningToast("上传错误: \(error.localizedDescription)")
                }
            }
        }
        
        _dataManager = nil
    }
    
    
    //MARK: - Notification
    @objc func appDidTermination() {
        stopRecord()
    }
    
    /// 注册App状态通知
    private func registerAppStateNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    /// 移除App状态通知
    private func unregisterAppStateNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    /// App进入后台回调
    @objc private func appDidEnterBackground() {
        debugPrint("App进入后台，继续定位追踪")
        
        // 确保后台定位已启用
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.showsBackgroundLocationIndicator = true
        }
        
        // 重新开始后台保活
        DispatchQueue.main.async { [weak self] in
            self?.startBackgroundKeepAlive()
        }
    }
    
    /// App将要进入前台回调
    @objc private func appWillEnterForeground() {
        debugPrint("App将要进入前台")
        
        // 进入前台后，可以调整定位精度和频率
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }

    //MARK: - Test
    func testSavePoints() {
        guard let record = dataManager.createNewRecord(), let fileURL = record.fileFullURL()  else {
            return
        }
        currentRecord = record
        
        // 批量写入轨迹点
        dataManager.writeRecordPoints(sampleRecords(), to: fileURL)
    }
    
    func sampleRecords() -> [RecordPoint] {
        // 随机生成5个点，每个点间隔约6米
        var points: [RecordPoint] = []
        let baseLatitude = 30.667323
        let baseLongitude = 103.959066
        
        // 每6米大约对应0.000054纬度差（1度≈111km）
        let meterPerDegreeLat: Double = 1.0 / 111000.0
        let meterPerDegreeLng: Double = 1.0 / (111000.0 * cos(baseLatitude * .pi / 180.0))
        
        for i in 0..<5 {
            // 随机方向，0~2π
            let angle = Double.random(in: 0..<(2 * .pi))
            // 6米距离
            let distance: Double = 6.0
            let deltaLat = distance * cos(angle) * meterPerDegreeLat
            let deltaLng = distance * sin(angle) * meterPerDegreeLng
            
            let lat = baseLatitude + deltaLat * Double(i + 1)
            let lng = baseLongitude + deltaLng * Double(i + 1)
            let timestamp = Date().addingTimeInterval(5)
            
            let point =  RecordPoint(latitude: lat, longitude: lng, timestamp: timestamp)
            points.append(point)
        }
        
        return points
    }
}

// MARK: - CLLocationManagerDelegate

extension TrackManager: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        // 记录权限状态变化
        debugPrint("定位权限状态变化: \(status.rawValue)")
        
        // 权限变化时更新后台定位设置
        if status == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        } else if status == .authorizedWhenInUse {
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 检查位置的有效性
        if location.horizontalAccuracy < 0 {
            return
        }
        // 如果本次定位的位置和上一次定位的位置距离小于3米则不存储位置
        if let lastPoint = lastLocation, location.distance(from: lastPoint) < 3 {
            return
        }
        lastLocation = location
        
        // 处理有效的位置数据
        saveNewLocation(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("定位失败: \(error)")
        
        // 如果是权限错误，尝试重新请求权限
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                debugPrint("定位权限被拒绝")
            case .locationUnknown:
                debugPrint("位置未知，正在重试...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.requestLoaction()
                }
            default:
                debugPrint("定位错误: \(clError.code.rawValue)")
            }
        }
    }
}

// MARK: - 后台保活功能
extension TrackManager {
    /// 开始后台保活
    private func startBackgroundKeepAlive() {
        // 开始后台任务
        startBackgroundTask()
    }
    
    /// 停止后台保活
    private func stopBackgroundKeepAlive() {
        // 停止后台任务
        stopBackgroundTask()
    }
    
    /// 开始后台任务
    private func startBackgroundTask() {
        // 结束之前的后台任务
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
        
        // 创建新的后台任务
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "LocationTracking") { [weak self] in
            // 后台任务即将结束时的处理
            self?.handleBackgroundTaskExpiration()
        }
        
        // 使用定时器定期刷新后台任务
        scheduleBackgroundTaskRefresh()
    }
    
    /// 停止后台任务
    private func stopBackgroundTask() {
        if backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
    
    /// 处理后台任务过期
    private func handleBackgroundTaskExpiration() {
        debugPrint("后台任务即将过期，正在保存最后位置数据...")
        
        // 保存当前状态
        stopRecord()
        
        // 结束后台任务
        stopBackgroundTask()
    }
    
    /// 定期刷新后台任务
    private func scheduleBackgroundTaskRefresh() {
        // 每30秒刷新一次后台任务
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self = self, self.recording else { return }
            
            // 检查App状态需要在主线程执行
            DispatchQueue.main.sync { [weak self] in
                guard let self = self, self.recording else { return }
                
                // 如果App仍在后台运行，刷新后台任务
                if UIApplication.shared.applicationState == .background {
                    debugPrint("刷新后台任务")
                    self.startBackgroundTask()
                } else {
                    // App在前台，重新调度
                    self.scheduleBackgroundTaskRefresh()
                }
            }
        }
    }
}

