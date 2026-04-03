//
//  MarkerLayerManager.swift
//  Pods
//
//  Created by TXTS on 2025/12/9.
//


import UIKit
import CoreLocation
import TangramMap

// MARK: - Marker类型
public enum MarkerType {
    case point       // 点标记
    case line        // 线标记
}

// MARK: - Marker样式协议
public protocol MarkerStyle {
    var type: MarkerType { get }
    var order: Int { get }
    var yamlString: String { get }
    var hiddenYamlString: String { get }
    var selectedYamlString: String { get }
}

// MARK: - 点标记样式
public struct PointMarkerStyle: MarkerStyle {
    public var type: MarkerType = .point
    public var color: String
    public var size: [CGFloat]
    public var interactive: Bool
    public var order: Int
    public var collide: Bool
    public var icon: UIImage?

    public init(color: String = "white",
                size: [CGFloat] = [30, 30],
                interactive: Bool = true,
                order: Int = 500,
                collide: Bool = false,
                icon: UIImage? = nil) {
        self.color = color
        self.size = size
        self.interactive = interactive
        self.order = order
        self.collide = collide
        self.icon = icon
    }

    public var yamlString: String {
        return """
        { style: 'points',
          interactive: \(interactive),
          color: '\(color)',
          size: [\(size[0])px, \(size[1])px],
          order: \(order),
          collide: \(collide) }
        """
    }

    public var hiddenYamlString: String {
        return """
        { style: 'points',
          interactive: \(interactive),
          color: 'transparent',
          size: [0px, 0px],
          order: 0,
          collide: false }
        """
    }
    
    public var selectedYamlString: String {
        return yamlString
    }

    // 预设样式
    public static let `default` = PointMarkerStyle()
    public static let selected = PointMarkerStyle(size: [45, 45], order: 1000)
    public static let hidden = PointMarkerStyle(color: "transparent", size: [0, 0], interactive: true, order: 0)

    // 按图层ID预设样式
    public static func style(for layerId: String) -> PointMarkerStyle {
        switch layerId {
        case "campsite":
            return PointMarkerStyle(size: [30, 30], order: 401)
        case "scenicSpots":
            return PointMarkerStyle(size: [30, 30], order: 402)
        case "gasStation":
            return PointMarkerStyle(size: [30, 30], order: 403)
        case "medical":
            return PointMarkerStyle(size: [30, 30], order: 404)
        case "custom", "newCustom":
            return PointMarkerStyle(size: [30, 30], order: 700)
        case "memberLocation", "safe", "sos":
            return PointMarkerStyle(size: [32, 32], order: 701)
        case "route_node":
            return PointMarkerStyle(size: [12, 12], order: 501)
        case "track_start", "track_end":
            return PointMarkerStyle(size: [16, 16], order: 501)
        default:
            return PointMarkerStyle.default
        }
    }

    // 按图层ID获取图标
    public static func icon(for layerId: String) -> UIImage? {
        switch layerId {
        case "campsite":
            return SWKitModule.image(named: "map_poi_1")
        case "scenicSpots":
            return SWKitModule.image(named: "map_poi_2")
        case "gasStation":
            return SWKitModule.image(named: "map_poi_3")
        case "medical":
            return SWKitModule.image(named: "map_poi_4")
        case "memberLocation":
            return SWKitModule.image(named: "team_location_member")
        case "safe":
            return SWKitModule.image(named: "team_location_safe")
        case "sos":
            return SWKitModule.image(named: "team_location_sos")
        case "route_node":
            return SWKitModule.image(named: "map_node")
        case "track_start":
            return SWKitModule.image(named: "map_track_start")
        case "track_end":
            return SWKitModule.image(named: "map_track_end")
        default:
            return SWKitModule.image(named: "map_poi_custom")
        }
    }
}

