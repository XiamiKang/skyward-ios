//
//  NetworkAPI.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

/// 核心API协议和响应模型等

import Foundation
import Moya

public protocol NetworkAPI: TargetType {
    /// API版本
    var version: String { get }
    
    /// 是否需要认证
    var requiresAuth: Bool { get }
    
    /// 是否启用缓存
    var enableCache: Bool { get }
    
    /// 缓存时间（秒）
    var cacheTime: TimeInterval { get }
}

/// 提供默认实现
public extension NetworkAPI {
    
    var version: String { "v1" }
    
    var requiresAuth: Bool { false }
    
    var enableCache: Bool { false }
    
    var cacheTime: TimeInterval { 300 } // 默认5分钟
    
    /// 默认基础URL - 可以根据环境切换
    var baseURL: URL {
        return NetworkConfig.shared.baseURL
    }
    
    /// 默认请求头
    var headers: [String: String]? {
        var headers = [String: String]()
        
        // 添加认证头（如果需要）
        if requiresAuth {
            // 这里可以从TokenManager获取token
            // headers["Authorization"] = "Bearer \(TokenManager.shared.token)"
        }
        
        // 添加版本头
        headers["API-Version"] = version
        
        // 添加内容类型
        switch method {
        case .get:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        default:
            headers["Content-Type"] = "application/json"
        }
        
        return headers
    }
    
    /// 默认验证类型
    var validationType: ValidationType {
        return .successCodes
    }
}

/// 网络响应模型
public struct NetworkResponse<T: Codable>: Codable {
    public let code: String?
    public let msg: String?
    public let data: T?
    
    public init(code: String, message: String? = nil, data: T? = nil) {
        self.code = code
        self.msg = message
        self.data = data
    }
    
    /// 检查响应是否成功（code为00000）
    public var isSuccess: Bool {
        return code == "00000"
    }
}

/// 空响应模型
public struct NetworkEmptyResponse: Codable {
    public init() {}
}

/// 网络结果枚举 - 包含错误类型
public enum NetworkResult<T> {
    case success(T)
    case failure(NetworkError)
    
    /// 获取成功值
    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// 获取错误
    public var error: NetworkError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// 是否成功
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

/// 网络状态枚举
public enum NetworkStatus {
    case unknown
    case notReachable
    case reachableViaWiFi
    case reachableViaWWAN
}


public struct EmptyDecodable: Codable { }
