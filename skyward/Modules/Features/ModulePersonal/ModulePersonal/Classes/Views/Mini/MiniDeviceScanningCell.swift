//
//  DeviceTableViewCell.swift
//  test11
//
//  Created by yifan kang on 2025/11/12.
//


import UIKit
import CoreBluetooth
import SWKit

class MiniDeviceScanningCell: UITableViewCell {
    static let identifier = "MiniDeviceScanningCell"
    
    // MARK: - UI Components
    private let deviceIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = PersonalModule.image(named: "device_mini_icon")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let imeiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let statusButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.setTitle("连接", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        return button
    }()
    
    private let connectingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // MARK: - Properties
    private var peripheral: CBPeripheral?
    private var scannedDevice: ScannedDevice?
    var onConnectTapped: ((CBPeripheral,ScannedDevice) -> Void)?
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(deviceIcon)
        contentView.addSubview(nameLabel)
        contentView.addSubview(imeiLabel)
        contentView.addSubview(statusButton)
        statusButton.addSubview(connectingIndicator)
        
        deviceIcon.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        imeiLabel.translatesAutoresizingMaskIntoConstraints = false
        statusButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            deviceIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deviceIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deviceIcon.widthAnchor.constraint(equalToConstant: 32),
            deviceIcon.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: deviceIcon.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusButton.leadingAnchor, constant: -8),
            
            imeiLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            imeiLabel.leadingAnchor.constraint(equalTo: deviceIcon.trailingAnchor, constant: 12),
            imeiLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusButton.leadingAnchor, constant: -8),
            imeiLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            statusButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statusButton.heightAnchor.constraint(equalToConstant: 32),
            statusButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            connectingIndicator.centerXAnchor.constraint(equalTo: statusButton.centerXAnchor),
            connectingIndicator.centerYAnchor.constraint(equalTo: statusButton.centerYAnchor)
        ])
        
        // 设置单元格样式
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    private func setupActions() {
        statusButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with peripheral: CBPeripheral,
                   scannedDevice: ScannedDevice? = nil,
                   isConnecting: Bool = false,
                   isConnected: Bool = false) {
        self.peripheral = peripheral
        self.scannedDevice = scannedDevice
        // 设备名称
        nameLabel.text = peripheral.name ?? "未知设备"
        
        // 如果有扫描到的设备信息，显示完整信息
        if let device = scannedDevice {
            // 显示IMEI和产品信息
            imeiLabel.text = "IMEI: \(device.imei)"
            
            // 可以根据绑定状态调整UI
            if device.bondStatus == 1 {
                // 已绑定设备的特殊显示
                imeiLabel.textColor = UIColor(hex: "#28A745")
            } else {
                imeiLabel.textColor = .secondaryLabel
            }
        } else {
            // 没有扫描信息时显示基本UUID
            let shortUUID = String(peripheral.identifier.uuidString.prefix(8)).uppercased()
            imeiLabel.text = "ID: \(shortUUID)"
            imeiLabel.textColor = .secondaryLabel
        }
        
        // 更新连接状态
        updateConnectionState(isConnecting: isConnecting, isConnected: isConnected)
    }
    
    private func updateConnectionState(isConnecting: Bool, isConnected: Bool) {
        if isConnecting {
            // 连接中状态
            statusButton.setTitle("", for: .normal)
            statusButton.backgroundColor = UIColor(hex: "#6C757D")
            statusButton.isEnabled = false
            connectingIndicator.startAnimating()
        } else if isConnected {
            // 已连接状态
            statusButton.setTitle("已连接", for: .normal)
            statusButton.backgroundColor = UIColor(hex: "#28A745")
            statusButton.isEnabled = false
            connectingIndicator.stopAnimating()
        } else {
            // 未连接状态
            statusButton.setTitle("连接", for: .normal)
            statusButton.backgroundColor = UIColor(hex: "#FE6A00")
            statusButton.isEnabled = true
            connectingIndicator.stopAnimating()
        }
    }
    
    // MARK: - Actions
    @objc private func connectButtonTapped() {
        guard let peripheral = peripheral, let scannedDevice = scannedDevice else { return }
        onConnectTapped?(peripheral, scannedDevice)
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        peripheral = nil
        onConnectTapped = nil
        nameLabel.text = nil
        imeiLabel.text = nil
        statusButton.isEnabled = true
        connectingIndicator.stopAnimating()
    }
}
