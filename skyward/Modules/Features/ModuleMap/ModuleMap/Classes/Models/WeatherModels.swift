//
//  WeatherModels.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import CoreLocation

public struct WeatherLayerData: Codable {
    public let maxlon: String
    public let minlon: String
    public let tuliurl: String
    public let time: String
    public let minlat: String
    public let maxlat: String
    public let imgurl: String
    
    public var maxLonDouble: Double? { Double(maxlon) }
    public var minLonDouble: Double? { Double(minlon) }
    public var maxLatDouble: Double? { Double(maxlat) }
    public var minLatDouble: Double? { Double(minlat) }
    
    public var coordinateBounds: (min: CLLocationCoordinate2D, max: CLLocationCoordinate2D)? {
        guard let minLon = minLonDouble,
              let maxLon = maxLonDouble,
              let minLat = minLatDouble,
              let maxLat = maxLatDouble else {
            return nil
        }
        
        return (
            min: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
            max: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        )
    }
}

public struct WeatherAPIResponse: Codable {
    public let TEM: WeatherLayerData?  // 温度
    public let RHU: WeatherLayerData?  // 湿度
    public let WINS: WeatherLayerData? // 风速
    public let VIS: WeatherLayerData?  // 能见度
}

public struct WeatherBaseResponse: Codable {
    public let code: String
    public let data: String  // 嵌套的JSON字符串
    public let msg: String
    
    public func parseWeatherData() -> Result<WeatherAPIResponse, MapError> {
        guard let jsonData = data.data(using: .utf8) else {
            return .failure(.parseError("天气数据编码错误"))
        }
        
        do {
            let weatherResponse = try JSONDecoder().decode(WeatherAPIResponse.self, from: jsonData)
            return .success(weatherResponse)
        } catch {
            print("解析嵌套天气数据失败: \(error)")
            return .failure(.parseError("天气数据格式错误"))
        }
    }
}
