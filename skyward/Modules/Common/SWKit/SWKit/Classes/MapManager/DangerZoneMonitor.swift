//
//  DangerZoneMonitor.swift
//  Pods
//
//  Created by TXTS on 2026/3/18.
//

import Foundation
import CoreLocation
import UIKit
import UserNotifications

// MARK: - 危险点数据模型
public struct DangerPoint: Codable, Identifiable {
    public let id = UUID()
    let lng: Double      // 经度
    let lat: Double      // 纬度
    
    // 计算属性，保持与原有接口兼容
    public var index: Int { 0 }  // 如果没有序号，默认返回0
    public var latitude: Double { lat }
    public var longitude: Double { lng }
    public var name: String { "危险点-\(lng),\(lat)" }
    public var radius: Double { 1.0 } // 默认危险半径1公里
    public var description: String? { nil }
    public var 来源: String { "未知" } // 如果没有来源信息，默认返回"未知"
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    public func toLocation() -> CLLocation {
        return CLLocation(latitude: lat, longitude: lng)
    }
    
    enum CodingKeys: String, CodingKey {
        case lng, lat
    }
}

// MARK: - 危险点警告模型
public struct DangerZoneAlert {
    public let point: DangerPoint
    public let distance: Double  // 公里
    public let bearing: Double   // 方位角
    public let direction: String // 中文方向
    public let isInDangerZone: Bool
    
    public var formattedDistance: String {
        if distance < 1 {
            return String(format: "%.0f米", distance * 1000)
        } else if distance < 10 {
            return String(format: "%.2f公里", distance)
        } else {
            return String(format: "%.1f公里", distance)
        }
    }
}

// MARK: - 通知名称
public extension Notification.Name {
    static let dangerZoneAlert = Notification.Name("DangerZoneAlert")
    static let dangerZoneWarning = Notification.Name("DangerZoneWarning")
    static let dangerZoneSafe = Notification.Name("dangerZoneSafe")
}

// MARK: - 错误类型
public enum DangerZoneError: Error {
    case fileNotFound
    case invalidKey
    case decryptionFailed
    case invalidData
    case pointsNotLoaded
    case invalidBase64
    case invalidJSON
    
    public var localizedDescription: String {
        switch self {
        case .fileNotFound: return "文件不存在"
        case .invalidKey: return "无效的密钥"
        case .decryptionFailed: return "解密失败"
        case .invalidData: return "无效的数据格式"
        case .pointsNotLoaded: return "数据未加载"
        case .invalidBase64: return "无效的Base64编码"
        case .invalidJSON: return "无效的JSON格式"
        }
    }
}

// MARK: - 危险区域监控器
public class DangerZoneMonitor: NSObject {
    
    // MARK: - 单例
    public static let shared = DangerZoneMonitor()
    
    // MARK: - 属性
    private var dangerPoints: [DangerPoint] = []
    private var alertedPointIds: Set<String> = []
    public var warningThreshold: Double = 20.0  // 警告阈值（公里）
    private var checkTimer: Timer?
    private var isMonitoring = false
    
    // MARK: - 初始化
    private override init() {
        super.init()
        requestNotificationPermission()
    }
    
    // MARK: - 公开方法
    
    /// 加载加密的危险点数据
    public func loadDangerPoints(from fileName: String = "encrypted_points.txt",
                                 password: String,
                                 completion: ((Result<[DangerPoint], Error>) -> Void)? = nil) {
        do {
            let points = try DangerPointHelper.shared.loadDangerPoints(
                from: fileName,
                password: password
            )
            self.dangerPoints = points
            print("✅ 危险点监控: 成功加载 \(points.count) 个危险点")
            completion?(.success(points))
        } catch {
            print("❌ 危险点监控: 加载失败 \(error)")
            completion?(.failure(error))
        }
    }
    
    /// 开始监控
    public func startMonitoring(threshold: Double = 20.0) {
        guard !dangerPoints.isEmpty else {
            print("⚠️ 危险点监控: 数据未加载，无法开始监控")
            return
        }
        
        self.warningThreshold = threshold
        self.isMonitoring = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.checkTimer?.invalidate()
            self.checkTimer = Timer.scheduledTimer(
                withTimeInterval: 180,
                repeats: true
            ) { [weak self] _ in
                self?.performTimedCheck()
            }
        }
        
