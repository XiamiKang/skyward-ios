//
//  LocationClassifier.swift
//  Pods
//
//  Created by TXTS on 2026/2/10.
//


import UIKit
import CoreLocation

// MARK: - 位置区域枚举（简化版）
public enum LocationRegion {
    case domestic  // 国内
    case overseas  // 国外
    
    var isDomestic: Bool {
        return self == .domestic
    }
    
    var isOverseas: Bool {
        return self == .overseas
    }
    
    // 便捷访问属性
    static var isInChina: Bool {
        return LocationRegionManager.shared.currentRegion.isDomestic
    }
}

// MARK: - 精简版位置管理器
public class LocationRegionManager: NSObject {
    
    // MARK: - 单例
    public static let shared = LocationRegionManager()
    
    // MARK: - 属性
    private(set) var currentRegion: LocationRegion = .domestic  // 默认国内
    
    // MARK: - 私有属性
    private let locationManager = CLLocationManager()
    
    // 中国的边界坐标（简化版）
    private let chinaBounds = (
        minLat: 18.0, maxLat: 53.0,
        minLng: 73.0, maxLng: 135.0
    )
    
    // MARK: - 初始化
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - 配置
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - 公开方法
    
    /// 启动位置服务（静默启动）
    public func startLocationService() {
        // 检查权限状态
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // 不主动请求权限，直接使用默认值（国内）
            return
        case .denied, .restricted:
            // 权限被拒，使用默认值（国内）
            return
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        @unknown default:
            return
        }
    }
    
    /// 获取当前区域状态
    func getCurrentRegion() -> LocationRegion {
        return currentRegion
    }
    
    /// 判断位置是否在中国边界内
    private func isLocationInChina(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return (coordinate.latitude >= chinaBounds.minLat &&
                coordinate.latitude <= chinaBounds.maxLat) &&
               (coordinate.longitude >= chinaBounds.minLng &&
                coordinate.longitude <= chinaBounds.maxLng)
    }
    
    /// 更新区域状态（内部使用）
    private func updateRegion(_ region: LocationRegion) {
        
        DispatchQueue.main.async {
            self.currentRegion = region
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationRegionManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("yifan-----手机定位：lat=\(location.coordinate.latitude),log=\(location.coordinate.longitude)")
        let isInChina = isLocationInChina(location.coordinate)
        updateRegion(isInChina ? .domestic : .overseas)
        MapConfig.shared.resetCurrentTileSourceName()
        // 获取到位置后停止更新以省电
        manager.stopUpdatingLocation()
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 定位失败，保持默认的国内状态
        print("定位失败，使用默认国内状态")
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 权限变化时，如果有权限就尝试获取位置
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
}


// MARK: - 全局便捷访问
/// 判断是否在国内（全局函数）
public func isInChina() -> Bool {
    return LocationRegionManager.shared.currentRegion.isDomestic
}

/// 判断是否在国外（全局函数）
public func isOverseas() -> Bool {
    return LocationRegionManager.shared.currentRegion.isOverseas
}

/// 获取当前区域（全局函数）
public func currentRegion() -> LocationRegion {
    return LocationRegionManager.shared.getCurrentRegion()
}

/// 根据区域执行不同的逻辑
public func runByRegion(domestic: () -> Void, overseas: () -> Void) {
    if isInChina() {
        domestic()
    } else {
        overseas()
    }
}

/// 根据区域返回不同的值
public func valueByRegion<T>(domestic: T, overseas: T) -> T {
    return isInChina() ? domestic : overseas
}
