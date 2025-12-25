//
//  ProDeviceBaseMsgCell.swift
//  Pods
//
//  Created by TXTS on 2025/12/15.
//


import UIKit
import SWKit

class MiniDeviceBaseMsgCell: UITableViewCell {
    
    private let bgView = UIView()
    private let deviceImageView = UIImageView()
    private let deviceNameLabel = UILabel()
    private let connectionStatusLabel = UILabel()
    private let imeiLabel = UILabel()
    private let bluetoothStatusImageView = UIImageView()
    private let satelliteStatusImageView = UIImageView()
    private let batteryLevelImageView = UIImageView()
    private let batteryLevelLabel = UILabel()
    private let connectionButton = UIButton(type: .system)
    
    // 新增点击计数器和时间记录
    private var tapCount = 0
    private var lastTapTime: Date?
    private let tapInterval: TimeInterval = 5.0 // 2秒内完成5次点击
    
    var connectionAction: (() -> Void)?
    var quintupleTapAction: (() -> Void)? // 新增：连续点击5次的回调
    
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
        
        // 设备图片
        deviceImageView.translatesAutoresizingMaskIntoConstraints = false
        deviceImageView.contentMode = .scaleAspectFill
        deviceImageView.image = PersonalModule.image(named: "device_mini_logo")
        deviceImageView.isUserInteractionEnabled = true // 启用用户交互
        bgView.addSubview(deviceImageView)
        
        // 添加点击手势识别器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeviceImageTap))
        deviceImageView.addGestureRecognizer(tapGesture)
        
        // 设备名称
        deviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        deviceNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        deviceNameLabel.text = "行者Pro"
        deviceNameLabel.textColor = UIColor(str: "#84888C")
        bgView.addSubview(deviceNameLabel)
        
        // 连接状态
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        connectionStatusLabel.textColor = UIColor(hex: "#A0A3A7")
        connectionStatusLabel.text = "  •未连接"
        connectionStatusLabel.backgroundColor = UIColor(str: "#DFE0E2")
        connectionStatusLabel.layer.masksToBounds = true
        connectionStatusLabel.layer.cornerRadius = 6
        bgView.addSubview(connectionStatusLabel)
        
        // IMEI
        imeiLabel.translatesAutoresizingMaskIntoConstraints = false
        imeiLabel.font = .systemFont(ofSize: 12)
        imeiLabel.textColor = UIColor(hex: "#303236")
        imeiLabel.text = "IMEI: --"
        bgView.addSubview(imeiLabel)
        
        // 蓝牙状态
        bluetoothStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        bluetoothStatusImageView.image = PersonalModule.image(named: "device_mini_noLine_bluetooth")
        bluetoothStatusImageView.contentMode = .scaleAspectFit
        bgView.addSubview(bluetoothStatusImageView)
        
        // 卫星状态
        satelliteStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        satelliteStatusImageView.image = PersonalModule.image(named: "device_mini_noLine_satellite")
        satelliteStatusImageView.contentMode = .scaleAspectFit
        bgView.addSubview(satelliteStatusImageView)
        
        // 电池状态
        batteryLevelImageView.translatesAutoresizingMaskIntoConstraints = false
        batteryLevelImageView.image = PersonalModule.image(named: "device_mini_noLine_battery")
        batteryLevelImageView.contentMode = .scaleAspectFit
        bgView.addSubview(batteryLevelImageView)
        
        // 电池电量
        batteryLevelLabel.translatesAutoresizingMaskIntoConstraints = false
        batteryLevelLabel.font = .systemFont(ofSize: 12, weight: .bold)
        batteryLevelLabel.textColor = .black
        batteryLevelLabel.text = "0%"
        batteryLevelLabel.isHidden = true
        bgView.addSubview(batteryLevelLabel)
        
        // 连接/断开按钮
        connectionButton.translatesAutoresizingMaskIntoConstraints = false
        connectionButton.setTitle("连接", for: .normal)
        connectionButton.backgroundColor = UIColor(hex: "#FE6A00")
        connectionButton.setTitleColor(.white, for: .normal)
        connectionButton.layer.cornerRadius = 6
        connectionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        connectionButton.addTarget(self, action: #selector(connectionButtonTapped), for: .touchUpInside)
        bgView.addSubview(connectionButton)

        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bgView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            // 设备图片
            deviceImageView.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 16),
            deviceImageView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            deviceImageView.widthAnchor.constraint(equalToConstant: 90),
            deviceImageView.heightAnchor.constraint(equalToConstant: 90),
            
