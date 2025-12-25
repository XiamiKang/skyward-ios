//
//  MarkerLayerManager.swift
//  Pods
//
//  Created by TXTS on 2025/12/9.
//


import UIKit
import CoreLocation
import TangramMap

// MARK: - Marker图层管理器
public class MarkerLayerManager: NSObject {
    
    // MARK: - 属性
    
    private weak var mapView: TGMapView?
    
    /// 所有图层
    private var layers: [String: MarkerLayer] = [:]
    
    /// Marker到图层的映射 [marker.identifier: (layerId, markerId)]
    private var markerToLayerMap: [UInt32: (layerId: String, markerId: String)] = [:]
    
    /// 当前选中的marker
    private var selectedMarkerId: String?
    
    /// 回调
    public var onLayerVisibilityChanged: ((String, Bool) -> Void)?
    public var onMarkerSelected: ((String, MarkerData, String) -> Void)?
    public var onMarkerDeselected: ((String, MarkerData, String) -> Void)?
    public var onLayerChanged: ((String, Int) -> Void)?
    
    // MARK: - 初始化
    
    init(mapView: TGMapView) {
        self.mapView = mapView
        super.init()
    }
    
    // MARK: - 关键方法：根据TGMarker查找markerId
    
    /// 根据TGMarker查找markerId
    func findMarkerId(for marker: TGMarker?) -> String? {
        guard let marker = marker else { return nil }
        return markerToLayerMap[marker.identifier]?.markerId
    }
    
    /// 根据TGMarker查找图层ID
    public func findLayerId(for marker: TGMarker?) -> String? {
        guard let marker = marker else { return nil }
        return markerToLayerMap[marker.identifier]?.layerId
    }
    
    /// 根据markerId查找图层和数据
    func findLayerAndData(for markerId: String) -> (layerId: String, data: MarkerData)? {
        for (layerId, layer) in layers {
            if let data = layer.data[markerId] {
                return (layerId, data)
            }
        }
        return nil
    }
    
    /// 根据markerId查找TGMarker
    public func findMarker(for markerId: String) -> TGMarker? {
        for (_, layer) in layers {
            if let marker = layer.markers[markerId] {
                return marker
            }
        }
        return nil
    }
    
    // MARK: - 图层管理
    
    public func createLayer(id: String, name: String, isVisible: Bool) -> MarkerLayer {
        let layer = MarkerLayer(id: id, name: name, isVisible: isVisible)
        layers[id] = layer
        return layer
    }
    
    func removeLayer(id: String) {
        guard let layer = layers[id] else { return }
        
        // 移除该图层所有marker
        for (markerId, marker) in layer.markers {
            // 从映射中移除
            markerToLayerMap.removeValue(forKey: marker.identifier)
            mapView?.markerRemove(marker)
        }
        
        layers.removeValue(forKey: id)
        onLayerChanged?(id, 0)
    }
    
    func getLayer(id: String) -> MarkerLayer? {
        return layers[id]
    }
    
    func getAllLayers() -> [MarkerLayer] {
        return Array(layers.values)
    }
    
    public func setLayerVisible(_ visible: Bool, layerId: String) {
        guard let layer = layers[layerId] else { return }
        
        layer.isVisible = visible
        
        // 更新图层内所有marker的显示状态
        for (_, marker) in layer.markers {
            let style = visible ? MarkerStyle.defaultStyle.yamlString : MarkerStyle.hiddenStyle.yamlString
            marker.stylingString = style
            marker.visible = visible
        }
        
        onLayerVisibilityChanged?(layerId, visible)
        onLayerChanged?(layerId, layer.markerCount)
    }
    
    func toggleLayerVisible(layerId: String) {
        guard let layer = layers[layerId] else { return }
        setLayerVisible(!layer.isVisible, layerId: layerId)
    }
    
    func showAllLayers() {
        for layerId in layers.keys {
            setLayerVisible(true, layerId: layerId)
        }
    }
    
