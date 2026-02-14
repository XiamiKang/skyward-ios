//
//  RouteDataManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/15.
//

import Foundation
import CoreLocation
import TXKit
import SWKit
import SWNetwork
import WCDBSwift

// MARK: - 轨迹数据管理器
class RouteDataManager {
    // 常量定义
    private let txtExtension = "txt"
    private let gpxExtension = "gpx"
    // 本次记录的相关属性
    private(set) var sessionRoute: Route?

    private lazy var uploadManager: UploadManager = {
        let mgr = UploadManager()
        return mgr
    }()

    private lazy var mapService: MapService = {
        let mapService = MapService()
        return mapService
    }()

    private lazy var locationManager: LocationManager = {
        let manager = LocationManager()
        return manager
    }()
    
    
    func startRecord(type: RouteType) {
        sessionRoute = Route(id: String(Int64(Date().timeIntervalSince1970)), travelTime: 0, type: type.rawValue)

        // 创建空文件，确保后续写入时文件已存在
        if let fileURL = sessionTxtFileURL() {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
        }
    }
    
    func endRecord() {
        deleteSessionTxtFile()
        sessionRoute = nil
    }
    
    // MARK: - 增删改查
    // 写入记录的点到文件
    @discardableResult
    func writePointToSessionTxtFile(_ point: RecordPoint) -> Bool {
        guard let txtFileURL = sessionTxtFileURL() else {
            return false
        }
        let pointString = point.toString() + "\n"

        do {
            // 如果文件不存在，创建新文件并写入内容
            if !FileManager.default.fileExists(atPath: txtFileURL.path) {
                try pointString.write(to: txtFileURL, atomically: true, encoding: .utf8)
            } else {
                // 文件已存在，追加写入
                let fileHandle = try FileHandle(forWritingTo: txtFileURL)
                defer { fileHandle.closeFile() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(pointString.data(using: .utf8)!)
            }
            return true
        } catch {
            debugPrint("写入文件失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 按行读取文件中的轨迹点
    private func readPointsFromTxtFile(fileURL: URL?) -> [RecordPoint] {
        guard let fileURL = fileURL else {
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
                        debugPrint("解析轨迹点失败：\(line)")
                    }
                }
            }
        } catch {
            debugPrint("读取文件失败：\(error.localizedDescription)")
        }
        
        return points
    }
    
    func readCoordinatesFromGPXFile(from routeId: String) -> [CLLocationCoordinate2D] {
        guard let fileURL = gpxFileURL(routeId) else {
            debugPrint("GPX文件路径为空")
            return []
        }
        
        var coordinates: [CLLocationCoordinate2D] = []
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            coordinates = parseGPXCoordinates(from: content)
            debugPrint("从GPX文件读取了 \(coordinates.count) 个坐标点")
        } catch {
            debugPrint("读取GPX文件失败：\(error.localizedDescription)")
        }
        
        return coordinates
    }
    // 保存当前记录的路线/轨迹记录到本地
    @discardableResult
    func saveSessionRouteToLocal(_ route: Route) -> Bool {
        
        guard let _ = route.type else {
            return false
        }
        
        guard let txtFileURL = sessionTxtFileURL() else {
            return false
        }
        
        guard let gpxFileURL = gpxFileURL(route.id) else {
            return false
        }
        
        guard DBManager.shared.insertToDb(objects: [route], intoTable: DBTableName.route.rawValue) else {
            return false
        }
        
        let points = readPointsFromTxtFile(fileURL: txtFileURL)
        
        if generateGPXFile(from: points, targetURL: gpxFileURL, name: route.routeName) {
            return true
        }
        return false
    }
    
    // 根据新的路线/轨迹更新旧的
    @discardableResult
    func updateLocalRouteWithRemote(local: Route, remote: Route) -> Bool {
        
        guard let oldGPXFileURL = gpxFileURL(local.id) else {
            return false
        }
        
        guard let newGPXFileURL = gpxFileURL(remote.id) else {
            return false
        }
        
        if DBManager.shared.updateToDb(table: DBTableName.route.rawValue,
                                       on: [Route.Properties.id],
                                       with: remote,
                                       where: Route.Properties.id == local.id) {
            //把oldGPXFileURL里的文件移至newGPXFileURL
            do {
                try FileManager.default.moveItem(at: oldGPXFileURL, to: newGPXFileURL)
                return true
            } catch {
                return false
            }
        }
        return false
    }
    