            // 设备名称
            deviceNameLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 20),
            deviceNameLabel.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            
            // 连接状态
            connectionStatusLabel.centerYAnchor.constraint(equalTo: deviceNameLabel.centerYAnchor),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.trailingAnchor, constant: 10),
            connectionStatusLabel.widthAnchor.constraint(equalToConstant: 55),
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: 30),
            
            // IMEI
            imeiLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 10),
            imeiLabel.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            imeiLabel.trailingAnchor.constraint(lessThanOrEqualTo: bgView.trailingAnchor, constant: -16),
            
            // 蓝牙状态
            bluetoothStatusImageView.topAnchor.constraint(equalTo: imeiLabel.bottomAnchor, constant: 10),
            bluetoothStatusImageView.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            bluetoothStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            bluetoothStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 卫星状态
            satelliteStatusImageView.centerYAnchor.constraint(equalTo: bluetoothStatusImageView.centerYAnchor),
            satelliteStatusImageView.leadingAnchor.constraint(equalTo: bluetoothStatusImageView.trailingAnchor, constant: 5),
            satelliteStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            satelliteStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 电池状态
            batteryLevelImageView.centerYAnchor.constraint(equalTo: bluetoothStatusImageView.centerYAnchor),
            batteryLevelImageView.leadingAnchor.constraint(equalTo: satelliteStatusImageView.trailingAnchor, constant: 5),
            batteryLevelImageView.widthAnchor.constraint(equalToConstant: 16),
            batteryLevelImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 电池电量
            batteryLevelLabel.centerYAnchor.constraint(equalTo: bluetoothStatusImageView.centerYAnchor),
            batteryLevelLabel.leadingAnchor.constraint(equalTo: batteryLevelImageView.trailingAnchor, constant: 5),
            
            // 连接按钮
            connectionButton.topAnchor.constraint(equalTo: bluetoothStatusImageView.bottomAnchor, constant: 15),
            connectionButton.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            connectionButton.widthAnchor.constraint(equalToConstant: 60),
            connectionButton.heightAnchor.constraint(equalToConstant: 32),
            connectionButton.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - 设备图片连续点击处理
    @objc private func handleDeviceImageTap() {
        let currentTime = Date()
        
        // 如果是第一次点击或者距离上次点击超过时间间隔，重置计数器
        if lastTapTime == nil || currentTime.timeIntervalSince(lastTapTime!) > tapInterval {
            tapCount = 1
        } else {
            tapCount += 1
        }
        
        lastTapTime = currentTime
        
        print("设备图片点击次数: \(tapCount)")
        
        // 如果达到5次点击，触发回调并重置计数器
        if tapCount >= 5 {
            print("连续点击5次触发")
            quintupleTapAction?()
            resetTapCounter()
        }
    }
    
    // 重置点击计数器
    private func resetTapCounter() {
        tapCount = 0
        lastTapTime = nil
    }
    
    // MARK: - Actions
    @objc private func connectionButtonTapped() {
        print("连接按钮点击")
        self.connectionAction?()
    }
    
    // 配置方法
    func configure(with deviceName: String, imei: String) {
        deviceNameLabel.text = deviceName
        imeiLabel.text = "IMEI: \(imei)"
    }
    
    // 更改连接显示
    func changeStatus(isConnect: Bool) {
        if isConnect {
            deviceNameLabel.textColor = UIColor(str: "#070808")
            
            connectionStatusLabel.textColor = UIColor(hex: "#16C282")
            connectionStatusLabel.text = "  •已连接"
            connectionStatusLabel.backgroundColor = UIColor(hex: "#DFF5EA")
            
            connectionButton.setTitle("断开", for: .normal)
            connectionButton.backgroundColor = UIColor(hex: "#F2F3F4")
            connectionButton.setTitleColor(UIColor(hex: "#FE6A00"), for: .normal)
            
        }else {
            deviceNameLabel.textColor = UIColor(str: "#84888C")
            connectionStatusLabel.textColor = UIColor(hex: "#A0A3A7")
            connectionStatusLabel.text = "  •未连接"
            connectionStatusLabel.backgroundColor = UIColor(hex: "#DFE0E2")
            
            connectionButton.setTitle("连接", for: .normal)
            connectionButton.backgroundColor = UIColor(hex: "#FE6A00")
            connectionButton.setTitleColor(.white, for: .normal)
            
            batteryLevelLabel.isHidden = true
            bluetoothStatusImageView.image = PersonalModule.image(named: "device_mini_noLine_bluetooth")
            satelliteStatusImageView.image = PersonalModule.image(named: "device_mini_noLine_satellite")
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_noLine_battery")
        }
    }
    // 更改电池，卫星，蓝牙状态
    func updateMsg(_ statusInfo: StatusInfo) {
        // 同时更新基本信息中的电池电量
        batteryLevelLabel.isHidden = false
        batteryLevelLabel.text = "\(statusInfo.battery)%"
        
        let bleStatus = (statusInfo.moduleStatus & 0x01)
        let satelliteStatus = (statusInfo.moduleStatus & 0x02)
        bluetoothStatusImageView.image = bleStatus != 0 ? PersonalModule.image(named: "device_mini_noLine_bluetooth") : PersonalModule.image(named: "device_mini_line_bluetooth")
        satelliteStatusImageView.image = satelliteStatus != 0 ? PersonalModule.image(named: "device_mini_noLine_satellite") : PersonalModule.image(named: "device_mini_line_satellite")
        if statusInfo.battery >= 80 {
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_line_battery")
        }else if statusInfo.battery >= 60 {
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_line_battery2")
        }else if statusInfo.battery >= 40 {
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_line_battery3")
        }else if statusInfo.battery >= 20 {
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_line_battery4")
        }else if statusInfo.battery >= 0 {
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_line_battery5")
        }else {
            batteryLevelImageView.image = PersonalModule.image(named: "device_mini_noLine_battery")
        }
    }
    
    
    // 可以在cell重用前重置状态
    override func prepareForReuse() {
        super.prepareForReuse()
        resetTapCounter()
    }
}
