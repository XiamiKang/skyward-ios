//
//  CoordinateModels.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import CoreLocation

public struct Coordinate: Codable {
    public let longitude: Double?
    public let latitude: Double?
    
    public init(longitude: Double?, latitude: Double?) {
        self.longitude = longitude
        self.latitude = latitude
    }
    
    // 便捷初始化方法
    public init(_ coordinate: CLLocationCoordinate2D) {
        self.longitude = coordinate.longitude
        self.latitude = coordinate.latitude
    }
    
    // 判断坐标是否有效
    public var isValid: Bool {
        return longitude != nil && latitude != nil
    }
    
    // 转换为 CLLocationCoordinate2D
    public var clLocationCoordinate2D: CLLocationCoordinate2D? {
        guard let lon = longitude, let lat = latitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    // 转换为字典，用于编码
    public var dictionary: [String: Double] {
        return [
            "longitude": longitude ?? 0.0,
            "latitude": latitude ?? 0.0
        ]
    }
}

public struct LocationData: Codable, Equatable, Hashable {
    // MARK: - 基础属性
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    public let horizontalAccuracy: Double
    public let verticalAccuracy: Double?
    public let altitude: Double?
    public let speed: Double?
    public let course: Double?
    public let floor: Int?
    
    // MARK: - 初始化方法
    public init(
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        horizontalAccuracy: Double = kCLLocationAccuracyNearestTenMeters,
        verticalAccuracy: Double? = nil,
        altitude: Double? = nil,
        speed: Double? = nil,
        course: Double? = nil,
        floor: Int? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.altitude = altitude
        self.speed = speed
        self.course = course
        self.floor = floor
    }
    
    public init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.altitude = location.altitude
        self.speed = location.speed
        self.course = location.course
        self.floor = location.floor?.level
    }
    
    public init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = Date()
        self.horizontalAccuracy = kCLLocationAccuracyNearestTenMeters
        self.verticalAccuracy = nil
        self.altitude = nil
        self.speed = nil
        self.course = nil
        self.floor = nil
    }
}

// MARK: - 计算属性
public extension LocationData {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var clLocation: CLLocation {
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude ?? -1,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy ?? -1,
            course: course ?? -1,
            speed: speed ?? -1,
            timestamp: timestamp
        )
    }
    
    var isHighAccuracy: Bool {
        return horizontalAccuracy > 0 && horizontalAccuracy <= 50
    }
    
    var isRecent: Bool {
        return abs(timestamp.timeIntervalSinceNow) < 300 // 5分钟内
    }
    
    var directionString: String? {
        guard let course = course, course >= 0 else { return nil }
        
        let directions = ["北", "东北", "东", "东南", "南", "西南", "西", "西北"]
        let index = Int((course + 22.5) / 45) % 8
        return directions[index]
    }
    
    var speedString: String? {
        guard let speed = speed, speed >= 0 else { return nil }
        
        if speed < 0.1 {
            return "静止"
        } else if speed < 5 {
            return String(format: "%.1f km/h", speed * 3.6)
        } else {
            return String(format: "%.0f km/h", speed * 3.6)
        }
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(timestamp) {
            formatter.dateFormat = "HH:mm:ss"
        } else {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }
        return formatter.string(from: timestamp)
    }
}

// MARK: - 位置计算
public extension LocationData {
    func distance(to other: LocationData) -> Double {
        return clLocation.distance(from: other.clLocation)
    }
    
    func bearing(to other: LocationData) -> Double {
        let lat1 = latitude.degreesToRadians
        let lon1 = longitude.degreesToRadians
        let lat2 = other.latitude.degreesToRadians
        let lon2 = other.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var bearing = atan2(y, x).radiansToDegrees
        
        if bearing < 0 {
            bearing += 360
        }
        
        return bearing
    }
    
    func movedBy(distanceMeters: Double, bearingDegrees: Double) -> LocationData {
        let earthRadius: Double = 6378137.0 // WGS-84地球半径
        
        let latRad = latitude.degreesToRadians
        let lonRad = longitude.degreesToRadians
        let bearingRad = bearingDegrees.degreesToRadians
        
        let newLatRad = asin(sin(latRad) * cos(distanceMeters / earthRadius) +
                           cos(latRad) * sin(distanceMeters / earthRadius) * cos(bearingRad))
        
        let newLonRad = lonRad + atan2(sin(bearingRad) * sin(distanceMeters / earthRadius) * cos(latRad),
                                      cos(distanceMeters / earthRadius) - sin(latRad) * sin(newLatRad))
        
        let newLat = newLatRad.radiansToDegrees
        let newLon = newLonRad.radiansToDegrees
        
        return LocationData(
            latitude: newLat,
            longitude: newLon,
            timestamp: timestamp,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            altitude: altitude,
            speed: speed,
            course: course,
            floor: floor
        )
    }
}