        print("🕵️ 危险点监控: 已启动，每3分钟检查一次，阈值: \(threshold)公里")
    }
    
    /// 停止监控
    public func stopMonitoring() {
        isMonitoring = false
        checkTimer?.invalidate()
        checkTimer = nil
        alertedPointIds.removeAll()
        print("🛑 危险点监控: 已停止")
    }
    
    /// 获取所有危险点
    public func getAllPoints() -> [DangerPoint] {
        return dangerPoints
    }
    
    /// 按区域获取危险点（根据经纬度范围判断）
    public func getPointsInRegion(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double) -> [DangerPoint] {
        return dangerPoints.filter { point in
            point.lat >= minLat && point.lat <= maxLat &&
            point.lng >= minLng && point.lng <= maxLng
        }
    }
    
    /// 获取统计信息
    public func getStatistics() -> String {
        return """
        总危险点: \(dangerPoints.count)
        经度范围: \(dangerPoints.map { $0.lng }.min() ?? 0) - \(dangerPoints.map { $0.lng }.max() ?? 0)
        纬度范围: \(dangerPoints.map { $0.lat }.min() ?? 0) - \(dangerPoints.map { $0.lat }.max() ?? 0)
        """
    }
    
    // MARK: - 私有方法
    @objc private func performTimedCheck() {
        guard isMonitoring, let location = LocationManager.lastLocation() else {
            print("🕵️ 危险点----没有找到定位")
            return
        }
        checkLocationAndNotify(location)
    }
    
    private func checkLocationAndNotify(_ location: CLLocation) {
        var activePointIds: [String] = []
        var hasDanger = false
        var hasWarning = false
        
        for point in dangerPoints {
            let pointId = "\(point.lng),\(point.lat)"
            activePointIds.append(pointId)
            
            let distance = DangerPointHelper.shared.calculateDistance(from: location, to: point)
            let bearing = DangerPointHelper.shared.calculateBearing(from: location.coordinate, to: point.coordinate)
            let direction = DangerPointHelper.shared.getChineseDirection(from: bearing)
            let isInDanger = distance <= point.radius
            
            if isInDanger {
                hasDanger = true
                sendNotification(
                    type: .danger,
                    point: point,
                    distance: distance,
                    direction: direction
                )
            } else if distance <= warningThreshold {
                hasWarning = true
                if !alertedPointIds.contains(pointId) {
                    sendNotification(
                        type: .warning,
                        point: point,
                        distance: distance,
                        direction: direction
                    )
                    alertedPointIds.insert(pointId)
                }
            }else {
                sendNotification(
                    type: .safe,
                    point: point,
                    distance: 0,
                    direction: ""
                )
            }
        }
        
        alertedPointIds = alertedPointIds.filter { activePointIds.contains($0) }
        
        let status = hasDanger ? "⚠️ 存在危险区域" : (hasWarning ? "⚠️ 存在接近区域" : "✅ 安全")
        print("📍 危险点监控 [\(Date())] - \(status)")
    }
    
    private func sendNotification(type: AlertType, point: DangerPoint, distance: Double, direction: String) {
        let title = type == .danger ? "⚠️ 处于信号薄弱区" : "⚠️ 接近信号薄弱区"
        let remaining = distance - point.radius
        
        let message: String
        if type == .danger {
            message = """
                您已进入信号薄弱区
                """
            sendLocalNotification(title: title, body: message)
        } else if type == .warning {
            message = """
                您正在接近信号薄弱区
                位置：\(String(format: "%.6f", point.lat)), \(String(format: "%.6f", point.lng))
                距离：\(formatDistance(distance))
                方位：\(direction)
                剩余：\(formatDistance(remaining))进入
                """
            sendLocalNotification(title: title, body: message)
        }else {
            message = """
                您位于安全区域
                """
        }
        
        
        if type == .danger || type == .warning{
            NotificationCenter.default.post(
                name: type == .danger ? .dangerZoneAlert : .dangerZoneWarning,
                object: nil,
                userInfo: [
                    "title": title,
                    "message": message,
                    "pointId": "\(point.lng),\(point.lat)",
                    "latitude": point.lat,
                    "longitude": point.lng,
                    "distance": distance,
                    "direction": direction,
                    "isDanger": type == .danger
                ]
            )
        }
        if type == .safe {
            NotificationCenter.default.post(
                name: .dangerZoneSafe,
                object: nil,
                userInfo: [
                    "title": title
                ]
            )
        }
        
    }
    
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "danger_zone_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print(granted ? "✅ 通知权限已获取" : "⚠️ 通知权限被拒绝")
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return String(format: "%.0f米", distance * 1000)
        } else if distance < 10 {
            return String(format: "%.2f公里", distance)
        } else {
            return String(format: "%.1f公里", distance)
        }
    }
}

