//
//  LayerPopupViewModel.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import Combine

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

public class LayerPopupViewModel: ObservableObject {
    
    // MARK: - 输出属性
    @Published public var sections: [SectionData] = []
    @Published public var selectedOptions: [String: Any] = [:]
    
    public private(set) var currentSelectedOptions: [String: Any] = [:]
    
    // MARK: - 私有属性
    private var mapSources: [MapSource] = [
        MapSource(name: "天地图街道",
                  imageName: "map1",
                  sceneUrl: "http://t1.tianditu.com/DataServer?T=vec_w&x={x}&y={y}&l={z}&tk=eb97ffb585b9a0dbde9e2b8eb54d6477"),
        MapSource(name: "天地图影像",
                  imageName: "map2",
                  sceneUrl: "http://t1.tianditu.com/DataServer?T=img_w&x={x}&y={y}&l={z}&tk=eb97ffb585b9a0dbde9e2b8eb54d6477"),
        MapSource(name: "吉林长光影像",
                  imageName: "map3",
                  sceneUrl: "https://api.jl1mall.com/getMap/{z}/{x}/{y}?mk=3ddec00f5f435270285ffc7ad1a60ce5&tk=c4e73a6b0428f65a94fb6fbe677d2375"),
        MapSource(name: "海图",
                  imageName: "map4",
                  sceneUrl: "https://m12.shipxy.com/tile.c?l=Na&m=o&x={x}&y={y}&z={z}")
//        MapSource(name: "谷歌地图",
//                  imageName: "map5",
//                  sceneUrl: "https://gdtc.shipxy.com/tile.g?z={z}&x={x}&y={y}"),
//        MapSource(name: "谷歌卫星",
//                  imageName: "map6",
//                  sceneUrl: "https://gwxc.shipxy.com/tile.g?z={z}&x={x}&y={y}")
    ]
    
    private var annotationOptions: [AnnotationOption] = [
        AnnotationOption(name: "矢量注记")
    ]
    
    private var poiOptions: [AnnotationOption] = [
        AnnotationOption(name: "露营地"),
        AnnotationOption(name: "风景名胜"),
        AnnotationOption(name: "加油站"),
        AnnotationOption(name: "我的兴趣点"),
        AnnotationOption(name: "我的路线")
    ]
    
    private var weatherOptions: [AnnotationOption] = [
        AnnotationOption(name: "温度"),
        AnnotationOption(name: "相对湿度"),
        AnnotationOption(name: "风速"),
        AnnotationOption(name: "能见度")
    ]
    
    // MARK: - 用户默认值键值
    private enum UserDefaultsKey {
        static let selectedMap = "selectedMapName"
        static let selectedAnnotations = "selectedAnnotations"
        static let selectedPOIs = "selectedPOIs"
        static let selectedWeathers = "selectedWeathers"
        static let lastSavedSelections = "UserMapLayerSelections"
    }
    
    // MARK: - Combine
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    public init() {
        setupData()
        loadUserSelections()
        
        currentSelectedOptions = selectedOptions
        // 添加所有可能的键，即使值为空
        if currentSelectedOptions["selectedPOIs"] == nil {
            currentSelectedOptions["selectedPOIs"] = []
        }
        if currentSelectedOptions["selectedWeathers"] == nil {
            currentSelectedOptions["selectedWeathers"] = []
        }
    }
    
    // MARK: - 数据设置
    private func setupData() {
        // 初始化时不设置任何选中，由 loadUserSelections 来恢复
        sections = [
            SectionData(type: .map, title: "地图类型", items: mapSources),
            SectionData(type: .annotation, title: "注记", items: annotationOptions),
            SectionData(type: .poi, title: "兴趣点", items: poiOptions),
//            SectionData(type: .weather, title: "天气图层", items: weatherOptions)
        ]
        updateSelectedOptions()
    }
    
    // MARK: - 操作
    public func selectMap(at indexPath: IndexPath) {
        guard indexPath.section < sections.count else { return }
        let section = sections[indexPath.section]
        
        guard section.type == .map else { return }
        
        // 更新地图选择
        for i in 0..<mapSources.count {
            mapSources[i].isSelected = (i == indexPath.item)
        }
        
        // 保存选中的地图
        saveSelectedMap(mapSources[indexPath.item].name)
        
        // 更新sections
        sections[indexPath.section].items = mapSources
        updateSelectedOptions()
        
        print("当前选中的地图: \(mapSources[indexPath.item].name)")
    }
    
