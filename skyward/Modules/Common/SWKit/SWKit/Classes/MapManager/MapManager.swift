//
//  MapManager.swift
//  SWKit
//
//  Created by TXTS on 2025/12/9.
//

import Foundation
import UIKit
import TangramMap
import CoreLocation

public class MapManager: NSObject {
    
    // MARK: - 属性
    public private(set) var mapView: TGMapView?
    public private(set) var markerLayerManager: MarkerLayerManager?
    // 使用单例配置
    private var config: MapConfig {
        return MapConfig.shared
    }
    
    // 定位相关 - 替换为统一的LocationManager
    private let locationManager = LocationManager()
    public var userLocationMarker: TGMarker?
    public var pointLocationMarker: TGMarker?
    private var cityWeatherMapData: TGMapData?
    private var cityWeatherDatas: [CityWeatherData] = []
    private var isFollowingUserLocation = true
    private var sceneUpdates: [TGSceneUpdate] = [] // 当前应用的地图场景更新
    
    // 权限
    public var isMeasurementStatus: Bool = false    // 是否测量状态
    public var isTrajectoryStatus: Bool = false     // 是否添加轨迹状态
    
    // 回调
    public var onSceneLoaded: ((Int32) -> Void)?
    public var onMapError: ((Error) -> Void)?
    public var onUserLocationUpdated: ((CLLocationCoordinate2D, Double?) -> Void)? // 添加精度参数
    public var onMarkerSelected: ((String, MarkerData, String) -> Void)?
    public var onLayerVisibilityChanged: ((String, Bool) -> Void)?
    public var onLocationPermissionChanged: ((CLAuthorizationStatus) -> Void)?
    public var onTileSourceChanged: ((String) -> Void)? // 地图源切换回调
    public var onMapSingleTapHandler: ((CLLocationCoordinate2D, CGPoint) -> Void)?
    public var onMapPanHandler: (() -> Void)?
    public var onScreenshotCaptured: ((UIImage) -> Void)? // 截图完成回调
    
    // 状态跟踪
    private var isInitialized = false
    private var hasLoadedScene = false
    
    // MARK: - 公开的初始化方法
    public override init() {
        super.init()
        
        setupLocationManager()
    }
    
