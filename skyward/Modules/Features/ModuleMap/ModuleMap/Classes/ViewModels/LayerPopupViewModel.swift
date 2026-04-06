//
//  LayerPopupViewModel.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import SWKit

public struct AnnotationOption {
    public let name: String
    public var isSelected: Bool
    public let type: AnnotationType // 添加类型区分
    
    public init(name: String, type: AnnotationType, isSelected: Bool = false) {
        self.name = name
        self.type = type
        self.isSelected = isSelected
    }
}

// 新增：注记类型枚举
public enum AnnotationType {
    case vector    // 矢量注记
    case weather   // 天气
    case other     // 其他类型（预留）
}

public struct POIOption {
    public let name: String
    public var isSelected: Bool
    public let type: POIType
    
    public init(name: String, type: POIType, isSelected: Bool = false) {
        self.name = name
        self.type = type
        self.isSelected = isSelected
    }
}

public struct SectionData {
    public enum SectionType {
        case map
        case annotation
        case poi
    }
    
    public let type: SectionType
    public let title: String
    public var items: [Any]
    
    public init(type: SectionType, title: String, items: [Any]) {
        self.type = type
        self.title = title
        self.items = items
    }
}

// MARK: - 配置模型
public class LayerPopupConfig {
    // 单例实例
    public static let shared = LayerPopupConfig()
    
    public var mapSources: [MapSource]
    public var annotationOptions: [AnnotationOption]
    public var poiOptions: [POIOption]
    
    private init() {
        // 初始化默认配置
        let chooseTileSourceName = UserDefaults.standard.string(forKey: "ChooseTileSourceName") ?? "吉林长光影像"
        self.mapSources = [
            MapSource(name: "天地图街道",
                      imageName: "map1",
                      sceneUrl: "http://t1.tianditu.com/DataServer?T=vec_w&x={x}&y={y}&l={z}&tk=eb97ffb585b9a0dbde9e2b8eb54d6477",
                      isSelected: chooseTileSourceName == "天地图街道"),
            MapSource(name: "天地图影像",
                      imageName: "map2",
                      sceneUrl: "http://t1.tianditu.com/DataServer?T=img_w&x={x}&y={y}&l={z}&tk=eb97ffb585b9a0dbde9e2b8eb54d6477",
                      isSelected: chooseTileSourceName == "天地图影像"),
            MapSource(name: "吉林长光影像",
                      imageName: "map3",
                      sceneUrl: "https://api.jl1mall.com/getMap/{z}/{x}/{y}?mk=3ddec00f5f435270285ffc7ad1a60ce5&tk=c4e73a6b0428f65a94fb6fbe677d2375",
                      isSelected: chooseTileSourceName == "吉林长光影像")
        ]
        
        if !isInChina() {
            self.mapSources.append(MapSource(name: "谷歌地图",
                                             imageName: "map5",
                                             sceneUrl: "http://mts0.googleapis.com/vt?lyrs=y&x={x}&y={y}&z={z}",
                                            isSelected: isInChina() ? false : true))
        }
        
        
        self.annotationOptions = [
            AnnotationOption(name: "矢量注记", type: .vector, isSelected: true),
            AnnotationOption(name: "天气", type: .weather)
        ]
        
        self.poiOptions = [
            POIOption(name: "露营地", type: .campsite),
            POIOption(name: "风景名胜", type: .scenicSpot),
            POIOption(name: "加油站", type: .gasStation),
            POIOption(name: "医疗", type: .medical)
        ]
    }
    
    // MARK: - 重置为默认值（可选，如果需要的话）
    public func resetToDefault() {
        self.mapSources = [
            MapSource(name: "天地图街道",
                      imageName: "map1",
                      sceneUrl: "http://t1.tianditu.com/DataServer?T=vec_w&x={x}&y={y}&l={z}&tk=eb97ffb585b9a0dbde9e2b8eb54d6477"),
            MapSource(name: "天地图影像",
                      imageName: "map2",
                      sceneUrl: "http://t1.tianditu.com/DataServer?T=img_w&x={x}&y={y}&l={z}&tk=eb97ffb585b9a0dbde9e2b8eb54d6477"),
            MapSource(name: "吉林长光影像",
                      imageName: "map3",
                      sceneUrl: "https://api.jl1mall.com/getMap/{z}/{x}/{y}?mk=3ddec00f5f435270285ffc7ad1a60ce5&tk=c4e73a6b0428f65a94fb6fbe677d2375",
                      isSelected: true)
        ]
        
        self.annotationOptions = [
            AnnotationOption(name: "矢量注记", type: .vector, isSelected: true),
            AnnotationOption(name: "天气", type: .weather)
        ]
        
        self.poiOptions = [
            POIOption(name: "露营地", type: .campsite),
            POIOption(name: "风景名胜", type: .scenicSpot),
            POIOption(name: "加油站", type: .gasStation),
            POIOption(name: "医疗", type: .medical)
        ]
    }
}

public class LayerPopupViewModel: ObservableObject {
    
    // MARK: - 输出属性
    @Published public var sections: [SectionData] = []
    @Published public var selectedOptions: [String: Any] = [:]
    public private(set) var currentSelectedOptions: [String: Any] = [:]
    
    private var config = LayerPopupConfig.shared
    
    // MARK: - 初始化
    public init() {
        setupData()
        currentSelectedOptions = selectedOptions
    }
    
    // MARK: - 数据设置
    private func setupData() {
        sections = [
            SectionData(type: .map, title: "地图切换", items: config.mapSources),
            SectionData(type: .poi, title: "兴趣点", items: config.poiOptions),
            SectionData(type: .annotation, title: "注记", items: config.annotationOptions),
        ]
        updateSelectedOptions()
    }
    
