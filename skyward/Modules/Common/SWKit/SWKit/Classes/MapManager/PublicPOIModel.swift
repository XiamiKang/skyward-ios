//
//  PublicPOIModel.swift
//  ModuleMap
//
//  Created by TXTS on 2026/2/26.
//

import Foundation
import WCDBSwift

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
    public var isCollection: Bool?
    public var isIsCheck: Bool?
    public var altitude: Double?
    public var minZoom: Int?
    // 新增操作时间字段
    public var collectionTime: Date?  // 收藏时间
    public var checkTime: Date?       // 打卡时间
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
        case altitude
        case minZoom
        case collectionTime  // 新增
        case checkTime       // 新增
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id"),
                .wgsLon: ColumnConstraintConfig(wgsLon, isPrimary: true, defaultTo: 0.0),
                .wgsLat: ColumnConstraintConfig(wgsLat, isPrimary: true, defaultTo: 0.0),
                .category: ColumnConstraintConfig(category, isPrimary: true, defaultTo: 0),
                .collectionTime: ColumnConstraintConfig(collectionTime, defaultTo: nil),
                .checkTime: ColumnConstraintConfig(checkTime, defaultTo: nil),
            ]
        }
    }
    
    public var isAutoIncrement: Bool { false }
    public init() { self.init(id: nil, name: nil, description: nil, type: nil, address: nil, lon: nil, lat: nil, category: nil, tel: nil, wgsLon: nil, wgsLat: nil, images: nil, isCollection: nil, isIsCheck: nil, altitude: nil, minZoom: nil, collectionTime: nil, checkTime: nil) }
}

// MARK: - POI TXT 行模型
struct POITextRow {
    let id: String
    let wgsLon: Double
    let wgsLat: Double
    let name: String
    let address: String
    let category: Int
    let altitude: Double?
    let minZoom: Int
    
    // 转换为数据库模型
    func toPublicPOIData() -> PublicPOIData {
        return PublicPOIData(
            id: id,
            name: name,
            description: nil,
            type: nil,
            address: address.isEmpty ? nil : address,
            lon: wgsLon,
            lat: wgsLat,
            category: category,
            tel: nil,
            wgsLon: wgsLon,
            wgsLat: wgsLat,
            images: nil,
            isCollection: nil,
            isIsCheck: nil,
            altitude: altitude,
            minZoom: minZoom
        )
    }
}

// 确保 POIDownloadStatus 有正确的定义
public struct POIDownloadStatus: TableCodable {
    var id: Int? // 主键
    var lastDownloadTime: Date
    var fileVersion: String
    var fileUrl: String
    var fileMd5: String
    var totalCount: Int
    var lastSuccessfulPage: Int? // 可以删除，保留为兼容
    var isCompleted: Bool? // 可以删除，保留为兼容
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = POIDownloadStatus
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case lastDownloadTime
        case fileVersion
        case fileUrl
        case fileMd5
        case totalCount
        case lastSuccessfulPage
        case isCompleted
        
        static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, isAutoIncrement: true, defaultTo: "id"),
                .lastDownloadTime: ColumnConstraintConfig(lastDownloadTime, defaultTo: Date()),
                .fileVersion: ColumnConstraintConfig(fileVersion, defaultTo: ""),
                .totalCount: ColumnConstraintConfig(totalCount, defaultTo: 0)
            ]
        }
    }
    
    public var isAutoIncrement: Bool { true }
    
    init(id: Int? = nil,
         lastDownloadTime: Date = Date(),
         fileVersion: String = "",
         fileUrl: String = "",
         fileMd5: String = "",
         totalCount: Int = 0,
         lastSuccessfulPage: Int? = nil,
         isCompleted: Bool? = nil) {
        self.id = id
        self.lastDownloadTime = lastDownloadTime
        self.fileVersion = fileVersion
        self.fileUrl = fileUrl
        self.fileMd5 = fileMd5
        self.totalCount = totalCount
        self.lastSuccessfulPage = lastSuccessfulPage
        self.isCompleted = isCompleted
    }
}