    // 删除路线/轨迹记录从本地
    @discardableResult
    private func deleteRouteFromLocal(_ routeId: String) -> Bool {
        
        guard DBManager.shared.deleteFromDb(fromTable: DBTableName.route.rawValue,
                                            where: Route.Properties.id == routeId) else {
            return false
        }
        
        guard let fileURL = gpxFileURL(routeId) else {
            debugPrint("删除失败：gpxFileURL为空")
            return false
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            debugPrint("删除gpx成功：\(fileURL)")
            return true
        } catch {
            debugPrint("删除gpx失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 删除当前记录的写入文件
    private func deleteSessionTxtFile() {
        guard let txtFileURL = sessionTxtFileURL() else {
            return
        }
        
        try? FileManager.default.removeItem(at: txtFileURL)
    }
    
    // 修改当前记录名
    @discardableResult
    func renameRoute(_ route: Route) -> Bool {
        return DBManager.shared.updateToDb(table: DBTableName.route.rawValue,
                                           on: [Route.Properties.routeName],
                                           with: route,
                                           where: Route.Properties.id == route.id)
    }
    
    // 根据类型获取记录的路线/轨迹
    func getRoutes(type: RouteType) -> [Route] {
        guard let routes = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue,
                                                         cls: Route.self,
                                                         where: Route.Properties.type == type.rawValue,
                                                         orderBy: [Route.Properties.id.order(.descending)]) else {
            return []
        }
        return routes
    }
    
    // MARK: - 更新session route
    
    func updateSessionRoute(name: String, desc: String? = nil) {
        sessionRoute?.routeName = name
        if let desc = desc {
            sessionRoute?.description = desc
        }
    }
    
    func assembleSessionRoute(completion: @escaping () ->Void) {
        guard sessionRoute != nil else {
            return
        }
        // 读取所有记录点
        let points = readPointsFromTxtFile(fileURL: sessionTxtFileURL())

        guard points.count > 1 else {
            return
        }

        // 计算总距离
        var totalDistance: CLLocationDistance = 0
        for i in 0..<points.count-1 {
            autoreleasepool {
                let currentPoint = points[i]
                let nextPoint = points[i+1]
                
                let currentLocation = CLLocation(latitude: currentPoint.latitude, longitude: currentPoint.longitude)
                let nextLocation = CLLocation(latitude: nextPoint.latitude, longitude: nextPoint.longitude)
                
                let distance = currentLocation.distance(from: nextLocation)
                totalDistance += distance
            }
        }
        
        // 将距离转换为公里并存储
        sessionRoute?.distance = totalDistance / 1000.0

        // 获取起点和终点
        let startPoint = points.first!
        let endPoint = points.last!
        
        sessionRoute?.startLongitude = startPoint.longitude
        sessionRoute?.startLatitude = startPoint.latitude
        sessionRoute?.endLongitude = endPoint.longitude
        sessionRoute?.endLatitude = endPoint.latitude
        
        // 日期格式化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timeString = dateFormatter.string(from: endPoint.timestamp)
        
        // 存储地址信息
        var startShortName = ""
        var endShortName = ""
        
        // 使用调度组等待两个异步操作完成
        let group = DispatchGroup()

        // 起点逆地理编码
        group.enter()
        let startLocation = CLLocation(latitude: startPoint.latitude, longitude: startPoint.longitude)
        locationManager.reverseGeocode(location: startLocation) { placemark in
            if let address = placemark {
                if let city = address.locality, !city.isEmpty {
                    startShortName.append(city)
                }
                if let district = address.subLocality, !district.isEmpty {
                    startShortName.append(district)
                }
                
                if let addrName = address.areasOfInterest?.first ?? address.name {
                    self.sessionRoute?.startName = startShortName + addrName
                } else {
                    self.sessionRoute?.startName = startShortName
                }
            }
            group.leave()
        }

        // 终点逆地理编码
        group.enter()
        let endlocation = CLLocation(latitude: endPoint.latitude, longitude: endPoint.longitude)
        locationManager.reverseGeocode(location: endlocation) { placemark in
            if let address = placemark {
                if let city = address.locality, !city.isEmpty {
                    endShortName.append(city)
                }
                if let district = address.subLocality, !district.isEmpty {
                    endShortName.append(district)
                }
                if let addrName = address.areasOfInterest?.first ?? address.name {
                    self.sessionRoute?.endName = endShortName + addrName
                } else {
                    self.sessionRoute?.endName = endShortName
                }
            }
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            // 组装最终名称
            if startShortName.count > 0, endShortName.count > 0 {
                self.sessionRoute?.routeName = "\(startShortName)至\(endShortName) \(timeString)"
            } else {
                self.sessionRoute?.routeName = timeString
            }
            
            completion()
        }
    }
    
    //MARK: - GPX
        
    private func getRouteGPXData(from route: Route) -> Data? {
        guard let targetURL = gpxFileURL(route.id) else {
            return nil
        }
        // 用户轨迹保存失败再次上传
        if let data = try? Data(contentsOf: targetURL) {
            return data
        }
        
        //存入临时路径是为了：1.上传失败时还要处理移除相关逻辑 2. 上传成功还要根据服务端的id更新本地的id作为gpx文件名
        let tempGPXURL = FileManager.default.temporaryDirectory.appendingPathComponent(route.id).appendingPathExtension(gpxExtension)
        let points = readPointsFromTxtFile(fileURL: sessionTxtFileURL())
        if generateGPXFile(from: points, targetURL: tempGPXURL, name: route.routeName) {
            return try? Data(contentsOf: tempGPXURL)
        }
        return nil
    }
    
    /// 将轨迹点数据生成GPX文件
    /// - Parameters:
    ///   - points: 轨迹点数组
    ///   - targetURL: 文件路径
    ///   - name: 名称
    /// - Returns: 是否生成成功
    @discardableResult
    private func generateGPXFile(from points: [RecordPoint], targetURL: URL, name: String? = nil) -> Bool {
        let gpxContent: String 
        if let name = name, !name.isEmpty {
            gpxContent = generateGPXContent(from: points, name: name)
        } else {
            gpxContent = generateGPXContent(from: points, name: "Generated Record")
        }
        
        do {
            try gpxContent.write(to: targetURL, atomically: true, encoding: .utf8)
            debugPrint("GPX文件生成成功：\(targetURL.path)")
            return true
        } catch {
            debugPrint("GPX文件生成失败：\(error.localizedDescription)")
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
    
    /// 解析GPX内容，提取坐标点
    /// - Parameter gpxContent: GPX格式的字符串内容
    /// - Returns: 坐标点数组
    private func parseGPXCoordinates(from gpxContent: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []

        // 使用正则表达式匹配 <trkpt> 标签及其属性
        // 匹配格式：<trkpt lat="纬度" lon="经度">
        let pattern = "<trkpt\\s+lat=\"([+-]?\\d+\\.\\d+)\"\\s+lon=\"([+-]?\\d+\\.\\d+)\""

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(gpxContent.startIndex..., in: gpxContent)
            let matches = regex.matches(in: gpxContent, options: [], range: range)

            for match in matches {
                // 提取纬度
                if let latRange = Range(match.range(at: 1), in: gpxContent),
                   let latString = Double(gpxContent[latRange]),
                   // 提取经度
                   let lonRange = Range(match.range(at: 2), in: gpxContent),
                   let lonString = Double(gpxContent[lonRange]) {
                    let coordinate = CLLocationCoordinate2D(latitude: latString, longitude: lonString)
                    coordinates.append(coordinate)
                }
            }
        } catch {
            debugPrint("正则表达式解析失败：\(error.localizedDescription)")
        }

        return coordinates
    }
    
    // MARK: - 目录路径
    
    private func gpxFileURL(_ routeId: String) -> URL? {

        guard let routeDirectory = getRouteDirectory() else {
            return nil
        }
        
        let fileName = String(routeId)
        guard !fileName.isEmpty else {
            return nil
        }
        
        let fileURL = routeDirectory.appendingPathComponent(fileName).appendingPathExtension(gpxExtension)
        return fileURL
    }
    
    private func sessionTxtFileURL() -> URL? {
        guard let routeId = sessionRoute?.id, !routeId.isEmpty else {
            return nil
        }
        
        guard let routeDirectory = getRouteDirectory() else {
            return nil
        }
        
        let fileURL = routeDirectory.appendingPathComponent(routeId).appendingPathExtension(txtExtension)
        return fileURL
    }
    
    private func getRouteDirectory() -> URL? {
        guard !UserManager.shared.userId.isEmpty else {
            return nil
        }
        
        guard let routeDirectory = SandBox.docmentsURL?.appendingPathComponent(UserManager.shared.userId).appendingPathComponent("route") else {
            return nil
        }
        
        // 创建主目录（如果不存在）
        do {
            try FileManager.default.createDirectory(at: routeDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            debugPrint("创建主目录失败：\(error.localizedDescription)")
            return nil
        }
        return routeDirectory
    }
}

// MARK: - network
extension RouteDataManager {
    
    /// 保存路线到地图服务
    /// - Parameters:
    ///   - route: 路线记录
    ///   - fileUrl: 上传后的文件URL
    func saveRouteToService(_ route: Route, completion: ((Route?, String?) -> Void)?) {
        guard route.type != nil else {
            completion?(nil, nil)
            return
        }
        
        var routeDict = route.toDictionary()
        
        uploadRouteToService(route) { [weak self] fileUrl, errorMsg in
            guard let fileUrl = fileUrl else {
                completion?(nil, errorMsg)
                return
            }
            routeDict["fileUrl"] = fileUrl
            
            self?.mapService.saveUserRoute(params: routeDict) { result in
                switch result {
                case .success(let response):
                    do {
                        let bizResponse = try JSONDecoder().decode(NetworkResponse<Route>.self, from: response.data)
                        if let route = bizResponse.data {
                            completion?(route, nil)
                        } else {
                            completion?(nil, response.description)
                        }
                    } catch {
                        completion?(nil, error.localizedDescription)
                    }
                case .failure(let error):
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }
    
    // 删除路线
    func deleteRouteFromService(routeId: String, completion: ((Bool, String?) -> Void)?) {
        
        mapService.deleteRoute(routeId) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<Bool>.self, from: response.data)
                    if bizResponse.data == true {
                        completion?(true, nil)
                        self?.deleteRouteFromLocal(routeId)
                    } else {
                        completion?(false, response.description)
                    }
                } catch {
                    completion?(false, error.localizedDescription)
                }
            case .failure(let error):
                completion?(false, error.localizedDescription)
            }
        }
    }
    
    private func uploadRouteToService(_ route: Route, completion: ((String?, String?) -> Void)?) {
        guard let fileData = getRouteGPXData(from: route) else {
            completion?(nil, "生成数据失败")
            return
        }
        let routeName = route.routeName ?? "未命名"
        
        uploadManager.uploadFile(fileData: fileData, fileName: routeName, mimeType: gpxExtension) { progress in
            debugPrint("上传进度： \(progress)")
        } completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.isSuccess, let fileUrl = response.data?.fileUrl {
                        completion?(fileUrl, nil)
                    } else {
                        completion?(nil, response.msg)
                    }
                case .failure(let error):
                    completion?(nil, error.localizedDescription)
                }
            }
        }
    }
    
