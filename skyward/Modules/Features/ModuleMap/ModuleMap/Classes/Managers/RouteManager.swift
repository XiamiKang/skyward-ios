//
//  RouteManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/18.
//

import Foundation
import CoreLocation
import SWKit
import WCDBSwift

struct RouteRecord: TableCodable {
    let routeId: UInt64?
    var name: String?
    var desc: String?
    var uploadStatus: Int?
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = RouteRecord
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case routeId
        case name
        case desc
        case uploadStatus
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .routeId: ColumnConstraintConfig(routeId, isPrimary: true, defaultTo: "routeId")
            ]
        }
    }
}


struct RoutePoint: TableCodable {
    let routeId: UInt64?
    let longitude: Double?
    let latitude: Double?
    var altitude: Double?
    var timestamp: UInt64?
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = RoutePoint
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case routeId
        case longitude
        case latitude
        case altitude
        case timestamp
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .routeId: ColumnConstraintConfig(routeId, isPrimary: true, defaultTo: "routeId")
            ]
        }
    }
}


class RouteManager {
    var currentRouteId: UInt64? = nil
    
    // 常量定义
    private let gpxExtension = "gpx"
    
    private lazy var uploadManager: UploadManager = {
        let mgr = UploadManager()
        return mgr
    }()
    
    private lazy var mapService: MapService = {
        let mapService = MapService()
        return mapService
    }()
    
    init() {
        DBManager.shared.createTable(table: DBTableName.route.rawValue, of: RouteRecord.self)
        DBManager.shared.createTable(table: DBTableName.routePoint.rawValue, of: RoutePoint.self)
    }
    
    func closeRecord() {
        currentRouteId = nil
    }
    
    func writePoint(_ point: CLLocationCoordinate2D) {

        if currentRouteId == nil {
            currentRouteId = UInt64(Date().timeIntervalSince1970)
            let routeRecord = RouteRecord(routeId: currentRouteId, name: nil, desc: nil, uploadStatus: 0)
            DBManager.shared.insertToDb(objects: [routeRecord], intoTable: DBTableName.route.rawValue)
        }
        let routePoint = RoutePoint(routeId: currentRouteId,
                                    longitude: point.longitude,
                                    latitude: point.latitude,
                                    altitude: 0,
                                    timestamp: UInt64(Date().timeIntervalSince1970))
        DBManager.shared.insertToDb(objects: [routePoint], intoTable: DBTableName.routePoint.rawValue)
    }
    
