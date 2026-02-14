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
        Logger.debug("结束记录")
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
            coordinates = RouteDataManager.parseGPXCoordinates(from: content)
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
    
    // 保存云端记录的路线/轨迹记录到本地
    @discardableResult
    func saveServiceRouteToLocal(_ route: Route) -> Bool {
        
        guard let _ = route.type else {
            Logger.debug("路线/轨迹没有类型")
            return false
        }
        
        guard let _ = gpxFileURL(route.id) else {
            Logger.debug("路线/轨迹本地没有对应的gpx文件： routeName:\(route.routeName ?? "未命名")")
            return false
        }
        
        guard DBManager.shared.insertToDb(objects: [route], intoTable: DBTableName.route.rawValue) else {
            Logger.debug("路线/轨迹存入本地数据库失败： routeName:\(route.routeName ?? "未命名")")
            return false
        }
        Logger.debug("路线/轨迹存入本地数据库成功： routeName:\(route.routeName ?? "未命名")")
        return true
    }
    
    // 根据服务端轨迹更新本地的
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
    
    // 更新路线/轨迹
    @discardableResult
    func updateLocalRoute(route: Route) -> Bool {
        if DBManager.shared.insertToDb(objects: [route], intoTable:  DBTableName.route.rawValue) {
            return true
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
        
        Logger.debug("将要删除sessionTxt文件：\(txtFileURL)")
        
        do {
            try FileManager.default.removeItem(at: txtFileURL)
            Logger.debug("删除sessionTxt成功：\(txtFileURL)")
        } catch {
            Logger.debug("删除sessionTxt失败：\(error.localizedDescription)")
        }
    }
    
    // 根据类型获取记录的路线/轨迹
    func getRoutes(type: RouteType, onlyUnUploaded: Bool = false) -> [Route] {
        if onlyUnUploaded {
            guard let routes = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue,
                                                             cls: Route.self,
                                                             where: Route.Properties.type == type.rawValue && Route.Properties.uploaded == false,
                                                             orderBy: [Route.Properties.id.order(.descending)]) else {
                return []
            }
            return routes
        }
        guard let routes = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue,
                                                         cls: Route.self,
                                                         where: Route.Properties.type == type.rawValue,
                                                         orderBy: [Route.Properties.id.order(.descending)]) else {
            return []
        }
        return routes
    }
    
    func routeExsitInLocal(routeId: String) -> Bool {
        guard let _ = DBManager.shared.queryFromDb(fromTable: DBTableName.route.rawValue,
                                                   cls: Route.self,
                                                   where: Route.Properties.id == routeId)?.first else {
            return false
        }
        let points = readCoordinatesFromGPXFile(from: routeId)
        if points.count == 0 {
            return false
        }
        return true
    }
    
    // MARK: - 更新session route
    
    /// 更新总距离（千米）和起始、终止的坐标
    func updateSessionRoute(point: RecordPoint) {
        // 处理第一个点
        guard let startLongitude = sessionRoute?.startLongitude, let startLatitude = sessionRoute?.startLatitude else {
            sessionRoute?.startLongitude = point.longitude
            sessionRoute?.startLatitude = point.latitude
            return
        }
        
        let nextLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
        
        // 处理第二个点
        guard let endLongitude = sessionRoute?.endLongitude, let endLatitude = sessionRoute?.endLatitude else {
            let lastLocation = CLLocation(latitude: startLatitude, longitude: startLongitude)
            let distance = lastLocation.distance(from: nextLocation) / 1000
            sessionRoute?.distance = distance
            sessionRoute?.maxAltitude = point.altitude
            sessionRoute?.endLongitude = point.longitude
            sessionRoute?.endLatitude = point.latitude
            return
        }
        // 处理第三个及以后的点
        let currentRoute = sessionRoute
        let lastLocation = CLLocation(latitude: endLatitude, longitude: endLongitude)
        let distance = lastLocation.distance(from: nextLocation)
        sessionRoute?.distance = (currentRoute?.distance ?? 0) + distance / 1000
        sessionRoute?.maxAltitude = max(currentRoute?.maxAltitude ?? 0, point.altitude)
        sessionRoute?.endLongitude = point.longitude
        sessionRoute?.endLatitude = point.latitude
    }
    
    // 规划路线时撤销上一个点
    @discardableResult
    func sessionRouteRemoveLastPoint() -> Bool {
        // 读取当前记录数据的文件
        guard let txtFileURL = sessionTxtFileURL() else {
            Logger.debug("读取sessionTxtFile失败")
            return false
        }

        let points = readPointsFromTxtFile(fileURL: txtFileURL)

        // 至少需要2个点才能撤销（撤销后还剩至少1个点）
        guard points.count > 1 else {
            return sessionRouteRemoveAllPoint()
        }

        let willRemovePoint = points.last!
        let willLastPoint = points[points.count - 2]

        // 重新计算距离和更新sessionRoute
        if let currentRoute = sessionRoute {
            let removedLocation = CLLocation(latitude: willRemovePoint.latitude, longitude: willRemovePoint.longitude)
            let willLastLocation = CLLocation(latitude: willLastPoint.latitude, longitude: willLastPoint.longitude)
            let distance = removedLocation.distance(from: willLastLocation)

            sessionRoute?.distance = max(0, (currentRoute.distance ?? 0) - distance / 1000)
            sessionRoute?.maxAltitude = max((currentRoute.maxAltitude ?? 0), willLastPoint.altitude)
            sessionRoute?.endLongitude = willLastPoint.longitude
            sessionRoute?.endLatitude = willLastPoint.latitude
        }

        // 移除最后一个点后重新写入文件
        let newPoints = points.dropLast()
        do {
            var content = ""
            for point in newPoints {
                content += point.toString() + "\n"
            }
            try content.write(to: txtFileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            Logger.debug("更新文件失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // 规划路线时删除所有规划的点
    @discardableResult
    func sessionRouteRemoveAllPoint() -> Bool {
        // 读取当前记录数据的文件
        guard let txtFileURL = sessionTxtFileURL() else {
            Logger.debug("读取sessionTxtFile失败")
            return false
        }
        do {
            try "".write(to: txtFileURL, atomically: true, encoding: .utf8)
            if let routeId = sessionRoute?.id {
                let currentRoute = Route(id: routeId, type: sessionRoute?.type)
                sessionRoute = currentRoute
            }
            return true
        } catch {
            Logger.debug("更新文件失败：\(error.localizedDescription)")
            return false
        }
    }

    /// 更新记录时长
    func updateSessionRoute(timeInterval: Int = 1) {
        guard var currentRoute = sessionRoute else {
            return
        }
        currentRoute.travelTime = (currentRoute.travelTime ?? 0) + timeInterval
        sessionRoute = currentRoute
    }
    
    /// 更新路线名称和描述
    func updateSessionRoute(name: String, desc: String? = nil) {
        sessionRoute?.routeName = name
        if let desc = desc {
            sessionRoute?.description = desc
        }
    }
    
    func assembleSessionRoute(completion: @escaping () ->Void) {
        guard let sessionRoute = sessionRoute else {
            return
        }
        
        // 日期格式化
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let timeString = dateFormatter.string(from: Date())
        
        // 存储地址信息
        var startShortName = ""
        var endShortName = ""
        
        // 使用调度组等待两个异步操作完成
        let group = DispatchGroup()

        // 起点逆地理编码
        if let startLongitude = sessionRoute.startLongitude, let startLatitude = sessionRoute.startLatitude {
            group.enter()
            let startLocation = CLLocation(latitude: startLatitude, longitude: startLongitude)
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
        }

        // 终点逆地理编码
        if let endLongitude = sessionRoute.endLongitude, let endLatitude = sessionRoute.endLatitude {
            group.enter()
            let endlocation = CLLocation(latitude: endLatitude, longitude: endLongitude)
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
    static func parseGPXCoordinates(from gpxContent: String) -> [CLLocationCoordinate2D] {
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
    ///   - coverImage： 封面图
    ///   - fileUrl: 上传后的文件URL
    func saveRouteToService(_ route: Route, coverImage: UIImage? = nil,  completion: ((Bool) -> Void)?) {
        guard let _ = route.type else {
            completion?(false)
            UIWindow.topWindow?.sw_showWarningToast("未知错误")
            Logger.debug("路线/轨迹没有类型")
            return
        }
        //如果有封面图coverImage 则和uploadRouteToService并行上传，两个都上传成功再走mapService.saveUserRoute
        //如果没有封面图coverImage 则先走uploadRouteToService 然后走mapService.saveUserRoute
        
        var coverImageUrl: String?
        var gpxFileUrl: String?
    
        let group = DispatchGroup()

        if let coverImage = coverImage {
            group.enter()
            uploadRouteCoverToService(coverImage) { fileUrl in
                coverImageUrl = fileUrl
                group.leave()
            }
        }
        
        group.enter()
        uploadRouteGPXToService(route) { fileUrl in
            gpxFileUrl = fileUrl
            group.leave()
        }

        group.notify(queue: .main) {
            guard let fileUrl = gpxFileUrl else {
                completion?(false)
                return
            }
            
            var params = route.toDictionary()
            params["fileUrl"] = fileUrl
            if let coverImageUrl = coverImageUrl {
                params["coverImageUrl"] = coverImageUrl
            }
            
            self.mapService.saveUserRoute(params: params) { [weak self] result in
                switch result {
                case .success(let response):
                    do {
                        let bizResponse = try JSONDecoder().decode(NetworkResponse<Route>.self, from: response.data)
                        if var rspRoute = bizResponse.data {
                            rspRoute.uploaded = true

                            if let _ = self?.sessionRoute {
                                // 正常记录轨迹或规划路线，然后保存
                                self?.saveSessionRouteToLocal(rspRoute)
                            } else {
                                // 记录轨迹中，app被主动或被动杀掉后重新保存
                                self?.updateLocalRouteWithRemote(local: route, remote: rspRoute)
                            }
                            completion?(true)
                            UIWindow.topWindow?.sw_showSuccessToast("保存成功")
                        } else {
                            completion?(false)
                            UIWindow.topWindow?.sw_showWarningToast(response.description)
                        }
                    } catch {
                        completion?(false)
                        UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                    }
                case .failure(let error):
                    completion?(false)
                    UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
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
    
    func deleteRoutesFromServer(routeIds: [String], completion: ((Bool) -> Void)?) {
        mapService.deleteRoutes(routeIds) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<Bool>.self, from: response.data)
                    if bizResponse.data == true {
                        completion?(true)
                        routeIds.forEach { routeId in
                            self?.deleteRouteFromLocal(routeId)
                        }
                    } else {
                        completion?(false)
                        UIWindow.topWindow?.sw_showWarningToast(response.description)
                    }
                } catch {
                    completion?(false)
                    UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                }
            case .failure(let error):
                completion?(false)
                UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
            }
        }
    }
    
    func updateRouteToService(_ route: Route, completion: ((Bool, String?) -> Void)?) {
        var params = [String : Any]()
        params["id"] = route.id
        params["routeName"] = route.routeName
        self.mapService.updateRoute(params: params) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<Bool>.self, from: response.data)
                    if bizResponse.data == true {
                        completion?(true, nil)
                        self?.updateLocalRoute(route: route)
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
    
    private func uploadRouteGPXToService(_ route: Route, completion: ((String?) -> Void)?) {
        guard let fileData = getRouteGPXData(from: route) else {
            completion?(nil)
            return
        }
        let routeName = route.routeName ?? "未命名"
        
        uploadManager.uploadFile(fileData: fileData, fileName: routeName, mimeType: gpxExtension) { progress in
            debugPrint("GPX上传进度： \(progress)")
        } completion: { result in
            switch result {
            case .success(let response):
                if response.isSuccess, let fileUrl = response.data?.fileUrl {
                    completion?(fileUrl)
                    Logger.debug("上传GPX成功 fileUrl: \(fileUrl)")
                } else {
                    completion?(nil)
                    UIWindow.topWindow?.sw_showWarningToast(response.msg)
                }
            case .failure(let error):
                completion?(nil)
                UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
            }
        }
    }
    
    func uploadRouteCoverToService(_ coverImage: UIImage, completion: ((String?) -> Void)?) {
        uploadManager.uploadImage(coverImage) { progress in
            Logger.debug("封面图上传进度： \(progress)")
        } completion: { result in
            switch result {
            case .success(let response):
                if response.isSuccess, let fileUrl = response.data?.fileUrl {
                    completion?(fileUrl)
                    Logger.debug("上传封面图成功 fileUrl: \(fileUrl)")
                } else {
                    completion?(nil)
                    UIWindow.topWindow?.sw_showWarningToast(response.msg)
                }
            case .failure(let error):
                completion?(nil)
                UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
            }
        }
    }
    
    func requestRouteList(req: RouteListReq, completion: ((RouteListRsp?) ->Void)?) {
        self.mapService.getRouteList(req) { result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<RouteListRsp>.self, from: response.data)
                    if var rsp = bizResponse.data, let routes = rsp.list {
                        var newRoutes: [Route] = []
                        for route in routes {
                            var newRoute = route
                            newRoute.uploaded = true
                            newRoutes.append(newRoute)
                        }
                        rsp.list = newRoutes
                        completion?(rsp)
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
        guard let fileUrlString = route.fileUrl,
              let fileUrl = URL(string: fileUrlString) else {
            Logger.debug("下载GPX文件失败：fileUrl无效")
            completion("加载失败")
            return
        }

        guard let targetURL = gpxFileURL(route.id) else {
            Logger.debug("下载GPX文件失败：无法获取下载的目标路径")
            completion("加载失败")
            return
        }

        // 检查文件是否已存在
        if FileManager.default.fileExists(atPath: targetURL.path) {
            Logger.debug("GPX文件已存在：\(targetURL.path)")
            completion(nil)
            return
        }

        // 创建下载任务
        let task = URLSession.shared.downloadTask(with: fileUrl) { tempURL, response, error in
            if let error = error {
                completion("加载失败")
                Logger.debug("下载GPX文件失败：\(error.localizedDescription)")
                return
            }

            guard let tempURL = tempURL else {
                completion("加载失败")
                Logger.debug("下载GPX文件失败：临时文件为空")
                return
            }

            do {
                // 将临时文件移动到目标位置
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: targetURL)
                completion(nil)
                Logger.debug("下载GPX文件成功：\(targetURL.path)")
            } catch {
                completion("加载失败")
                Logger.debug("保存GPX文件失败：\(error.localizedDescription)")
            }
        }

        task.resume()
    }
    
    func checkSensitiveWords(_ name: String?, completion:((Bool, String?) ->Void)?) {
        guard let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            completion?(false, nil)
            return
        }
        self.mapService.checkSensitiveWords(name) { result in
            switch result {
            case .success(let response):
                do {
                    let bizResponse = try JSONDecoder().decode(NetworkResponse<Bool>.self, from: response.data)
                    if bizResponse.data == true {
                        completion?(true, nil)
                    } else {
                        completion?(false, bizResponse.msg)
                    }
                } catch {
                    completion?(false, error.localizedDescription)
                }
            case .failure(let error):
                completion?(false, error.localizedDescription)
            }
        }
    }
}

// MARK: - 迁移老数据
extension RouteDataManager {
    func migrateLocalDataToNewPath() {
        // 老的RouteRecord和TrackRecord的数据都迁移到route表中，然后route和track下的点统一以gpx格式存入到gpxFileURL中
//        requestRouteList(req: RouteListReq(type: 0)) { rspRoutes in
//            self.migrateRouteLocalData(rspRoutes: rspRoutes)
//        }
//        
//        requestRouteList(req: RouteListReq(type: 1)) { rspRoutes in
//            self.migrateTrackLocalData(rspTracks: rspRoutes)
//        }
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

