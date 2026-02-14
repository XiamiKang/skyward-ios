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
    private let locationManager = CLLocationManager()
    private let dataManager = RouteDataManager()
    private var lastLocation: CLLocation?
    // 记录时长定时器
    private var travelTimeTimer: Timer?
    // 定位更新的回调
    var locationUpdateCompletion: ((CLLocation?) -> Void)?
    // 轨迹信息更新的回调
    var routeUpdateHandler: ((Route?) -> Void)?
    
    // MARK: - Initializer
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        setupLocationManager()
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
        
        dataManager.startRecord(type: .track)
        // 启动持续定位更新（使用startUpdatingLocation而非requestLocation）
        // 系统会根据distanceFilter和desiredAccuracy自动推送位置更新
        // 系统会自动保持定位服务在后台运行，无需额外的后台保活机制
        // 当收到位置更新时，系统会自动延长后台执行时间
        locationManager.startUpdatingLocation()

        // 启动记录时长定时器
        startTravelTimeTimer()
    }
    
    func stopRecord() {
        recording = false
        // 停止定位更新
        locationManager.stopUpdatingLocation()
        // 停止记录时长定时器
        stopTravelTimeTimer()
    }
    
    func endRecord() {
        dataManager.endRecord()
        lastLocation = nil
        // 停止记录时长定时器
        stopTravelTimeTimer()
    }

    // MARK: - Travel Time Timer

    /// 启动记录时长定时器
    private func startTravelTimeTimer() {
        // 先停止之前的定时器
        stopTravelTimeTimer()

        // 每秒触发一次
        travelTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTravelTime()
        }

        // 确保定时器在RunLoop中正常运行
        if let timer = travelTimeTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    /// 停止记录时长定时器
    private func stopTravelTimeTimer() {
        travelTimeTimer?.invalidate()
        travelTimeTimer = nil
    }

    /// 更新记录时长
    private func updateTravelTime() {
        guard dataManager.sessionRoute != nil else {
            return
        }

        // 更新时长
        dataManager.updateSessionRoute(timeInterval: 1)

        // 回调通知更新
        routeUpdateHandler?(dataManager.sessionRoute)
    }
    
    // MARK: - Location Processing

    private func saveNewLocation(_ location: CLLocation) {
        // 新点合法性校验
        guard validateLocation(location) else {
            return
        }
        // 写入点到本地
        writePoint(location)
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
        
        // 没有上一个点，说明是第一个点
        guard let lastLocation = lastLocation else {
            return true
        }
        
        // 检查1: 与上一个点的距离是否小于3米
        let distance = newLocation.distance(from: lastLocation)
        if distance < 3 {
            debugPrint("新点与上一个点距离小于3米(\(distance)米)，已跳过记录")
            return false
        }
        
        // 通过所有校验，点合法
        return true
    }
    
    // MARK: - 增删改查
    
    func writePoint(_ location: CLLocation) {
        let point = RecordPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, timestamp: location.timestamp)
        if dataManager.writePointToSessionTxtFile(point) {
            
            dataManager.updateSessionRoute(point: point)
            
            locationUpdateCompletion?(location)
        }
    }
    
    func getAllRoutes() -> [Route] {
        let result = dataManager.getRoutes(type: .track)
        
        guard let sessionRouteId = dataManager.sessionRoute?.id else {
            return result
        }
        
        return result.filter({$0.id != sessionRouteId})
    }

    func getPointsInRoute(routeId: String) -> [CLLocationCoordinate2D]? {
        return dataManager.readCoordinatesFromGPXFile(from: routeId)
    }
    
    func saveRoute(name: String, completion: @escaping ()->Void) {
        dataManager.updateSessionRoute(name: name)
        guard let route = dataManager.sessionRoute else {
            completion()
            return
        }
        UIWindow.topWindow?.sw_showLoading()
        dataManager.saveRouteToService(route) { success in
            UIWindow.topWindow?.sw_hideLoading()
            if success {
                completion()
            }
        }
    }
    
    func deleteRoute(_ routeId: String, completion: ((Bool) -> Void)?) {
        dataManager.deleteRouteFromService(routeId: routeId) { success, errorMsg in
            completion?(success)
            
            if success == false, let msg = errorMsg {
                UIWindow.topWindow?.sw_showWarningToast(msg)
            }
        }
    }
    
    func getSessionRoute(completion: @escaping (Route?) ->Void) {
        dataManager.assembleSessionRoute { [weak self] in
            completion(self?.dataManager.sessionRoute)
        }
    }
    
    //MARK: - Notification
    
    @objc func appDidTermination() {
        guard let route = dataManager.sessionRoute else {
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timeString = dateFormatter.string(from: Date())
        dataManager.updateSessionRoute(name: timeString)
        dataManager.saveSessionRouteToLocal(route)
    }

    //MARK: - Test
    func testSavePoints() {
        // 批量写入轨迹点
        sampleRecords().forEach { point in
            self.dataManager.writePointToSessionTxtFile(point)
        }
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

