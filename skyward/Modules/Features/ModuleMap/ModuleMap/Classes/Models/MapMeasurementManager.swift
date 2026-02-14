//
//  MapMeasurementManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import TangramMap
import Foundation
import TXKit

protocol MarkerFundation {
    func addPoint(at coordinate: CLLocationCoordinate2D)
    func addLine(coordinates: [CLLocationCoordinate2D])
}

public class DistanceMeasurementManager {
    
    private var mapView: TGMapView
    private var pointMarkers: [TGMarker] = []
    private var lineMarkers: [TGMarker] = []
    private var textMarkers: [TGMapData] = []
    public var coordinates: [CLLocationCoordinate2D] = []
    
    public init(mapView: TGMapView) {
        self.mapView = mapView
    }
    
    // MARK: - Public
    
    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
        
        if coordinates.count == 1 {
            addStartPoint(at: coordinate)
        } else {
            addPoint(at: coordinate)
        }
        
        if coordinates.count >= 2 {
            addDistanceLine()
            addDistanceText()
        }
    }
    
    func revocation() {
        if let pointMarker = pointMarkers.last {
            mapView.markerRemove(pointMarker)
            pointMarkers.removeLast()
        }
        
        if let lineMarker = lineMarkers.last {
            mapView.markerRemove(lineMarker)
            lineMarkers.removeLast()
        }
        
        if let textMarker = textMarkers.last {
            textMarker.remove()
            textMarkers.removeLast()
        }
        
        if coordinates.count > 0 {
            coordinates.removeLast()
        }
        
        addDistanceLine()
    }
    
    func clear() {
        pointMarkers.forEach { mapView.markerRemove($0) }
        lineMarkers.forEach { mapView.markerRemove($0) }
        textMarkers.forEach { $0.remove() }
        
        pointMarkers.removeAll()
        lineMarkers.removeAll()
        textMarkers.removeAll()
        coordinates.removeAll()
    }
    
    func addRouteLine(at coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
        
        addPoint(at: coordinate)
        
        if coordinates.count >= 2 {
            addDistanceLine()
        }
    }
    
    func trackLine(coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
        
        if coordinates.count == 1 {
            addStartPoint(at: coordinate)
        }
        
        if coordinates.count >= 2 {
            addDistanceLine()
        }
    }
    
    func trackLines(coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count > 1 else {
            return
        }
        clear()
        self.coordinates.append(contentsOf: coordinates)

        if let firstCoordinate =  coordinates.first {
            addStartPoint(at: firstCoordinate)
        }

        addDistanceLine()

        let bounds = TGCoordinateBounds(sw: coordinates.first!, ne: coordinates.last!)
        let cameraPosition = mapView.cameraThatFitsBounds(bounds, withPadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50))
        mapView.setCameraPosition(cameraPosition, withDuration: 0.3, easeType: .linear)
    }

    /// 调整相机位置以显示所有规划的路线点
    /// - Parameters:
    ///   - animated: 是否使用动画
    ///   - completion: 完成回调
    func fitAllCoordinates(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let (sw, ne) = getSWAndNE() else {
            completion?()
            return
        }
        
        let bounds = TGCoordinateBounds(sw: sw, ne: ne)
        
        // 统一使用 60 的边距
        let padding = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
        var cameraPosition = mapView.cameraThatFitsBounds(bounds, withPadding: padding)
        
        // 先临时设置相机位置，以便计算屏幕上的实际尺寸
        mapView.cameraPosition = cameraPosition

        // 计算在屏幕上的实际矩形区域
        if let routeRect = getRouteBoundsRect() {
            let width = routeRect.width
            let height = routeRect.height
            
            // 如果高度大于宽度，需要缩小（减小 zoom）让高度降低
            if height > width {
                // 计算需要缩小的比例
                let scale = width / height  // 例如: 300/400 = 0.75
                
                // 通过调整 zoom 来实现缩放
                // zoom 越小，显示区域越大（图像越小）
                // 需要让图像变小，所以 zoom 要减小
                let currentZoom = mapView.zoom
                // zoom 是对数刻度，每增加 1 显示区域缩小一半
                // 缩小 scale 倍对应的 zoom 调整：log2(1/scale)
                let zoomAdjustment = log2(1.0 / scale)
                let newZoom = currentZoom - CGFloat(zoomAdjustment)
                
                // 创建新的相机位置，使用调整后的 zoom
                if let adjustedPosition = TGCameraPosition(center: cameraPosition.center,
                                                           zoom: newZoom,
                                                           bearing: cameraPosition.bearing,
                                                           pitch: cameraPosition.pitch) {
                    cameraPosition = adjustedPosition
                }
            }
        }
        
        if animated {
            mapView.setCameraPosition(cameraPosition, withDuration: 0.5, easeType: .linear) { _ in
                completion?()
            }
        } else {
            mapView.cameraPosition = cameraPosition
            completion?()
        }
    }

    // 辅助函数：计算 log2
    private func log2(_ x: Double) -> Double {
        return log(x) / log(2)
    }

    /// 获取包含所有路线点的屏幕矩形区域
    /// - Returns: 包含所有点的 CGRect（相对于 mapView）
    func getRouteBoundsRect() -> CGRect? {
        guard let (sw, ne) = getSWAndNE() else {
            return nil
        }

        // 转换为屏幕坐标
        let swPoint = mapView.viewPosition(from: sw, clipToViewport: false)
        let nePoint = mapView.viewPosition(from: ne, clipToViewport: false)

        // 计算实际占据的矩形（不含边距）
        let minX = min(swPoint.x, nePoint.x)
        let maxX = max(swPoint.x, nePoint.x)
        let minY = min(swPoint.y, nePoint.y)
        let maxY = max(swPoint.y, nePoint.y)

        let actualWidth = maxX - minX
        let actualHeight = maxY - minY

        // 返回实际占据的矩形，用于判断是否需要调整 zoom
        return CGRect(x: minX, y: minY, width: actualWidth, height: actualHeight)
    }

    /// 获取裁剪区域的矩形（固定宽度为屏幕宽，高度等于宽度）
    /// - Returns: 裁剪区域的 CGRect（相对于 mapView）
    func getCropBoundsRect() -> CGRect? {
        guard let routeRect = getRouteBoundsRect() else {
            return nil
        }
        let width = ScreenUtil.screenWidth
        return CGRect(x: 0, y: routeRect.minY - 60, width: width, height: width)
    }
    
    func getSWAndNE() ->(CLLocationCoordinate2D, CLLocationCoordinate2D)? {
        guard coordinates.count > 1 else {
            return nil
        }

        // 计算所有点的边界
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let sw = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
        let ne = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        
        return (sw, ne)
    }
    
    func showRoute(coordinates: [CLLocationCoordinate2D]) {
        guard coordinates.count > 1 else {
            return
        }
        self.coordinates.append(contentsOf: coordinates)
        
        for coordinate in coordinates {
            addPoint(at: coordinate)
        }
        
        let polyline = TGGeoPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        let marker = mapView.markerAdd()
        marker.polyline = polyline
        
        marker.stylingString = """
        {
            style: 'lines',
            color: '#FE6A00',
            width: 2px,
            order: 999,
            cap: 'round',
            join: 'round'
        }
        """
        lineMarkers.append(marker)
    }
}

