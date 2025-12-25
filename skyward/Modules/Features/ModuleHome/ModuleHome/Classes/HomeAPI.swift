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
}

extension HomeAPI: NetworkAPI {
    
    var path: String {
        return "/txts-data-app/api/v1/data/weather/current"
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

let noticeList_sub = "txts/home/servertoapp/notice/list/\(UserManager.shared.userId)"

let noticeList_pub = "txts/home/apptoserver/notice/list/\(UserManager.shared.userId)"

let latestMessage_sub = "txts/home/servertoapp/urgentMessage/latest/\(UserManager.shared.userId)"

let latestMessage_pub = "txts/home/apptoserver/urgentMessage/latest/\(UserManager.shared.userId)"

let cleanMessage_pub = "txts/home/apptoserver/urgentMessage/clean/\(UserManager.shared.userId)"
