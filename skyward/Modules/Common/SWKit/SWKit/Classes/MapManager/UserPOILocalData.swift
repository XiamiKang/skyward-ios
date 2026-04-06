//
//  File.swift
//  SWKit
//
//  Created by TXTS on 2026/2/4.
//

import Foundation
import WCDBSwift

public struct UserPOILocalData: TableCodable {
    
    public var id: Int?                           // 本地数据储存编号（自增）
    public var poiId: String?                     // 兴趣点id，用于后续网络接口操作
    public var name: String?                      // 兴趣点名称
    public var address: String?                   // 兴趣点地址
    public var description: String?               // 兴趣点描述
    public var lon: Double?                       // 经度
    public var lat: Double?                       // 纬度
    public var category: Int?                     // 兴趣点分类（1：露营地，2：风景名胜，3：加油站，4：医疗）
    public var imageData1: String?                // 图片1
    public var imageData2: String?                // 图片2
    public var imageData3: String?                // 图片3
    public var isDelected: Bool? = false          // 是否本地删除
    public var isHide: Bool? = true               // 是否隐藏
    public var altitude: Double?                  // 海拔
    public var isSynchronousNetwork: Bool? = false// 是否同步网络
    
    public init(id: Int? = nil,
                poiId: String? = nil,
                name: String?,
                address: String? = nil,
                description: String? = nil,
                lon: Double?,
                lat: Double?,
                category: Int?,
                imageData1: String? = nil,
                imageData2: String? = nil,
                imageData3: String? = nil,
                isDelected: Bool? = false,
                isHide: Bool? = false,
                altitude: Double? = nil,
                isSynchronousNetwork: Bool? = false) {
        self.id = id
        self.poiId = poiId
        self.name = name
        self.address = address
        self.description = description
        self.lon = lon
        self.lat = lat
        self.category = category
        self.imageData1 = imageData1
        self.imageData2 = imageData2
        self.imageData3 = imageData3
        self.isDelected = isDelected
        self.isHide = isHide
        self.altitude = altitude
        self.isSynchronousNetwork = isSynchronousNetwork
    }
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = UserPOILocalData
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, isAutoIncrement: true, isUnique: true)
        }
        
        case id
        case poiId
        case name
        case address
        case description
        case lon
        case lat
        case category
        case imageData1
        case imageData2
        case imageData3
        case isDelected
        case isHide
        case altitude
        case isSynchronousNetwork
        
        static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, defaultTo: 0),
                .isDelected: ColumnConstraintConfig(isDelected, defaultTo: false),
                .isHide: ColumnConstraintConfig(isHide, defaultTo: true),
                .isSynchronousNetwork: ColumnConstraintConfig(isSynchronousNetwork, defaultTo: false)
            ]
        }
    }
}


public struct UserPOIData: Codable {
    public let poiId: String?
    public let name: String?
    public let description: String?
    public let lon: Double?
    public let lat: Double?
    public let category: Int?
    public let imgUrlList: [String]?
    public let address: String?
    public let altitude: String?
}
