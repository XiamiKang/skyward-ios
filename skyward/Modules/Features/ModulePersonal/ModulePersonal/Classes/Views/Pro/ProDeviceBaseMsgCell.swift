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
    private let deviceImageView = UIImageView()
    private let deviceNameLabel = UILabel()
    private let connectionStatusLabel = UILabel()
    private let wifiStatusImageView = UIImageView()
    private let modeCatImageView = UIImageView()
    private let modeGroundImageView = UIImageView()
    private let modeCatLabel = UILabel()
    private let modeGroundLabel = UILabel()
    private let modeCatButton = UIButton(type: .custom)
    private let modeGroundButton = UIButton(type: .custom)
    private let satelliteStatusImageView = UIImageView()
    private let collectButton = UIButton(type: .custom)
    private let lineStarButton = UIButton(type: .custom)
    
    // 新增活动指示器
    private let collectActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let lineStarActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    // 新增点击计数器和时间记录
    private var tapCount = 0
    private var lastTapTime: Date?
    private let tapInterval: TimeInterval = 5.0 // 2秒内完成5次点击
    
    var collectionAction: (() -> Void)?
    var lineStarAction: (() -> Void)?
    var quintupleTapAction: (() -> Void)? // 新增：连续点击5次的回调
    var resendModlAction: ((Int) -> Void)?
    
    // 按钮状态
    private var isCollecting = false {
        didSet {
            updateCollectButtonState()
        }
    }
    
    private var isLiningStar = false {
        didSet {
            updateLineStarButtonState()
        }
    }
    
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
        deviceImageView.image = PersonalModule.image(named: "device_pro_logo")
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
        modeCatImageView.translatesAutoresizingMaskIntoConstraints = false
        modeCatImageView.image = PersonalModule.image(named: "device_pro_mode_sel")
        bgView.addSubview(modeCatImageView)
        modeCatLabel.translatesAutoresizingMaskIntoConstraints = false
        modeCatLabel.text = "车载模式"
        modeCatLabel.textColor = .black
        modeCatLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bgView.addSubview(modeCatLabel)
        modeCatButton.translatesAutoresizingMaskIntoConstraints = false
        modeCatButton.backgroundColor = .clear
        modeCatButton.addTarget(self, action: #selector(modeCatTapped), for: .touchUpInside)
        bgView.addSubview(modeCatButton)
        
        // 地面状态
        modeGroundImageView.translatesAutoresizingMaskIntoConstraints = false
        modeGroundImageView.image = PersonalModule.image(named: "device_pro_mode")
        bgView.addSubview(modeGroundImageView)
        modeGroundLabel.translatesAutoresizingMaskIntoConstraints = false
        modeGroundLabel.text = "地面模式"
        modeGroundLabel.textColor = .black
        modeGroundLabel.font = .systemFont(ofSize: 12, weight: .regular)
        bgView.addSubview(modeGroundLabel)
        modeGroundButton.translatesAutoresizingMaskIntoConstraints = false
        modeGroundButton.backgroundColor = .clear
        modeGroundButton.addTarget(self, action: #selector(modeGroundTapped), for: .touchUpInside)
        bgView.addSubview(modeGroundButton)
        
        // 收藏按钮
        collectButton.translatesAutoresizingMaskIntoConstraints = false
        collectButton.setTitle("收藏", for: .normal)
        collectButton.backgroundColor = UIColor(str: "#F2F3F4")
        collectButton.setTitleColor(UIColor(hex: "#C4C7CA"), for: .normal)
        collectButton.layer.cornerRadius = 6
        collectButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        collectButton.addTarget(self, action: #selector(collectionButtonTapped), for: .touchUpInside)
        bgView.addSubview(collectButton)
        
        // 收藏按钮活动指示器
        collectActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        collectActivityIndicator.hidesWhenStopped = true
        collectActivityIndicator.color = UIColor(hex: "#FE6A00")
        collectButton.addSubview(collectActivityIndicator)
        
        // 对星按钮
        lineStarButton.translatesAutoresizingMaskIntoConstraints = false
        lineStarButton.setTitle("对星", for: .normal)
        lineStarButton.backgroundColor = UIColor(str: "#FE6A00")
        lineStarButton.setTitleColor(.white, for: .normal)
        lineStarButton.layer.cornerRadius = 6
        lineStarButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        lineStarButton.addTarget(self, action: #selector(lineStarButtonTapped), for: .touchUpInside)
        bgView.addSubview(lineStarButton)
        
        // 对星按钮活动指示器
        lineStarActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        lineStarActivityIndicator.hidesWhenStopped = true
        lineStarActivityIndicator.color = .white
        lineStarButton.addSubview(lineStarActivityIndicator)

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
            
            // 蓝牙状态
            wifiStatusImageView.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 10),
            wifiStatusImageView.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            wifiStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            wifiStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 卫星状态
            satelliteStatusImageView.centerYAnchor.constraint(equalTo: wifiStatusImageView.centerYAnchor),
            satelliteStatusImageView.leadingAnchor.constraint(equalTo: wifiStatusImageView.trailingAnchor, constant: 5),
            satelliteStatusImageView.widthAnchor.constraint(equalToConstant: 16),
            satelliteStatusImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // 车载模式
            modeCatImageView.topAnchor.constraint(equalTo: wifiStatusImageView.bottomAnchor, constant: 16),
            modeCatImageView.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            modeCatImageView.widthAnchor.constraint(equalToConstant: 12),
            modeCatImageView.heightAnchor.constraint(equalToConstant: 12),
            modeCatLabel.centerYAnchor.constraint(equalTo: modeCatImageView.centerYAnchor),
            modeCatLabel.leadingAnchor.constraint(equalTo: modeCatImageView.trailingAnchor, constant: 5),
            modeCatButton.centerYAnchor.constraint(equalTo: modeCatImageView.centerYAnchor),
            modeCatButton.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 15),
            modeCatButton.widthAnchor.constraint(equalToConstant: 80),
            modeCatButton.heightAnchor.constraint(equalToConstant: 22),
            
            // 地面模式
            modeGroundImageView.topAnchor.constraint(equalTo: wifiStatusImageView.bottomAnchor, constant: 16),
            modeGroundImageView.leadingAnchor.constraint(equalTo: modeCatButton.trailingAnchor, constant: 16),
            modeGroundImageView.widthAnchor.constraint(equalToConstant: 12),
            modeGroundImageView.heightAnchor.constraint(equalToConstant: 12),
            modeGroundLabel.centerYAnchor.constraint(equalTo: modeGroundImageView.centerYAnchor),
            modeGroundLabel.leadingAnchor.constraint(equalTo: modeGroundImageView.trailingAnchor, constant: 5),
            modeGroundButton.centerYAnchor.constraint(equalTo: modeGroundImageView.centerYAnchor),
            modeGroundButton.leadingAnchor.constraint(equalTo: modeCatButton.trailingAnchor, constant: 15),
            modeGroundButton.widthAnchor.constraint(equalToConstant: 80),
            modeGroundButton.heightAnchor.constraint(equalToConstant: 22),
            
            // 收藏按钮
            collectButton.topAnchor.constraint(equalTo: modeCatButton.bottomAnchor, constant: 15),
            collectButton.leadingAnchor.constraint(equalTo: deviceImageView.trailingAnchor, constant: 16),
            collectButton.widthAnchor.constraint(equalToConstant: 90), // 增加宽度容纳指示器
            collectButton.heightAnchor.constraint(equalToConstant: 32),
            collectButton.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -16),
            
            // 收藏按钮活动指示器
            collectActivityIndicator.centerYAnchor.constraint(equalTo: collectButton.centerYAnchor),
            collectActivityIndicator.leadingAnchor.constraint(equalTo: collectButton.leadingAnchor, constant: 12),
            
            // 对星按钮
            lineStarButton.centerYAnchor.constraint(equalTo: collectButton.centerYAnchor),
            lineStarButton.leadingAnchor.constraint(equalTo: collectButton.trailingAnchor, constant: 16),
            lineStarButton.widthAnchor.constraint(equalToConstant: 90), // 增加宽度容纳指示器
            lineStarButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 对星按钮活动指示器
            lineStarActivityIndicator.centerYAnchor.constraint(equalTo: lineStarButton.centerYAnchor),
            lineStarActivityIndicator.leadingAnchor.constraint(equalTo: lineStarButton.leadingAnchor, constant: 12),
        ])
    }
    
    // MARK: - 按钮状态更新
    private func updateCollectButtonState() {
        if isCollecting {
            // 显示等待状态
            collectButton.setTitle("收藏中", for: .normal)
            collectButton.isEnabled = false
            collectButton.setTitleColor(UIColor(str: "#FE6A00"), for: .normal)
            collectActivityIndicator.startAnimating()
            
            // 调整标题位置
            collectButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        } else {
            // 恢复正常状态
            collectButton.setTitle("收藏", for: .normal)
            collectButton.isEnabled = true
            collectButton.setTitleColor(UIColor(str: "#C4C7CA"), for: .normal)
            collectActivityIndicator.stopAnimating()
            
            // 重置标题位置
            collectButton.titleEdgeInsets = .zero
        }
    }
    
    private func updateLineStarButtonState() {
        if isLiningStar {
            // 显示等待状态
            lineStarButton.setTitle("对星中", for: .normal)
            lineStarButton.isEnabled = false
            lineStarButton.backgroundColor = UIColor(str: "#FE6A00").withAlphaComponent(0.7)
            lineStarActivityIndicator.startAnimating()
            
            // 调整标题位置
            lineStarButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        } else {
            // 恢复正常状态
            lineStarButton.setTitle("对星", for: .normal)
            lineStarButton.isEnabled = true
            lineStarButton.backgroundColor = UIColor(str: "#FE6A00")
            lineStarActivityIndicator.stopAnimating()
            
            // 重置标题位置
            lineStarButton.titleEdgeInsets = .zero
        }
    }
    
    // MARK: - 公开方法
    func startCollecting() {
        isCollecting = true
    }
    
    func stopCollecting() {
        isCollecting = false
    }
    
    func startLiningStar() {
        isLiningStar = true
    }
    
    func stopLiningStar() {
        isLiningStar = false
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
        resendModlAction?(1)
        modeCatImageView.image = PersonalModule.image(named: "device_pro_mode_sel")
        modeGroundImageView.image = PersonalModule.image(named: "device_pro_mode")
    }
    
    @objc private func modeGroundTapped() {
        print("地面按钮点击")
        resendModlAction?(0)
        modeCatImageView.image = PersonalModule.image(named: "device_pro_mode")
        modeGroundImageView.image = PersonalModule.image(named: "device_pro_mode_sel")
    }
    
    @objc private func collectionButtonTapped() {
        print("收藏按钮点击")
        
        // 开始收藏动画
        startCollecting()
        
        // 延迟执行回调，模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.collectionAction?()
        }
    }
    
    @objc private func lineStarButtonTapped() {
        print("对星按钮点击")
        
        // 开始对星动画
        startLiningStar()
        
        // 延迟执行回调，模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lineStarAction?()
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
            wifiStatusImageView.image = PersonalModule.image(named: "device_pro_noline_wifi")
        }
    }
    
    
    // 可以在cell重用前重置状态
    override func prepareForReuse() {
        super.prepareForReuse()
        resetTapCounter()
        stopCollecting()
        stopLiningStar()
    }
}
