//
//  PermissionViewManager.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit

// MARK: - 权限界面管理器
class PermissionViewManager {
    private let breathingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "#F0F8FF")
        view.layer.cornerRadius = 100
        return view
    }()
    
    private let deviceLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_mini_logo")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        return button
    }()
    
    var onActionButtonTapped: (() -> Void)?
    
    func setup(in container: UIView) {
        container.addSubview(breathingView)
        container.addSubview(deviceLogoImageView)
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(actionButton)
        
        NSLayoutConstraint.activate([
            breathingView.topAnchor.constraint(equalTo: container.topAnchor, constant: 80),
            breathingView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            breathingView.widthAnchor.constraint(equalToConstant: 200),
            breathingView.heightAnchor.constraint(equalToConstant: 200),
            
            deviceLogoImageView.centerXAnchor.constraint(equalTo: breathingView.centerXAnchor),
            deviceLogoImageView.centerYAnchor.constraint(equalTo: breathingView.centerYAnchor),
            deviceLogoImageView.widthAnchor.constraint(equalToConstant: 80),
            deviceLogoImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: breathingView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            actionButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // 默认配置为权限拒绝
        configureForPermissionDenied()
    }
    
    func configureForPermissionDenied() {
        titleLabel.text = "未开启蓝牙权限"
        messageLabel.text = "请在手机设置中允许应用使用蓝牙"
        actionButton.setTitle("去设置", for: .normal)
    }
    
    func configureForBluetoothOff() {
        titleLabel.text = "蓝牙未打开"
        messageLabel.text = "请在手机设置中打开蓝牙"
        actionButton.setTitle("去打开蓝牙", for: .normal)
    }
    
    func removeFromSuperview() {
        breathingView.removeFromSuperview()
        deviceLogoImageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        messageLabel.removeFromSuperview()
        actionButton.removeFromSuperview()
    }
    
    @objc private func actionButtonTapped() {
        onActionButtonTapped?()
    }
}
