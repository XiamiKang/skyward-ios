//
//  MapAddPOIStartView.swift
//  ModuleMap
//
//  Created by TXTS on 2026/2/24.
//

import UIKit
import TXKit
import SWTheme
import CoreLocation
import SWKit

class MapAddPOIStartView: UIView {
    
    private var coordinate: CLLocationCoordinate2D?
    private var POIData: MapSearchPointMsgData?
    var AddPOIAction:((CLLocationCoordinate2D, MapSearchPointMsgData?) -> Void)?
    
    private var POIName: UILabel = {
        let label = UILabel()
        label.text = "--"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var POILatAndLot: UILabel = {
        let label = UILabel()
        label.text = "经纬度：--"
        if let coordinate = coordinate {
            let longitudeStr = String(format: "%.6f", coordinate.longitude)
            let latitudeStr = String(format: "%.6f", coordinate.latitude)
            label.text = "经纬度：\(longitudeStr)°E, \(latitudeStr)°N"
        }
        label.textColor = UIColor(str: "#84888C")
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var POIAltitude: UILabel = {
        let label = UILabel()
        label.text = "海拔：--"
        label.textColor = UIColor(str: "#84888C")
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addPOIButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.mainColor
        button.setTitle("添加兴趣点", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(addPOIClick), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = ThemeManager.current.backgroundColor
        layer.cornerRadius = 12
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(POIName)
        addSubview(POILatAndLot)
        addSubview(POIAltitude)
        addSubview(addPOIButton)
        
        NSLayoutConstraint.activate([
            
            POIName.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            POIName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            POIName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            POILatAndLot.topAnchor.constraint(equalTo: POIName.bottomAnchor, constant: 8),
            POILatAndLot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            POILatAndLot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            POIAltitude.topAnchor.constraint(equalTo: POILatAndLot.bottomAnchor, constant: 8),
            POIAltitude.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            POIAltitude.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            addPOIButton.topAnchor.constraint(equalTo: POIAltitude.bottomAnchor, constant: 20),
            addPOIButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            addPOIButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            addPOIButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    @objc private func addPOIClick() {
        guard let coordinate = coordinate else {
            print("没有获取到经纬度")
            return
        }
        AddPOIAction?(coordinate, POIData)
    }
    
    func config(_ data: MapSearchPointMsgData) {
        POIData = data
        POIName.text = data.name
        if let longitude = data.longitude, let latitude = data.latitude {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let longitudeDirection = longitude >= 0 ? "E" : "W"
            let latitudeDirection = latitude >= 0 ? "N" : "S"
            let longitudeStr = String(format: "%.6f", abs(longitude))
            let latitudeStr = String(format: "%.6f", abs(latitude))
            POILatAndLot.text = "经纬度：\(longitudeStr)°\(longitudeDirection), \(latitudeStr)°\(latitudeDirection)"
        }
        POIAltitude.text = "海拔：\(data.altitude ?? "--")米"
    }
    
    func config(_ mapCoordinate: CLLocationCoordinate2D) {
        coordinate = mapCoordinate
        
        // 判断经度方向
        let longitudeDirection = mapCoordinate.longitude >= 0 ? "E" : "W"
        // 判断纬度方向
        let latitudeDirection = mapCoordinate.latitude >= 0 ? "N" : "S"
        
        // 取绝对值并格式化，保留6位小数
        let longitudeStr = String(format: "%.6f", abs(mapCoordinate.longitude))
        let latitudeStr = String(format: "%.6f", abs(mapCoordinate.latitude))
        
        POILatAndLot.text = "经纬度：\(longitudeStr)°\(longitudeDirection), \(latitudeStr)°\(latitudeDirection)"
    }
    
    func resetUI() {
        POIName.text = "--"
        POILatAndLot.text = "经纬度：--"
        POIAltitude.text = "海拔：--"
    }
}
