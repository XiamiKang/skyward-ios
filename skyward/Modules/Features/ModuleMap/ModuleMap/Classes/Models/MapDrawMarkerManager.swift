//
//  MapDrawMarkerManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import TangramMap
import Foundation
import TXKit
import SWKit

public class MapDrawMarkerManager {
    
    private var mapView: TGMapView
    private var pointMarkers: [TGMarker] = []
    private var lineMarkers: [TGMarker] = []
    private var textMarkers: [TGMapData] = []
    private(set) var coordinates: [CLLocationCoordinate2D] = []
    
    public init(mapView: TGMapView) {
        self.mapView = mapView
    }
    
    // MARK: - Public
    
    private func revocation() {
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
    
    func revocationDistance() {
        revocation()
        drawDistanceLine()
    }
    
    func revocationRoute() {
        revocation()
        drawRouteLine()
    }
    
    func addDistanceLine(at coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
        addPoint(at: coordinate)
        if coordinates.count >= 2 {
            drawDistanceLine()
            addDistanceText()
        }
    }
    
    func addRouteLine(at coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
        addPoint(at: coordinate)
        if coordinates.count >= 2 {
            drawRouteLine()
        }
    }
}

// MARK: - Core

extension MapDrawMarkerManager {
    
    private func addPoint(at coordinate: CLLocationCoordinate2D) {
        let marker = mapView.markerAdd()
        marker.point = coordinate
        
        // 设置标记样式
        marker.stylingString = """
        {
            style: 'points',
            color: 'white',
            size: [12px, 12px],
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
    
    private func drawDistanceLine() {
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
            width: 4px,
            order: 500,
            cap: 'round',
            join: 'round'
        }
        """
        lineMarkers.append(marker)
    }
    
    private func drawRouteLine() {
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
    
    private func addDistanceText() {
        guard coordinates.count >= 2 else { return }
        
        let start = coordinates[coordinates.count - 2]
        let end = coordinates[coordinates.count - 1]
        let distance = MapMarkerTool.calculateDistance(from: start, to: end)
        
        let midPoint = CLLocationCoordinate2D(
            latitude: (start.latitude + end.latitude) / 2,
            longitude: (start.longitude + end.longitude) / 2
        )
        
        let distanceText = MapMarkerTool.formatDistance(distance)
        
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
