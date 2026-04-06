//
//  PublicPOIAPI.swift
//  Pods
//
//  Created by TXTS on 2025/12/31.
//


import Foundation
import Moya
import WCDBSwift
import SWNetwork

// MARK: - 公共兴趣点相关API
public enum PublicPOIAPI {
    case getPublicPOIList  // 导出公共兴趣点数据为txt文件
}

extension PublicPOIAPI: NetworkAPI {
    
    public var path: String {
        switch self {
        case .getPublicPOIList:
            return "/txts-data-app/api/v1/data/point-position/export"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .getPublicPOIList:
            return .get
        }
    }
    
    public var task: Task {
        switch self {
        case .getPublicPOIList:
            return .requestPlain
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

public class PublicPOIService {
    
    private let provider: NetworkProvider<PublicPOIAPI>
    
    public init(logEnabled: Bool = false) {
        
        var plugins: [PluginType] = []
        
        if !logEnabled {
            // 不包含日志插件
            plugins.append(NetworkCachePlugin(cachePolicy: .memoryOnly))
            plugins.append(NetworkMonitorPlugin { _ in })
            // 可以添加其他非日志插件
        }
        
        // 如果传入空数组，NetworkProvider会使用默认插件
        if plugins.isEmpty {
            // 使用默认配置但不包含日志插件
            plugins = NetworkDefaultPlugins.createDefaultMoyaPlugins(
                logLevel: .none,  // 设置为 .none 可以禁用日志
                cachePolicy: .memoryOnly
            )
        }
        
        // 创建配置
        let config = NetworkConfigurationManager.shared.getConfig()
        
        // 创建自定义的 NetworkProvider
        self.provider = NetworkProvider<PublicPOIAPI>(
            config: config,
            plugins: plugins,
            stubClosure: MoyaProvider.neverStub
        )
    }
    
    // MARK: - 获取公共兴趣点列表
    @available(iOS 13.0, *)
    public func getPublicPOIList() async throws -> Response {
        return try await provider.request(.getPublicPOIList)
    }
    
    public func getPublicPOIList(_ completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getPublicPOIList, completion: completion)
    }
}



public struct PublicPOIListModel {
    public let pageNum: Int
    public let pageSize: Int
    
    public init(pageNum: Int, pageSize: Int) {
        self.pageNum = pageNum
        self.pageSize = pageSize
    }
    
    public func toDictionary() -> [String: Any] {
        let dictionary: [String: Any] = [
            "pageNum": pageNum,
            "pageSize": pageSize
        ]
        return dictionary
    }
}

// MARK: - 导出响应模型
struct POIExportResponse: Codable {
    let code: String
    let data: POIExportData
    let msg: String
    let requestId: String?
}

struct POIExportData: Codable {
    let fileUrl: String
    let fileMd5: String
    let version: String
}