    // MARK: - 操作
    public func selectMap(at indexPath: IndexPath) {
        guard indexPath.section < sections.count else { return }
        let section = sections[indexPath.section]
        
        guard section.type == .map else { return }
        
        // 更新地图选择
        for i in 0..<config.mapSources.count {
            config.mapSources[i].isSelected = (i == indexPath.item)
        }
        
        // 更新sections
        sections[indexPath.section].items = config.mapSources
        updateSelectedOptions()
        
        print("当前的地图: \(config.mapSources)")
    }
    
    public func toggleAnnotationOption(at indexPath: IndexPath) {
        guard indexPath.section < sections.count else { return }
        let section = sections[indexPath.section]
        
        guard section.type != .map else { return }
        
        switch section.type {
        case .annotation:
            guard indexPath.item < config.annotationOptions.count else { return }
            config.annotationOptions[indexPath.item].isSelected.toggle()
            sections[indexPath.section].items = config.annotationOptions
            
            
        case .poi:
            guard indexPath.item < config.poiOptions.count else { return }
            config.poiOptions[indexPath.item].isSelected.toggle()
            sections[indexPath.section].items = config.poiOptions
            
        default:
            return
        }
        
        updateSelectedOptions()
    }
    
    private func getIsSelectedForItem(at indexPath: IndexPath) -> Bool {
        guard indexPath.section < sections.count else { return false }
        let section = sections[indexPath.section]
        
        switch section.type {
        case .annotation:
            return indexPath.item < config.annotationOptions.count ? config.annotationOptions[indexPath.item].isSelected : false
        case .poi:
            return indexPath.item < config.poiOptions.count ? config.poiOptions[indexPath.item].isSelected : false
        default:
            return false
        }
    }
    
    // MARK: - 工具方法
    private func updateSelectedOptions() {
        selectedOptions = getSelectedOptions()
    }
    
    private func getSelectedOptions() -> [String: Any] {
        var result: [String: Any] = [:]
        
        // 获取选中的地图
        if let selectedMap = config.mapSources.first(where: { $0.isSelected }) {
            result["selectedMap"] = [
                "name": selectedMap.name,
                "sceneUrl": selectedMap.sceneUrl
            ]
        }
        
        // 获取选中的注记 - 按类型分别存储
        let selectedVectorAnnotations = config.annotationOptions.filter { $0.isSelected && $0.type == .vector }
        let selectedWeatherAnnotations = config.annotationOptions.filter { $0.isSelected && $0.type == .weather }
        
        result["selectedVectorAnnotations"] = selectedVectorAnnotations.map { $0.name }
        result["selectedWeatherAnnotations"] = selectedWeatherAnnotations.map { $0.name }
        
        // 获取选中的兴趣点 - 按类型分别存储
        let selectedCampgrounds = config.poiOptions.filter { $0.isSelected && $0.type == .campsite }
        let selectedScenics = config.poiOptions.filter { $0.isSelected && $0.type == .scenicSpot }
        let selectedGasStations = config.poiOptions.filter { $0.isSelected && $0.type == .gasStation }
        let selectedMedicals = config.poiOptions.filter { $0.isSelected && $0.type == .medical }
        
        result["selectedCampgrounds"] = selectedCampgrounds.map { $0.name }
        result["selectedScenics"] = selectedScenics.map { $0.name }
        result["selectedGasStations"] = selectedGasStations.map { $0.name }
        result["selectedMedicals"] = selectedMedicals.map { $0.name }
        
        return result
    }
    
    // MARK: - 图层处理 - 分开处理不同类型的图层
    public func handleVectorAnnotationLayer(_ selectedAnnotations: [String]) -> Bool {
        // 处理矢量注记图层
        return selectedAnnotations.contains("矢量注记")
    }
    
    public func handleWeatherAnnotationLayer(_ selectedAnnotations: [String]) -> Bool {
        // 处理天气图层
        return selectedAnnotations.contains("天气")
    }
    
    public func handleCampgroundLayer(_ selectedPOIs: [String]) -> Bool {
        return selectedPOIs.contains("露营地")
    }
    
    public func handleScenicLayer(_ selectedPOIs: [String]) -> Bool {
        return selectedPOIs.contains("风景名胜")
    }
    
    public func handleGasStationLayer(_ selectedPOIs: [String]) -> Bool {
        return selectedPOIs.contains("加油站")
    }
    
    public func handleMedicalLayer(_ selectedPOIs: [String]) -> Bool {
        return selectedPOIs.contains("医疗")
    }
    
    // 新增：获取所有图层状态的统一方法
    public func getAllLayersState() -> [String: Bool] {
        var layersState: [String: Bool] = [:]
        
        // 获取选中的注记
        let selectedAnnotations = config.annotationOptions.filter { $0.isSelected }.map { $0.name }
        
        // 注记图层
        layersState["矢量注记"] = selectedAnnotations.contains("矢量注记")
        layersState["天气"] = selectedAnnotations.contains("天气")
        
        // 获取选中的POI
        let selectedPOIs = config.poiOptions.filter { $0.isSelected }.map { $0.name }
        
        // POI图层
        layersState["露营地"] = selectedPOIs.contains("露营地")
        layersState["风景名胜"] = selectedPOIs.contains("风景名胜")
        layersState["加油站"] = selectedPOIs.contains("加油站")
        layersState["医疗"] = selectedPOIs.contains("医疗")
        
        return layersState
    }
}
