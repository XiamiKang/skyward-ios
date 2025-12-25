//
//  MapModel.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import CoreLocation


// 地图相关模型
public struct MapSource: Codable, Equatable {
    public let name: String
    public let imageName: String
    public let sceneUrl: String
    public var isSelected: Bool
    
    public init(name: String, imageName: String, sceneUrl: String, isSelected: Bool = false) {
        self.name = name
        self.imageName = imageName
        self.sceneUrl = sceneUrl
        self.isSelected = isSelected
    }
}

public struct MeasurementResult {
    public let distance: Double
    public let startCoordinate: CLLocationCoordinate2D
    public let endCoordinate: CLLocationCoordinate2D
    
    public init(distance: Double, startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) {
        self.distance = distance
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
    }
}

public struct POICoordinate {
    public let latitude: Double
    public let longitude: Double
    
    public var displayString: String {
        return String(format: "纬度: %.6f  经度: %.6f", latitude, longitude)
    }
}

