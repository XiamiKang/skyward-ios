//
//  MapViewController+POI.swift
//  ModuleMap
//
//  Created by TXTS on 2026/3/6.
//

import Foundation
import CoreLocation
import SWKit

extension MapViewController {
    
    public func setupMarkerLayer() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        _ = markerLayerManager.createLayer(id: "campsite", name: "露营地", isVisible: false)
        _ = markerLayerManager.createLayer(id: "scenicSpots", name: "风景名胜", isVisible: false)
        _ = markerLayerManager.createLayer(id: "gasStation", name: "加油站", isVisible: false)
        _ = markerLayerManager.createLayer(id: "medical", name: "医疗", isVisible: false)
        _ = markerLayerManager.createLayer(id: "custom", name: "自定义标注", isVisible: true)
        _ = markerLayerManager.createLayer(id: "myRoutesLine", name: "我的路线", isVisible: true)
        _ = markerLayerManager.createLayer(id: "myRoutesNode", name: "我的路线节点", isVisible: true)
        _ = markerLayerManager.createLayer(id: "weather", name: "天气点", isVisible: true)
        registeRouteMarkerLayers()
    }
    
    public func creatPublicMarkers() {
        let (minLat, maxLat, minLon, maxLon) = createCoordinateArrayFromScreenBounds()
        print("区域开始查询")
        guard let zoom = mapManager.mapView?.zoom else {return}
        POIDatabaseManager.shared.fetchPOIsInRegion(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon, zoom: zoom) { [weak self] publicPOIList in
            guard let self = self else { return }
            
            self.addPublicMarkers(with: publicPOIList)
        }
    }
    /// 添加公共兴趣点
    private func addPublicMarkers(with markersData: [PublicPOIData]) {
//        print("兴趣点消息------\(markersData)")
        // 添加露营地
        let campsitesData = markersData.filter { $0.category == 1 }
//        print("露营地消息------\(campsitesData)")
        addMarkerWirtStyle(poiData: campsitesData, styleStr: "campsite")
        
        // 添加风景名胜
        let scenicSpotsData = markersData.filter { $0.category == 2 }
//        print("风景名胜消息------\(scenicSpotsData)")
        addMarkerWirtStyle(poiData: scenicSpotsData, styleStr: "scenicSpots")
        
        // 添加加油站
        let gasStationData = markersData.filter { $0.category == 3 }
        addMarkerWirtStyle(poiData: gasStationData, styleStr: "gasStation")
        
        // 添加医疗
        let medicalData = markersData.filter { $0.category == 4 }
        addMarkerWirtStyle(poiData: medicalData, styleStr: "medical")
        
    }
    
    private func addMarkerWirtStyle(poiData: [PublicPOIData], styleStr: String) {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        // 移除所有的marker
        markerLayerManager.removeAllMarkers(in: styleStr)
        // 重新添加新的marker
        for (_, publicPoi) in poiData.enumerated() {
            if let lat = publicPoi.wgsLat, let lon = publicPoi.wgsLon, let id = publicPoi.id {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let data = MarkerData(
                    id: "\(styleStr)_\(id)",
                    coordinate: coordinate,
                    title: publicPoi.name ?? "",
                    subtitle: publicPoi.address ?? ""
                )
                markerLayerManager.addMarker(to: styleStr, data: data)
            }
        }
    }
    
    // 获取屏幕经纬度
    private func createCoordinateArrayFromScreenBounds() -> (Double, Double, Double, Double) {
        // 使用 MapManager 的方法获取坐标
        let corners = mapManager.createCoordinateArrayForPOIRequest()
        let minLat = corners.bottomRight.latitude
        let maxLat = corners.topLeft.latitude
        let minLon = corners.topLeft.longitude
        let maxLon = corners.bottomRight.longitude
       
        return (minLat, maxLat, minLon, maxLon)
    }
    
    
    public func createCustomPOIMarker(with poiData: UserPOILocalData) {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        
        if let lat = poiData.lat, let lon = poiData.lon, let id = poiData.id {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let data = MarkerData(
                id: "custom_\(id)",
                coordinate: coordinate,
                title: poiData.name ?? "",
                subtitle: poiData.address ?? ""
            )
            markerLayerManager.addMarker(to: "custom", data: data)
        }
        
    }
}
