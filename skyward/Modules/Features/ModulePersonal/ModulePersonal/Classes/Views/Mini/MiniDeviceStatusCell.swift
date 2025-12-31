//
//  ProDeviceStatusCell.swift
//  Pods
//
//  Created by TXTS on 2025/12/15.
//


import UIKit
import SWKit

class MiniDeviceStatusCell: UITableViewCell {
    
    private let bgView = UIView()
    private let statusTitle = UILabel()
    private let refreshButton = UIButton(type: .custom)
    private let msgLongitudeText = UILabel()
    private let msgLatitudeText = UILabel()
    private let msgAltitudeText = UILabel()
    private let msgTemperatureText = UILabel()
    private let msgHumidityText = UILabel()
    private let msgMotionText = UILabel()
    private let longitudeLabel = UILabel()
    private let latitudeLabel = UILabel()
    private let altitudeLabel = UILabel()
    private let temperatureLabel = UILabel()
    private let humidityLabel = UILabel()
    private let motionLabel = UILabel()
    
    var refreshAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupNotifications()
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
        
        statusTitle.text = "设备参数"
        statusTitle.textColor = UIColor(str: "#070808")
        statusTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        bgView.addSubview(statusTitle)
        
        refreshButton.setImage(PersonalModule.image(named: "device_pro_refresh"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshClick), for: .touchUpInside)
        bgView.addSubview(refreshButton)
        
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
        
        msgTemperatureText.text = "--"
        msgTemperatureText.textColor = UIColor(str: "#070808")
        msgTemperatureText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgTemperatureText.textAlignment = .left
        bgView.addSubview(msgTemperatureText)
        
        msgHumidityText.text = "--"
        msgHumidityText.textColor = UIColor(str: "#070808")
        msgHumidityText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgHumidityText.textAlignment = .center
        bgView.addSubview(msgHumidityText)
        
        msgMotionText.text = "--"
        msgMotionText.textColor = UIColor(str: "#070808")
        msgMotionText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgMotionText.textAlignment = .right
        bgView.addSubview(msgMotionText)
        
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
        
        altitudeLabel.text = "海拔（m）"
        altitudeLabel.textColor = UIColor(str: "#84888C")
        altitudeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        altitudeLabel.textAlignment = .right
        bgView.addSubview(altitudeLabel)
        
        temperatureLabel.text = "温度（℃）"
        temperatureLabel.textColor = UIColor(str: "#84888C")
        temperatureLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        temperatureLabel.textAlignment = .left
        bgView.addSubview(temperatureLabel)
        
        humidityLabel.text = "湿度（%RH）"
        humidityLabel.textColor = UIColor(str: "#84888C")
        humidityLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        humidityLabel.textAlignment = .center
        bgView.addSubview(humidityLabel)
        
