//
//  CoordinateTransform.swift
//  Pods
//
//  Created by TXTS on 2026/1/5.
//


import CoreLocation

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
