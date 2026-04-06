//
//  LocationManager.swift
//  SWKit
//
//  Created by zhaobo on 2024/11/25.
//

import Foundation
import CoreLocation
import UIKit

/// 定位管理类
public typealias LocationPermissionCompletion = (CLAuthorizationStatus) -> Void
public typealias LocationUpdateCompletion = (CLLocation?, Error?) -> Void
public typealias ReverseGeocodeCompletion = (CLPlacemark?, Error?) -> Void

let lastLocationKey = "lastLocationKey"

public class LocationManager: NSObject {
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    public var authorizationStatus: CLAuthorizationStatus {
        get {
            locationManager.authorizationStatus
        }
    }
    private var lastHeadingUpdateTime: Date = Date()
    private var locationTimeoutTimer: Timer?
    
    // 闭包
    private var permissionCompletion: LocationPermissionCompletion?
    private var onceLocationUpdateCompletion: LocationUpdateCompletion?
    private var locationUpdateCompletion: LocationUpdateCompletion?
    public var onHeadingUpdate: ((CLLocationDirection) -> Void)?
    
    // MARK: - Initializer
    public override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        
        // 减少电池消耗的设置
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.activityType = .other

        
        // 设置后台定位权限 - 只有在确认有权限时才启用
        // 注意：需要在Xcode项目中配置"Background Modes"中的"Location updates"
        if UIApplication.shared.backgroundRefreshStatus == .available, locationManager.authorizationStatus == .authorizedAlways {
           locationManager.showsBackgroundLocationIndicator = true
       } else {
           debugPrint("警告: 应用程序未配置后台定位模式，后台定位更新已禁用")
       }

    }
    
    // MARK: - Permission Management
    /// 请求定位权限
    public func requestLocationPermission(completion: LocationPermissionCompletion?) {
        self.permissionCompletion = completion
        
        // 检查当前权限状态
        let status = authorizationStatus
        
        switch status {
        case .notDetermined:
            // 首先请求使用App期间权限
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // 如果已有使用App期间权限，可以根据需要请求始终权限
            // 注意：在iOS 13及以上版本，需要先获得使用App期间权限，才能请求始终权限
            locationManager.requestAlwaysAuthorization()
            completion?(status)
        default:
            // 其他状态直接返回
            completion?(status)
        }
    }
    
    // MARK: - 定位
    /// 开始持续定位
    public func startContinuousLocationUpdates(updateHandler: LocationUpdateCompletion? = nil) {
        // 检查权限
        let status = authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            updateHandler?(nil, NSError(domain: "LocationError", code: 100, userInfo: [NSLocalizedDescriptionKey: "定位权限被拒绝"]))
            return
        }
        
        self.locationUpdateCompletion = updateHandler
        
        // 开始定位
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /// 停止持续定位
    public func stopContinuousLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    /// 单次定位
    public func getCurrentLocation(completion: @escaping LocationUpdateCompletion) {
        let status = authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            completion(nil, NSError(domain: "LocationError", code: 100, userInfo: [NSLocalizedDescriptionKey: "定位权限被拒绝"]))
            return
        }
        
        // 使用局部变量强引用 self，确保在闭包执行期间实例不会被释放
        // 闭包执行完毕后，manager 变量释放，实例随后被释放
        let manager = self
        self.locationUpdateCompletion = { location, error in
            completion(location, error)
            manager.locationTimeoutTimer?.invalidate()
            manager.locationUpdateCompletion = nil
        }
        
        // 设置超时定时器
        locationTimeoutTimer?.invalidate() // 确保之前的定时器已停止
        locationTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            manager.locationUpdateCompletion?(nil, NSError(domain: "LocationError", code: 102, userInfo: [NSLocalizedDescriptionKey: "定位请求超时"]))
            manager.locationUpdateCompletion = nil
        }
        
        // 执行定位请求
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestLocation()
    }
    
    // 获取上次的定位信息
    public static func lastLocation() -> CLLocation? {
        guard let lastLocationDict = UserDefaults.standard.value(forKey: lastLocationKey) as? [String: Double] else {
            return nil
        }
        return CLLocation(latitude: lastLocationDict["latitude"]!, longitude: lastLocationDict["longitude"]!)
    }

    // MARK: - Reverse Geocoding

    /// 获取地址信息（便捷方法，带超时，使用独立的 geocoder 实例）
    /// - Parameters:
    ///   - location: 要转换的坐标位置
    ///   - timeout: 超时时间（秒），默认 2 秒
    ///   - completion: 完成回调，返回 CLPlacemark（包含地址信息）
    public static func reverseGeocode(location: CLLocation, timeout: TimeInterval = 2.0, completion: @escaping (CLPlacemark?) -> Void) {
        // 为每个请求创建独立的 geocoder 实例，避免并发请求相互取消
        let independentGeocoder = CLGeocoder()
        var hasCompleted = false

        // 超时处理
        let timeoutWorkItem = DispatchWorkItem {
            guard !hasCompleted else { return }
            hasCompleted = true
            debugPrint("反地理编码超时")
            independentGeocoder.cancelGeocode()
            completion(nil)
        }

        // 执行超时任务
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        debugPrint("反地理编码经度：\(location.coordinate.longitude),纬度: \(location.coordinate.latitude)")

        // 执行反地理编码
        independentGeocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard !hasCompleted else { return }
            hasCompleted = true
            timeoutWorkItem.cancel()

            if let error = error {
                debugPrint("反地理编码失败: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let placemark = placemarks?.first else {
                debugPrint("反地理编码失败: 未找到地址信息")
                completion(nil)
                return
            }

            debugPrint("反地理编码成功: \(placemark.subLocality ?? "未知位置"), \(placemark.locality ?? "")")
            completion(placemark)
        }
    }
    
    public func navigationToGaodeMap(with coordinate: CLLocationCoordinate2D, destinationName: String) {
        getCurrentLocation { [weak self] location, error in
            guard let self = self else { return }
            let startLat = location?.coordinate.latitude ?? 0.0
            let startLon = location?.coordinate.latitude ?? 0.0
            let coordinate = CoordinateTransform.wgs84ToGcj02(CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude))
            let endLat = coordinate.latitude
            let endLon = coordinate.longitude
            openAmapNavigation(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon, destinationName: destinationName)
        }
    }
    
    private func openAmapNavigation(startLat: Double, startLon: Double,
                           endLat: Double, endLon: Double,
                           destinationName: String) {
        let urlString = "iosamap://path?sourceApplication=skyward&sid=BGVIS1&slat=\(startLat)&slon=\(startLon)&sname=我的位置&did=BGVIS2&dlat=\(endLat)&dlon=\(endLon)&dname=\(destinationName)&dev=0&t=0"
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // 未安装高德地图，跳转App Store下载
            let appStoreURL = URL(string: "https://apps.apple.com/cn/app/id461703208")!
            UIApplication.shared.open(appStoreURL)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        permissionCompletion?(status)
        
        // 记录权限状态变化
        print("定位权限状态变化: \(status.rawValue)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 检查位置的有效性
        guard let location = locations.last else {
            locationUpdateCompletion?(nil, NSError(domain: "LocationError", code: 101, userInfo: [NSLocalizedDescriptionKey: "无效的位置数据"]))
            onceLocationUpdateCompletion?(nil, NSError(domain: "LocationError", code: 101, userInfo: [NSLocalizedDescriptionKey: "无效的位置数据"]))
            return
        }
        locationUpdateCompletion?(location, nil)
        onceLocationUpdateCompletion?(location, nil)
        
        UserDefaults.standard.setValue(["latitude": location.coordinate.latitude, "longitude": location.coordinate.longitude], forKey: lastLocationKey)
        debugPrint("定位成功: 经度:\(location.coordinate.longitude),纬度:\(location.coordinate.latitude)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationUpdateCompletion?(nil, error)
        onceLocationUpdateCompletion?(nil, error)
        debugPrint("定位失败: \(error)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // 限制更新频率（避免UI过于频繁更新）
        let now = Date()
        if now.timeIntervalSince(lastHeadingUpdateTime) < 0.1 {  // 100毫秒
            return
        }
        lastHeadingUpdateTime = now
        
        // 获取磁北方向
        let magneticHeading = newHeading.trueHeading
        
        // 通知方向更新
        onHeadingUpdate?(magneticHeading)
    }
}

public class CoordinateTransform {
    
    // 定义常量
    private struct Constants {
        static let pi = Double.pi
        static let a = 6378245.0 // WGS-84 长半轴
        static let ee = 0.00669342162296594323 // WGS-84 偏心率平方
    }
    
    /// 判断坐标是否在中国境外
    private static func isOutOfChina(lat: Double, lng: Double) -> Bool {
        if lng < 72.004 || lng > 137.8347 {
            return true
        }
        if lat < 0.8293 || lat > 55.8271 {
            return true
        }
        return false
    }
    
    /// 转换经度
    private static func transformLon(x: Double, y: Double) -> Double {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * Constants.pi) + 20.0 * sin(2.0 * x * Constants.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * Constants.pi) + 40.0 * sin(x / 3.0 * Constants.pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * Constants.pi) + 300.0 * sin(x / 30.0 * Constants.pi)) * 2.0 / 3.0
        return ret
    }
    
    /// 转换纬度
    private static func transformLat(x: Double, y: Double) -> Double {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * Constants.pi) + 20.0 * sin(2.0 * x * Constants.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * Constants.pi) + 40.0 * sin(y / 3.0 * Constants.pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * Constants.pi) + 320.0 * sin(y * Constants.pi / 30.0)) * 2.0 / 3.0
        return ret
    }
    
    /// WGS-84 转 GCJ-02（火星坐标）
    /// - Parameter wgsCoord: WGS-84 坐标
    /// - Returns: GCJ-02 坐标
    public static func wgs84ToGcj02(_ wgsCoord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 如果坐标在中国境外，直接返回原坐标
        if isOutOfChina(lat: wgsCoord.latitude, lng: wgsCoord.longitude) {
            return wgsCoord
        }
        
        let wgsLat = wgsCoord.latitude
        let wgsLon = wgsCoord.longitude
        
        var dLat = transformLat(x: wgsLon - 105.0, y: wgsLat - 35.0)
        var dLon = transformLon(x: wgsLon - 105.0, y: wgsLat - 35.0)
        
        let radLat = wgsLat / 180.0 * Constants.pi
        var magic = sin(radLat)
        magic = 1 - Constants.ee * magic * magic
        let sqrtMagic = sqrt(magic)
        
        dLat = (dLat * 180.0) / ((Constants.a * (1 - Constants.ee)) / (magic * sqrtMagic) * Constants.pi)
        dLon = (dLon * 180.0) / (Constants.a / sqrtMagic * cos(radLat) * Constants.pi)
        
        let mgLat = wgsLat + dLat
        let mgLon = wgsLon + dLon
        
        return CLLocationCoordinate2D(latitude: mgLat, longitude: mgLon)
    }
    
    /// GCJ-02 转 WGS-84
    /// - Parameter gcjCoord: GCJ-02 坐标
    /// - Returns: WGS-84 坐标（近似值）
    static func gcj02ToWgs84(_ gcjCoord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // 如果坐标在中国境外，直接返回原坐标
        if isOutOfChina(lat: gcjCoord.latitude, lng: gcjCoord.longitude) {
            return gcjCoord
        }
        
        var wgsCoord = wgs84ToGcj02(gcjCoord)
        let latDiff = gcjCoord.latitude - wgsCoord.latitude
        let lonDiff = gcjCoord.longitude - wgsCoord.longitude
        
        wgsCoord.latitude = gcjCoord.latitude + latDiff
        wgsCoord.longitude = gcjCoord.longitude + lonDiff
        
        return wgsCoord
    }
    
    /// GCJ-02 转 BD-09（百度坐标）
    static func gcj02ToBd09(_ gcjCoord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let x = gcjCoord.longitude
        let y = gcjCoord.latitude
        let z = sqrt(x * x + y * y) + 0.00002 * sin(y * Constants.pi)
        let theta = atan2(y, x) + 0.000003 * cos(x * Constants.pi)
        let bdLon = z * cos(theta) + 0.0065
        let bdLat = z * sin(theta) + 0.006
        return CLLocationCoordinate2D(latitude: bdLat, longitude: bdLon)
    }
    
    /// BD-09 转 GCJ-02
    static func bd09ToGcj02(_ bdCoord: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let x = bdCoord.longitude - 0.0065
        let y = bdCoord.latitude - 0.006
        let z = sqrt(x * x + y * y) - 0.00002 * sin(y * Constants.pi)
        let theta = atan2(y, x) - 0.000003 * cos(x * Constants.pi)
        let gcjLon = z * cos(theta)
        let gcjLat = z * sin(theta)
        return CLLocationCoordinate2D(latitude: gcjLat, longitude: gcjLon)
    }
}
