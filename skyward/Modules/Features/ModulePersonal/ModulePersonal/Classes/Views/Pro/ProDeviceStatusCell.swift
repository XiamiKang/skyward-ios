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
    private let msgRunText = UILabel()
    private let msgCollectionText = UILabel()
    private let msgLongitudeText = UILabel()
    private let msgLatitudeText = UILabel()
    private let msgAltitudeText = UILabel()
    private let msgTemText = UILabel()
    private let msgHumText = UILabel()
    
    private let lockLabel = UILabel()
    private let runLabel = UILabel()
    private let collectionLabel = UILabel()
    private let longitudeLabel = UILabel()
    private let latitudeLabel = UILabel()
    private let altitudeLabel = UILabel()
    private let temLabel = UILabel()
    private let humLabel = UILabel()

    
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
        
        msgRunText.text = "--"
               msgRunText.textColor = UIColor(str: "#070808")
               msgRunText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
               msgRunText.textAlignment = .center
               bgView.addSubview(msgRunText)

        
        msgCollectionText.text = "--"
        msgCollectionText.textColor = UIColor(str: "#070808")
        msgCollectionText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgCollectionText.textAlignment = .right
        bgView.addSubview(msgCollectionText)
        
        msgLongitudeText.text = "--"
        msgLongitudeText.textColor = UIColor(str: "#070808")
        msgLongitudeText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgLongitudeText.textAlignment = .left
        bgView.addSubview(msgLongitudeText)
        
        msgLatitudeText.text = "--"
        msgLatitudeText.textColor = UIColor(str: "#070808")
        msgLatitudeText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgLatitudeText.textAlignment = .center
        bgView.addSubview(msgLatitudeText)
        
        msgAltitudeText.text = "--"
        msgAltitudeText.textColor = UIColor(str: "#070808")
        msgAltitudeText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgAltitudeText.textAlignment = .right
        bgView.addSubview(msgAltitudeText)
        
        msgTemText.text = "--"
               msgTemText.textColor = UIColor(str: "#070808")
               msgTemText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
               msgTemText.textAlignment = .left
               bgView.addSubview(msgTemText)
               
               msgHumText.text = "--"
               msgHumText.textColor = UIColor(str: "#070808")
               msgHumText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
               msgHumText.textAlignment = .center
               bgView.addSubview(msgHumText)

        
        lockLabel.text = "锁定状态"
        lockLabel.textColor = UIColor(str: "#84888C")
        lockLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        lockLabel.textAlignment = .left
        bgView.addSubview(lockLabel)
        
        runLabel.text = "运行状态"
                runLabel.textColor = UIColor(str: "#84888C")
                runLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                runLabel.textAlignment = .center
                bgView.addSubview(runLabel)

        collectionLabel.text = "入网"
        collectionLabel.textColor = UIColor(str: "#84888C")
        collectionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        collectionLabel.textAlignment = .right
        bgView.addSubview(collectionLabel)
        
        
        longitudeLabel.text = "经度"
        longitudeLabel.textColor = UIColor(str: "#84888C")
        longitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        longitudeLabel.textAlignment = .left
        bgView.addSubview(longitudeLabel)
        
        latitudeLabel.text = "纬度"
        latitudeLabel.textColor = UIColor(str: "#84888C")
        latitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        latitudeLabel.textAlignment = .center
        bgView.addSubview(latitudeLabel)
        
        altitudeLabel.text = "海拔"
        altitudeLabel.textColor = UIColor(str: "#84888C")
        altitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        altitudeLabel.textAlignment = .right
        bgView.addSubview(altitudeLabel)
        
        temLabel.text = "终端温度"
                temLabel.textColor = UIColor(str: "#84888C")
                temLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                temLabel.textAlignment = .left
                bgView.addSubview(temLabel)
                
                humLabel.text = "终端湿度"
                humLabel.textColor = UIColor(str: "#84888C")
                humLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                humLabel.textAlignment = .center
                bgView.addSubview(humLabel)

        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        statusTitle.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        lineStatusText.translatesAutoresizingMaskIntoConstraints = false
        msgLockText.translatesAutoresizingMaskIntoConstraints = false
        msgRunText.translatesAutoresizingMaskIntoConstraints = false
        msgCollectionText.translatesAutoresizingMaskIntoConstraints = false
        msgLongitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgLatitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgAltitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgTemText.translatesAutoresizingMaskIntoConstraints = false
        msgHumText.translatesAutoresizingMaskIntoConstraints = false
        lockLabel.translatesAutoresizingMaskIntoConstraints = false
        runLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionLabel.translatesAutoresizingMaskIntoConstraints = false
        longitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        latitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        temLabel.translatesAutoresizingMaskIntoConstraints = false
        humLabel.translatesAutoresizingMaskIntoConstraints = false

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
            
            // 锁定状态，运行状态，入网
            msgLockText.topAnchor.constraint(equalTo: lineStatusText.bottomAnchor, constant: 16),
            msgLockText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgRunText.topAnchor.constraint(equalTo: lineStatusText.bottomAnchor, constant: 16),
            msgRunText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            msgCollectionText.topAnchor.constraint(equalTo: lineStatusText.bottomAnchor, constant: 16),
            msgCollectionText.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            lockLabel.topAnchor.constraint(equalTo: msgLockText.bottomAnchor, constant: 5),
            lockLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            runLabel.topAnchor.constraint(equalTo: msgRunText.bottomAnchor, constant: 5),
            runLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            collectionLabel.topAnchor.constraint(equalTo: msgCollectionText.bottomAnchor, constant: 5),
            collectionLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            //经纬，海拔
            msgLongitudeText.topAnchor.constraint(equalTo: lockLabel.bottomAnchor, constant: 16),
            msgLongitudeText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgLatitudeText.topAnchor.constraint(equalTo: lockLabel.bottomAnchor, constant: 16),
            msgLatitudeText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            msgAltitudeText.topAnchor.constraint(equalTo: lockLabel.bottomAnchor, constant: 16),
            msgAltitudeText.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            longitudeLabel.topAnchor.constraint(equalTo: msgLongitudeText.bottomAnchor, constant: 5),
            longitudeLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            latitudeLabel.topAnchor.constraint(equalTo: msgLatitudeText.bottomAnchor, constant: 5),
            latitudeLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            altitudeLabel.topAnchor.constraint(equalTo: msgAltitudeText.bottomAnchor, constant: 5),
            altitudeLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            //温度，湿度
            msgTemText.topAnchor.constraint(equalTo: longitudeLabel.bottomAnchor, constant: 16),
            msgTemText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgHumText.topAnchor.constraint(equalTo: longitudeLabel.bottomAnchor, constant: 16),
            msgHumText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            temLabel.topAnchor.constraint(equalTo: msgTemText.bottomAnchor, constant: 5),
            temLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            humLabel.topAnchor.constraint(equalTo: msgHumText.bottomAnchor, constant: 5),
            humLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
        ])
    }
    
    @objc private func refreshClick() {
        refreshAction?()
    }
    
    func configon(with data: ProDeviceStatus) {
        msgLockText.text = data.lockStatus.description
        msgCollectionText.text = data.antennaStatus.description
        msgLatitudeText.text = String(format: "%.6f°N",data.latitude)
        msgLongitudeText.text = String(format: "%.6f°E",data.longitude)
        msgAltitudeText.text = String(format:"%.2f米",data.altitude)
        msgAltitudeText.text = String(data.altitude)
        lineStatusText.text = data.antennaStatus.contentText
        if data.antennaStatus == .stableTracking {
            lineStatusText.textColor = UIColor(str: "#16C282")
        }else {
            lineStatusText.textColor = UIColor(str: "#FF9447")
        }
    }
    
    func configonEnvironment(with data: EnvironmentInfo) {
        msgTemText.text = "\(data.temperature)℃"
        msgHumText.text =  "\(data.humidity)%"
    }
    
    func configRunStatus(with data: SatelliteLinkStatus) {
        msgRunText.text = data.description
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