    public func toggleAnnotationOption(at indexPath: IndexPath) {
        guard indexPath.section < sections.count else { return }
        let section = sections[indexPath.section]
        
        guard section.type != .map else { return }
        
        var optionName: String?
        
        switch section.type {
        case .annotation:
            guard indexPath.item < annotationOptions.count else { return }
            annotationOptions[indexPath.item].isSelected.toggle()
            sections[indexPath.section].items = annotationOptions
            optionName = annotationOptions[indexPath.item].name
            
        case .poi:
            guard indexPath.item < poiOptions.count else { return }
            poiOptions[indexPath.item].isSelected.toggle()
            sections[indexPath.section].items = poiOptions
            optionName = poiOptions[indexPath.item].name
            
        case .weather:
            guard indexPath.item < weatherOptions.count else { return }
            weatherOptions[indexPath.item].isSelected.toggle()
            sections[indexPath.section].items = weatherOptions
            optionName = weatherOptions[indexPath.item].name
            
        default:
            return
        }
        
        // 保存选项
        if let name = optionName {
            saveOptionSelection(name: name, isSelected: getIsSelectedForItem(at: indexPath), type: section.type)
        }
        
        updateSelectedOptions()
    }
    
    private func getIsSelectedForItem(at indexPath: IndexPath) -> Bool {
        guard indexPath.section < sections.count else { return false }
        let section = sections[indexPath.section]
        
        switch section.type {
        case .annotation:
            return indexPath.item < annotationOptions.count ? annotationOptions[indexPath.item].isSelected : false
        case .poi:
            return indexPath.item < poiOptions.count ? poiOptions[indexPath.item].isSelected : false
        case .weather:
            return indexPath.item < weatherOptions.count ? weatherOptions[indexPath.item].isSelected : false
        default:
            return false
        }
    }
    
    // MARK: - 持久化方法
    private func saveSelectedMap(_ mapName: String) {
        UserDefaults.standard.set(mapName, forKey: UserDefaultsKey.selectedMap)
        UserDefaults.standard.synchronize()
        print("✅ 保存选中的地图: \(mapName)")
    }
    
    private func saveOptionSelection(name: String, isSelected: Bool, type: SectionData.SectionType) {
        let key: String
        switch type {
        case .annotation:
            key = UserDefaultsKey.selectedAnnotations
        case .poi:
            key = UserDefaultsKey.selectedPOIs
        case .weather:
            key = UserDefaultsKey.selectedWeathers
        default:
            return
        }
        
        var selectedOptions = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        
        if isSelected {
            if !selectedOptions.contains(name) {
                selectedOptions.append(name)
            }
        } else {
            selectedOptions.removeAll { $0 == name }
        }
        
        UserDefaults.standard.set(selectedOptions, forKey: key)
        UserDefaults.standard.synchronize()
        print("✅ 保存选项: \(name) - \(isSelected ? "选中" : "取消")")
    }
    
    public func loadUserSelections() {
        // 1. 加载选中的地图
        let selectedMapName = UserDefaults.standard.string(forKey: UserDefaultsKey.selectedMap)
        
        // 设置默认地图（如果没有保存的选择，则使用吉林长光影像）
        let defaultMapName = selectedMapName ?? "吉林长光影像"
        
        // 重置所有地图的选中状态
        for i in 0..<mapSources.count {
            mapSources[i].isSelected = (mapSources[i].name == defaultMapName)
        }
        
        // 2. 加载选中的注记
        let selectedAnnotations = UserDefaults.standard.array(forKey: UserDefaultsKey.selectedAnnotations) as? [String] ?? []
        // 如果没有保存的注记选择，默认选中"矢量注记"
        let finalSelectedAnnotations = selectedAnnotations.isEmpty ? ["矢量注记"] : selectedAnnotations
        for i in 0..<annotationOptions.count {
            annotationOptions[i].isSelected = finalSelectedAnnotations.contains(annotationOptions[i].name)
        }
        
        // 3. 加载选中的兴趣点
        let selectedPOIs = UserDefaults.standard.array(forKey: UserDefaultsKey.selectedPOIs) as? [String] ?? []
        // 如果没有保存的POI选择，默认没有选中
        let finalSelectedPOIs = selectedPOIs.isEmpty ? [] : selectedPOIs
        for i in 0..<poiOptions.count {
            poiOptions[i].isSelected = finalSelectedPOIs.contains(poiOptions[i].name)
        }
        
        // 4. 加载选中的天气图层
        let selectedWeathers = UserDefaults.standard.array(forKey: UserDefaultsKey.selectedWeathers) as? [String] ?? []
        for i in 0..<weatherOptions.count {
            weatherOptions[i].isSelected = selectedWeathers.contains(weatherOptions[i].name)
        }
        
        // 更新sections
        sections = [
            SectionData(type: .map, title: "地图类型", items: mapSources),
            SectionData(type: .annotation, title: "注记", items: annotationOptions),
            SectionData(type: .poi, title: "兴趣点", items: poiOptions),
//            SectionData(type: .weather, title: "天气图层", items: weatherOptions)
        ]
        
        updateSelectedOptions()
        
        print("📂 加载用户选择: 地图-\(defaultMapName), 注记-\(finalSelectedAnnotations), POI-\(finalSelectedPOIs), 天气-\(selectedWeathers)")
    }
    
