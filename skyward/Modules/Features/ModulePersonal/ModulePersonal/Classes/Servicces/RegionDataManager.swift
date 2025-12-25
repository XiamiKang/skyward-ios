//
//  Region.swift
//  Pods
//
//  Created by TXTS on 2025/12/23.
//


import UIKit

// MARK: - 数据模型
struct Region {
    let code: String
    let name: String
    let level: Int
    let pcode: String
    
    var isProvince: Bool { level == 1 }
    var isCity: Bool { level == 2 }
    var isDistrict: Bool { level == 3 }
}

// MARK: - 数据管理器
class RegionDataManager {
    static let shared = RegionDataManager()
    
    private(set) var allRegions: [Region] = []
    private(set) var provinces: [Region] = []
    private var citiesMap: [String: [Region]] = [:] // key: 省份code
    private var districtsMap: [String: [Region]] = [:] // key: 城市code
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        // 从plist文件加载数据
        guard let path = Bundle.main.path(forResource: "Citys", ofType: "plist"),
              let array = NSArray(contentsOfFile: path) as? [[String: Any]] else {
            print("Failed to load region data")
            return
        }
        
        // 解析数据
        var regions: [Region] = []
        var provinces: [Region] = []
        var citiesMap: [String: [Region]] = [:]
        var districtsMap: [String: [Region]] = [:]
        
        for dict in array {
            guard let code = dict["code"] as? String,
                  let name = dict["name"] as? String,
                  let level = dict["level"] as? Int,
                  let pcode = dict["pcode"] as? String else {
                continue
            }
            
            let region = Region(code: code, name: name, level: level, pcode: pcode)
            regions.append(region)
            
            switch level {
            case 1:
                provinces.append(region)
            case 2:
                var cities = citiesMap[pcode] ?? []
                cities.append(region)
                citiesMap[pcode] = cities
            case 3:
                var districts = districtsMap[pcode] ?? []
                districts.append(region)
                districtsMap[pcode] = districts
            default:
                break
            }
        }
        
        self.allRegions = regions
        self.provinces = provinces
        self.citiesMap = citiesMap
        self.districtsMap = districtsMap
    }
    
    func getCities(forProvinceCode provinceCode: String) -> [Region] {
        return citiesMap[provinceCode] ?? []
    }
    
    func getDistricts(forCityCode cityCode: String) -> [Region] {
        return districtsMap[cityCode] ?? []
    }
    
    func findRegion(byCode code: String) -> Region? {
        return allRegions.first { $0.code == code }
    }
}