        motionLabel.text = "运动状态"
        motionLabel.textColor = UIColor(str: "#84888C")
        motionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        motionLabel.textAlignment = .right
        bgView.addSubview(motionLabel)
        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        statusTitle.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        msgLongitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgLatitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgAltitudeText.translatesAutoresizingMaskIntoConstraints = false
        msgTemperatureText.translatesAutoresizingMaskIntoConstraints = false
        msgHumidityText.translatesAutoresizingMaskIntoConstraints = false
        msgMotionText.translatesAutoresizingMaskIntoConstraints = false
        longitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        latitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        temperatureLabel.translatesAutoresizingMaskIntoConstraints = false
        humidityLabel.translatesAutoresizingMaskIntoConstraints = false
        motionLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            msgLongitudeText.topAnchor.constraint(equalTo: statusTitle.bottomAnchor, constant: 16),
            msgLongitudeText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgLatitudeText.topAnchor.constraint(equalTo: statusTitle.bottomAnchor, constant: 16),
            msgLatitudeText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            msgAltitudeText.topAnchor.constraint(equalTo: statusTitle.bottomAnchor, constant: 16),
            msgAltitudeText.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            longitudeLabel.topAnchor.constraint(equalTo: msgLongitudeText.bottomAnchor, constant: 5),
            longitudeLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            latitudeLabel.topAnchor.constraint(equalTo: msgLatitudeText.bottomAnchor, constant: 5),
            latitudeLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            altitudeLabel.topAnchor.constraint(equalTo: msgAltitudeText.bottomAnchor, constant: 5),
            altitudeLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            msgTemperatureText.topAnchor.constraint(equalTo: longitudeLabel.bottomAnchor, constant: 12),
            msgTemperatureText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgHumidityText.topAnchor.constraint(equalTo: longitudeLabel.bottomAnchor, constant: 12),
            msgHumidityText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            msgMotionText.topAnchor.constraint(equalTo: longitudeLabel.bottomAnchor, constant: 12),
            msgMotionText.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
            temperatureLabel.topAnchor.constraint(equalTo: msgTemperatureText.bottomAnchor, constant: 5),
            temperatureLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            humidityLabel.topAnchor.constraint(equalTo: msgHumidityText.bottomAnchor, constant: 5),
            humidityLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            motionLabel.topAnchor.constraint(equalTo: msgMotionText.bottomAnchor, constant: 5),
            motionLabel.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            
        ])
    }
    
    @objc private func refreshClick() {
        refreshAction?()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusInfoUpdate(_:)),
            name: .didReceiveStatusInfo,
            object: nil
        )
    }
    
    @objc private func handleStatusInfoUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let statusInfo = userInfo["statusInfo"] as? StatusInfo else {
            return
        }
        
        DispatchQueue.main.async {
            self.configon(with: statusInfo)
        }
    }
    
    func resetStatus(isConnect: Bool) {
        if !isConnect {
            msgLongitudeText.text = "--"
            msgLatitudeText.text = "--"
            msgAltitudeText.text = "--"
            msgTemperatureText.text = "--"
            msgHumidityText.text = "--"
            msgMotionText.text = "--"
        }
    }
    
    func configon(with statusInfo: StatusInfo) {
        
        // 经度
        let longitudeValue = Double(statusInfo.longitude) / 10000.0
        let longitudeHemisphere = statusInfo.longitudeHemisphere == 0 ? "E" : "W"
//        let (degrees, minutes, seconds) = decimalToDMS(longitudeValue)
//        let longitudeString = "\(degrees)°\(minutes)′\(seconds)″\(longitudeHemisphere)"
        let longitudeNum = decimalToDegrees(longitudeValue)
        let longitudeString = "\(longitudeNum)°\(longitudeHemisphere)"
        
        // 纬度
        let latitudeValue = Double(statusInfo.latitude) / 10000.0
        let latitudeHemisphere = statusInfo.latitudeHemisphere == 0 ? "N" : "S"
//        let (laDegrees, laMinutes, laSeconds) = decimalToDMS(latitudeValue)
//        let latitudeString = "\(laDegrees)°\(laMinutes)′\(laSeconds)″\(latitudeHemisphere)"
        let latitudeNum = decimalToDegrees(latitudeValue)
        let latitudeString = "\(latitudeNum)°\(latitudeHemisphere)"
        
        // 海拔
        let altitudeValue = Double(statusInfo.altitude) / 10.0
        let altitudeString = String(format: "%.1f", altitudeValue)
        
        // 温度
        let temperatureValue = Double(statusInfo.temperature) / 100.0
        let temperatureString = String(format: "%.1f", temperatureValue)
        
        // 湿度
        let humidityValue = Double(statusInfo.humidity) / 100.0
        let humidityString = String(format: "%.1f%%", humidityValue)
        
        // 运动状态
        let motionStatusString: String
        switch statusInfo.motionStatus {
        case 0:
            motionStatusString = "静止"
        case 1:
            motionStatusString = "移动"
        case 2:
            motionStatusString = "跌倒"
        default:
            motionStatusString = "未知"
        }
        
        msgLongitudeText.text = longitudeString
        msgLatitudeText.text = latitudeString
        msgAltitudeText.text = altitudeString
        msgTemperatureText.text = temperatureString
        msgHumidityText.text = humidityString
        msgMotionText.text = motionStatusString
    }
    
    // 经纬度转换
    private func decimalToDMS(_ decimal: Double) -> (Int, Int, Int) {
        // 3039.985107 实际上是 30度 + 39.985107分
        // 所以需要先分离出度和分的小数部分
        let totalDegrees = Int(decimal / 100) // 获取前两位作为度
        let remaining = decimal - Double(totalDegrees * 100) // 获取剩余部分作为分
        
        let minutes = Int(remaining) // 分的整数部分
        let secondsDecimal = (remaining - Double(minutes)) * 60 // 秒的小数部分
        
        let seconds = Int(secondsDecimal.rounded()) // 四舍五入到整数秒
        
        return (totalDegrees, minutes, seconds)
    }
    
    private func decimalToDegrees(_ decimal: Double) -> String {
        // 将 DDMM.MMMMMM 格式转换为十进制度
        // 3039.985107 -> 30度 + 39.985107分
        
        // 获取度（前两位）
        let degrees = Int(decimal / 100)
        
        // 获取剩余部分作为分
        let minutes = decimal - Double(degrees * 100)
        
        // 将分转换为度（1度=60分）
        let decimalDegrees = Double(degrees) + minutes / 60.0
        
        return String(format: "%.6f", decimalDegrees)
    }
}