    /// 创建地图视图（适用于不同尺寸的容器）
    public func createMapView(in containerView: UIView? = nil, frame: CGRect? = nil) -> TGMapView {
        // 如果已存在地图视图，先清理
        if let existingMapView = mapView {
            // 保存当前相机状态
            let cameraPosition = existingMapView.cameraPosition
            removeMapView()
            
            // 创建新地图视图
            let newMapView = createNewMapView(in: containerView, frame: frame)
            
            // 恢复相机位置
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                newMapView.cameraPosition = cameraPosition
            }
            
            return newMapView
        } else {
            // 创建新地图视图
            return createNewMapView(in: containerView, frame: frame)
        }
    }
    
    private func createNewMapView(in containerView: UIView? = nil, frame: CGRect? = nil) -> TGMapView {
        // 确定视图框架
        let mapFrame: CGRect
        if let frame = frame {
            mapFrame = frame
        } else if let containerView = containerView {
            mapFrame = containerView.bounds
        } else {
            // 默认框架
            mapFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        
        // 创建地图视图
        let newMapView = TGMapView(frame: mapFrame)
        newMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 应用配置
        newMapView.minimumZoomLevel = config.minZoom
        newMapView.maximumZoomLevel = config.maxZoom
        newMapView.cameraType = .perspective
        newMapView.zoom = config.defaultZoom
        newMapView.padding = UIEdgeInsets(top: 20, left: 20, bottom: 100, right: 20)
        
        
        // 设置委托
        newMapView.mapViewDelegate = self
        newMapView.gestureDelegate = self
        
        // 保存引用
        self.mapView = newMapView
        
        // 初始化标记层管理器
        setupMarkerLayerManager()
        // 设置地图瓦片缓存
        setupMapCacheTiles()
        
        if config.showUserLocation {
            createUserLocationMarker()
        }
        
        loadMapWithCurrentTileSource()
        
        newMapView.cameraPosition = TGCameraPosition(center: config.userPosition, zoom: config.defaultZoom, bearing: 0, pitch: 0)
        
        // 添加到容器视图
        if let containerView = containerView {
            containerView.addSubview(newMapView)
        }
        
        print("创建新的地图视图，大小: \(mapFrame.size)")
        
        return newMapView
    }
    
    /// 更新地图视图大小
    public func updateMapViewFrame(_ frame: CGRect) {
        mapView?.frame = frame
        mapView?.setNeedsLayout()
        mapView?.layoutIfNeeded()
    }
    
    /// 移除地图视图（但不销毁管理器状态）
    public func removeMapView() {
        // 停止定位跟踪
        stopLocationTracking()
        
        // 移除地图视图
        mapView?.removeFromSuperview()
        
        // 清除地图视图引用，但保留其他状态
        markerLayerManager = nil
        userLocationMarker = nil
        
        print("地图视图已移除")
    }
    
    // MARK: - 设置方法
    private func setupMarkerLayerManager() {
        guard let mapView = mapView else {
            print("地图视图未创建，无法设置标记层管理器")
            return
        }
        
        markerLayerManager = MarkerLayerManager(mapView: mapView)
        
        // 设置回调
        markerLayerManager?.onMarkerSelected = { [weak self] markerId, data, layerId in
            self?.onMarkerSelected?(markerId, data, layerId)
        }
        
        markerLayerManager?.onLayerVisibilityChanged = { [weak self] layerId, isVisible in
            self?.onLayerVisibilityChanged?(layerId, isVisible)
        }
    }
    
    private func setupLocationManager() {
        // 请求定位权限
        locationManager.requestLocationPermission { [weak self] status in
            print("定位权限状态: \(status)")
            self?.onLocationPermissionChanged?(status)
        }
    }
    
    // MARK: - 地图源管理
    
    /// 获取所有可用的地图源
    public func getAvailableTileSources() -> [String: String] {
        return config.tileSources
    }
    
    /// 切换地图源
    public func switchTileSource(to sourceName: String, completion: ((Bool) -> Void)? = nil) {
        
        let success = config.switchTileSource(to: sourceName)
        
        // 保存当前标注数据
        let savedData = markerLayerManager?.saveMarkerData() ?? [:]
        
        if success, let tileSourceURL = config.currentTileSourceURL {
            
            let mapUpdates = creatMapUpdates(tileSourceURL: tileSourceURL)
            
            self.sceneUpdates = mapUpdates
            
            // 重新加载地图
            loadMapWithUpdates(self.sceneUpdates)
            
            onTileSourceChanged?(sourceName)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                // 添加自己位置
                self?.createUserLocationMarker()
                // 添加标注图层
                self?.markerLayerManager?.restoreMarkerData(savedData)
                // 回调
                self?.onTileSourceChanged?(sourceName)
            }
        }
        
        completion?(success)
        print("切换地图源结果: \(success ? "成功" : "失败")")
    }
    
    public func uploadNotesLayer(with isShow: Bool) {
        let roadUpdate = TGSceneUpdate()
        roadUpdate.path = "layers.road-overlay.visible"
        roadUpdate.value = "\(isShow)"
        
        loadMapWithUpdates([roadUpdate])
    }
    
    public func loadMapWithCurrentTileSource() {
        if let tileSourceURL = config.currentTileSourceURL {
            let mapUpdates = creatMapUpdates(tileSourceURL: tileSourceURL)
            loadMapWithUpdates(mapUpdates)
        } else {
            loadMapWithUpdates([])
        }
    }
    
    private func setupMapCacheTiles() {
        guard let mapView = mapView else { return }
        // 缓存地图瓦片到Caches目录下的tiles文件夹中（需要在mapView.loadScene前）
        if let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
            let tileCachePath = cacheDirectory + "/tiles"
            let fileManager = FileManager.default
            // 检查tiles文件夹是否存在，不存在则创建
            if !fileManager.fileExists(atPath: tileCachePath) {
                do {
                    try fileManager.createDirectory(atPath: tileCachePath, withIntermediateDirectories: true, attributes: nil)
                    Logger.debug("tiles文件夹创建成功: \(tileCachePath)")
                } catch {
                    Logger.debug("创建tiles文件夹失败: \(error)")
                }
            }
            mapView.setDiskTileCache(tileCachePath, cacheSizeBytes: 256 * 1024 * 1024)
        }
    }
    
    private func creatMapUpdates(tileSourceURL: String) -> [TGSceneUpdate] {
        let update = TGSceneUpdate()
        update.path = config.tileSourcePath
        update.value = tileSourceURL
        
        let tmsUpdate = TGSceneUpdate()
        tmsUpdate.path = "sources.satellite.tms"
        tmsUpdate.value = tileSourceURL.contains("jl1mall") ? "true" : "false"
        
        let cacheNameUpdate = TGSceneUpdate()
        cacheNameUpdate.path = "sources.satellite.cache"
        if tileSourceURL.contains("http://t1.tianditu.com/DataServer?T=vec") {
            cacheNameUpdate.value = "tianditu-vec"
        }
        if tileSourceURL.contains("http://t1.tianditu.com/DataServer?T=img") {
            cacheNameUpdate.value = "tianditu-img"
        }
        if tileSourceURL.contains("jl1mall") {
            cacheNameUpdate.value = "jl1mall"
        }
        if tileSourceURL.contains("googleapis") {
            cacheNameUpdate.value = "google"
        }
        
        return [update,tmsUpdate,cacheNameUpdate]
    }
    
    // MARK: - 地图加载方法
    
    /// 加载地图场景
    public func loadMap() {
        guard let _ = mapView else {
            print("地图视图未创建，请先调用 createMapView()")
            return
        }
        
        // 如果有未完成的地图源更新，使用它们
        if !sceneUpdates.isEmpty {
            loadMapWithUpdates(sceneUpdates)
        } else {
            loadMapWithUpdates([])
        }
    }
    
    private func loadMapWithUpdates(_ updates: [TGSceneUpdate]) {
        guard let mapView = mapView else { return }
        
        guard let yamlPath = Bundle.main.path(forResource: config.sceneFileName, ofType: "yaml") else {
            print("地图配置文件未找到")
            return
        }
        
        guard let yamlContent = try? String(contentsOfFile: yamlPath, encoding: .utf8) else {
            print("无法读取地图配置")
            return
        }

        // 合并天气纹理场景更新
        let weatherTextureUpdates = createWeatherTextureSceneUpdates()
        var allUpdates = updates
        allUpdates.append(contentsOf: weatherTextureUpdates)

        let resourceURL = Bundle.main.resourceURL!
        mapView.loadScene(fromYAML: yamlContent, relativeTo: resourceURL, with: allUpdates)
        hasLoadedScene = false

        print("开始加载地图，使用更新数量: \(allUpdates.count)（包含天气纹理更新: \(weatherTextureUpdates.count)）")
    }
    
    // MARK: - 公开方法
    
    /// 开始定位
    public func startLocationTracking() {
        guard let _ = mapView else {
            print("地图视图未创建，无法开始定位")
            return
        }
        
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            print("没有定位权限")
            return
        }
        
        createUserLocationMarker()
        
        
        // 使用LocationManager的持续定位功能
        locationManager.startContinuousLocationUpdates { [weak self] locationPoint, error in
            guard let self = self else { return }
            
            if let error = error {
                print("定位更新错误: \(error)")
                return
            }
            
            guard let locationPoint = locationPoint else { return }
            
            // 更新用户位置
            let coordinate = CLLocationCoordinate2D(
                latitude: locationPoint.coordinate.latitude,
                longitude: locationPoint.coordinate.longitude
            )
            
            self.config.userPosition = coordinate
            
            // 更新用户位置标记
            self.updateUserLocationMarker(coordinate, accuracy: locationPoint.horizontalAccuracy)
            
            // 回调
            self.onUserLocationUpdated?(coordinate, locationPoint.horizontalAccuracy)
            
            // 如果开启了跟随，移动地图
            if self.isFollowingUserLocation {
                self.moveToUserLocation()
            }
            
            isFollowingUserLocation = false
        }
        
        locationManager.onHeadingUpdate = { [weak self] loaction in
            guard let self = self else { return }
            self.updateLocationMarker(to: loaction)
        }
    }
    
    /// 停止定位
    public func stopLocationTracking() {
        locationManager.stopContinuousLocationUpdates()
        isFollowingUserLocation = false
        print("停止定位跟踪")
    }
    
    /// 移动到用户位置
    public func moveToUserLocation() {
        guard let mapView = mapView else { return }
        let coordinate = config.userPosition
        let cameraPosition = TGCameraPosition(
            center: coordinate,
            zoom: config.defaultZoom,
            bearing: 0,
            pitch: mapView.pitch
        )
        
        guard let cameraPosition = cameraPosition else {
            print("相机点创建失败")
            return
        }
        
        mapView.cameraPosition = cameraPosition
        
        print("移动到用户位置: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    /// 获取用户当前位置（单次）
    public func getCurrentLocation(completion: @escaping (CLLocationCoordinate2D?, Double?, Error?) -> Void) {
        locationManager.getCurrentLocation { locationPoint, error in
            if let error = error {
                completion(nil, nil, error)
                return
            }
            
            guard let locationPoint = locationPoint else {
                completion(nil, nil, NSError(domain: "LocationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "未获取到位置"]))
                return
            }
            
            let coordinate = CLLocationCoordinate2D(
                latitude: locationPoint.coordinate.latitude,
                longitude: locationPoint.coordinate.longitude
            )
            self.config.userPosition = coordinate
            
            completion(coordinate, locationPoint.horizontalAccuracy, nil)
        }
    }
    
    /// 添加自定义标注
    public func addCustomMarker(layerId: String, coordinate: CLLocationCoordinate2D, title: String,
                                subtitle: String? = nil, style: MarkerStyle = PointMarkerStyle.default) -> String? {
        guard let markerLayerManager = markerLayerManager else {
            print("标记层管理器未初始化")
            return nil
        }
        
        let markerId = UUID().uuidString
        let data = MarkerData(id: markerId, coordinate: coordinate, title: title, subtitle: subtitle)
        
        return markerLayerManager.addMarker(to: layerId, data: data)
    }
    
    public func createPointLocationMarker(with coordinate: CLLocationCoordinate2D) {
        guard let mapView = mapView else { return }
        
        if let marker = pointLocationMarker {
            mapView.markerRemove(marker)
            pointLocationMarker = nil
        }
        
        // 创建用户位置标记
        pointLocationMarker = mapView.markerAdd()
        pointLocationMarker?.point = coordinate
        pointLocationMarker?.stylingString = """
        { style: 'points',
          interactive: true,
          color: 'white',
          size: [30px, 30px],
          order: 1005,
          collide: false }
        """
        pointLocationMarker?.icon = SWKitModule.image(named: "map_search_marker")!
        if let positon = TGCameraPosition(center: coordinate, zoom: 16, bearing: 0, pitch: mapView.pitch) {
            mapView.fly(to: positon, withSpeed: 6)
        }
    }
    
    // 创建天气点位
    public func createWeatherPointMarker(with coordinate: CLLocationCoordinate2D) {
        guard let mapView = mapView else { return }
        
        if let marker = pointLocationMarker {
            mapView.markerRemove(marker)
            pointLocationMarker = nil
        }
        pointLocationMarker = mapView.markerAdd()
        pointLocationMarker?.point = coordinate
        pointLocationMarker?.stylingString = """
        { style: 'points',
          interactive: false,
          color: 'white',
          size: [25px, 25px],
          order: 1006,
          collide: false }
        """
        pointLocationMarker?.icon = SWKitModule.image(named: "measure_start2")!
    }
    // 天气点位隐藏
    public func hideWeatherPointMarker() {
        guard let mapView = mapView, let marker = pointLocationMarker else { return }
        mapView.markerRemove(marker)
    }
    
    public func hideLocationMarker() {
        guard let marker = userLocationMarker else { return }
        marker.stylingString = """
        { style: 'points',
          interactive: false,
          color: 'transparent',
          size: [40px, 40px],
          order: 1000,
          collide: false,
          opacity: 0}
        """
    }

    public func showLocationMarker() {
        guard let marker = userLocationMarker else { return }
        marker.stylingString = """
        { style: 'points',
          interactive: false,
          color: 'white',
          size: [40px, 40px],
          order: 1000,
          collide: false }
        """
    }
    
    // MARK: - 私有方法
    
    private func createUserLocationMarker() {
        guard let mapView = mapView else { return }
        
        if let marker = userLocationMarker {
            mapView.markerRemove(marker)
            userLocationMarker = nil
        }
        
        // 创建用户位置标记
        userLocationMarker = mapView.markerAdd()
        userLocationMarker?.point = config.userPosition
        userLocationMarker?.stylingString = """
        { style: 'points',
          interactive: false,
          color: 'white',
          size: [40px, 40px],
          order: 1000,
          collide: false }
        """
        
        userLocationMarker?.drawOrder = 1000
        userLocationMarker?.icon = SWKitModule.image(named: "Location")!
    }
    
    private func updateUserLocationMarker(_ coordinate: CLLocationCoordinate2D, accuracy: Double?) {
        // 更新用户位置标记
        userLocationMarker?.point = coordinate
    }
    
    // MARK: - 状态检查
    
    /// 检查地图是否已准备就绪
    public var isMapReady: Bool {
        return mapView != nil && hasLoadedScene
    }
    
    /// 检查地图是否已创建
    public var hasMapView: Bool {
        return mapView != nil
    }
    
    // MARK: - 清理方法
    
    /// 完全重置地图管理器（清理所有状态）
    public func reset() {
        removeMapView()
        clearCallbacks()
        isInitialized = false
        hasLoadedScene = false
        isFollowingUserLocation = false
        isMeasurementStatus = false
        isTrajectoryStatus = false
        sceneUpdates = []
        
        print("地图管理器已重置")
    }
    
    /// 清除所有回调
    public func clearCallbacks() {
        onSceneLoaded = nil
        onMapError = nil
        onUserLocationUpdated = nil
        onMarkerSelected = nil
        onLayerVisibilityChanged = nil
        onLocationPermissionChanged = nil
        onTileSourceChanged = nil
        onScreenshotCaptured = nil
    }
}

// MARK: - TGMapViewDelegate
extension MapManager: TGMapViewDelegate {
    
    public func mapView(_ mapView: TGMapView, didLoadScene sceneID: Int32, withError sceneError: (any Error)?) {
        if let error = sceneError {
            print("地图加载失败: \(error)")
            onMapError?(error)
        } else {
            print("地图加载成功: \(sceneID)，当前地图源: \(config.currentTileSourceName)")
            hasLoadedScene = true
            onSceneLoaded?(sceneID)
            
            if config.showUserLocation {
                // 地图加载成功后检查定位权限
                let status = locationManager.authorizationStatus
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    startLocationTracking()
                }
                moveToUserLocation()
            }
        }
    }
    
    public func mapView(_ mapView: TGMapView, didSelectMarker markerPickResult: TGMarkerPickResult?,
                atScreenPosition position: CGPoint) {
        
        print("yifan----marker点击代理方法回调")
        
        guard let result = markerPickResult,
              let markerId = markerLayerManager?.findMarkerId(for: result.marker) else {
            return
        }
        
        // 在图层管理器中处理选择
        if let (layerId, _) = markerLayerManager?.findLayerAndData(for: markerId) {
            markerLayerManager?.selectMarker(markerId, in: layerId)
        }
    }

    public func mapView(_ mapView: TGMapView, didCaptureScreenshot screenshot: UIImage) {
        onScreenshotCaptured?(screenshot)
    }
}

extension MapManager {
    /// 显示/隐藏图层
    public func setLayerVisible(_ visible: Bool, layerId: String) {
        markerLayerManager?.setLayerVisible(visible, layerId: layerId)
    }
    
    /// 获取图层统计
    func getLayerStats() -> [(id: String, name: String, visible: Bool, count: Int)] {
        if let markerLayerManager = markerLayerManager {
            return markerLayerManager.getAllLayers().map { layer in
                (layer.id, layer.name, layer.isVisible, layer.markerCount)
            }
        }else {
            markerLayerManager = MarkerLayerManager(mapView: mapView!)
            return markerLayerManager!.getAllLayers().map { layer in
                (layer.id, layer.name, layer.isVisible, layer.markerCount)
            }
        }
    }
}


// MARK: - TGRecognizerDelegate
extension MapManager: TGRecognizerDelegate {
    
    public func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, didRecognizePanGesture displacement: CGPoint) {
        onMapPanHandler?()
    }
    
    public func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, didRecognizeSingleTapGesture location: CGPoint) {
        guard let mapView = mapView else { return }
        
        let coordinate = mapView.coordinate(fromViewPosition: location)
        print("单点手势位置：经度=\(coordinate.longitude)--纬度=\(coordinate.latitude)")

        onMapSingleTapHandler?(coordinate, location)
        
        // 如果是轨迹记录状态，添加轨迹点
        if isTrajectoryStatus {
            if markerLayerManager?.findMarker(for: "trajectory") == nil {
                _ = markerLayerManager?.createLayer(id: "trajectory", name: "轨迹", isVisible: true)
            }
            // 添加轨迹点
            _ = addCustomMarker(
                layerId: "trajectory",
                coordinate: coordinate,
                title: "轨迹点",
                subtitle: "手动添加的轨迹点",
                style: PointMarkerStyle(
                    color: "orange",
                    size: [12, 12]
                )
            )
        }
    }
    
}