    func hideAllLayers() {
        for layerId in layers.keys {
            setLayerVisible(false, layerId: layerId)
        }
    }
    
    // MARK: - Marker管理
    
    @discardableResult
    func addMarker(to layerId: String, data: MarkerData, style: MarkerStyle = .defaultStyle) -> String? {
//        guard let mapView = mapView,
//              let layer = layers[layerId],
//              layer.markers[data.id] == nil else { return nil }
        guard let mapView = mapView else {
            return nil
        }
        guard let layer = layers[layerId] else {
            return nil
        }
        guard layer.markers[data.id] == nil else {
            return nil
        }
        // 创建marker
        let marker = mapView.markerAdd()
        marker.point = data.coordinate
        
        // 设置样式（根据图层显示状态）
        let markerStyle = layer.isVisible ? style.yamlString : MarkerStyle.hiddenStyle.yamlString
        marker.stylingString = markerStyle
        marker.visible = layer.isVisible
        marker.drawOrder = style.order
        
        marker.icon = SWKitModule.image(named: "map_poi_4")!
        if layer.id == "campsite" {
            marker.icon = SWKitModule.image(named: "map_poi_1")!
        }
        if layer.id == "scenicSpots" {
            marker.icon = SWKitModule.image(named: "map_poi_2")!
        }
        if layer.id == "gasStation" {
            marker.icon = SWKitModule.image(named: "map_poi_3")!
        }
        
        if layer.id == "memberLocation" {
            marker.icon = SWKitModule.image(named: "team_location_member")!
        }
        if layer.id == "safe" {
            marker.icon = SWKitModule.image(named: "team_location_safe")!
        }
        if layer.id == "sos" {
            marker.icon = SWKitModule.image(named: "team_location_sos")!
        }
        
        
        // 保存数据
        layer.markers[data.id] = marker
        layer.data[data.id] = data
        
        // 保存映射关系（使用identifier）
        markerToLayerMap[marker.identifier] = (layerId, data.id)
        
        onLayerChanged?(layerId, layer.markerCount)
        
        return data.id
    }
    
    func addMarkers(to layerId: String, dataArray: [MarkerData], style: MarkerStyle = .defaultStyle) -> [String] {
        var addedIds: [String] = []
        
        for data in dataArray {
            if let id = addMarker(to: layerId, data: data, style: style) {
                addedIds.append(id)
            }
        }
        
        return addedIds
    }
    
