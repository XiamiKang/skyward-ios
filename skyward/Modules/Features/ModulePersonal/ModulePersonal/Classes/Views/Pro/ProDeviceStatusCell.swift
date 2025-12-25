//
//  Pro.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

class ProDeviceStatusCell: UITableViewCell {
    
    private let bgView = UIView()
    private let statusTitle = UILabel()
    private let refreshButton = UIButton(type: .custom)
    private let lineStatusText = UILabel()
    private let msgLockText = UILabel()
    private let msgCollectionText = UILabel()
    private let msgAzimuthText = UILabel()
    private let msgPitchAngleText = UILabel()
    private let msgLongitudeText = UILabel()
    private let msgLatitudeText = UILabel()
    private let msgAltitudeText = UILabel()
    private let lockLabel = UILabel()
    private let collectionLabel = UILabel()
    private let azimuthLabel = UILabel()
    private let pitchAngleLabel = UILabel()
    private let longitudeLabel = UILabel()
    private let latitudeLabel = UILabel()
    private let altitudeLabel = UILabel()
    
    var refreshAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor(str: "#F2F3F4")
        
        bgView.backgroundColor = .white
        bgView.layer.cornerRadius = 8
        contentView.addSubview(bgView)
        
        statusTitle.text = "终端状态"
        statusTitle.textColor = UIColor(str: "#070808")
        statusTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        bgView.addSubview(statusTitle)
        
        refreshButton.setImage(PersonalModule.image(named: "device_pro_refresh"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshClick), for: .touchUpInside)
        bgView.addSubview(refreshButton)
        
        lineStatusText.text = "正在获取设备当前地理位置信息..."
        lineStatusText.textColor = UIColor(str: "#FF9447")
        lineStatusText.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        bgView.addSubview(lineStatusText)
        
        msgLockText.text = "--"
        msgLockText.textColor = UIColor(str: "#070808")
        msgLockText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgLockText.textAlignment = .left
        bgView.addSubview(msgLockText)
        
        msgCollectionText.text = "--"
        msgCollectionText.textColor = UIColor(str: "#070808")
        msgCollectionText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgCollectionText.textAlignment = .center
        bgView.addSubview(msgCollectionText)
        
        msgAzimuthText.text = "--"
        msgAzimuthText.textColor = UIColor(str: "#070808")
        msgAzimuthText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgAzimuthText.textAlignment = .right
        bgView.addSubview(msgAzimuthText)
        
        msgPitchAngleText.text = "--"
        msgPitchAngleText.textColor = UIColor(str: "#070808")
        msgPitchAngleText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgPitchAngleText.textAlignment = .left
        bgView.addSubview(msgPitchAngleText)
        
        msgLongitudeText.text = "--"
        msgLongitudeText.textColor = UIColor(str: "#070808")
        msgLongitudeText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgLongitudeText.textAlignment = .center
        bgView.addSubview(msgLongitudeText)
        
        msgLatitudeText.text = "--"
        msgLatitudeText.textColor = UIColor(str: "#070808")
        msgLatitudeText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgLatitudeText.textAlignment = .right
        bgView.addSubview(msgLatitudeText)
        
        msgAltitudeText.text = "--"
        msgAltitudeText.textColor = UIColor(str: "#070808")
        msgAltitudeText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgAltitudeText.textAlignment = .left
        bgView.addSubview(msgAltitudeText)
        
        lockLabel.text = "锁定状态"
        lockLabel.textColor = UIColor(str: "#84888C")
        lockLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        lockLabel.textAlignment = .left
        bgView.addSubview(lockLabel)
        
        collectionLabel.text = "入网"
        collectionLabel.textColor = UIColor(str: "#84888C")
        collectionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        collectionLabel.textAlignment = .center
        bgView.addSubview(collectionLabel)
        
        azimuthLabel.text = "方位角"
        azimuthLabel.textColor = UIColor(str: "#84888C")
        azimuthLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        azimuthLabel.textAlignment = .right
        bgView.addSubview(azimuthLabel)
        
        pitchAngleLabel.text = "俯仰角"
        pitchAngleLabel.textColor = UIColor(str: "#84888C")
        pitchAngleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        pitchAngleLabel.textAlignment = .left
        bgView.addSubview(pitchAngleLabel)
        
        longitudeLabel.text = "经度"
        longitudeLabel.textColor = UIColor(str: "#84888C")
        longitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        longitudeLabel.textAlignment = .center
        bgView.addSubview(longitudeLabel)
        
        latitudeLabel.text = "纬度"
        latitudeLabel.textColor = UIColor(str: "#84888C")
        latitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        latitudeLabel.textAlignment = .right
        bgView.addSubview(latitudeLabel)
        