// MARK: - 线标记样式
public struct LineMarkerStyle: MarkerStyle {
    public var type: MarkerType = .line
    public var color: String
    public var width: CGFloat
    public var interactive: Bool
    public var order: Int
    public var opacity: CGFloat
    /// outline宽度（用于扩大点击区域）
    public var outlineWidth: CGFloat
    /// outline颜色（设为透明用于扩大点击区域）
    public var outlineColor: String

    public init(color: String = "#FE6A00",
                width: CGFloat = 4,
                interactive: Bool = true,
                order: Int = 500,
                opacity: CGFloat = 0.5,
                outlineWidth: CGFloat = 1,
                outlineColor: String = "rgba(255,255,255,1)") {
        self.color = color
        self.width = width
        self.interactive = interactive
        self.order = order
        self.opacity = opacity
        self.outlineWidth = outlineWidth
        self.outlineColor = outlineColor
    }

    public var yamlString: String {
        return """
        { style: 'lines',
          interactive: \(interactive),
          color: '\(color)',
          width: \(width)px,
          order: \(order),
          cap: 'round',
          join: 'round',
          opacity: \(opacity),
          outline: { width: \(outlineWidth)px, color: '\(outlineColor)', interactive: true} }
        """
    }

    public var hiddenYamlString: String {
        return """
        { style: 'lines',
          interactive: false,
          color: 'transparent',
          width: 0px,
          order: 0,
          cap: 'round',
          join: 'round',
          opacity: 0 }
        """
    }

    public var selectedYamlString: String {
        return yamlString
    }