// MARK: - 通知类型
private enum AlertType {
    case danger
    case warning
    case safe
}

// MARK: - 危险点助手类
fileprivate class DangerPointHelper {
    
    static let shared = DangerPointHelper()
    
    func loadDangerPoints(from fileName: String, password: String) throws -> [DangerPoint] {
        // 1. 查找文件
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("❌ 文件不存在: \(fileName)")
            throw DangerZoneError.fileNotFound
        }
        
        print("✅ 找到文件: \(fileURL.lastPathComponent)")
        
        // 2. 读取加密数据
        let encryptedBase64 = try String(contentsOf: fileURL, encoding: .utf8)
        print("📦 加密数据大小: \(encryptedBase64.count) 字符")
        
        // 3. 解密数据
        return try decryptPoints(encryptedBase64, password: password)
    }
    
    func decryptPoints(_ encryptedBase64: String, password: String) throws -> [DangerPoint] {
        // 1. Base64解码
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else {
            throw DangerZoneError.invalidBase64
        }
        
        // 2. 提取IV（前16字节）
        guard encryptedData.count > 16 else {
            throw DangerZoneError.invalidData
        }
        
        let iv = encryptedData.prefix(16)
        let cipherData = encryptedData.suffix(from: 16)
        
        // 3. 生成密钥（使用密码的SHA256哈希）
        let key = sha256(string: password)
        
        // 4. AES解密
        guard let decryptedData = aesDecrypt(data: cipherData, key: key, iv: iv) else {
            throw DangerZoneError.decryptionFailed
        }
        
        // 5. 解析JSON
        do {
            let points = try JSONDecoder().decode([DangerPoint].self, from: decryptedData)
            return points
        } catch {
            print("JSON解析失败: \(error)")
            throw DangerZoneError.invalidJSON
        }
    }
    
    // AES解密
    private func aesDecrypt(data: Data, key: Data, iv: Data) -> Data? {
        let bufferSize = data.count + kCCBlockSizeAES128
        var buffer = Data(count: bufferSize)
        
        var numBytesDecrypted = 0
        
        let status = buffer.withUnsafeMutableBytes { bufferBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, data.count,
                            bufferBytes.baseAddress, bufferSize,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        
        guard status == kCCSuccess else {
            print("AES解密失败，状态码: \(status)")
            return nil
        }
        
        return buffer.prefix(numBytesDecrypted)
    }
    
    // SHA256哈希
    private func sha256(string: String) -> Data {
        let data = string.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
    
    // MARK: - 计算方法
    func calculateDistance(from userLocation: CLLocation, to dangerPoint: DangerPoint) -> Double {
        let pointLocation = dangerPoint.toLocation()
        let distanceInMeters = userLocation.distance(from: pointLocation)
        return distanceInMeters / 1000.0
    }
    
    func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLat = from.latitude.degreesToRadians
        let fromLon = from.longitude.degreesToRadians
        let toLat = to.latitude.degreesToRadians
        let toLon = to.longitude.degreesToRadians
        
        let dLon = toLon - fromLon
        
        let y = sin(dLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLon)
        
        var bearing = atan2(y, x).radiansToDegrees
        bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)
        
        return bearing
    }
    
    func getChineseDirection(from bearing: Double) -> String {
        let directions = ["正北", "东北", "正东", "东南", "正南", "西南", "正西", "西北"]
        let index = Int((bearing + 22.5) / 45.0) % 8
        return directions[index]
    }
}

// 需要导入CommonCrypto
import CommonCrypto