// MARK: - 坐标范围计算
extension MapManager {
    
    /// 根据地图屏幕边界创建坐标数组用于POI请求
    public func createCoordinateArrayForPOIRequest() -> (
        topLeft: CLLocationCoordinate2D,
        topRight: CLLocationCoordinate2D,
        bottomLeft: CLLocationCoordinate2D,
        bottomRight: CLLocationCoordinate2D
    ) {
        guard let mapView = mapView else {
            // 如果地图视图不存在，返回默认坐标
            return getDefaultCoordinates()
        }
        
        // 获取屏幕的四个角点坐标
        let viewBounds = mapView.bounds
        
        // 计算四个角点的屏幕坐标
        let topLeftPoint = CGPoint(x: viewBounds.minX, y: viewBounds.minY)
        let topRightPoint = CGPoint(x: viewBounds.maxX, y: viewBounds.minY)
        let bottomLeftPoint = CGPoint(x: viewBounds.minX, y: viewBounds.maxY)
        let bottomRightPoint = CGPoint(x: viewBounds.maxX, y: viewBounds.maxY)
        
        // 将屏幕坐标转换为地理坐标
        let topLeftCoord = mapView.coordinate(fromViewPosition: topLeftPoint)
        let topRightCoord = mapView.coordinate(fromViewPosition: topRightPoint)
        let bottomLeftCoord = mapView.coordinate(fromViewPosition: bottomLeftPoint)
        let bottomRightCoord = mapView.coordinate(fromViewPosition: bottomRightPoint)
        
        // 确保坐标的有效性
        guard isValidCoordinate(topLeftCoord),
              isValidCoordinate(topRightCoord),
              isValidCoordinate(bottomLeftCoord),
              isValidCoordinate(bottomRightCoord) else {
            print("坐标无效，使用默认坐标")
            return getDefaultCoordinates()
        }
        
        print("屏幕边界坐标：")
        print("左上: (\(topLeftCoord.latitude), \(topLeftCoord.longitude))")
        print("右上: (\(topRightCoord.latitude), \(topRightCoord.longitude))")
        print("左下: (\(bottomLeftCoord.latitude), \(bottomLeftCoord.longitude))")
        print("右下: (\(bottomRightCoord.latitude), \(bottomRightCoord.longitude))")
        
        return (topLeftCoord, topRightCoord, bottomLeftCoord, bottomRightCoord)
    }
    
