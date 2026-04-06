//
//  HomeAPI.swift
//  ModuleHome
//
//  Created by 赵波 on 2025/11/18.
//

import Foundation
import SWNetwork
import Moya
import SWKit

enum HomeAPI {
    case weatherInfo(longitude: Double, latitude: Double)
    
    case noticeList
    
    static var noticeNew_sub: String {
        return "txts/home/servertoapp/notice/new/\(UserManager.shared.userId)"
    }

    static var cleanMessage_pub: String {
        return "txts/home/apptoserver/notice/clean/\(UserManager.shared.userId)"
    }

    static var onlinePing_pub: String {
        return "txts/user/apptoserver/online/\(UserManager.shared.userId)"
    }
}

extension HomeAPI: NetworkAPI {
    
    var path: String {
        switch self {
        case .weatherInfo:
            return "/txts-data-app/api/v1/data/weather/current"
        case .noticeList:
            return "/txts-user-center-app/api/v1/notice/list"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var task: Moya.Task {
        switch self {
        case .weatherInfo(let longitude, let latitude):
            // 将经纬度参数作为查询参数添加到URL中
            let parameters: [String: Any] = [
                "longitude": longitude,
                "latitude": latitude
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .noticeList:
            let parameters: [String: Any] = [
                "pageNum": 1,
                "pageSize": -1
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}