// MARK: - 编码/解码自定义处理
extension LocationData {
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude, timestamp, horizontalAccuracy
        case verticalAccuracy, altitude, speed, course, floor
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        horizontalAccuracy = try container.decode(Double.self, forKey: .horizontalAccuracy)
        
        verticalAccuracy = try container.decodeIfPresent(Double.self, forKey: .verticalAccuracy)
        altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        course = try container.decodeIfPresent(Double.self, forKey: .course)
        floor = try container.decodeIfPresent(Int.self, forKey: .floor)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        
        try container.encodeIfPresent(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(course, forKey: .course)
        try container.encodeIfPresent(floor, forKey: .floor)
    }
}

// MARK: - JSON 支持
public extension LocationData {
    var jsonString: String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            print("JSON编码错误: \(error)")
            return nil
        }
    }
    
    var jsonData: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            return try encoder.encode(self)
        } catch {
            print("JSON编码错误: \(error)")
            return nil
        }
    }
    
    static func from(jsonString: String) -> LocationData? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return from(jsonData: data)
    }
    
    static func from(jsonData: Data) -> LocationData? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(LocationData.self, from: jsonData)
        } catch {
            print("JSON解码错误: \(error)")
            return nil
        }
    }
}

// MARK: - 坐标边界计算
public extension LocationData {
    func boundingBox(radiusMeters: Double) -> (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D) {
        let latDistance = radiusMeters / 111320.0  // 每度纬度约111.32公里
        let lonDistance = radiusMeters / (111320.0 * cos(latitude.degreesToRadians))
        
        let minLat = latitude - latDistance
        let maxLat = latitude + latDistance
        let minLon = longitude - lonDistance
        let maxLon = longitude + lonDistance
        
        return (
            min: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
            max: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        )
    }
    
    func isWithin(radiusMeters: Double, of other: LocationData) -> Bool {
        return distance(to: other) <= radiusMeters
    }
    
    func isWithin(bounds: (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D)) -> Bool {
        return latitude >= bounds.min.latitude &&
               latitude <= bounds.max.latitude &&
               longitude >= bounds.min.longitude &&
               longitude <= bounds.max.longitude
    }
}

// MARK: - 集合操作
public extension Array where Element == LocationData {
    func averageLocation() -> LocationData? {
        guard !isEmpty else { return nil }
        
        let avgLat = map { $0.latitude }.reduce(0, +) / Double(count)
        let avgLon = map { $0.longitude }.reduce(0, +) / Double(count)
        let avgAccuracy = map { $0.horizontalAccuracy }.reduce(0, +) / Double(count)
        
        return LocationData(
            latitude: avgLat,
            longitude: avgLon,
            timestamp: Date(),
            horizontalAccuracy: avgAccuracy
        )
    }
    
    func medianLocation() -> LocationData? {
        guard !isEmpty else { return nil }
        
        let sortedByLat = sorted { $0.latitude < $1.latitude }
        let sortedByLon = sorted { $0.longitude < $1.longitude }
        
        let medianLat = sortedByLat[count / 2].latitude
        let medianLon = sortedByLon[count / 2].longitude
        
        return LocationData(
            latitude: medianLat,
            longitude: medianLon,
            timestamp: Date(),
            horizontalAccuracy: map { $0.horizontalAccuracy }.reduce(0, +) / Double(count)
        )
    }
    
    func filterByAccuracy(maxAccuracy: Double) -> [LocationData] {
        return filter { $0.horizontalAccuracy <= maxAccuracy }
    }
    
    func filterByRecency(maxAgeSeconds: TimeInterval) -> [LocationData] {
        let cutoffDate = Date().addingTimeInterval(-maxAgeSeconds)
        return filter { $0.timestamp > cutoffDate }
    }
    
    var totalDistance: Double {
        guard count > 1 else { return 0 }
        
        var total: Double = 0
        for i in 1..<count {
            total += self[i].distance(to: self[i-1])
        }
        return total
    }
}

// MARK: - 角度转换扩展
public extension Double {
    var degreesToRadians: Double {
        return self * .pi / 180
    }
    
    var radiansToDegrees: Double {
        return self * 180 / .pi
    }
}

// MARK: - 自定义运算符
extension LocationData {
    public static func == (lhs: LocationData, rhs: LocationData) -> Bool {
        return lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.timestamp == rhs.timestamp
    }
    
    public static func + (lhs: LocationData, rhs: CLLocationCoordinate2D) -> LocationData {
        return LocationData(
            latitude: lhs.latitude + rhs.latitude,
            longitude: lhs.longitude + rhs.longitude,
            timestamp: lhs.timestamp,
            horizontalAccuracy: lhs.horizontalAccuracy
        )
    }
    
    public static func - (lhs: LocationData, rhs: CLLocationCoordinate2D) -> LocationData {
        return LocationData(
            latitude: lhs.latitude - rhs.latitude,
            longitude: lhs.longitude - rhs.longitude,
            timestamp: lhs.timestamp,
            horizontalAccuracy: lhs.horizontalAccuracy
        )
    }
}