    /// 根据地图可见区域创建坐标数组（使用地图中心点和当前缩放级别）
    public func createCoordinateArrayFromVisibleArea() -> (
        topLeft: CLLocationCoordinate2D,
        topRight: CLLocationCoordinate2D,
        bottomLeft: CLLocationCoordinate2D,
        bottomRight: CLLocationCoordinate2D
    ) {
        guard let mapView = mapView else {
            return getDefaultCoordinates()
        }
        
        let center = mapView.position
        let zoom = mapView.zoom
        
        print("使用地图中心点创建范围: \(center.latitude), \(center.longitude)，缩放级别: \(zoom)")
        
        // 根据缩放级别计算范围大小
        // 缩放级别越高，显示的范围越小
        let baseDelta: Double = 1.0
        let zoomFactor = 1.0 / pow(2.0, zoom - 10.0) // 10级缩放作为基准
        
        // 计算经度和纬度的增量
        // 纬度：1度约111公里
        // 经度：在赤道上1度约111公里，随着纬度增加而减小
        let latDelta = baseDelta * zoomFactor
        let lonDelta = baseDelta * zoomFactor
        
        // 计算四个角的坐标
        let topLeftCoord = CLLocationCoordinate2D(
            latitude: center.latitude + latDelta,
            longitude: center.longitude - lonDelta
        )
        let topRightCoord = CLLocationCoordinate2D(
            latitude: center.latitude + latDelta,
            longitude: center.longitude + lonDelta
        )
        let bottomLeftCoord = CLLocationCoordinate2D(
            latitude: center.latitude - latDelta,
            longitude: center.longitude - lonDelta
        )
        let bottomRightCoord = CLLocationCoordinate2D(
            latitude: center.latitude - latDelta,
            longitude: center.longitude + lonDelta
        )
        
        return (topLeftCoord, topRightCoord, bottomLeftCoord, bottomRightCoord)
    }
    
