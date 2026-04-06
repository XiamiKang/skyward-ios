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
import SWNetwork
import TangramMap

class TrackManager: NSObject {
    
    // MARK: - Properties
    private(set) var recording: Bool = false
    private let locationManager = CLLocationManager()
    private let dataManager = RouteDataManager()
    private var lastLocation: CLLocation?
    // 记录时长定时器
    private var travelTimeTimer: Timer?
    // 定位更新的回调
    var locationUpdateCompletion: ((CLLocation?) -> Void)?
    // 轨迹信息更新的回调
    var routeUpdateHandler: ((Route?) -> Void)?
    
    // markers
    private var mapView: TGMapView
    private var pointMarkers: [TGMarker] = []
    private var lineMarkers: [TGMarker] = []
    private(set) var coordinates: [CLLocationCoordinate2D] = []
    
    // MARK: - Initializer
    
    init(mapView: TGMapView) {
        self.mapView = mapView
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
        guard recording == false else {
            return
        }
        recording = true
        
        // 检查权限
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            UIWindow.topWindow?.sw_showWarningToast("定位权限被拒绝")
            return
        }
        
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
        // 停止定位更新
        locationManager.stopUpdatingLocation()
        // 停止记录时长定时器
        stopTravelTimeTimer()
        
        drawEndPoint()
    }
    
    func endRecord() {
        recording = false
        lastLocation = nil
        dataManager.endRecord()
        clearMarkers()
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
        guard let sessionRoute = dataManager.sessionRoute else {
            return
        }
        dataManager.sessionRoute?.travelTime = (sessionRoute.travelTime ?? 0) + 1

        routeUpdateHandler?(sessionRoute)
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
            Logger.debug("定位无效：horizontalAccuracy < 0")
            return false
        }
        
        // 检查定位精度：如果精度超过50米，则认为是低精度点，不记录
        let maxAccuracy: Double = 50.0  // 最大允许的定位精度（米）
        if newLocation.horizontalAccuracy > maxAccuracy {
            Logger.debug("定位精度不足：\(newLocation.horizontalAccuracy)米 > \(maxAccuracy)米，已跳过记录")
            return false
        }
        
        // 没有上一个点，说明是第一个点
        guard let lastLocation = lastLocation else {
            self.lastLocation = newLocation
            return true
        }
        self.lastLocation = newLocation
        
        // 检查1: 与上一个点的距离是否小于3米
        let distance = newLocation.distance(from: lastLocation)
        if distance < 3 {
            Logger.debug("新点与上一个点距离小于3米(\(distance)米)，已跳过记录")
            return false
        }
        
        // 通过所有校验，点合法
        return true
    }
    
    // MARK: - 增删改查
    
    func writePoint(_ location: CLLocation) {
        let point = RecordPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, timestamp: location.timestamp)
        if dataManager.writePointToSessionTxtFile(point) {            
            drawLine(at: location.coordinate)
            locationUpdateCompletion?(location)
        }
    }

    // MARK: 保存轨迹相关
    
    func isValidSessionRoute() -> Bool {
        guard let route = dataManager.sessionRoute else {
            return false
        }
        return route.endLatitude != nil && route.endLongitude != nil
    }
    
    func assembleSessionRoute(completion: @escaping (Route?) ->Void) {
        dataManager.assembleSessionRoute { [weak self] in
            completion(self?.dataManager.sessionRoute)
        }
    }
    
    func saveSessionRoute(newName: String?, coverImage: UIImage?, completion: @escaping (Bool) -> Void) {
        if let newName = newName, !newName.isEmpty {
            dataManager.sessionRoute?.routeName = newName
        }
        guard let route = dataManager.sessionRoute else {
            completion(false)
            return
        }
        
        if NetworkMonitor.shared.isConnected {
            dataManager.checkSensitiveWords(newName) { [weak self] success in
                if success {
                    self?.dataManager.saveRouteToServer(route, coverImage: coverImage, completion: completion)
                }
            }
        } else {
            RouteDataManager.saveRouteCoverToLocal(coverImage, routeId: route.id)
            completion(dataManager.saveSessionRouteToLocal())
        }
    }
    
    //MARK: - Notification
    
    @objc func appDidTermination() {
        Logger.debug("记录轨迹中程序被杀了")
        guard let _ = dataManager.sessionRoute else {
            Logger.debug("记录轨迹中程序被杀了，但是没拿到sessionRoute")
            return
        }
        if dataManager.saveSessionRouteToLocal() {
            dataManager.endRecord()
        }
    }
    
    //MARK: - Markers
    
    private func clearMarkers() {
        pointMarkers.forEach { mapView.markerRemove($0) }
        lineMarkers.forEach { mapView.markerRemove($0) }
        pointMarkers.removeAll()
        lineMarkers.removeAll()
        coordinates.removeAll()
    }
    
    private func drawLine(at coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
        if coordinates.count == 1 {
            drawStartPoint(at: coordinate)
        }
        if coordinates.count >= 2 {
            // 清除所有线段标记
            lineMarkers.forEach { mapView.markerRemove($0) }
            lineMarkers.removeAll()
            
            let polyline = TGGeoPolyline(coordinates: coordinates, count: UInt(coordinates.count))
            let marker = mapView.markerAdd()
            marker.polyline = polyline
            
            marker.stylingString = """
            {
                style: 'lines',
                interactive: true,
                color: '#FE6A00',
                width: 4px,
                order: 500,
                cap: 'round',
                join: 'round',
                outline: { width: 1px, color: '#FFFFFF', interactive: true} }
            }
            """
            lineMarkers.append(marker)
        }
    }
    
    private func drawStartPoint(at coordinate: CLLocationCoordinate2D) {
        let marker = mapView.markerAdd()
        marker.point = coordinate
        
        // 设置标记样式
        marker.stylingString = """
        {
            style: 'points',
            color: 'white',
            size: [16px, 16px],
            order: 999,
            collide: false
        }
        """
        // 直接设置图标图片
        if let image = SWKitModule.image(named: "map_track_start") {
            marker.icon = image
        }
        
        pointMarkers.append(marker)
    }
    
    func drawEndPoint() {
        guard coordinates.count > 1, let coordinate = coordinates.last else {
            return
        }
        
        let marker = mapView.markerAdd()
        marker.point = coordinate
        
        // 设置标记样式
        marker.stylingString = """
        {
            style: 'points',
            color: 'white',
            size: [16px, 16px],
            order: 999,
            collide: false
        }
        """
        // 直接设置图标图片
        if let image = SWKitModule.image(named: "map_track_end") {
            marker.icon = image
        }
        
        pointMarkers.append(marker)
    }

    //MARK: - Test
    func testSavePoints() {
        // 批量写入轨迹点
        sampleRecords().forEach { loc in
            self.writePoint(loc)
        }
    }
    
    func sampleRecords() -> [CLLocation] {
        // 沿东北方向生成12个点，每个点间隔约12米
        var points: [CLLocation] = []
        let baseLatitude = 30.667323
        let baseLongitude = 103.959066

        // 每6米大约对应0.000054纬度差（1度≈111km）
        let meterPerDegreeLat: Double = 1.0 / 111000.0
        let meterPerDegreeLng: Double = 1.0 / (111000.0 * cos(baseLatitude * .pi / 180.0))

        // 主方向：东北方向（45度，即π/4）
        let mainDirection: Double = .pi / 4  // 45度，东北方向
        let distancePerStep: Double = 12.0   // 每步12米

        // 主方向的基础偏移量
        let baseDeltaLat = distancePerStep * cos(mainDirection) * meterPerDegreeLat
        let baseDeltaLng = distancePerStep * sin(mainDirection) * meterPerDegreeLng

        var currentLat = baseLatitude
        var currentLng = baseLongitude

        for i in 0..<12 {
            // 添加小的随机偏移（±20度范围内），使轨迹更自然
            let angleOffset = Double.random(in: -0.35...0.35)  // 约±20度
            let adjustedAngle = mainDirection + angleOffset

            // 计算该步的实际偏移
            let deltaLat = distancePerStep * cos(adjustedAngle) * meterPerDegreeLat
            let deltaLng = distancePerStep * sin(adjustedAngle) * meterPerDegreeLng

            // 累加偏移量
            currentLat += deltaLat
            currentLng += deltaLng

            // 时间戳每次递增3秒
            let timestamp = Date().addingTimeInterval(TimeInterval(i * 3))

            let location = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLng),
                altitude: 501,
                horizontalAccuracy: 1,
                verticalAccuracy: 1,
                timestamp: timestamp
            )
            points.append(location)
        }

        return points
    }
}

// MARK: - CLLocationManagerDelegate

extension TrackManager: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        // 记录权限状态变化
        Logger.debug("定位权限状态变化: \(status.rawValue)")
        setupBackgroundLocationUpdates()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard recording == true else { return }
        saveNewLocation(location)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.debug("定位失败: \(error)")
        
        // 如果是权限错误，尝试重新请求权限
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                Logger.debug("定位权限被拒绝")
            case .locationUnknown:
                Logger.debug("位置未知，等待系统自动重试...")
                // 注意：使用startUpdatingLocation时，系统会自动重试，无需手动调用
            default:
                Logger.debug("定位错误: \(clError.code.rawValue)")
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