    func requestRouteList(req: RouteListModel, completion: (([Route]?) ->Void)?) {
        self.mapService.getRouteList(req) { result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<[Route]>.self, from: response.data)
                    if let routes = bizResponse.data {
                        completion?(routes)
                    } else {
                        completion?(nil)
                    }
                } catch {
                    completion?(nil)
                }
            case .failure(_):
                completion?(nil)
            }
        }
    }
    
    func downloadRouteGPXFile(_ route: Route, completion: @escaping (String?) ->Void) {
        // fileUrl: http://oss-dev-pulbc.bjtxts.com/20260112/5d7619cf9aea48169ed312d645b78eb6-污水厂
        guard let fileUrlString = route.fileUrl,
              let fileUrl = URL(string: fileUrlString) else {
            debugPrint("下载GPX文件失败：fileUrl无效")
            completion("加载失败")
            return
        }

        guard let targetURL = gpxFileURL(route.id) else {
            debugPrint("下载GPX文件失败：无法获取下载的目标路径")
            completion("加载失败")
            return
        }

        // 检查文件是否已存在
        if FileManager.default.fileExists(atPath: targetURL.path) {
            debugPrint("GPX文件已存在：\(targetURL.path)")
            completion(nil)
            return
        }

        // 创建下载任务
        let task = URLSession.shared.downloadTask(with: fileUrl) { tempURL, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion("加载失败")
                }
                debugPrint("下载GPX文件失败：\(error.localizedDescription)")
                return
            }

            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    completion("加载失败")
                }
                debugPrint("下载GPX文件失败：临时文件为空")
                return
            }

            do {
                // 将临时文件移动到目标位置
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                DispatchQueue.main.async {
                    completion(nil)
                }
                debugPrint("下载GPX文件成功：\(targetURL.path)")
            } catch {
                DispatchQueue.main.async {
                    completion("加载失败")
                }
                debugPrint("保存GPX文件失败：\(error.localizedDescription)")
            }
        }

        task.resume()
    }
}

