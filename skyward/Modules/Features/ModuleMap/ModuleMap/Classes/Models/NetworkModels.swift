//
//  NetworkModels.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import SWKit

// 网络请求参数模型
public struct RouteListModel {
    public let type: String   // 路线类型(0-路线 1-自动轨迹)
    public let pageNum: String
    public let pageSize: String
    
    public func toDictionary() -> [String: Any] {
        return [
            "type": type,
            "pageNum": pageNum,
            "pageSize": pageSize
        ]
    }
}

public struct RouteMsgModel {
    public let routeId: Int
    
    public func toDictionary() -> [String: Any] {
        return ["routeId": routeId]
    }
}

public struct PublicPOIListModel {
    public let pageNum: Int
    public let pageSize: Int
    public let category: Int?  // 旅游景点 0; 露营地 1; 风景名胜 2; 公共设施 3
    public let id: String?
    public let name: String?
    public let baseCoordinateList: [Coordinate]?
    
    public func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "pageNum": pageNum,
            "pageSize": pageSize
        ]
        dictionary.addIfPresent(pageNum, forKey: "pageNum")
        dictionary.addIfPresent(pageSize, forKey: "pageSize")
        dictionary.addIfPresent(category, forKey: "category")
        dictionary.addIfPresent(id, forKey: "id")
        dictionary.addIfPresent(name, forKey: "name")
        dictionary.addValidCoordinates(baseCoordinateList, forKey: "baseCoordinateList")
        
        return dictionary
    }
}

public struct UserPOIModel {
    public let name: String
    public let description: String
    public let lon: Double
    public let lat: Double
    public let category: Int // 旅游景点 0; 露营地 1; 风景名胜 2; 加油站 3
    public let imgUrlList: [String]?
    public let state: Int  // 状态(0-正常 1-删除)
    public let userId: Int
    
    public func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "name": name,
            "description": description,
            "lon": lon,
            "lat": lat,
            "category": category,
            "state": state,
            "userId": userId
        ]
        dictionary.addIfPresent(imgUrlList, forKey: "imgUrlList")
        return dictionary
    }
}


public struct UserRouteModel {
    public let routeName: String
    public let startName: String
    public let endName: Double
    public let distance: Double
    public let coordinates: [Coordinate]
    public let type: Int  // 路线类型(0-路线 1-自动轨迹)
    public let state: Int  // 状态(0-正常 1-删除)
    public let userId: Int
    
    public func toDictionary() -> [String: Any] {
        let dictionary: [String: Any] = [
            "routeName": routeName,
            "startName": startName,
            "endName": endName,
            "distance": distance,
            "coordinates": coordinates,
            "type": type,
            "state": state,
            "userId": userId
        ]
        return dictionary
    }
}


