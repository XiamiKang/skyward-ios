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
           locationManager.allowsBackgroundLocationUpdates = true
           locationManager.showsBackgroundLocationIndicator = true
       } else {
           debugPrint("警告: 应用程序未配置后台定位模式，后台定位更新已禁用")
           locationManager.allowsBackgroundLocationUpdates = false
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
        let magneticHeading = newHeading.magneticHeading
        
        // 通知方向更新
        onHeadingUpdate?(magneticHeading)
    }
}
