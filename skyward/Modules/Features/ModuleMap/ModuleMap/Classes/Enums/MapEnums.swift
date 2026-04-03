//
//  MapEnums.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation

public enum POIType: String, CaseIterable {
    case campsite = "露营地"
    case scenicSpot = "风景名胜"
    case gasStation = "加油站"
    case medical = "医疗"
    
    public var iconName: String {
        switch self {
        case .campsite: return "map_poi_type1"
        case .scenicSpot: return "map_poi_type2"
        case .gasStation: return "map_poi_type3"
        case .medical: return "map_poi_type4"
        }
    }
    
    public var selIconName: String {
        switch self {
        case .campsite: return "map_poi_selType1"
        case .scenicSpot: return "map_poi_selType2"
        case .gasStation: return "map_poi_selType3"
        case .medical: return "map_poi_selType4"
        }
    }
    
    public var category: Int {
        switch self {
        case .campsite: return 1
        case .scenicSpot: return 2
        case .gasStation: return 3
        case .medical: return 4
        }
    }
    
    public static func categoryConversionType(category: Int) -> POIType {
        switch category {
        case 1:
                .campsite
        case 2:
                .scenicSpot
        case 3:
                .gasStation
        case 4:
                .medical
        default:
                .campsite
        }
    }
}

public enum MapError: Error {
    case networkError(String)
    case parseError(String)
    case businessError(message: String, code: String)
    
    public var errorMessage: String {
        switch self {
        case .networkError(let message):
            return message
        case .parseError(let message):
            return message
        case .businessError(let message, _):
            return message
        }
    }
    
    public var errorCode: String {
        switch self {
        case .businessError(_, let code):
            return code
        default:
            return "-1"
        }
    }
}