// MARK: - Core

extension DistanceMeasurementManager {
    
    private func addPoint(at coordinate: CLLocationCoordinate2D) {
        let marker = mapView.markerAdd()
        marker.point = coordinate
        
        // 设置标记样式
        marker.stylingString = """
        {
            style: 'points',
            color: 'white',
            size: [8px, 8px],
            order: 999,
            collide: false
        }
        """
        // 直接设置图标图片
        if let image = MapModule.image(named: "measure_dot") {
            marker.icon = image
        }
        
        pointMarkers.append(marker)
    }
    
    private func addStartPoint(at coordinate: CLLocationCoordinate2D) {
        let marker = mapView.markerAdd()
        marker.point = coordinate
        
        // 设置标记样式
        marker.stylingString = """
        {
            style: 'points',
            color: 'white',
            size: [24px, 24px],
            order: 999,
            collide: false
        }
        """
        // 直接设置图标图片
        if let image = MapModule.image(named: "measure_start") {
            marker.icon = image
        }
        
        pointMarkers.append(marker)
    }
    
    private func addDistanceLine() {
        guard coordinates.count >= 2 else { return }
        
        // 清除所有线段标记
        lineMarkers.forEach { mapView.markerRemove($0) }
        lineMarkers.removeAll()
        
        let polyline = TGGeoPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        let marker = mapView.markerAdd()
        marker.polyline = polyline
        
        marker.stylingString = """
        {
            style: 'lines',
            color: '#FE6A00',
            width: 2px,
            order: 999,
            cap: 'round',
            join: 'round'
        }
        """
        lineMarkers.append(marker)
    }
    
    private func addDistanceText() {
        guard coordinates.count >= 2 else { return }
        
        let start = coordinates[coordinates.count - 2]
        let end = coordinates[coordinates.count - 1]
        let distance = calculateDistance(from: start, to: end)
        
        let midPoint = CLLocationCoordinate2D(
            latitude: (start.latitude + end.latitude) / 2,
            longitude: (start.longitude + end.longitude) / 2
        )
        
        let distanceText = formatDistance(distance)
        
        // 创建GeoJSON数据以显示距离文本
        let geojson: [String: Any] = [
            "type": "FeatureCollection",
            "features": [
                [
                    "type": "Feature",
                    "geometry": [
                        "type": "Point",
                        "coordinates": [midPoint.longitude, midPoint.latitude]
                    ],
                    "properties": [
                        "name": distanceText, // 必须与YAML中的text_source对应
                    ]
                ]
            ]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: geojson)
            let jsonString = String(data: data, encoding: .utf8)!
            
            // 使用正确的图层名称，这将连接到scene3d11.yaml中定义的distance_text_layer
            guard let mapData = mapView.addDataLayer("distance_text_layer", generateCentroid: true) else {
                print("Failed to add data layer for distance text")
                return
            }
            
            // 设置GeoJSON数据
            mapData.setGeoJson(jsonString)
            
            textMarkers.append(mapData)
        } catch {
            print("GeoJSON 序列化失败: \(error)")
        }
    }
}
// MARK: - Tool
extension DistanceMeasurementManager {

    /// 计算所有坐标点的总距离
    /// - Returns: 总距离（米）
    func calculateTotalDistance() -> Double {
        guard coordinates.count >= 2 else {
            return 0
        }

        var totalDistance = 0.0
        for i in 0..<(coordinates.count - 1) {
            totalDistance += calculateDistance(from: coordinates[i], to: coordinates[i + 1])
        }
        return totalDistance
    }

    /// 获取格式化的总距离字符串
    /// - Returns: 格式化后的距离字符串（如 "1.2km" 或 "500.5m"）
    func getTotalDistanceString() -> String {
        let totalDistance = calculateTotalDistance()
        return formatDistance(totalDistance)
    }

    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.1fm", distance)
        } else {
            return String(format: "%.2fkm", distance / 1000)
        }
    }
}
