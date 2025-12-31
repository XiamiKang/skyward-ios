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
        
        setupBackgroundLocationUpdates()
    }
    
    // 设置后台定位权限 - 只要有定位权限且应用支持后台定位时就可以启用
    // 注意：需要在Xcode项目中配置"Background Modes"中的"Location updates"
    func setupBackgroundLocationUpdates(){
        let hasPermission = locationManager.authorizationStatus == .authorizedAlways ||
                           locationManager.authorizationStatus == .authorizedWhenInUse
        if isBackgroundLocationEnabled() && hasPermission {
           locationManager.allowsBackgroundLocationUpdates = true
           locationManager.showsBackgroundLocationIndicator = true
       } else {
           locationManager.allowsBackgroundLocationUpdates = false
           locationManager.showsBackgroundLocationIndicator = false
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
        
        // 启动持续定位更新（使用startUpdatingLocation而非requestLocation）
        // 系统会根据distanceFilter和desiredAccuracy自动推送位置更新
        // 系统会自动保持定位服务在后台运行，无需额外的后台保活机制
        // 当收到位置更新时，系统会自动延长后台执行时间
        locationManager.startUpdatingLocation()
    }
    
    func stopRecord() {
        recording = false
        
        // 停止定位更新
        locationManager.stopUpdatingLocation()
    }
    
    func deleteRecords() {
        if let record = currentRecord {
            dataManager.deleteRecord(record)
        }
        finishRecord()
    }
    
    func finishRecord() {
        _dataManager = nil
        currentRecord = nil
    }
    
    // MARK: - Location Processing

    private func saveNewLocation(_ location: CLLocation) {
        // 新点合法性校验
        guard validateLocation(location) else {
            return
        }
        guard let trackFileURL = currentRecord?.fileFullURL() else {
            return
        }
        // 创建定位点
        let point = RecordPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, timestamp: location.timestamp)
        if dataManager.writeRecordPoint(point, to: trackFileURL) {
            locationUpdateCompletion?(location.coordinate, nil)
        }
    }
    
    /// 校验新位置点是否合法
    /// - Parameters:
    ///   - newLocation: 新的位置点
    /// - Returns: true表示合法，false表示不合法
    private func validateLocation(_ newLocation: CLLocation) -> Bool {
        // 检查位置的有效性
        if newLocation.horizontalAccuracy < 0 {
            debugPrint("定位无效：horizontalAccuracy < 0")
            return false
        }
        
        // 检查定位精度：如果精度超过50米，则认为是低精度点，不记录
        let maxAccuracy: Double = 50.0  // 最大允许的定位精度（米）
        if newLocation.horizontalAccuracy > maxAccuracy {
            debugPrint("定位精度不足：\(newLocation.horizontalAccuracy)米 > \(maxAccuracy)米，已跳过记录")
            return false
        }
        
        guard let currentRecord = currentRecord else {
            return false
        }
        
        let recordCoordinates = dataManager.readRecordCoordinates(from: currentRecord)
        if recordCoordinates.count == 0 {
            return true
        }
        // 读取文件中最后一个点
        guard let lastLatitude = recordCoordinates.last?.latitude, let lastLongitude = recordCoordinates.last?.longitude else {
            // 如果文件中没有点，则新点合法
            return true
        }
        
        // 检查1: 与上一个点的距离是否小于3米
        let lastLocation = CLLocation(
            latitude: lastLatitude,
            longitude: lastLongitude
        )
        let distance = newLocation.distance(from: lastLocation)
        if distance < 3 {
            debugPrint("新点与上一个点距离小于3米(\(distance)米)，已跳过记录")
            return false
        }
        
        // 检查2: 是否与上一个点完全相同
        if abs(lastLatitude - newLocation.coordinate.latitude) < 0.000001 &&
            abs(lastLongitude - newLocation.coordinate.longitude) < 0.000001 {
            debugPrint("检测到完全相同的轨迹点，已跳过记录")
            return false
        }
        
        // 通过所有校验，点合法
        return true
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
            // 创建更新后的record对象
            var updatedRecord = record
            updatedRecord.name = recordName
            
            // 修改本地文件夹名称和数据库记录
            if dataManager.renameRecord(updatedRecord) {
                // 只有当重命名成功后，才更新currentRecord的名称
                currentRecord?.name = recordName
            }
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
                                        self?.finishRecord()
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
    
    func getTrackRecords() -> [TrackRecord] {
        let result = dataManager.getTrackRecords()
        if let currentRecord = currentRecord {
            return result.filter({$0.id != currentRecord.id})
        }
        return result
    }
    
    
    //MARK: - Notification
    @objc func appDidTermination() {
        stopRecord()
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
        setupBackgroundLocationUpdates()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard recording == true else { return }
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
                debugPrint("位置未知，等待系统自动重试...")
                // 注意：使用startUpdatingLocation时，系统会自动重试，无需手动调用
            default:
                debugPrint("定位错误: \(clError.code.rawValue)")
            }
        }
    }
}

// MARK: - 后台定位检查
extension TrackManager {
    
    /// 检查应用是否支持后台定位
    /// - Returns: true表示支持，false表示不支持
    private func isBackgroundLocationEnabled() -> Bool {
        // 检查Info.plist中是否配置了UIBackgroundModes
        guard let infoDict = Bundle.main.infoDictionary,
              let backgroundModes = infoDict["UIBackgroundModes"] as? [String] else {
            return false
        }
        
        // 检查是否包含location模式
        return backgroundModes.contains("location")
    }
}

