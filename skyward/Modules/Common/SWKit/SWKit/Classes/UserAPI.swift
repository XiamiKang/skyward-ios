//
//  UserAPI.swift
//  SWNetworkKit_Example
//
//  Created by 赵波 on 2025/11/17.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import Moya
import SWNetwork

public enum UserAPI {
    case getUserInfo
    case getEmergencyContact
    case bindEmergencyContact(name: String, phone: String)
    case bindMiniDevice(userId: String, serialNum: String, macAddress: String)
}

extension UserAPI: NetworkAPI {
    
    public var headers: [String: String]? {
        // 为所有请求添加默认的Accept头
        var defaultHeaders: [String: String] = [
            "Accept": "application/json"
        ]
        guard let token = TokenManager.shared.accessToken else {
            return defaultHeaders
        }
        defaultHeaders["Authorization"] = "Bearer \(token)"
        
        return defaultHeaders
    }
    
    public var path: String {
        switch self {
        case .getUserInfo:
            return "/txts-user-center-app/api/v1/user/app-user/info"
        case .getEmergencyContact:
            return "/txts-user-center-app/api/v1/emergency-contact/info"
        case .bindEmergencyContact:
            return "/txts-user-center-app/api/v1/emergency-contact"
        case .bindMiniDevice:
            return "/txts-user-center-app/api/v1/user/device/bindDevice"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .getUserInfo, .getEmergencyContact:
            return .get
        case .bindEmergencyContact, .bindMiniDevice:
            return .post
        }
    }
    
    public var task: Moya.Task {
        switch self {
        case .getUserInfo, .getEmergencyContact:
            return .requestPlain
        case .bindEmergencyContact(let name, let phone):
            return .requestParameters(parameters: ["name": name, "phone": phone], encoding: JSONEncoding.default)
        case .bindMiniDevice(let userId, let serialNum, let macAddress):
            return .requestParameters(
                parameters: ["userId": userId, "serialNum": serialNum, "macAddress": macAddress],
                encoding: JSONEncoding.default)
        }
    }
}

