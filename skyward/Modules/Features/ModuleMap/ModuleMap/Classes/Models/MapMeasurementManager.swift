//
//  MapMeasurementManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import TangramMap

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
        
        if coordinates.count == 1 {
            addStartPoint(at: coordinate)
        } else {
            addPoint(at: coordinate)
        }
        
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
