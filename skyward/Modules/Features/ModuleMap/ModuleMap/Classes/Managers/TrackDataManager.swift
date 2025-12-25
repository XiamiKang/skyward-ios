//
//  TrackDataManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/15.
//

import Foundation
import CoreLocation
import TXKit
import SWKit
import WCDBSwift

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
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = TrackRecord
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case id
        case name
        case localFileUrl
        case uploadStatus
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .id: ColumnConstraintConfig(id, isPrimary: true, defaultTo: "id")
            ]
        }
    }
    
    func fileFullURL() -> URL? {
        guard let fileUrl = localFileUrl, let fileURL = SandBox.docmentsURL?.appendingPathComponent(fileUrl) else {
            return nil
        }
        return fileURL
    }
}

// MARK: - 轨迹点数据结构
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

// MARK: - 轨迹数据管理器
class TrackDataManager {
    // 常量定义
    private let fileExtension = "txt"
    private let gpxExtension = "gpx"
    
    init() {
        DBManager.shared.createTable(table: DBTableName.track.rawValue, of: TrackRecord.self)
    }
    
    // 获取主目录路径
    private func getDirectoryPath() -> URL? {
        guard !UserManager.shared.userId.isEmpty else {
            return nil
        }
        
        guard let trackDirectory = SandBox.docmentsURL?.appendingPathComponent(UserManager.shared.userId).appendingPathComponent("track") else {
            return nil
        }
        
        // 创建主目录（如果不存在）
        do {
            try FileManager.default.createDirectory(at: trackDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("创建主目录失败：\(error.localizedDescription)")
            return nil
        }
        
        return trackDirectory
    }
    
    // 创建并获取本次记录的目录路径
    private func createSessionDirectory(dirName: String) -> URL? {
        guard let trackDirectory = getDirectoryPath() else { return nil }
        
        let fileManager = FileManager.default
        let sessionDirectory = trackDirectory.appendingPathComponent(dirName)
        
        do {
            try fileManager.createDirectory(at: sessionDirectory, withIntermediateDirectories: true, attributes: nil)
            print("创建会话目录成功：\(sessionDirectory.path)")
            return sessionDirectory
        } catch {
            print("创建会话目录失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    // 创建新的带时间戳的.txt文件
    @discardableResult
    func createNewFile(in directory: URL) -> URL? {
        let fileName = "record.\(fileExtension)"
        let fileURL = directory.appendingPathComponent(fileName)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: fileURL.path) {
            do {
                // 创建空文件
                try "".write(to: fileURL, atomically: true, encoding: .utf8)
                print("创建新文件成功：\(fileURL.path)")
                return fileURL
            } catch {
                print("创建新文件失败：\(error.localizedDescription)")
                return nil
            }
        } else {
            print("文件已存在：\(fileURL.path)")
            return fileURL
        }
    }
    
    @discardableResult
    func createNewRecord() -> TrackRecord? {
        var record = TrackRecord()
        
        guard let sessionDirectory = createSessionDirectory(dirName: record.name) else {
            return nil
        }
        
        guard let fileURL = createNewFile(in: sessionDirectory) else {
            return nil
        }
        
        guard let documentsURL = SandBox.docmentsURL else {
            return nil
        }
        // 一定要保存相对路径， 因为Documents目录路径会变（iOS每次重新运行应用时都会分配新的容器目录UUID）
        let relativePath = fileURL.pathComponents.dropFirst(documentsURL.pathComponents.count).joined(separator: "/")
        record.localFileUrl = relativePath
        
        DBManager.shared.insertToDb(objects: [record], intoTable: DBTableName.track.rawValue)
        return record
    }
    
    // 写入记录的点到文件
    @discardableResult
    func writeRecordPoint(_ point: RecordPoint, to fileURL: URL) -> Bool {
        let pointString = point.toString() + "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(pointString.data(using: .utf8)!)
            fileHandle.closeFile()
            return true
        } catch {
            print("写入文件失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 批量写入记录点到文件
    @discardableResult
    func writeRecordPoints(_ points: [RecordPoint], to fileURL: URL) -> Bool {
        let pointsString = points.map { $0.toString() }.joined(separator: "\n") + "\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(pointsString.data(using: .utf8)!)
            fileHandle.closeFile()
            return true
        } catch {
            print("批量写入文件失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 按行读取文件中的轨迹点
    func readRecordPoints(from record: TrackRecord) -> [RecordPoint] {
        guard let fileURL = record.fileFullURL() else {
            return []
        }
        var points: [RecordPoint] = []
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                if !line.isEmpty {
                    if let point = RecordPoint(from: line) {
                        points.append(point)
                    } else {
                        print("解析轨迹点失败：\(line)")
                    }
                }
            }
        } catch {
            print("读取文件失败：\(error.localizedDescription)")
        }
        
        return points
    }
    
    func readRecordCoordinates(from record: TrackRecord) -> [CLLocationCoordinate2D] {
        guard let fileURL = record.fileFullURL() else {
            return []
        }
        var coordinates: [CLLocationCoordinate2D] = []
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                if !line.isEmpty {
                    let components = line.components(separatedBy: ",")
                    guard components.count == 4 else { return [] }
                    
                    guard let lat = Double(components[0]),
                          let lon = Double(components[1]) else { return [] }
                    coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }
            }
        } catch {
            print("读取文件失败：\(error.localizedDescription)")
        }
        
        return coordinates
    }
    
    // 获取会话目录下的所有轨迹文件
    func getTrackFiles(in sessionDirectory: URL) -> [URL] {
        let fileManager = FileManager.default
        var trackFiles: [URL] = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: sessionDirectory, includingPropertiesForKeys: nil)
            trackFiles = files.filter { $0.pathExtension == fileExtension }
        } catch {
            print("获取文件列表失败：\(error.localizedDescription)")
        }
        
        return trackFiles
    }
    
    // 删除记录
    @discardableResult
    func deleteRecord(_ record: TrackRecord) -> Bool {
        guard let fileURL = record.fileFullURL() else {
            print("删除失败：localFileUrl为空")
            return false
        }
        
        let sessionDirectory = fileURL.deletingLastPathComponent()
        
        let fileManager = FileManager.default
        
        // 检查目录是否存在
        if !fileManager.fileExists(atPath: sessionDirectory.path) {
            print("删除失败：目录不存在 - \(sessionDirectory.path)")
            return false
        }
        
        // 检查是否为目录
        if !fileManager.isDirectory(at: sessionDirectory) {
            print("删除失败：不是目录 - \(sessionDirectory.path)")
            return false
        }
        
        do {
            // 先删除目录
            try fileManager.removeItem(at: sessionDirectory)
            print("删除会话目录成功：\(sessionDirectory.path)")
            
            // 再从数据库中删除记录
            let result = DBManager.shared.deleteFromDb(fromTable: DBTableName.track.rawValue,
                                                       where: TrackRecord.Properties.id == record.id)
            if result {
                print("从数据库删除记录成功：ID = \(record.id)")
                return true
            } else {
                print("从数据库删除记录失败：ID = \(record.id)")
                return false
            }
        } catch {
            print("删除会话目录失败：\(error.localizedDescription)")
            print("错误类型：\(type(of: error))")
            print("失败的目录路径：\(sessionDirectory.path)")
            return false
        }
    }
    
    // 修改当前记录名
    @discardableResult
    func renameRecord(_ record: TrackRecord) -> Bool {
        return DBManager.shared.updateToDb(table: DBTableName.track.rawValue,
                                           on: [TrackRecord.Properties.name],
                                           with: record,
                                           where: TrackRecord.Properties.id == record.id)
    }
    
    // 修改当前记录上传状态
    @discardableResult
    func updateUploadStatusRecord(_ record: TrackRecord) -> Bool {
        return DBManager.shared.updateToDb(table: DBTableName.track.rawValue,
                                           on: [TrackRecord.Properties.uploadStatus],
                                           with: record,
                                           where: TrackRecord.Properties.id == record.id)
    }
    
    //MARK: - 轨迹历史记录相关
    
    func getTrackRecords() -> [TrackRecord] {
        return DBManager.shared.queryFromDb(fromTable: DBTableName.track.rawValue, cls: TrackRecord.self) ?? []
    }
    
    func getTrackRecordGPXData(from record: TrackRecord) -> Data? {
        // 读取轨迹点
        let readPoints = readRecordPoints(from: record)
        let outputURL = tempOutputURL()
        if generateGPXFile(from: readPoints, outputURL: outputURL) {
            return try? Data(contentsOf: outputURL)
        }
        return nil
    }
    
    // MARK: - GPX文件生成功能
    
    /// 将轨迹点数据生成GPX文件
    /// - Parameters:
    ///   - points: 轨迹点数组
    ///   - outputURL: 输出文件路径
    ///   - name: 名称
    /// - Returns: 是否生成成功
    func generateGPXFile(from points: [RecordPoint], outputURL: URL, name: String = "Generated Record") -> Bool {
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
    private func generateGPXContent(from points: [RecordPoint], name: String) -> String {
        // 确保轨迹点按时间排序
        let sortedPoints = points.sorted { $0.timestamp < $1.timestamp }
        
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
            let timeString = dateFormatter.string(from: point.timestamp)
            gpxContent += "      <trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">\n"
            gpxContent += "        <ele>\(point.altitude)</ele>\n"
            gpxContent += "        <time>\(timeString)</time>\n"
            gpxContent += "      </trkpt>\n"
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
        let timestamp = UInt64(Date().timeIntervalSince1970)
        let tempFileURL = tempDirectory.appendingPathComponent("\(timestamp)").appendingPathExtension(gpxExtension)
        return tempFileURL
    }
}

// MARK: - 扩展FileManager以检查是否为目录
extension FileManager {
    func isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}
