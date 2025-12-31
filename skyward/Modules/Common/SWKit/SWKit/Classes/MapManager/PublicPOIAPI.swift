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
    case getPublicPOIList(_ model: PublicPOIListModel)  // 获取公共兴趣点列表
}

extension PublicPOIAPI: NetworkAPI {
    
    public var path: String {
        switch self {
        case .getPublicPOIList:
            return "/txts-data-app/api/v1/data/point-position/list"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .getPublicPOIList:
            return .post
        }
    }
    
    public var task: Task {
        switch self {
        case .getPublicPOIList(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
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
    
    public init() {
        self.provider = NetworkProvider<PublicPOIAPI>()
    }
    
    // MARK: - 获取公共兴趣点列表
    @available(iOS 13.0, *)
    public func getPublicPOIList(_ model: PublicPOIListModel) async throws -> Response {
        return try await provider.request(.getPublicPOIList(model))
    }
    
    public func getPublicPOIList(_ model: PublicPOIListModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getPublicPOIList(model), completion: completion)
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
        var dictionary: [String: Any] = [
            "pageNum": pageNum,
            "pageSize": pageSize
        ]
        return dictionary
    }
}

// MARK: - WCDB 表映射扩展
public struct PublicPOIData: Codable {
    public let id: String?
    public let name: String?
    public let description: String?
    public let type: String?
    public let address: String?
    public let lon: Double?
    public let lat: Double?
    public let category: Int?
    public let tel: String?
    public let wgsLon: Double?
    public let wgsLat: Double?
    public let images: String?
    public let isCollection: Bool?
    public let isIsCheck: Bool?
}

extension PublicPOIData: TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = PublicPOIData
        
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case name
        case description
        case type
        case address
        case lon
        case lat
        case category
        case tel
        case wgsLon
        case wgsLat
        case images
        case isCollection
        case isIsCheck
        
        // 列约束
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id"),
                .wgsLon: ColumnConstraintConfig(wgsLon, isPrimary: true, defaultTo: 0.0),
                .wgsLat: ColumnConstraintConfig(wgsLat, isPrimary: true, defaultTo: 0.0),
                .category: ColumnConstraintConfig(category, isPrimary: true, defaultTo: 0),
            ]
        }
    }
    
    public var isAutoIncrement: Bool { false }
    public init() { self.init(id: nil, name: nil, description: nil, type: nil, address: nil, lon: nil, lat: nil, category: nil, tel: nil, wgsLon: nil, wgsLat: nil, images: nil, isCollection: nil, isIsCheck: nil) }
}


// MARK: - 下载状态模型
public class POIDownloadStatus: TableCodable {
    var id: Int = 0
    var lastDownloadTime: Date = Date()
    var totalItems: Int = 0
    var lastSuccessfulPage: Int = 0
    var isCompleted: Bool = false
    
    // 必需的无参初始化器
    required init() {}
    
    // 便利初始化器
    convenience init(lastDownloadTime: Date = Date(),
                     totalItems: Int = 0,
                     lastSuccessfulPage: Int = 0,
                     isCompleted: Bool = false) {
        self.init()
        self.lastDownloadTime = lastDownloadTime
        self.totalItems = totalItems
        self.lastSuccessfulPage = lastSuccessfulPage
        self.isCompleted = isCompleted
    }
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = POIDownloadStatus
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case lastDownloadTime
        case totalItems
        case lastSuccessfulPage
        case isCompleted
        
        static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: 0)
            ]
        }
    }
}