        altitudeLabel.text = "海拔"
        altitudeLabel.textColor = UIColor(str: "#84888C")
        altitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        altitudeLabel.textAlignment = .right
        bgView.addSubview(altitudeLabel)
        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        statusTitle.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        lineStatusText.translatesAutoresizingMaskIntoConstraints = false
        msgLockText.translatesAutoresizingMaskIntoConstraints = false
        msgCollectionText.translatesAutoresizingMaskIntoConstraints = false
        msgAzimuthText.translatesAutoresizingMaskIntoConstraints = false
        msgPitchAngleText.translatesAutoresizingMaskIntoConstraints = false
        msgLongitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgLatitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgAltitudeText.translatesAutoresizingMaskIntoConstraints = false
        lockLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionLabel.translatesAutoresizingMaskIntoConstraints = false
        azimuthLabel.translatesAutoresizingMaskIntoConstraints = false
        pitchAngleLabel.translatesAutoresizingMaskIntoConstraints = false
        longitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        latitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            statusTitle.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 16),
            statusTitle.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            refreshButton.centerYAnchor.constraint(equalTo: statusTitle.centerYAnchor),
            refreshButton.leadingAnchor.constraint(equalTo: statusTitle.trailingAnchor, constant: 8),
            refreshButton.widthAnchor.constraint(equalToConstant: 16),
            refreshButton.heightAnchor.constraint(equalToConstant: 16),
            
            lineStatusText.topAnchor.constraint(equalTo: statusTitle.bottomAnchor, constant: 8),
            lineStatusText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgLockText.topAnchor.constraint(equalTo: lineStatusText.bottomAnchor, constant: 16),
            msgLockText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgCollectionText.topAnchor.constraint(equalTo: lineStatusText.bottomAnchor, constant: 16),
            msgCollectionText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            msgAzimuthText.topAnchor.constraint(equalTo: lineStatusText.bottomAnchor, constant: 16),
            msgAzimuthText.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            lockLabel.topAnchor.constraint(equalTo: msgLockText.bottomAnchor, constant: 5),
            lockLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            collectionLabel.topAnchor.constraint(equalTo: msgCollectionText.bottomAnchor, constant: 5),
            collectionLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            azimuthLabel.topAnchor.constraint(equalTo: msgAzimuthText.bottomAnchor, constant: 5),
            azimuthLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            lineStatusText.topAnchor.constraint(equalTo: statusTitle.bottomAnchor, constant: 8),
            lineStatusText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgPitchAngleText.topAnchor.constraint(equalTo: lockLabel.bottomAnchor, constant: 12),
            msgPitchAngleText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgLongitudeText.topAnchor.constraint(equalTo: lockLabel.bottomAnchor, constant: 12),
            msgLongitudeText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            msgLatitudeText.topAnchor.constraint(equalTo: lockLabel.bottomAnchor, constant: 12),
            msgLatitudeText.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            pitchAngleLabel.topAnchor.constraint(equalTo: msgPitchAngleText.bottomAnchor, constant: 5),
            pitchAngleLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            longitudeLabel.topAnchor.constraint(equalTo: msgLongitudeText.bottomAnchor, constant: 5),
            longitudeLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            latitudeLabel.topAnchor.constraint(equalTo: msgLatitudeText.bottomAnchor, constant: 5),
            latitudeLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            msgAltitudeText.topAnchor.constraint(equalTo: pitchAngleLabel.bottomAnchor, constant: 12),
            msgAltitudeText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            altitudeLabel.topAnchor.constraint(equalTo: msgAltitudeText.bottomAnchor, constant: 5),
            altitudeLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
        ])
    }
    
    @objc private func refreshClick() {
        refreshAction?()
    }
    
    func configon(with data: DeviceStatus) {
        msgLockText.text = data.lockStatus.description
        msgCollectionText.text = data.antennaStatus.description
        msgAzimuthText.text = String(data.azimuth)
        msgPitchAngleText.text = String(data.elevation)
        msgLatitudeText.text = convertToDMSString(data.latitude)
        msgLongitudeText.text = convertToDMSString(data.longitude)
        msgAltitudeText.text = String(data.altitude)
        lineStatusText.text = data.antennaStatus.contentText
        if data.antennaStatus == .stableTracking {
            lineStatusText.textColor = UIColor(str: "#16C282")
        }else {
            lineStatusText.textColor = UIColor(str: "#FF9447")
        }
    }
    
    // 经纬度转换
    func convertToDMSTuple(_ coordinate: Double) -> (degrees: Int, minutes: Int, seconds: Int) {
        let absCoordinate = abs(coordinate)
        let degrees = Int(absCoordinate)
        let minutesDecimal = (absCoordinate - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let secondsDecimal = (minutesDecimal - Double(minutes)) * 60
        let seconds = Int(secondsDecimal)
        return (degrees, minutes, seconds)
    }

    // 方法2：返回格式化字符串
    func convertToDMSString(_ coordinate: Double) -> String {
        let (degrees, minutes, seconds) = convertToDMSTuple(coordinate)
        return String(format: "%d°%d′%d″", degrees, minutes, seconds)
    }
}