    public func removeMarker(_ markerId: String, from layerId: String) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId] else { return }
        
        // 如果正在选中这个marker，先取消选中
        if selectedMarkerId == markerId {
            deselectMarker(markerId, in: layerId)
        }
        
        // 从映射中移除
        markerToLayerMap.removeValue(forKey: marker.identifier)
        
        // 从地图移除
        mapView?.markerRemove(marker)
        
        // 从数据结构移除
        layer.markers.removeValue(forKey: markerId)
        layer.data.removeValue(forKey: markerId)
        
        onLayerChanged?(layerId, layer.markerCount)
    }
    
    func removeAllMarkers(in layerId: String) {
        guard let layer = layers[layerId] else { return }
        
        for (markerId, marker) in layer.markers {
            // 从映射中移除
            markerToLayerMap.removeValue(forKey: marker.identifier)
            
            mapView?.markerRemove(marker)
            
            // 如果正在选中这个marker，取消选中
            if selectedMarkerId == markerId {
                selectedMarkerId = nil
            }
        }
        
        layer.markers.removeAll()
        layer.data.removeAll()
        
        onLayerChanged?(layerId, 0)
    }
    
    func removeAllMarkers() {
        for layerId in layers.keys {
            removeAllMarkers(in: layerId)
        }
        selectedMarkerId = nil
        markerToLayerMap.removeAll()
    }
    
    func getMarkerData(_ markerId: String, in layerId: String) -> MarkerData? {
        return layers[layerId]?.data[markerId]
    }
    
    func updateMarkerPosition(_ markerId: String, in layerId: String, coordinate: CLLocationCoordinate2D) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              var data = layer.data[markerId] else { return }
        
        data.coordinate = coordinate
        marker.point = coordinate
        layer.data[markerId] = data
    }
    
    func updateMarkerPositionEased(_ markerId: String, in layerId: String,
                                  coordinate: CLLocationCoordinate2D,
                                  duration: TimeInterval, easeType: TGEaseType) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              var data = layer.data[markerId] else { return }
        
        data.coordinate = coordinate
        marker.pointEased(coordinate, seconds: duration, easeType: easeType)
        layer.data[markerId] = data
    }
    
    func updateMarkerStyle(_ markerId: String, in layerId: String, style: MarkerStyle) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              layer.isVisible else { return }
        
        marker.stylingString = style.yamlString
        marker.drawOrder = style.order
    }
    
    func updateAllMarkersStyle(in layerId: String, style: MarkerStyle) {
        guard let layer = layers[layerId], layer.isVisible else { return }
        
        for (_, marker) in layer.markers {
            marker.stylingString = style.yamlString
            marker.drawOrder = style.order
        }
    }
    
    // MARK: - 选择管理
    
    func selectMarker(_ markerId: String, in layerId: String) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              let data = layer.data[markerId] else { return }
        
        // 取消之前选中的marker
        if let previousId = selectedMarkerId,
           let (previousLayerId, _) = findLayerAndData(for: previousId) {
            deselectMarker(previousId, in: previousLayerId)
        }
        
        // 应用选中样式
        marker.stylingString = MarkerStyle.selectedStyle.yamlString
        marker.drawOrder = MarkerStyle.selectedStyle.order
        selectedMarkerId = markerId
        
        // 回调
        onMarkerSelected?(markerId, data, layerId)
    }
    
    func deselectMarker(_ markerId: String, in layerId: String) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              let data = layer.data[markerId],
              layer.isVisible else { return }
        
        // 恢复默认样式
        marker.stylingString = MarkerStyle.defaultStyle.yamlString
        marker.drawOrder = MarkerStyle.defaultStyle.order
        
        if selectedMarkerId == markerId {
            selectedMarkerId = nil
        }
        
        // 回调
        onMarkerDeselected?(markerId, data, layerId)
    }
    
    func getSelectedMarker() -> (markerId: String, layerId: String, data: MarkerData)? {
        guard let selectedId = selectedMarkerId,
              let (layerId, data) = findLayerAndData(for: selectedId) else { return nil }
        
        return (selectedId, layerId, data)
    }
    
    func clearSelection() {
        guard let selectedId = selectedMarkerId,
              let (layerId, _) = findLayerAndData(for: selectedId) else { return }
        
        deselectMarker(selectedId, in: layerId)
    }
    
    // MARK: - Icon 支持
    
    func setMarkerIcon(_ markerId: String, in layerId: String, image: UIImage) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId] else { return }
        
        marker.icon = image
    }
    
    // MARK: - 可见性控制
    
    func setMarkerVisible(_ visible: Bool, markerId: String, in layerId: String) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId] else { return }
        
        marker.visible = visible
    }
    
    // MARK: - 数据管理
    
    func saveMarkerData() -> [String: [String: MarkerData]] {
        var savedData: [String: [String: MarkerData]] = [:]
        
        for (layerId, layer) in layers {
            savedData[layerId] = layer.data
        }
        
        return savedData
    }
    
    func restoreMarkerData(_ savedData: [String: [String: MarkerData]]) {
        removeAllMarkers()
        
        for (layerId, markerDict) in savedData {
            if layers[layerId] == nil {
                if layerId == "custom" {
                    _ = createLayer(id: layerId, name: "恢复的图层 \(layerId)", isVisible: true)
                }else {
                    _ = createLayer(id: layerId, name: "恢复的图层 \(layerId)", isVisible: false)
                }
            }
            
            for (_, data) in markerDict {
                let _ = addMarker(to: layerId, data: data)
            }
        }
    }
    
    // MARK: - 工具方法
    
    func getLayerStats() -> [(id: String, name: String, visible: Bool, count: Int)] {
        return getAllLayers().map { layer in
            (layer.id, layer.name, layer.isVisible, layer.markerCount)
        }
    }
    
    /// 获取图层中所有marker的坐标
    func getMarkerCoordinates(in layerId: String) -> [CLLocationCoordinate2D] {
        guard let layer = layers[layerId] else { return [] }
        
        return layer.data.values.map { $0.coordinate }
    }
    
    /// 根据坐标范围筛选marker
    func filterMarkers(in layerId: String, within bounds: (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)) -> [MarkerData] {
        guard let layer = layers[layerId] else { return [] }
        
        return layer.data.values.filter { data in
            data.coordinate.latitude >= bounds.minLat &&
            data.coordinate.latitude <= bounds.maxLat &&
            data.coordinate.longitude >= bounds.minLng &&
            data.coordinate.longitude <= bounds.maxLng
        }
    }
}

