//
//  NetworkConfig.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

/// 网络配置和环境管理

import Foundation

/// 网络环境枚举
public enum NetworkEnvironment {
    case development
    case test
    case production
    
    public var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://test.bjtxts.com:9999")!
        case .test:
            return URL(string: "http://api-test.example.com")!
        case .production:
            return URL(string: "http://api.bjtxts.com:9999")!
        }
    }
}

/// 网络配置协议
public protocol NetworkConfigProtocol {
    var baseURL: URL { get }
    var timeoutInterval: TimeInterval { get }
    var maxRetryCount: Int { get }
    var enableLogging: Bool { get }
    var enableCache: Bool { get }
    var commonParameters: [String: Any] { get }
    var commonHeaders: [String: String] { get }
}

/// 默认网络配置
public struct NetworkConfig: NetworkConfigProtocol {
    
    public static let shared = NetworkConfig()
    
    public let baseURL: URL
    public let timeoutInterval: TimeInterval
    public let maxRetryCount: Int
    public let enableLogging: Bool
    public let enableCache: Bool
    public let commonParameters: [String: Any]
    public let commonHeaders: [String: String]
    
    private init() {
        self.baseURL = NetworkEnvironment.development.baseURL
        self.timeoutInterval = 30.0
        self.maxRetryCount = 3
        self.enableLogging = true
        self.enableCache = true
        self.commonParameters = [:]
        self.commonHeaders = [
            "Accept": "application/json",
            "User-Agent": "Network/1.0"
        ]
    }
    
    /// 创建自定义配置
    public init(
        baseURL: URL,
        timeoutInterval: TimeInterval = 30.0,
        maxRetryCount: Int = 3,
        enableLogging: Bool = true,
        enableCache: Bool = true,
        commonParameters: [String: Any] = [:],
        commonHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.timeoutInterval = timeoutInterval
        self.maxRetryCount = maxRetryCount
        self.enableLogging = enableLogging
        self.enableCache = enableCache
        self.commonParameters = commonParameters
        self.commonHeaders = commonHeaders
    }
}

/// 网络配置管理器
public class NetworkConfigurationManager {
    
    public static let shared = NetworkConfigurationManager()
    
    private var currentConfig: NetworkConfigProtocol
    
    private init() {
        self.currentConfig = NetworkConfig.shared
    }
    
    /// 获取当前配置
    public func getConfig() -> NetworkConfigProtocol {
        return currentConfig
    }
    
    /// 设置新配置
    public func setConfig(_ config: NetworkConfigProtocol) {
        currentConfig = config
    }
    
    /// 根据环境切换配置
    public func switchEnvironment(_ environment: NetworkEnvironment) {
        let newConfig = NetworkConfig(
            baseURL: environment.baseURL,
            timeoutInterval: currentConfig.timeoutInterval,
            maxRetryCount: currentConfig.maxRetryCount,
            enableLogging: currentConfig.enableLogging,
            enableCache: currentConfig.enableCache,
            commonParameters: currentConfig.commonParameters,
            commonHeaders: currentConfig.commonHeaders
        )
        setConfig(newConfig)
    }
}
