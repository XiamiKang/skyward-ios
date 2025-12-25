//
//  Dictionary+Extensions.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import SWKit

extension Dictionary where Key == String {
    mutating func addIfPresent<T>(_ value: T?, forKey key: String) {
        if let value = value {
            self[key] = value as? Value
        }
    }
    
    mutating func addIfPresent<T>(_ value: T?, forKey key: String, where condition: (T) -> Bool) {
        if let value = value, condition(value) {
            self[key] = value as? Value
        }
    }
    
    mutating func addValidCoordinates(_ coordinates: [Coordinate]?, forKey key: String) {
        guard let coordinates = coordinates, !coordinates.isEmpty else { return }
        
        let validCoordinates = coordinates.compactMap { coord -> [String: Double]? in
            guard let longitude = coord.longitude,
                  let latitude = coord.latitude else {
                return nil
            }
            return ["longitude": longitude, "latitude": latitude]
        }
        
        if !validCoordinates.isEmpty {
            self[key] = validCoordinates as? Value
        }
    }
}
