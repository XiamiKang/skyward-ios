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
    
    public init(name: String, isSelected: Bool = false) {
        self.name = name
        self.isSelected = isSelected
    }
}

public struct SectionData {
    public enum SectionType {
        case map
        case annotation
        case poi
        case weather
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
    public var poiOptions: [AnnotationOption]
    public var weatherOptions: [AnnotationOption]
    
    private init() {
        // 初始化默认配置
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
                      isSelected: isInChina() ? true : false),
            MapSource(name: "谷歌地图",
                      imageName: "map5",
                      sceneUrl: "http://mts0.googleapis.com/vt?lyrs=y&x={x}&y={y}&z={z}",
                     isSelected: isInChina() ? false : true)
        ]
        
        
        
        self.annotationOptions = [
            AnnotationOption(name: "矢量注记", isSelected: true)
        ]
        
        self.poiOptions = [
            AnnotationOption(name: "露营地"),
            AnnotationOption(name: "风景名胜"),
            AnnotationOption(name: "加油站"),
            AnnotationOption(name: "医疗"),
            AnnotationOption(name: "我的兴趣点")
        ]
        
        self.weatherOptions = [
            AnnotationOption(name: "温度"),
            AnnotationOption(name: "相对湿度"),
            AnnotationOption(name: "风速"),
            AnnotationOption(name: "能见度")
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
            AnnotationOption(name: "矢量注记", isSelected: true)
        ]
        
        self.poiOptions = [
            AnnotationOption(name: "露营地"),
            AnnotationOption(name: "风景名胜"),
            AnnotationOption(name: "加油站"),
            AnnotationOption(name: "医疗"),
            AnnotationOption(name: "我的兴趣点")
        ]
        
        self.weatherOptions = [
            AnnotationOption(name: "温度"),
            AnnotationOption(name: "相对湿度"),
            AnnotationOption(name: "风速"),
            AnnotationOption(name: "能见度")
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
            SectionData(type: .annotation, title: "注记", items: config.annotationOptions),
            SectionData(type: .poi, title: "兴趣点", items: config.poiOptions),
//            SectionData(type: .weather, title: "天气图层", items: config.weatherOptions)
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
            
        case .weather:
            guard indexPath.item < config.weatherOptions.count else { return }
            config.weatherOptions[indexPath.item].isSelected.toggle()
            sections[indexPath.section].items = config.weatherOptions
            
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
        case .weather:
            return indexPath.item < config.weatherOptions.count ? config.weatherOptions[indexPath.item].isSelected : false
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
        
        // 获取选中的注记
        let selectedAnnotations = config.annotationOptions.filter { $0.isSelected }
        result["selectedAnnotations"] = selectedAnnotations.map { $0.name }
        
        // 获取选中的兴趣点
        let selectedPOIs = config.poiOptions.filter { $0.isSelected }
        result["selectedPOIs"] = selectedPOIs.map { $0.name }
        
        // 获取选中的天气图层
        let selectedWeathers = config.weatherOptions.filter { $0.isSelected }
        result["selectedWeathers"] = selectedWeathers.map { $0.name }
        
        return result
    }
    
    // MARK: - 图层处理
    public func handleNotesLayerDisplay(_ selectedPOIs: [String]) -> [String: Bool] {
        var notesLayers: [String: Bool] = [:]
        
        notesLayers["矢量注记"] = selectedPOIs.contains("矢量注记")
        
        return notesLayers
    }
    
    public func handlePOILayerDisplay(_ selectedPOIs: [String]) -> [String: Bool] {
        var poiLayers: [String: Bool] = [:]
        
        poiLayers["露营地"] = selectedPOIs.contains("露营地")
        poiLayers["风景名胜"] = selectedPOIs.contains("风景名胜")
        poiLayers["加油站"] = selectedPOIs.contains("加油站")
        poiLayers["医疗"] = selectedPOIs.contains("医疗")
        poiLayers["我的兴趣点"] = selectedPOIs.contains("我的兴趣点")
        
        return poiLayers
    }
    
    public func handleWeatherLayerDisplay(_ selectedWeathers: [String]) -> [String: Bool] {
        var weatherLayers: [String: Bool] = [:]
        
        weatherLayers["温度"] = selectedWeathers.contains("温度")
        weatherLayers["相对湿度"] = selectedWeathers.contains("相对湿度")
        weatherLayers["风速"] = selectedWeathers.contains("风速")
        weatherLayers["能见度"] = selectedWeathers.contains("能见度")
        
        return weatherLayers
    }
    
}
