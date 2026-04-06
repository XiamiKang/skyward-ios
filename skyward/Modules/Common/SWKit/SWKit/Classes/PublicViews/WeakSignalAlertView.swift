//
//  WeakSignalAlertView.swift
//  SWKit
//
//  Created by TXTS on 2026/3/20.
//

import UIKit

public enum AlertState {
    case warn
    case danger
    
    var backgroundColor: UIColor {
        switch self {
        case .warn:
            return UIColor(str: "#FF9447")
        case .danger:
            return UIColor(str: "#F7594B")
        }
    }
}

public class WeakSignalAlertView: UIView {
    
    // MARK: - 公开属性
    public var state: AlertState = .warn {
        didSet {
            updateAppearanceForCurrentState()
        }
    }
    
    // 如果需要动态修改文字
    public var message: String? {
        didSet {
            messageLabel.text = message
        }
    }
    
    // MARK: - UI 组件
    private let warnImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = SWKitModule.image(named: "tips_warn_icon")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "信号预警：西南方向10公里后进入卫星信号弱区域"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        if let closeImage = SWKitModule.image(named: "tips_close") {
            button.setImage(closeImage, for: .normal)
        } else {
            button.setTitle("✕", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
        button.contentMode = .scaleAspectFit
        button.imageView?.contentMode = .scaleAspectFit
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // 添加关闭回调
    public var onClose: (() -> Void)?
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 设置默认状态
        backgroundColor = state.backgroundColor
        
        addSubview(warnImageView)
        addSubview(messageLabel)
        addSubview(closeButton)
        
        setupConstraints()
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            warnImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            warnImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            warnImageView.widthAnchor.constraint(equalToConstant: 12),
            warnImageView.heightAnchor.constraint(equalToConstant: 12),
            
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            messageLabel.leadingAnchor.constraint(equalTo: warnImageView.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - 状态更新
    private func updateAppearanceForCurrentState() {
        UIView.animate(withDuration: 0.25) {
            self.backgroundColor = self.state.backgroundColor
        }
        // 如果不同状态需要不同的图标，可以在这里更新
        // warnImageView.image = UIImage(named: state.iconName)
    }
    
    // MARK: - Action
    @objc private func closeButtonTapped() {
        onClose?() // 调用回调
    }
    
    // 便利构造方法
    convenience init(state: AlertState, message: String? = nil) {
        self.init(frame: .zero)
        self.state = state
        if let message = message {
            self.message = message
        }
        updateAppearanceForCurrentState()
    }
}