// MARK: - 迁移老数据
extension RouteDataManager {
    func migrateLocalDataToNewPath() {
        // 老的RouteRecord和TrackRecord的数据都迁移到route表中，然后route和track下的点统一以gpx格式存入到gpxFileURL中
        requestRouteList(req: RouteListModel(type: "", pageNum: "1", pageSize: "100")) { rspRoutes in
            self.migrateRouteLocalData(rspRoutes: rspRoutes)
            self.migrateTrackLocalData(rspTracks: rspRoutes)
        }
    }
    
    // 迁移存量路线数据
    func migrateRouteLocalData(rspRoutes: [Route]?) {
        let routes = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue, cls: RouteRecord.self)
        DBManager.shared.dropTable(table: DBTableName.route.rawValue)
        
        DBManager.shared.createTable(table: DBTableName.route.rawValue, of: Route.self)
        
        if let routes = routes {
            for localRoute in routes {
                guard let newRoute = rspRoutes?.first(where: {$0.routeName == localRoute.name && $0.description == localRoute.desc && $0.type == 0}) else {
                    continue
                }

                //迁移该路线中的记录点
                guard let routeId = localRoute.routeId,
                      let points = DBManager.shared.queryFromDb(fromTable: DBTableName.routePoint.rawValue, cls: RoutePoint.self, where: RoutePoint.Properties.routeId == routeId),
                      points.count > 0 else {
                    continue
                }
                var newPoints: [RecordPoint] = []
                for point in points {
                    let newPoint = RecordPoint(latitude: point.latitude,
                                               longitude: point.longitude,
                                               altitude: point.altitude,
                                               timestamp: Date(timeIntervalSince1970: Double(point.timestamp)))
                    newPoints.append(newPoint)
                }
                if let targetURL = gpxFileURL(newRoute.id), generateGPXFile(from: newPoints, targetURL: targetURL, name: newRoute.routeName) {
                    DBManager.shared.insertToDb(objects: [newRoute], intoTable: DBTableName.route.rawValue)
                }
                // 删除该路线中的记录点 统一在下面的dropTable处理routePoint
            }
        }
        
