//
//  MapConfig.swift
//  Pods
//
//  Created by TXTS on 2025/12/18.
//

import Foundation
import CoreLocation

public class MapConfig {
    // MARK: - 单例实例
    public static let shared = MapConfig()
    
    // MARK: - 配置属性
    public var sceneFileName: String = "scene3d"
    public var minZoom: CGFloat = 0.0
    public var maxZoom: CGFloat = 20.5
    public var userPosition = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
    public var defaultZoom: CGFloat = 15.0
    public var showCompass: Bool = true
    public var showScaleBar: Bool = true
    
    // 地图源配置
    public private(set) var tileSources: [String: String] = [
        "天地图街道": "http://t1.tianditu.com/DataServer?T=vec_w&x={x}&y={y}&l={z}&tk=88e2f1d5ab64a7477a7361edd6b5f68a",
        "天地图影像": "http://t1.tianditu.com/DataServer?T=img_w&x={x}&y={y}&l={z}&tk=88e2f1d5ab64a7477a7361edd6b5f68a",
        "吉林长光影像": "https://api.jl1mall.com/getMap/{z}/{x}/{y}?mk=3ddec00f5f435270285ffc7ad1a60ce5&tk=c4e73a6b0428f65a94fb6fbe677d2375",
        "海图": "https://m12.shipxy.com/tile.c?l=Na&m=o&x={x}&y={y}&z={z}",
        "谷歌地图": "https://gdtc.shipxy.com/tile.g?z={z}&x={x}&y={y}",
        "谷歌卫星": "https://gwxc.shipxy.com/tile.g?z={z}&x={x}&y={y}"
    ]
    
    /// 当前选中的地图源名称
    public var currentTileSourceName: String = "吉林长光影像"
    
    /// 当前选中的地图源URL
    public var currentTileSourceURL: String? {
        return tileSources[currentTileSourceName]
    }
    
    /// 默认的地图源路径（根据你的实际配置修改）
    public var tileSourcePath: String {
        return "sources.satellite.url"
    }
    
    // MARK: - 私有初始化方法（确保单例）
    private init() {
        // 可以在这里加载保存的配置
        loadSavedConfig()
    }
    
    // MARK: - 配置管理方法
    
    /// 添加新的地图源
    public func addTileSource(name: String, url: String) {
        tileSources[name] = url
    }
    
    /// 移除地图源
    public func removeTileSource(name: String) {
        tileSources.removeValue(forKey: name)
        if currentTileSourceName == name {
            currentTileSourceName = tileSources.keys.first ?? ""
        }
    }
    
    /// 切换地图源
    public func switchTileSource(to name: String) -> Bool {
        guard tileSources[name] != nil else {
            print("未找到地图源: \(name)")
            return false
        }
        
        currentTileSourceName = name
        saveConfig()
        return true
    }
    
    /// 获取所有可用的地图源名称
    public func getAvailableTileSourceNames() -> [String] {
        return Array(tileSources.keys).sorted()
    }
    
    // MARK: - 配置持久化
    
    private let configKey = "MapConfig_UserDefaults_Key"
    
    /// 保存配置到 UserDefaults
    public func saveConfig() {
        let configDict: [String: Any] = [
            "sceneFileName": sceneFileName,
            "minZoom": minZoom,
            "maxZoom": maxZoom,
            "userPositionLatitude": userPosition.latitude,
            "userPositionLongitude": userPosition.longitude,
            "defaultZoom": defaultZoom,
            "showCompass": showCompass,
            "showScaleBar": showScaleBar,
            "currentTileSourceName": currentTileSourceName
        ]
        
        UserDefaults.standard.set(configDict, forKey: configKey)
        UserDefaults.standard.synchronize()
        
        print("地图配置已保存")
    }
    
    /// 从 UserDefaults 加载配置
    private func loadSavedConfig() {
        guard let configDict = UserDefaults.standard.dictionary(forKey: configKey) else {
            print("没有保存的地图配置，使用默认值")
            return
        }
        
        if let sceneFileName = configDict["sceneFileName"] as? String {
            self.sceneFileName = sceneFileName
        }
        
        if let minZoom = configDict["minZoom"] as? CGFloat {
            self.minZoom = minZoom
        }
        
        if let maxZoom = configDict["maxZoom"] as? CGFloat {
            self.maxZoom = maxZoom
        }
        
        if let lat = configDict["userPositionLatitude"] as? Double,
           let lon = configDict["userPositionLongitude"] as? Double {
            self.userPosition = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        if let defaultZoom = configDict["defaultZoom"] as? CGFloat {
            self.defaultZoom = defaultZoom
        }
        
        if let showCompass = configDict["showCompass"] as? Bool {
            self.showCompass = showCompass
        }
        
        if let showScaleBar = configDict["showScaleBar"] as? Bool {
            self.showScaleBar = showScaleBar
        }
        
        if let tileSourceName = configDict["currentTileSourceName"] as? String {
            self.currentTileSourceName = tileSourceName
        }
        
        print("地图配置已加载: \(currentTileSourceName)")
    }
    
    // MARK: - 重置配置
    public func resetToDefaults() {
        sceneFileName = "scene3d"
        minZoom = 0.0
        maxZoom = 20.5
        userPosition = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        defaultZoom = 15.0
        showCompass = true
        showScaleBar = true
        currentTileSourceName = "天地图影像"
        
        UserDefaults.standard.removeObject(forKey: configKey)
        print("地图配置已重置为默认值")
    }
    
    // MARK: - 配置信息
    public var configInfo: [String: Any] {
        return [
            "sceneFileName": sceneFileName,
            "minZoom": minZoom,
            "maxZoom": maxZoom,
            "userPosition": "\(userPosition.latitude), \(userPosition.longitude)",
            "defaultZoom": defaultZoom,
            "showCompass": showCompass,
            "showScaleBar": showScaleBar,
            "currentTileSource": currentTileSourceName,
            "availableTileSources": getAvailableTileSourceNames(),
            "tileSourcesCount": tileSources.count
        ]
    }
}
