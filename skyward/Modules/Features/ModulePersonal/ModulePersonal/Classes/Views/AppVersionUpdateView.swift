//
//  AppVersionUpdateView.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/3/16.
//

import UIKit
import SnapKit

class AppVersionUpdateView: UIView {
    
    // MARK: - UI Components
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        view.alpha = 0
        return view
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = PersonalModule.image(named: "app_version_icon")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "发现新版本"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.backgroundColor = UIColor(hex: "#F2F3F4")
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var updateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("跳转AppStore", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    private var upgradeType: Int = 1 // 1: 可选更新（两个按钮） 2: 强制更新（一个按钮）
    private var updateUrl: String?
    private var cancelHandler: (() -> Void)?
    private var updateHandler: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(backgroundView)
        addSubview(containerView)
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(versionLabel)
        containerView.addSubview(cancelButton)
        containerView.addSubview(updateButton)
        
        setupConstraints()
        
        // 添加点击背景消失的手势（仅可选更新时有效）
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(36)
            make.centerY.equalToSuperview()
            // 高度根据内容自适应，不设置固定高度
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }
        
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        // 按钮的约束会在 configure 中根据 type 动态调整
    }
    
    // MARK: - Public Methods
    func configure(
        version: String,
        upgradeType: Int,
        updateUrl: String? = nil,
        cancelHandler: (() -> Void)? = nil,
        updateHandler: (() -> Void)? = nil
    ) {
        self.upgradeType = upgradeType
        self.updateUrl = updateUrl
        self.cancelHandler = cancelHandler
        self.updateHandler = updateHandler
        
        versionLabel.text = "更新包版本：\(version)"
        
        // 根据升级类型设置按钮
        setupButtonsForUpgradeType()
    }
    
    private func setupButtonsForUpgradeType() {
        // 先移除所有按钮的旧约束
        cancelButton.snp.removeConstraints()
        updateButton.snp.removeConstraints()
        
        if upgradeType == 2 {
            // 强制更新：只显示一个按钮
            cancelButton.isHidden = true
            updateButton.isHidden = false
            
            updateButton.snp.makeConstraints { make in
                make.top.equalTo(versionLabel.snp.bottom).offset(24)
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(40)
                make.bottom.equalToSuperview().offset(-24)
            }
        } else {
            // 可选更新：显示两个按钮
            cancelButton.isHidden = false
            updateButton.isHidden = false
            
            cancelButton.snp.makeConstraints { make in
                make.top.equalTo(versionLabel.snp.bottom).offset(24)
                make.left.equalToSuperview().offset(16)
                make.right.equalTo(updateButton.snp.left).offset(-12)
                make.height.equalTo(40)
                make.bottom.equalToSuperview().offset(-24)
            }
            
            updateButton.snp.makeConstraints { make in
                make.top.equalTo(versionLabel.snp.bottom).offset(24)
                make.right.equalToSuperview().offset(-16)
                make.width.equalTo(cancelButton)
                make.height.equalTo(40)
            }
        }
    }
    
    func show(in view: UIView) {
        self.frame = view.bounds
        view.addSubview(self)
        
        UIView.animate(withDuration: 0.25) {
            self.backgroundView.alpha = 1
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundView.alpha = 0
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    // MARK: - Actions
    @objc private func updateButtonTapped() {
        if let urlString = updateUrl, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        updateHandler?()
        
        // 可选更新时点击更新按钮关闭弹窗，强制更新不关闭（让用户必须更新）
        if upgradeType == 1 {
            dismiss()
        }
    }
    
    @objc private func cancelButtonTapped() {
        cancelHandler?()
        dismiss()
    }
    
    @objc private func backgroundTapped() {
        // 可选更新时点击背景关闭
        if upgradeType == 1 {
            cancelHandler?()
            dismiss()
        }
    }
}

// MARK: - 使用示例
extension AppVersionUpdateView {
    static func showUpdateDialog(
        in view: UIView,
        version: String,
        upgradeType: Int, // 1: 可选更新 2: 强制更新
        updateUrl: String? = nil,
        cancelHandler: (() -> Void)? = nil,
        updateHandler: (() -> Void)? = nil
    ) {
        let updateView = AppVersionUpdateView()
        updateView.configure(
            version: version,
            upgradeType: upgradeType,
            updateUrl: updateUrl,
            cancelHandler: cancelHandler,
            updateHandler: updateHandler
        )
        updateView.show(in: view)
    }
}
