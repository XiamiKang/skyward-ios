//
//  WeatherModels.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import CoreLocation
import WCDBSwift

public struct CityWeatherData: Codable {
    public let cityId: String?
    public let cityName: String?
    public let weatherCode: String?
    public let tempMax: Int?
    public let tempMin: Int?
    public let lon: Double?
    public let lat: Double?
    public let isProvincial: Bool?
}

extension CityWeatherData: TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = CityWeatherData
        
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case cityId
        case cityName
        case weatherCode
        case tempMax
        case tempMin
        case lon
        case lat
        case isProvincial
        
        public static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .cityId: ColumnConstraintConfig(cityId, isPrimary: true, defaultTo: ""),
            ]
        }
    }
    
    public var isAutoIncrement: Bool { false }
    public init() { self.init(cityId: nil, cityName: nil, weatherCode: nil, tempMax: nil, tempMin: nil, lon: nil, lat: nil, isProvincial: nil) }
}