    /// 创建坐标数组（根据当前视图的边界）
    public func createCoordinateArrayForCurrentView() -> [Coordinate] {
        let corners = createCoordinateArrayForPOIRequest()
        
        let coordinateList = [
            Coordinate(longitude: corners.topLeft.longitude, latitude: corners.topLeft.latitude),
            Coordinate(longitude: corners.topRight.longitude, latitude: corners.topRight.latitude),
            Coordinate(longitude: corners.bottomLeft.longitude, latitude: corners.bottomLeft.latitude),
            Coordinate(longitude: corners.bottomRight.longitude, latitude: corners.bottomRight.latitude)
        ]
        
        return coordinateList
    }
    
    /// 获取当前视图的地理边界
    public func getCurrentViewBounds() -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        let corners = createCoordinateArrayForPOIRequest()
        
        let latitudes = [corners.topLeft.latitude, corners.topRight.latitude,
                        corners.bottomLeft.latitude, corners.bottomRight.latitude]
        let longitudes = [corners.topLeft.longitude, corners.topRight.longitude,
                         corners.bottomLeft.longitude, corners.bottomRight.longitude]
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return (39.9, 40.0, 116.3, 116.5) // 默认值
        }
        
        return (minLat, maxLat, minLon, maxLon)
    }
    
    /// 检查坐标是否有效
    private func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        // 纬度范围：-90 到 90
        // 经度范围：-180 到 180
        return coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
               coordinate.longitude >= -180 && coordinate.longitude <= 180
    }
    
    /// 获取默认坐标（北京天安门附近）
    private func getDefaultCoordinates() -> (
        topLeft: CLLocationCoordinate2D,
        topRight: CLLocationCoordinate2D,
        bottomLeft: CLLocationCoordinate2D,
        bottomRight: CLLocationCoordinate2D
    ) {
        let center = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        let delta: Double = 0.1 // 约10公里范围
        
        return (
            topLeft: CLLocationCoordinate2D(latitude: center.latitude + delta, longitude: center.longitude - delta),
            topRight: CLLocationCoordinate2D(latitude: center.latitude + delta, longitude: center.longitude + delta),
            bottomLeft: CLLocationCoordinate2D(latitude: center.latitude - delta, longitude: center.longitude - delta),
            bottomRight: CLLocationCoordinate2D(latitude: center.latitude - delta, longitude: center.longitude + delta)
        )
    }
    
    private func updateLocationMarker(to heading: CLLocationDirection) {
        userLocationMarker?.stylingString = """
        { style: 'points',
          interactive: false,
          color: 'white',
          size: [40px, 40px],
          order: 1000,
          collide: false,
          angle: \(heading)
        }
        """
        userLocationMarker?.point = self.config.userPosition
    }
}


