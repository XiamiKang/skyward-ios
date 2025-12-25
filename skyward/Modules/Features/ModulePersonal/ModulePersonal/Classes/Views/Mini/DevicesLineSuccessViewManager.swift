//
//  DevicesViewManager.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit

// MARK: - 设备连接成功界面管理器
class DevicesLineSuccessViewManager: NSObject {
    private let successImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_line_success")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.text = "设备连接成功"
        return label
    }()
    
    private let deviceNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let detailButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.setTitle("查看设备详情", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        return button
    }()
    
    var onDetailButtonTapped: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func setup(in container: UIView) {
        container.addSubview(successImageView)
        container.addSubview(titleLabel)
        container.addSubview(deviceNameLabel)
        container.addSubview(detailButton)
        
        NSLayoutConstraint.activate([
            // 成功图片
            successImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            successImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 60),
            successImageView.widthAnchor.constraint(equalToConstant: 80),
            successImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // 标题
            titleLabel.topAnchor.constraint(equalTo: successImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 设备名称
            deviceNameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            deviceNameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            deviceNameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 详情按钮
            detailButton.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 24),
            detailButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            detailButton.heightAnchor.constraint(equalToConstant: 40),
            detailButton.widthAnchor.constraint(equalToConstant: 140)
        ])
        
        detailButton.addTarget(self, action: #selector(detailButtonTapped), for: .touchUpInside)
    }
    
    func configure(with deviceName: String) {
        deviceNameLabel.text = deviceName
    }
    
    func removeFromSuperview() {
        successImageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        deviceNameLabel.removeFromSuperview()
        detailButton.removeFromSuperview()
    }
    
    @objc private func detailButtonTapped() {
        onDetailButtonTapped?()
    }
}
