//
//  Pro.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

class ProDeviceBaseMsgCell: UITableViewCell {
    
    private let bgView = UIView()
    private var deviceNameLabel = UILabel()
    private var connectionStatusLabel = UILabel()
    private var wifiStatusImageView = UIImageView()
    private var satelliteStatusImageView = UIImageView()
    private var nowModelLabel = UILabel()
    private let deviceImageView = UIImageView()
    private let satelliteImageView = UIImageView()
    private let upArrowImageView = UIImageView()
    private let downArrowImageView = UIImageView()
    private let upNetworkMsgView = UIView()
    private var upNetworkSpeedLabel = UILabel()
    private var upNetworkSignalImageView = UIImageView()
    private var upNetworkSignalLabel = UILabel()
    private let downNetworkMsgView = UIView()
    private var downNetworkSpeedLabel = UILabel()
    private var downNetworkSignalImageView = UIImageView()
    private var downNetworkSignalLabel = UILabel()
    private let upNoDataLabel = UILabel()
    private let downNoDataLabel = UILabel()
    
    // 新增点击计数器和时间记录
    private var tapCount = 0
    private var lastTapTime: Date?
    private let tapInterval: TimeInterval = 5.0 // 2秒内完成5次点击
    
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
        
        // wifi状态
        wifiStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        wifiStatusImageView.image = PersonalModule.image(named: "device_pro_noLine_wifi")
        wifiStatusImageView.contentMode = .scaleAspectFit
        bgView.addSubview(wifiStatusImageView)
        
        // 卫星状态
        satelliteStatusImageView.translatesAutoresizingMaskIntoConstraints = false
        satelliteStatusImageView.image = PersonalModule.image(named: "device_mini_noLine_satellite")
        satelliteStatusImageView.contentMode = .scaleAspectFit
        bgView.addSubview(satelliteStatusImageView)
        
        // 车载状态
        nowModelLabel.translatesAutoresizingMaskIntoConstraints = false
        nowModelLabel.text = "当前模式：车载模式"
        nowModelLabel.textColor = .black
        nowModelLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bgView.addSubview(nowModelLabel)
        
        // 设备图片
        deviceImageView.translatesAutoresizingMaskIntoConstraints = false
        deviceImageView.contentMode = .scaleAspectFill
        deviceImageView.image = PersonalModule.image(named: "device_pro_logo")
        deviceImageView.isUserInteractionEnabled = true // 启用用户交互
        bgView.addSubview(deviceImageView)
        
