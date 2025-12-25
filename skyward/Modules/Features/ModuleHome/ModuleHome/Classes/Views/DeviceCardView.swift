//
//  DeviceCardView.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/21.
//

import TXKit
import SWKit
import SWTheme

class DeviceCardView: UIView {
    
    // MARK: - Public Properties
    
    /// 是否有设备连接
    var hasDevice: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    /// 是否处于选中状态
    var isSelected: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    /// 是否处于连接状态
    var isConnected: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    /// 设备名称
    var deviceName: String? {
        didSet {
            deviceInfoView.deviceName = deviceName ?? ""
        }
    }
    
    /// 设置连接图标
    var connectionIcon: UIImage? {
        didSet {
            deviceInfoView.connectionIcon = connectionIcon
        }
    }
    
    /// 设置连接图标
    var satelliteIcon: UIImage? {
        didSet {
            deviceInfoView.satelliteIcon = satelliteIcon
        }
    }
    
    /// 点击事件回调
    var onTap: (() -> Void)?
    
    // MARK: - Private Subviews
    
    private let deviceInfoView = DeviceInfoView()
    private let arrowImageView = UIImageView()
    private let tapGesture = UITapGestureRecognizer()
    
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
        // 设置背景色
        backgroundColor = ThemeManager.current.mediumGrayBGColor
        clipsToBounds = true
        layer.cornerRadius = CornerRadius.medium.rawValue
        
        // 配置设备信息视图
        deviceInfoView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置箭头图标
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        arrowImageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        // 添加子视图
        addSubview(deviceInfoView)
        addSubview(arrowImageView)
        
        // 配置点击手势
        tapGesture.addTarget(self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // 设置布局
        NSLayoutConstraint.activate([
            // 设备信息视图约束
            deviceInfoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            deviceInfoView.centerYAnchor.constraint(equalTo: centerYAnchor),
            deviceInfoView.trailingAnchor.constraint(lessThanOrEqualTo: arrowImageView.leadingAnchor, constant: -8),
            
            // 箭头图标约束
            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            arrowImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // 初始更新UI
        updateUI()
    }
    
    // MARK: - Private Methods
    
    private func updateUI() {
        // 更新边框
        layer.borderWidth = isSelected && hasDevice ? 1.0 / ScreenUtil.scale  : 0.0
        layer.borderColor = UIColor.black.cgColor
        
        // 更新设备信息视图中的名称颜色
        if hasDevice {
            deviceInfoView.connectionImageView.isHidden = false
            deviceInfoView.satelliteImageView.isHidden = false
            if isConnected {
                deviceInfoView.nameLabel.textColor = .black
                
            } else {
                deviceInfoView.nameLabel.textColor = .gray
            }
            
            // 更新箭头方向（有设备时）
            let arrowDirection = isSelected ? HomeModule.image(named: "device_arrow_up") : HomeModule.image(named: "device_arrow_down")
            arrowImageView.image = arrowDirection
        } else {
            // 无设备状态
            deviceInfoView.nameLabel.textColor = .gray
            // 隐藏所有图标
            deviceInfoView.connectionImageView.isHidden = true
            deviceInfoView.satelliteImageView.isHidden = true
            // 箭头始终朝右
            arrowImageView.image = HomeModule.image(named: "device_arrow_right")
        }
    }
    
    @objc private func handleTap() {
        // 点击时切换选中状态（只有在有设备时才切换）
        if hasDevice {
            isSelected.toggle()
        }
        // 调用回调
        onTap?()
    }
}