// MapManager+Weather.swift
extension MapManager {

    /// 生成天气纹理的场景更新
    /// 将Assets.xcassets中的天气图标转换为data URI并更新到场景中
    /// - Returns: 天气纹理的场景更新数组
    func createWeatherTextureSceneUpdates() -> [TGSceneUpdate] {
        var updates: [TGSceneUpdate] = []

        // 天气代码列表（对应scene3d.yaml中的textures定义）
        let weatherCodes = ["0", "1", "2", "3", "45", "48", "51", "53", "55", "56",
                            "57", "61", "63", "65", "66", "67", "71", "73", "75",
                            "77", "80", "81", "82", "85", "86", "95", "96", "99"]

        for code in weatherCodes {
            // 从Assets.xcassets加载对应的图片
            let imageName = "weather_\(code)"
            if let image = UIImage(named: imageName),
               let dataURI = createDataURI(from: image) {
                // 创建场景更新来设置纹理URL
                let update = TGSceneUpdate()
                update.path = "textures.\(code).url"
                update.value = "\(dataURI)"
                updates.append(update)
                Logger.debug("已添加天气纹理更新: \(code)")
            } else {
                Logger.debug("警告: 未找到天气图标 \(imageName) 或转换失败")
            }
        }

        return updates
    }

    /// 将UIImage转换为base64 data URI字符串
    /// - Parameter image: 源图片
    /// - Returns: data URI字符串（如 "data:image/png;base64,iVBORw0KG..."）
    private func createDataURI(from image: UIImage) -> String? {
        guard let imageData = image.pngData() else {
            return nil
        }
        let base64String = imageData.base64EncodedString()
        return "data:image/png;base64,\(base64String)"
    }