// MARK: - Marker图层模型
public class MarkerLayer {
    let id: String
    var name: String
    var isVisible: Bool = true
    var markers: [String: TGMarker] = [:]  // [markerId: TGMarker对象]
    var data: [String: MarkerData] = [:]   // [markerId: marker数据]
    
    init(id: String, name: String, isVisible: Bool) {
        self.id = id
        self.name = name
        self.isVisible = isVisible
    }
    
    var markerCount: Int {
        return markers.count
    }
}

// MARK: - Marker数据模型
public class MarkerData {
    public let id: String
    public var coordinate: CLLocationCoordinate2D
    public var title: String
    public var subtitle: String?
    public var userInfo: [String: Any]?
    
    public init(id: String, coordinate: CLLocationCoordinate2D, title: String,
         subtitle: String? = nil, userInfo: [String: Any]? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.userInfo = userInfo
    }
}

// MARK: - Marker样式配置
public struct MarkerStyle {
    var color: String = "white"
    var size: [CGFloat] = [24, 32]
    var interactive: Bool = true
    var order: Int = 500
    var collide: Bool = false
    
    public static let defaultStyle = MarkerStyle()
    static let selectedStyle = MarkerStyle(color: "yellow", size: [40, 40], order: 1000)
    static let hiddenStyle = MarkerStyle(color: "transparent", size: [0, 0], interactive: false, order: 0)
    
    var yamlString: String {
        return """
        { style: 'points',
          interactive: \(interactive),
          color: '\(color)',
          size: [\(size[0])px, \(size[1])px],
          order: \(order),
          collide: \(collide) }
        """
    }
}

// MARK: - 预设样式类型
public enum PresetStyleType {
    case campsite
    case scenicSpots
    case gasStation
    case user
    case selected
    case memberLocation
    case safe
    case sos
    case `default`
}

// MARK: - MarkerLayerManager 扩展
extension MarkerLayerManager {
    /// 使用预设样式添加marker
    public func addMarkerWithPresetStyle(to layerId: String, data: MarkerData, styleType: PresetStyleType = .default) {
        let style: MarkerStyle
        switch styleType {
        case .campsite:
            style = MarkerStyle(color: "white", size: [24, 32], order: 600)
        case .scenicSpots:
            style = MarkerStyle(color: "white", size: [24, 32], order: 500)
        case .gasStation:
            style = MarkerStyle(color: "white", size: [24, 32], order: 400)
        case .user:
            style = MarkerStyle(color: "white", size: [24, 32], order: 700)
        case .selected:
            style = MarkerStyle.selectedStyle
        case .memberLocation, .safe, .sos:
            style = MarkerStyle(color: "white", size: [32, 32], order: 701)
        case .default:
            style = MarkerStyle.defaultStyle
        }
        
        let _ = addMarker(to: layerId, data: data, style: style)
    }
}


