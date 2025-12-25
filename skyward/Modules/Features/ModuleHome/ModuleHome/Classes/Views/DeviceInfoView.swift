//
//  DeviceInfoView.swift
//  ModuleHome
//
//  Created by 赵波 on 2025/11/20.
//

import UIKit

class DeviceInfoView: UIView {
    
    // MARK: - Public Properties
    
    var deviceName: String = "" {
        didSet {
            nameLabel.text = deviceName
        }
    }
    
    /// 设置连接图标（如蓝牙/Wi-Fi 图标）
    var connectionIcon: UIImage? {
        didSet {
            connectionImageView.image = connectionIcon
        }
    }
    
    /// 设置卫星图标
    var satelliteIcon: UIImage? {
        didSet {
            satelliteImageView.image = satelliteIcon
        }
    }
    
    /// 电池电量百分比（0~100），设置后自动显示电池区域；设为 nil 则隐藏
    var batteryLevel: UInt8? {
        didSet {
            if let level = batteryLevel {
                batteryLabel.text = "\(level)%"
                batteryContainerView.isHidden = false
                if level >= 0 && level < 20 {
                    batteryIconImageView.image = HomeModule.image(named: "device_battery_0")
                } else if level >= 20 && level < 40 {
                    batteryIconImageView.image = HomeModule.image(named: "device_battery_20")
                } else if level >= 40 && level < 60 {
                    batteryIconImageView.image = HomeModule.image(named: "device_battery_40")
                } else if level >= 60 && level < 80 {
                    batteryIconImageView.image = HomeModule.image(named: "device_battery_60")
                } else if level >= 80 && level <= 100 {
                    batteryIconImageView.image = HomeModule.image(named: "device_battery_80")
                } else {
                    
                }
                
            } else {
                batteryContainerView.isHidden = true
            }
        }
    }
    
    // MARK: - Private Subviews
    
    public let nameLabel = UILabel()
    public let connectionImageView = UIImageView()
    public let satelliteImageView = UIImageView()
    public let batteryContainerView = UIView()
    private let batteryIconImageView = UIImageView()
    public let batteryLabel = UILabel()
    private let rightStackView = UIStackView()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        // 设备名称
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        nameLabel.textColor = .black
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // 连接图标
        connectionImageView.contentMode = .scaleAspectFit
        connectionImageView.translatesAutoresizingMaskIntoConstraints = false
        connectionImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        connectionImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        // 卫星图标
        satelliteImageView.contentMode = .scaleAspectFit
        satelliteImageView.translatesAutoresizingMaskIntoConstraints = false
        satelliteImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        satelliteImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        // 电池图标
        batteryIconImageView.contentMode = .scaleAspectFit
        batteryIconImageView.translatesAutoresizingMaskIntoConstraints = false
        batteryIconImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        batteryIconImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        // 电池百分比文本
        batteryLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        batteryLabel.textColor = .black
        batteryLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        batteryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        batteryLabel.translatesAutoresizingMaskIntoConstraints = false
        batteryLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        batteryLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        // 创建电池容器视图，并添加子视图：电池图标和电池百分比文本
        batteryContainerView.translatesAutoresizingMaskIntoConstraints = false
        batteryContainerView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        batteryContainerView.isHidden = true
        batteryContainerView.addSubview(batteryIconImageView)
        batteryContainerView.addSubview(batteryLabel)
        
        // 使用 Auto Layout 布局电池容器视图内的控件
        NSLayoutConstraint.activate([
            batteryIconImageView.leadingAnchor.constraint(equalTo: batteryContainerView.leadingAnchor, constant: 4),
            batteryIconImageView.centerYAnchor.constraint(equalTo: batteryContainerView.centerYAnchor),
            
            batteryLabel.leadingAnchor.constraint(equalTo: batteryIconImageView.trailingAnchor, constant: 4),
            batteryLabel.trailingAnchor.constraint(equalTo: batteryContainerView.trailingAnchor),
            batteryLabel.centerYAnchor.constraint(equalTo: batteryContainerView.centerYAnchor)
        ]);
        
        
        // 右侧总 stack（连接图标 | 卫星 | 电池）
        rightStackView.axis = .horizontal
        rightStackView.spacing = 4 // 图标之间默认间距 4
        rightStackView.alignment = .center
        rightStackView.distribution = .fill
        
        // 添加子视图到 rightStackView
        rightStackView.addArrangedSubview(connectionImageView)
        rightStackView.addArrangedSubview(satelliteImageView)
        rightStackView.addArrangedSubview(batteryContainerView)
        
        // 整体布局
        addSubview(nameLabel)
        addSubview(rightStackView)
        
        // 启用 Auto Layout
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        rightStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 垂直居中
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // 水平排列：名称在左，stack 在右
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            rightStackView.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            trailingAnchor.constraint(equalTo: rightStackView.trailingAnchor),
            
            // 高度自适应内容
            heightAnchor.constraint(greaterThanOrEqualTo: nameLabel.heightAnchor),
            heightAnchor.constraint(greaterThanOrEqualTo: rightStackView.heightAnchor)
        ])
    }
}
