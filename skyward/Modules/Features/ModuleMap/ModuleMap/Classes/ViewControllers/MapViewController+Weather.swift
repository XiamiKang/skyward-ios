//
//  MapViewController+Weather.swift
//  ModuleMap
//
//  Created by TXTS on 2026/3/7.
//

import Foundation
import SWKit

extension MapViewController {
    
    public func setupWeatherLayer() {
        mapManager.buildCityWeatherMapData()
    }
    
}
