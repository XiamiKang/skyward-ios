//
//  DeviceCollectionViewCell.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit
import CoreBluetooth
import SWKit

// MARK: - 设备Cell
class MiniDeviceCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let deviceImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let statusView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "#DFE0E2")
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor(hex: "#A0A3A7")
        label.text = "•未连接"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(deviceImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(statusView)
        
        statusView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            deviceImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            deviceImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            deviceImageView.widthAnchor.constraint(equalToConstant: 80),
            deviceImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: deviceImageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            statusView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            statusView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusView.heightAnchor.constraint(equalToConstant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: statusView.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: 3),
            statusLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -3),
            statusLabel.bottomAnchor.constraint(equalTo: statusView.bottomAnchor),
        ])
    }
    
    func configure(with device: BluetoothDeviceInfo) {
        deviceImageView.image = PersonalModule.image(named: "device_mini_logo")
        nameLabel.text = device.displayName
        
        // 设置状态
        guard let connectedPeripheral = BluetoothManager.shared.connectedPeripheral else { return }
        if device.uuid == connectedPeripheral.identifier.uuidString {
            statusView.backgroundColor = UIColor(hex: "#DFF5EA")
            statusLabel.textColor = UIColor(hex: "#16C282")
            statusLabel.text = "•已连接"
        }else {
            statusView.backgroundColor = UIColor(hex: "#DFE0E2")
            statusLabel.textColor = UIColor(hex: "#A0A3A7")
            statusLabel.text = "•未连接"
        }
    }
}