    // MARK: - 工具方法
    private func updateSelectedOptions() {
        selectedOptions = getSelectedOptions()
    }
    
    private func getSelectedOptions() -> [String: Any] {
        var result: [String: Any] = [:]
        
        // 获取选中的地图
        if let selectedMap = mapSources.first(where: { $0.isSelected }) {
            result["selectedMap"] = [
                "name": selectedMap.name,
                "sceneUrl": selectedMap.sceneUrl
            ]
        }
        
        // 获取选中的注记
        let selectedAnnotations = annotationOptions.filter { $0.isSelected }
        result["selectedAnnotations"] = selectedAnnotations.map { $0.name }
        
        // 获取选中的兴趣点
        let selectedPOIs = poiOptions.filter { $0.isSelected }
        result["selectedPOIs"] = selectedPOIs.map { $0.name }
        
        // 获取选中的天气图层
        let selectedWeathers = weatherOptions.filter { $0.isSelected }
        result["selectedWeathers"] = selectedWeathers.map { $0.name }
        
        return result
    }
    
    // MARK: - 公开的保存方法
    public func saveUserSelections() {
        // 保存到单独键值
        if let selectedMap = mapSources.first(where: { $0.isSelected }) {
            saveSelectedMap(selectedMap.name)
        }
        
        // 保存注记选择
        let selectedAnnotations = annotationOptions.filter { $0.isSelected }.map { $0.name }
        UserDefaults.standard.set(selectedAnnotations, forKey: UserDefaultsKey.selectedAnnotations)
        
        // 保存POI选择
        let selectedPOIs = poiOptions.filter { $0.isSelected }.map { $0.name }
        UserDefaults.standard.set(selectedPOIs, forKey: UserDefaultsKey.selectedPOIs)
        
        // 保存天气选择
        let selectedWeathers = weatherOptions.filter { $0.isSelected }.map { $0.name }
        UserDefaults.standard.set(selectedWeathers, forKey: UserDefaultsKey.selectedWeathers)
        
        // 保存完整的选择字典
        let selections = getSelectedOptions()
        UserDefaults.standard.set(selections, forKey: UserDefaultsKey.lastSavedSelections)
        UserDefaults.standard.synchronize()
        
        print("✅ 用户图层选择已保存到: \(UserDefaultsKey.lastSavedSelections)")
        print("保存内容: \(selections)")
    }
    
    // MARK: - 图层处理
    public func handlePOILayerDisplay(_ selectedPOIs: [String]) -> [String: Bool] {
        var poiLayers: [String: Bool] = [:]
        
        poiLayers["露营地"] = selectedPOIs.contains("露营地")
        poiLayers["风景名胜"] = selectedPOIs.contains("风景名胜")
        poiLayers["加油站"] = selectedPOIs.contains("加油站")
        poiLayers["我的兴趣点"] = selectedPOIs.contains("我的兴趣点")
        poiLayers["我的路线"] = selectedPOIs.contains("我的路线")
        
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
    
    // MARK: - 清除用户选择（调试用）
    public func clearUserSelections() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.selectedMap)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.selectedAnnotations)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.selectedPOIs)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.selectedWeathers)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.lastSavedSelections)
        UserDefaults.standard.synchronize()
        print("🧹 已清除所有用户选择")
        
        // 重新加载默认值
        loadUserSelections()
    }
}