    func getAllRoutes() -> [RouteRecord]? {
        return DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue, cls: RouteRecord.self)
    }

    func getPointsInRoute(routeId: UInt64) -> [RoutePoint]? {
        return DBManager.shared.queryFromDb(fromTable: DBTableName.routePoint.rawValue, cls: RoutePoint.self, where: RoutePoint.Properties.routeId == routeId)
    }
    
    func saveRoute(name: String, desc: String?) {
        guard let routeId = currentRouteId else {
            debugPrint("saveRoute: 没有当前路线ID")
            return
        }
        
        // 更新路线基本信息
        guard updateRouteBasicInfo(routeId: routeId, name: name, desc: desc) else {
            UIWindow.topWindow?.sw_showWarningToast("保存路线信息失败")
            return
        }
        
        // 查询路线记录和轨迹点
        guard let record = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue, cls: RouteRecord.self, where: RouteRecord.Properties.routeId == routeId)?.first, 
              let points = getPointsInRoute(routeId: routeId), 
              !points.isEmpty else {
            debugPrint("saveRoute: 没有找到路线记录或轨迹点为空")
            UIWindow.topWindow?.sw_showWarningToast("没有轨迹数据可保存")
            return
        }
        
        // 生成GPX并上传
        generateAndUploadGPX(for: record, with: points)
    }
    
    /// 更新路线基本信息
    /// - Parameters:
    ///   - routeId: 路线ID
    ///   - name: 名称
    ///   - desc: 描述
    /// - Returns: 是否更新成功
    private func updateRouteBasicInfo(routeId: UInt64, name: String, desc: String?) -> Bool {
        if var record = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue, cls: RouteRecord.self, where: RouteRecord.Properties.routeId == routeId)?.first {
            record.name = name
            record.desc = desc
            return DBManager.shared.updateToDb(table: DBTableName.route.rawValue,
                                               on: [RouteRecord.Properties.name, RouteRecord.Properties.desc],
                                               with: record,
                                               where: RouteRecord.Properties.routeId == routeId)
        }
        return false
    }
    
    /// 生成GPX文件并上传
    /// - Parameters:
    ///   - record: 路线记录
    ///   - points: 轨迹点数组
    private func generateAndUploadGPX(for record: RouteRecord, with points: [RoutePoint]) {
        // 生成GPX文件
        let outputURL = tempOutputURL()
        let fileName = record.name ?? "未命名路线"
        
        guard generateGPXFile(from: points, outputURL: outputURL, name: fileName), 
              let fileData = try? Data(contentsOf: outputURL) else {
            UIWindow.topWindow?.sw_showWarningToast("生成轨迹文件失败")
            return
        }
        
        UIWindow.topWindow?.sw_showLoading()
        
        // 上传文件
        uploadManager.uploadFile(fileData: fileData, fileName: fileName, mimeType: gpxExtension) { progress in
            debugPrint("上传进度： \(progress)")
        } completion: {[weak self] result in
            // 清理临时文件
            self?.cleanupTempFile(at: outputURL)
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.isSuccess, let fileUrl = response.data?.fileUrl {
                        // 上传成功，保存轨迹到地图服务
                        self?.saveTrackToMapService(record: record, fileUrl: fileUrl)
                    } else {
                        UIWindow.topWindow?.sw_hideLoading()
                        UIWindow.topWindow?.sw_showWarningToast("上传失败: \(response.msg ?? "未知错误")")
                    }
                case .failure(let error):
                    UIWindow.topWindow?.sw_hideLoading()
                    UIWindow.topWindow?.sw_showWarningToast("上传错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 保存轨迹到地图服务
    /// - Parameters:
    ///   - record: 路线记录
    ///   - fileUrl: 上传后的文件URL
    private func saveTrackToMapService(record: RouteRecord, fileUrl: String) {
        // 这里没有引用self，所以不需要[weak self]
        mapService.saveUserTrack(name: record.name ?? "未命名轨迹", fileUrl: fileUrl) {result in
            DispatchQueue.main.async {
                UIWindow.topWindow?.sw_hideLoading()
                
                switch result {
                case .success(let response):
                    if response.statusCode == 200 {
                        UIWindow.topWindow?.sw_showSuccessToast("保存成功")
                        // 更新上传状态
                        if let routeId = record.routeId {
                            var updatedRecord = record
                            updatedRecord.uploadStatus = 1
                            DBManager.shared.updateToDb(table: DBTableName.route.rawValue,
                                                        on: [RouteRecord.Properties.uploadStatus],
                                                        with: updatedRecord,
                                                        where: RouteRecord.Properties.routeId == routeId)
                        }
                    } else {
                        UIWindow.topWindow?.sw_showWarningToast("保存失败：\(response.description)")
                    }
                case .failure(let error):
                    UIWindow.topWindow?.sw_showWarningToast("保存失败：\(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 清理临时文件
    /// - Parameter url: 临时文件URL
    private func cleanupTempFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            debugPrint("已清理临时文件：\(url.lastPathComponent)")
        } catch {
            debugPrint("清理临时文件失败：\(error.localizedDescription)")
        }
    }
    
    
    // MARK: - GPX文件生成功能
    
    /// 将轨迹点数据生成GPX文件
    /// - Parameters:
    ///   - points: 轨迹点数组
    ///   - outputURL: 输出文件路径
    ///   - name: 名称
    /// - Returns: 是否生成成功
    func generateGPXFile(from points: [RoutePoint], outputURL: URL, name: String = "Generated Record") -> Bool {
        let gpxContent = generateGPXContent(from: points, name: name)
        
        do {
            try gpxContent.write(to: outputURL, atomically: true, encoding: .utf8)
            print("GPX文件生成成功：\(outputURL.path)")
            return true
        } catch {
            print("GPX文件生成失败：\(error.localizedDescription)")
            return false
        }
    }
    
    /// 生成GPX文件内容
    /// - Parameters:
    ///   - points: 轨迹点数组
    ///   - name: 名称
    /// - Returns: GPX格式的字符串内容
    private func generateGPXContent(from points: [RoutePoint], name: String) -> String {
        // 确保轨迹点按时间排序
        let sortedPoints = points.sorted { $0.timestamp ?? 0 < $1.timestamp ?? 0 }
        
        // 日期格式化器（用于生成GPX时间格式）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        // 构建GPX文件内容
        var gpxContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        gpxContent += "<gpx version=\"1.1\" creator=\"天行探索\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        gpxContent += "  <trk>\n"
        gpxContent += "    <name>\(name)</name>\n"
        gpxContent += "    <trkseg>\n"
        
        // 添加所有轨迹点
        for point in sortedPoints {
            if let latitude = point.latitude, let longitude = point.longitude {
                let timeString = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(point.timestamp ?? 0)))
                gpxContent += "      <trkpt lat=\"\(latitude)\" lon=\"\(longitude)\">\n"
                gpxContent += "        <ele>\(point.altitude ?? 0.0)</ele>\n"
                gpxContent += "        <time>\(timeString)</time>\n"
                gpxContent += "      </trkpt>\n"
            }
        }
        
        // 闭合标签
        gpxContent += "    </trkseg>\n"
        gpxContent += "  </trk>\n"
        gpxContent += "</gpx>"
        
        return gpxContent
    }
    
    func tempOutputURL() -> URL {
        // 在temp下随意创建个路径，用存放临时文件gpx
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(gpxExtension)
        return tempFileURL
    }
}