        // 添加点击手势识别器
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeviceImageTap))
        deviceImageView.addGestureRecognizer(tapGesture)
        // 卫星图片
        satelliteImageView.translatesAutoresizingMaskIntoConstraints = false
        satelliteImageView.contentMode = .scaleAspectFill
        satelliteImageView.image = PersonalModule.image(named: "device_pro_logo2")
        bgView.addSubview(satelliteImageView)
        
        // 上方箭头图片
        upArrowImageView.translatesAutoresizingMaskIntoConstraints = false
        upArrowImageView.contentMode = .scaleAspectFill
        upArrowImageView.image = PersonalModule.image(named: "device_pro_arrow1")
        bgView.addSubview(upArrowImageView)
        
        // 下方箭头图片
        downArrowImageView.translatesAutoresizingMaskIntoConstraints = false
        downArrowImageView.contentMode = .scaleAspectFill
        downArrowImageView.image = PersonalModule.image(named: "device_pro_arrow2")
        bgView.addSubview(downArrowImageView)
        
        // 上方没有数据时文字
        upNoDataLabel.translatesAutoresizingMaskIntoConstraints = false
        upNoDataLabel.text = "--"
        upNoDataLabel.textColor = UIColor(str: "#C4C7CA")
        upNoDataLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bgView.addSubview(upNoDataLabel)
        
        // 下方没有数据时文字
        downNoDataLabel.translatesAutoresizingMaskIntoConstraints = false
        downNoDataLabel.text = "--"
        downNoDataLabel.textColor = UIColor(str: "#C4C7CA")
        downNoDataLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bgView.addSubview(downNoDataLabel)
        
        // 上方数据
        upNetworkMsgView.translatesAutoresizingMaskIntoConstraints = false
        upNetworkMsgView.backgroundColor = .white
        upNetworkMsgView.isHidden = false
        bgView.addSubview(upNetworkMsgView)
        
        upNetworkSpeedLabel.translatesAutoresizingMaskIntoConstraints = false
        upNetworkSpeedLabel.text = "--kb/s"
        upNetworkSpeedLabel.textColor = UIColor(str: "#303236")
        upNetworkSpeedLabel.font = .systemFont(ofSize: 12, weight: .regular)
        upNetworkMsgView.addSubview(upNetworkSpeedLabel)
        
        upNetworkSignalImageView.translatesAutoresizingMaskIntoConstraints = false
        upNetworkSignalImageView.contentMode = .scaleAspectFit
        upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-00")
        upNetworkMsgView.addSubview(upNetworkSignalImageView)
        
        upNetworkSignalLabel.translatesAutoresizingMaskIntoConstraints = false
        upNetworkSignalLabel.text = "--db"
        upNetworkSignalLabel.textColor = UIColor(str: "#303236")
        upNetworkSignalLabel.font = .systemFont(ofSize: 12, weight: .regular)
        upNetworkMsgView.addSubview(upNetworkSignalLabel)
        
        // 下方数据
        downNetworkMsgView.translatesAutoresizingMaskIntoConstraints = false
        downNetworkMsgView.backgroundColor = .white
        downNetworkMsgView.isHidden = false
        bgView.addSubview(downNetworkMsgView)
        
        downNetworkSpeedLabel.translatesAutoresizingMaskIntoConstraints = false
        downNetworkSpeedLabel.text = "--kb/s"
        downNetworkSpeedLabel.textColor = UIColor(str: "#303236")
        downNetworkSpeedLabel.font = .systemFont(ofSize: 12, weight: .regular)
        downNetworkMsgView.addSubview(downNetworkSpeedLabel)
        
        downNetworkSignalImageView.translatesAutoresizingMaskIntoConstraints = false
        downNetworkSignalImageView.contentMode = .scaleAspectFit
        downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-00")
        downNetworkMsgView.addSubview(downNetworkSignalImageView)
        
        downNetworkSignalLabel.translatesAutoresizingMaskIntoConstraints = false
        downNetworkSignalLabel.text = "--db"
        downNetworkSignalLabel.textColor = UIColor(str: "#303236")
        downNetworkSignalLabel.font = .systemFont(ofSize: 12, weight: .regular)
        downNetworkMsgView.addSubview(downNetworkSignalLabel)
        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bgView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            // 设备名称
            deviceNameLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 20),
            deviceNameLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            // 连接状态
            connectionStatusLabel.centerYAnchor.constraint(equalTo: deviceNameLabel.centerYAnchor),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.trailingAnchor, constant: 10),
            connectionStatusLabel.widthAnchor.constraint(equalToConstant: 55),
            connectionStatusLabel.heightAnchor.constraint(equalToConstant: 30),
            
            wifiStatusImageView.centerYAnchor.constraint(equalTo: deviceNameLabel.centerYAnchor),
            wifiStatusImageView.leadingAnchor.constraint(equalTo: connectionStatusLabel.trailingAnchor, constant: 10),
            wifiStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            wifiStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 卫星状态
            satelliteStatusImageView.centerYAnchor.constraint(equalTo: wifiStatusImageView.centerYAnchor),
            satelliteStatusImageView.leadingAnchor.constraint(equalTo: wifiStatusImageView.trailingAnchor, constant: 8),
            satelliteStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            satelliteStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 当前模式
            nowModelLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 16),
            nowModelLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            // 设备图片
            deviceImageView.topAnchor.constraint(equalTo: nowModelLabel.bottomAnchor, constant: 12),
            deviceImageView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            deviceImageView.widthAnchor.constraint(equalToConstant: 72),
            deviceImageView.heightAnchor.constraint(equalToConstant: 72),
            
            // 卫星图片
            satelliteImageView.topAnchor.constraint(equalTo: nowModelLabel.bottomAnchor, constant: 12),
            satelliteImageView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            satelliteImageView.widthAnchor.constraint(equalToConstant: 72),
            satelliteImageView.heightAnchor.constraint(equalToConstant: 72),
            
            // 上方箭头图片
            upArrowImageView.centerYAnchor.constraint(equalTo: deviceImageView.centerYAnchor, constant: -7),
            upArrowImageView.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            upArrowImageView.trailingAnchor.constraint(equalTo: satelliteImageView.leadingAnchor, constant: -16),
            upArrowImageView.heightAnchor.constraint(equalToConstant: 4),
            // 下方箭头图片
            downArrowImageView.centerYAnchor.constraint(equalTo: deviceImageView.centerYAnchor, constant: 7),
            downArrowImageView.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            downArrowImageView.trailingAnchor.constraint(equalTo: satelliteImageView.leadingAnchor, constant: -16),
            downArrowImageView.heightAnchor.constraint(equalToConstant: 4),
            // 上方没数据的
            upNoDataLabel.bottomAnchor.constraint(equalTo: upArrowImageView.topAnchor, constant: -5),
            upNoDataLabel.centerXAnchor.constraint(equalTo: upArrowImageView.centerXAnchor),
            // 下方没数据的
            downNoDataLabel.topAnchor.constraint(equalTo: downArrowImageView.bottomAnchor, constant: 2),
            downNoDataLabel.centerXAnchor.constraint(equalTo: downArrowImageView.centerXAnchor),
            // 上方有数据的
            upNetworkMsgView.bottomAnchor.constraint(equalTo: upArrowImageView.topAnchor, constant: -5),
            upNetworkMsgView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            upNetworkSpeedLabel.bottomAnchor.constraint(equalTo: upNetworkMsgView.bottomAnchor),
            upNetworkSpeedLabel.leadingAnchor.constraint(equalTo: upNetworkMsgView.leadingAnchor),
            upNetworkSpeedLabel.topAnchor.constraint(equalTo: upNetworkMsgView.topAnchor),
            
            upNetworkSignalImageView.centerYAnchor.constraint(equalTo: upNetworkMsgView.centerYAnchor),
            upNetworkSignalImageView.leadingAnchor.constraint(equalTo: upNetworkSpeedLabel.trailingAnchor, constant: 8),
            upNetworkSignalImageView.widthAnchor.constraint(equalToConstant: 12),
            upNetworkSignalImageView.heightAnchor.constraint(equalToConstant: 12),
            
            upNetworkSignalLabel.bottomAnchor.constraint(equalTo: upNetworkMsgView.bottomAnchor),
            upNetworkSignalLabel.leadingAnchor.constraint(equalTo: upNetworkSignalImageView.trailingAnchor, constant: 2),
            upNetworkSignalLabel.trailingAnchor.constraint(equalTo: upNetworkMsgView.trailingAnchor),
            upNetworkSignalLabel.topAnchor.constraint(equalTo: upNetworkMsgView.topAnchor),
            
            // 下方有数据的
            downNetworkMsgView.topAnchor.constraint(equalTo: downArrowImageView.bottomAnchor, constant: 2),
            downNetworkMsgView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            downNetworkSpeedLabel.bottomAnchor.constraint(equalTo: downNetworkMsgView.bottomAnchor),
            downNetworkSpeedLabel.leadingAnchor.constraint(equalTo: downNetworkMsgView.leadingAnchor),
            downNetworkSpeedLabel.topAnchor.constraint(equalTo: downNetworkMsgView.topAnchor),
            
            downNetworkSignalImageView.centerYAnchor.constraint(equalTo: downNetworkMsgView.centerYAnchor),
            downNetworkSignalImageView.leadingAnchor.constraint(equalTo: downNetworkSpeedLabel.trailingAnchor, constant: 8),
            downNetworkSignalImageView.widthAnchor.constraint(equalToConstant: 12),
            downNetworkSignalImageView.heightAnchor.constraint(equalToConstant: 12),
            
            downNetworkSignalLabel.bottomAnchor.constraint(equalTo: downNetworkMsgView.bottomAnchor),
            downNetworkSignalLabel.leadingAnchor.constraint(equalTo: downNetworkSignalImageView.trailingAnchor, constant: 2),
            downNetworkSignalLabel.trailingAnchor.constraint(equalTo: downNetworkMsgView.trailingAnchor),
            downNetworkSignalLabel.topAnchor.constraint(equalTo: downNetworkMsgView.topAnchor),
            
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
    @objc private func modeCatTapped() {
        print("车载按钮点击")
        nowModelLabel.text = "当前模式：车载模式"
    }
    
    @objc private func modeGroundTapped() {
        print("地面按钮点击")
        nowModelLabel.text = "当前模式：地面模式"
    }
    
    // 对星完成更新模式
    func updateModeChooseAndCollecitonUI(with status: ProDeviceStatus) {
        if status.mode == 0 {
            modeGroundTapped()
        }
        if status.mode == 1 {
            modeCatTapped()
        }
        if status.antennaStatus == .stableTracking {
            satelliteStatusImageView.image = PersonalModule.image(named: "device_mini_line_satellite")
            upNetworkMsgView.isHidden = false
            downNetworkMsgView.isHidden = false

        }else {
            satelliteStatusImageView.image = PersonalModule.image(named: "device_mini_noLine_satellite")
            upNetworkMsgView.isHidden = true
            downNetworkMsgView.isHidden = true
            
        }
        
    }
    
    // 配置方法
    func configure(with quintupleTapAction: (() -> Void)?) {
        self.quintupleTapAction = quintupleTapAction
    }
    
    // 更改状态
    func changeStatus(isConnect: Bool) {
        if isConnect {
            deviceNameLabel.textColor = UIColor(str: "#070808")
            connectionStatusLabel.textColor = UIColor(hex: "#16C282")
            connectionStatusLabel.text = "  •已连接"
            connectionStatusLabel.backgroundColor = UIColor(hex: "#DFF5EA")
            wifiStatusImageView.image = PersonalModule.image(named: "device_pro_line_wifi")
        }else {
            deviceNameLabel.textColor = UIColor(str: "#84888C")
            connectionStatusLabel.textColor = UIColor(hex: "#A0A3A7")
            connectionStatusLabel.text = "  •未连接"
            connectionStatusLabel.backgroundColor = UIColor(hex: "#DFE0E2")
            wifiStatusImageView.image = PersonalModule.image(named: "device_pro_noLine_wifi")
        }
    }
    
    func updateNetworkSpeed(upText: String, downText: String) {
        DispatchQueue.main.async {
            self.upNetworkSpeedLabel.text = upText
            self.downNetworkSpeedLabel.text = downText
        }
    }
    
    func updateNetworkSNR(rxSnr: Int, txSnr: Int) {
        let rxSnrNum = rxSnr/10
        if (rxSnrNum <= 0){
            upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-00")
        }else if (rxSnrNum < 4){
            upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-01")
        }else if (rxSnrNum < 8){
            upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-02")
        }else if (rxSnrNum < 11){
            upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-03")
        }else if (rxSnrNum < 14){
            upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-04")
        }else{
            upNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-05")
        }
        upNetworkSignalLabel.text = "\(rxSnrNum)dB"
        let txSnrNum = txSnr/10
        if (txSnrNum <= 0){
            downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-00")
        }else if (txSnrNum < 4){
            downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-01")
        }else if (txSnrNum < 8){
            downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-02")
        }else if (txSnrNum < 11){
            downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-03")
        }else if (txSnrNum < 14){
            downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-04")
        }else{
            downNetworkSignalImageView.image = PersonalModule.image(named: "signal-full-05")
        }
        downNetworkSignalLabel.text = "\(txSnrNum)dB"
    }

    
    // 可以在cell重用前重置状态
    override func prepareForReuse() {
        super.prepareForReuse()
        resetTapCounter()
    }
}