    // 预设样式
    public static let `default` = LineMarkerStyle()
    public static let selected = LineMarkerStyle(width: 6, order: 1000)
    public static let hidden = LineMarkerStyle(color: "transparent", width: 0, opacity: 0)
}

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
        for (markerId, marker) in layer.markers {
            if let style = layer.styles[markerId] {
                let styleString = visible ? style.yamlString : style.hiddenYamlString
                marker.stylingString = styleString
            }
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
    public func addMarker(to layerId: String, data: MarkerData) -> String? {
        guard let mapView = mapView else { return nil }
        guard let layer = layers[layerId] else { return nil }
        guard layer.markers[data.id] == nil else { return nil }

        // 创建marker
        let marker = mapView.markerAdd()

        let style : MarkerStyle

        // 根据类型设置数据
        switch data.type {
        case .point:
            style = PointMarkerStyle.style(for: layerId)

            if let coordinate = data.coordinate {
                marker.point = coordinate
            }
            if let icon = PointMarkerStyle.icon(for: layerId) {
                marker.icon = icon
            }

        case .line:
            style = LineMarkerStyle.default

            if let coordinates = data.coordinates, !coordinates.isEmpty {
                let polyline = TGGeoPolyline(coordinates: coordinates, count: UInt(coordinates.count))
                marker.polyline = polyline
            }
        }

        // 设置样式
        let markerStyle = layer.isVisible ? style.yamlString : style.hiddenYamlString
        marker.stylingString = markerStyle
        marker.visible = layer.isVisible
        marker.drawOrder = style.order
        // 保存数据
        layer.markers[data.id] = marker
        layer.data[data.id] = data
        layer.styles[data.id] = style
        // 保存映射关系（使用identifier）
        markerToLayerMap[marker.identifier] = (layerId, data.id)
        
        onLayerChanged?(layerId, layer.markerCount)
        
        return data.id
    }
    
    public func addMarkers(to layerId: String, dataArray: [MarkerData]) -> [String] {
        var addedIds: [String] = []
        
        for data in dataArray {
            if let id = addMarker(to: layerId, data: data) {
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
        layer.styles.removeValue(forKey: markerId)
        
        onLayerChanged?(layerId, layer.markerCount)
    }
    
    public func removeAllMarkers(in layerId: String) {
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
        layer.styles.removeAll()

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
              let data = layer.data[markerId],
              data.type == .point else { return }
        
        data.coordinate = coordinate
        marker.point = coordinate
        layer.data[markerId] = data
    }
    
    func updateMarkerPositionEased(_ markerId: String, in layerId: String,
                                  coordinate: CLLocationCoordinate2D,
                                  duration: TimeInterval, easeType: TGEaseType) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              let data = layer.data[markerId],
              data.type == .point else { return }

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
        layer.styles[markerId] = style
    }
    
    func updateAllMarkersStyle(in layerId: String, style: MarkerStyle) {
        guard let layer = layers[layerId], layer.isVisible else { return }
        
        for (markerId, marker) in layer.markers {
            if let data = layer.data[markerId], data.type == style.type {
                marker.stylingString = style.yamlString
                marker.drawOrder = style.order
                layer.styles[markerId] = style
            }
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
        if let style = layer.styles[markerId] {
            marker.stylingString = style.selectedYamlString
        }

        selectedMarkerId = markerId
        
        // 回调
        onMarkerSelected?(markerId, data, layerId)
    }
    
    func deselectMarker(_ markerId: String, in layerId: String) {
        guard let layer = layers[layerId],
              let marker = layer.markers[markerId],
              let data = layer.data[markerId],
              let originalStyle = layer.styles[markerId],
              layer.isVisible else { return }

        marker.stylingString = originalStyle.yamlString
        marker.drawOrder = originalStyle.order

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
    
    public func setMarkerVisible(_ visible: Bool, markerId: String, in layerId: String) {
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
        
        return layer.data.values.compactMap { $0.coordinate }
    }
    
    /// 根据坐标范围筛选marker
    func filterMarkers(in layerId: String, within bounds: (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)) -> [MarkerData] {
        guard let layer = layers[layerId] else { return [] }
        
        return layer.data.values.filter { data in
            guard let coordinate = data.coordinate else { return false }
            return coordinate.latitude >= bounds.minLat &&
                   coordinate.latitude <= bounds.maxLat &&
                   coordinate.longitude >= bounds.minLng &&
                   coordinate.longitude <= bounds.maxLng
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
    var styles: [String: any MarkerStyle] = [:] // [markerId: marker样式]

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
    public let type: MarkerType
    public var title: String
    public var subtitle: String?
    public var userInfo: [String: Any]?
    // 点数据
    public var coordinate: CLLocationCoordinate2D?
    // 线数据
    public var coordinates: [CLLocationCoordinate2D]?

    public init(id: String, type: MarkerType, title: String,
                subtitle: String? = nil, userInfo: [String: Any]? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.userInfo = userInfo
    }

    /// 便捷初始化 - 点类型
    public convenience init(id: String, coordinate: CLLocationCoordinate2D, title: String,
                            subtitle: String? = nil, userInfo: [String: Any]? = nil) {
        self.init(id: id, type: .point, title: title, subtitle: subtitle, userInfo: userInfo)
        self.coordinate = coordinate
    }

    /// 便捷初始化 - 线类型
    public convenience init(id: String, coordinates: [CLLocationCoordinate2D], title: String,
                            subtitle: String? = nil, userInfo: [String: Any]? = nil) {
        self.init(id: id, type: .line, title: title, subtitle: subtitle, userInfo: userInfo)
        self.coordinates = coordinates
    }
}

// MARK: - MarkerLayerManager 扩展
extension MarkerLayerManager {
    /// 添加点类型的 marker
    @discardableResult
    public func addPointMarker(to layerId: String,
                               id: String,
                               coordinate: CLLocationCoordinate2D,
                               title: String = "",
                               style: PointMarkerStyle = .default) -> String? {
        let data = MarkerData(id: id, coordinate: coordinate, title: title)
        return addMarker(to: layerId, data: data)
    }

    /// 添加线类型的 marker
    @discardableResult
    public func addLineMarker(to layerId: String,
                              id: String,
                              coordinates: [CLLocationCoordinate2D],
                              title: String = "",
                              subTitle: String = "",
                              style: LineMarkerStyle = .default) -> String? {
        let data = MarkerData(id: id, coordinates: coordinates, title: title, subtitle: subTitle)
        return addMarker(to: layerId, data: data)
    }
}