    public func buildCityWeatherMapData() {
        
        guard let mapView = mapView else { return }
        cityWeatherMapData = mapView.addDataLayer("city-weather-source", generateCentroid: true)
        
        CityWeatherDBManager.shared.fetchCityWeathers { [weak self] cityWeatherDatas in
            guard let self = self, let cityWeatherMapData = self.cityWeatherMapData else {
                print("城市天气数据层未初始化")
                return
            }
            
            var features: [TGMapFeature] = []
            
            for item in cityWeatherDatas {
                guard let lat = item.lat,
                      let lon = item.lon else { continue }
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                
                let properties: [String: String] = [
                    "city": item.cityName ?? "未知城市",
                    "temperature": "\(item.tempMin ?? 0)~\(item.tempMax ?? 0)℃",
                    "weatherCode": String(item.weatherCode ?? "0"),
                    "provincial": item.isProvincial ?? false ? "hide" : "show"
                ]
                
                let feature = TGMapFeature(point: coordinate, properties: properties)
                features.append(feature)
            }
            
            // 设置要素到数据层
            cityWeatherMapData.setFeatures(features)
            print("已添加 \(features.count) 个城市天气标注")
        }
    }
    
    
    public func ShowOrHideCityWeatherLayer(isShow: Bool) {
        let roadUpdate = TGSceneUpdate()
        roadUpdate.path = "layers.marker_with_label2.visible"
        roadUpdate.value = isShow ? "ture": "false"
        
        loadMapWithUpdates([roadUpdate])
    }
    
}
