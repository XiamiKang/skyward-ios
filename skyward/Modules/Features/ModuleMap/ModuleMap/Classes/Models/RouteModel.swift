//
//  RouteModel.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/1/15.
//

import SWKit
import SWTheme
import WCDBSwift
import TXKit

public enum RouteType: Int {
    case route
    case track

    func name() -> String {
        switch self {
        case .route:
            return "路线"
        case .track:
            return "轨迹"
        }
    }
}

public enum PublicPOIChooseType: Int {
    case checkout
    case collect

    func name() -> String {
        switch self {
        case .checkout:
            return "打卡"
        case .collect:
            return "收藏"
        }
    }
}

// 路线/轨迹记录
struct Route: TableCodable {
    var id: String = String(Date().timeIntervalSince1970)
    var routeName: String?
    var startName: String?
    var startLongitude: Double?
    var startLatitude: Double?
    var endName: String?
    var endLongitude: Double?
    var endLatitude: Double?
    var distance: Double?
    var travelTime: Int?
    var maxAltitude: Double?
    var description: String?
    var fileUrl: String?
    var coverImageUrl: String?
    var type: Int?
    var createTime: String?
    
    // 非服务端字段
    var uploaded: Bool?
    var isVisible: Bool?
    // 非表字段
    var selected: Bool? = false
    var uploading: Bool? = false
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = Route
        
        case id
        case routeName
        case startName
        case startLongitude
        case startLatitude
        case endName
        case endLongitude
        case endLatitude
        case distance
        case travelTime
        case maxAltitude
        case description
        case fileUrl
        case coverImageUrl
        case type
        case createTime
        
        case uploaded
        case isVisible
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
            BindColumnConstraint(uploaded, defaultTo: false)
            BindColumnConstraint(isVisible, defaultTo: false)
        }
    }
    
    func startDesc() -> NSAttributedString? {
        guard let startName = startName else {
            return nil
        }
        guard let startLongitude = startLongitude, let startLatitude = startLatitude else {
            return nil
        }
        
        let startLonDesc = startLongitude.convertToDMSString(isLongitude: true)
        let startLatDesc = startLatitude.convertToDMSString(isLongitude: false)
        let coordinateDesc = startLonDesc + ", " + startLatDesc
        
        let range = NSRange(location: 0, length: startName.count)
        let attributedString = NSMutableAttributedString(string: startName + "\n" + coordinateDesc,
                                                         attributes: [
                                                             .font: UIFont.pingFangFontRegular(ofSize: 12),
                                                             .foregroundColor: ThemeManager.current.textColor
                                                         ])
        attributedString.addAttributes([
            .font: UIFont.pingFangFontMedium(ofSize: 14),
            .foregroundColor: ThemeManager.current.titleColor
        ], range: range)
        
        return attributedString
    }
    
    func endDesc() -> NSAttributedString? {
        guard let endName = endName else {
            return nil
        }
        guard let endLongitude = endLongitude, let endLatitude = endLatitude else {
            return nil
        }
        
        let endLonDesc = endLongitude.convertToDMSString(isLongitude: true)
        let endLatDesc = endLatitude.convertToDMSString(isLongitude: false)
        let coordinateDesc = endLonDesc + "," + endLatDesc
        
        let range = NSRange(location: 0, length: endName.count)
        let attributedString = NSMutableAttributedString(string: endName + "\n" + coordinateDesc,
                                                         attributes: [
                                                             .font: UIFont.pingFangFontRegular(ofSize: 12),
                                                             .foregroundColor: ThemeManager.current.textColor
                                                         ])
        attributedString.addAttributes([
            .font: UIFont.pingFangFontMedium(ofSize: 14),
            .foregroundColor: ThemeManager.current.titleColor
        ], range: range)
        
        return attributedString
    }
}

// 路线/轨迹记录点
struct RecordPoint {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    
    // 初始化方法
    init(latitude: Double, longitude: Double, altitude: Double = 0, timestamp: Date = Date()) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
    }
    
    // 从字符串解析轨迹点
    init?(from line: String) {
        let components = line.components(separatedBy: ",")
        guard components.count == 4 else { return nil }
        
        guard let lat = Double(components[0]),
              let lon = Double(components[1]),
              let alt = Double(components[2]),
              let timeInterval = Double(components[3]) else { return nil }
        
        self.latitude = lat
        self.longitude = lon
        self.altitude = alt
        self.timestamp = Date(timeIntervalSince1970: timeInterval)
    }
    
    // 转换为字符串格式（用于写入文件）
    func toString() -> String {
        let timeInterval = timestamp.timeIntervalSince1970
        return "\(latitude),\(longitude),\(altitude),\(timeInterval)"
    }
}

// MARK: 老数据结构

struct RouteRecord: TableCodable {
    let routeId: UInt64?
    var name: String?
    var desc: String?
    var uploadStatus: Int?
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = RouteRecord
        
        case routeId
        case name
        case desc
        case uploadStatus
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(routeId, isPrimary: true)
        }
    }
}


struct RoutePoint: TableCodable {
    let routeId: UInt64?
    let longitude: Double
    let latitude: Double
    var altitude: Double
    var timestamp: UInt64
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = RoutePoint
        
        case routeId
        case longitude
        case latitude
        case altitude
        case timestamp
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
    }
}

enum UploadStatus: Int, Codable, ColumnCodable {
    case notUploaded  // 未上传
    case uploaded     // 已上传
    case uploading    // 上传中
    
    public static var columnType: WCDBSwift.ColumnType {
        return .integer32
    }
    
    public init?(with value: WCDBSwift.Value) {
        self.init(rawValue: Int(value.int32Value))
    }
    
    public func archivedValue() -> WCDBSwift.Value {
        return FundamentalValue.init(Int32(self.rawValue))
    }
}

struct TrackRecord: TableCodable {
    var id: UInt64 = UInt64(Date().timeIntervalSince1970)
    var name: String = DateFormatter.fullPretty.string(from: Date())
    var localFileUrl: String?
    var uploadStatus: UploadStatus = .notUploaded
    var isLook: Bool = false
    
    enum CodingKeys: String, CodingTableKey {
        typealias Root = TrackRecord
        
        case id
        case name
        case localFileUrl
        case uploadStatus
        case isLook
        
        static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
        }
    }
    
    func fileFullURL() -> URL? {
        guard let fileUrl = localFileUrl, let fileURL = SandBox.docmentsURL?.appendingPathComponent(fileUrl) else {
            return nil
        }
        return fileURL
    }
}
