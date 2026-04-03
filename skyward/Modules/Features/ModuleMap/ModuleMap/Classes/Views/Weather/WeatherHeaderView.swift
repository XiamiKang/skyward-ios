//
//  SectionHeaderView.swift
//  Pods
//
//  Created by TXTS on 2025/12/8.
//

import UIKit
import SWKit
import CoreLocation

class WeatherHeaderView: UITableViewHeaderFooterView {
    
    let locationLabel = UILabel()
    let addressLabel = UILabel()
    let latAndLogLabel = UILabel()
    let altitudeLabel = UILabel()
    let closeButton = UIButton(type: .custom)
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        // 位置信息
        locationLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        locationLabel.textColor = .black
        locationLabel.text = "--"
        contentView.addSubview(locationLabel)
        
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = UIColor(str: "#84888C")
        addressLabel.text = "地址：--"
        contentView.addSubview(addressLabel)
        
        // 经纬度信息
        latAndLogLabel.font = .systemFont(ofSize: 14, weight: .regular)
        latAndLogLabel.textColor = UIColor(str: "#84888C")
        latAndLogLabel.text = "经纬度：--"
        addSubview(latAndLogLabel)
        
        // 海拔信息
        altitudeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        altitudeLabel.textColor = UIColor(str: "#84888C")
        altitudeLabel.text = "海拔：--"
        addSubview(altitudeLabel)
        
        // 关闭按钮
        closeButton.setImage(MapModule.image(named: "default_close"), for: .normal)
        closeButton.tintColor = UIColor(str: "#84888C")
        contentView.addSubview(closeButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        latAndLogLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            addressLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 8),
            addressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            latAndLogLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 5),
            latAndLogLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            latAndLogLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            altitudeLabel.topAnchor.constraint(equalTo: latAndLogLabel.bottomAnchor, constant: 5),
            altitudeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            altitudeLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            closeButton.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(with coordinate: CLLocationCoordinate2D) {
        let longitudeStr = String(format: "%.6f", coordinate.longitude)
        let latitudeStr = String(format: "%.6f", coordinate.latitude)
        latAndLogLabel.text = "经纬度：\(longitudeStr)°E, \(latitudeStr)°N"
    }
    
    func configure(with data: PublicPOIData) {
        locationLabel.text = data.name
        addressLabel.text = "位置：\(data.address ?? "--")"
        let longitudeStr = String(format: "%.6f", data.lon ?? 00)
        let latitudeStr = String(format: "%.6f", data.lat ?? 00)
        latAndLogLabel.text = "经纬度：\(longitudeStr)°E, \(latitudeStr)°N"
        altitudeLabel.text = "海拔：\(data.altitude ?? 00)米"
    }
    
    func configure(with data: MapSearchPointMsgData) {
        locationLabel.text = data.name
        addressLabel.text = "位置：\(data.address ?? "--")"
        let longitudeStr = String(format: "%.6f", data.longitude ?? 00)
        let latitudeStr = String(format: "%.6f", data.latitude ?? 00)
        latAndLogLabel.text = "经纬度：\(longitudeStr)°E, \(latitudeStr)°N"
        altitudeLabel.text = "海拔：\(data.altitude ?? "--")米"
    }
}