        DBManager.shared.dropTable(table: DBTableName.routePoint.rawValue)
    }
    
    // 迁移存量轨迹数据
    func migrateTrackLocalData(rspTracks: [Route]?) {
        let tracks = DBManager.shared.queryFromDb(fromTable: DBTableName.track.rawValue, cls: TrackRecord.self)
        DBManager.shared.dropTable(table: DBTableName.track.rawValue)
        
        DBManager.shared.createTable(table: DBTableName.route.rawValue, of: Route.self)
        
        if let tracks = tracks {
            for localTrack in tracks {
                //newTrack如果服务端有，用服务端的，仅本地有则新构造
                let newTrack = rspTracks?.first(where: {$0.routeName == localTrack.name && $0.type == 1}) ?? Route(id: String(localTrack.id), routeName: localTrack.name, type: 1)

                //迁移该轨迹中的记录点
                guard let newFileURL = gpxFileURL(newTrack.id) else {
                    continue
                }

                let oldFileURL = localTrack.fileFullURL()
                let points = readPointsFromTxtFile(fileURL: oldFileURL)
                if generateGPXFile(from: points, targetURL: newFileURL, name: newTrack.routeName) {
                    DBManager.shared.insertToDb(objects: [newTrack], intoTable: DBTableName.route.rawValue)
                }
                // 删除该轨迹中的记录点 统一在下面的removeItem处理
            }
        }
        
        //之前所有轨迹记录的点都存在该目录下
        guard let trackDirectory = SandBox.docmentsURL?.appendingPathComponent(UserManager.shared.userId).appendingPathComponent("track") else {
            return
        }
        
        guard FileManager.default.fileExists(atPath: trackDirectory.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(at: trackDirectory)
        } catch {
            debugPrint("删除track目录失败：\(error.localizedDescription)")
        }
    }
}

