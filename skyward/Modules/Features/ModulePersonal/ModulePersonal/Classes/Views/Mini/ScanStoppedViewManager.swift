//
//  ScanStoppedViewManager.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit
import CoreBluetooth
import SWKit

// MARK: - 扫描停止界面管理器
class ScanStoppedViewManager: NSObject {
    private let noFindImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_mini_scanStop")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.text = "扫描已结束"
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "没有找到自己想连接的设备？试试重新扫描"
        return label
    }()
    
    private let restartButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: "#F2F3F4")
        button.setTitle("重新扫描", for: .normal)
        button.setTitleColor(UIColor(hex: "#FE6A00"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        return button
    }()
    
    private let devicesTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.rowHeight = 90
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    private let noDevicesView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let noDevicesImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_nofind")
        return imageView
    }()
    
    private let noDevicesTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        label.text = "暂无扫描到的设备"
        return label
    }()
    
    // MARK: - Properties
    var onRestartScanTapped: (() -> Void)?
    var onDeviceSelected: ((CBPeripheral, ScannedDevice) -> Void)?
    
    // 使用ScannedDevice数组而不是元组数组
    private var scannedDevices: [ScannedDevice] = []
    private var connectingPeripheral: CBPeripheral?
    
    override init() {
        super.init()
    }
    
    func setup(in container: UIView) {
        container.addSubview(noFindImageView)
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(restartButton)
        container.addSubview(devicesTableView)
        container.addSubview(noDevicesView)
        
        setupNoDevicesView()
        setupConstraints(in: container)
        setupActions()
        setupTableView()
        
        // 初始更新设备显示状态
        updateDevicesDisplay()
    }
    
    private func setupNoDevicesView() {
        noDevicesView.addSubview(noDevicesImageView)
        noDevicesView.addSubview(noDevicesTitleLabel)
        
        NSLayoutConstraint.activate([
            noDevicesImageView.centerXAnchor.constraint(equalTo: noDevicesView.centerXAnchor),
            noDevicesImageView.topAnchor.constraint(equalTo: noDevicesView.topAnchor, constant: 40),
            noDevicesImageView.widthAnchor.constraint(equalToConstant: 100),
            noDevicesImageView.heightAnchor.constraint(equalToConstant: 100),
            
            noDevicesTitleLabel.topAnchor.constraint(equalTo: noDevicesImageView.bottomAnchor, constant: 16),
            noDevicesTitleLabel.leadingAnchor.constraint(equalTo: noDevicesView.leadingAnchor, constant: 20),
            noDevicesTitleLabel.trailingAnchor.constraint(equalTo: noDevicesView.trailingAnchor, constant: -20),
            noDevicesTitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: noDevicesView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupConstraints(in container: UIView) {
        NSLayoutConstraint.activate([
            // 顶部图片
            noFindImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 60),
            noFindImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            noFindImageView.widthAnchor.constraint(equalToConstant: 100),
            noFindImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // 标题
            titleLabel.topAnchor.constraint(equalTo: noFindImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 消息
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 重新扫描按钮
            restartButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            restartButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            restartButton.heightAnchor.constraint(equalToConstant: 44),
            restartButton.widthAnchor.constraint(equalToConstant: 140),
            
            // 设备列表
            devicesTableView.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 24),
            devicesTableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            devicesTableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            devicesTableView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -34),
            
            // 无设备视图
            noDevicesView.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 40),
            noDevicesView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            noDevicesView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            noDevicesView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -34)
        ])
    }
    
    private func setupActions() {
        restartButton.addTarget(self, action: #selector(restartButtonTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        devicesTableView.delegate = self
        devicesTableView.dataSource = self
        devicesTableView.register(MiniDeviceScanningCell.self, forCellReuseIdentifier: MiniDeviceScanningCell.identifier)
        
        // 设置表格视图样式
        devicesTableView.separatorStyle = .none
        devicesTableView.backgroundColor = .clear
    }
    
    // MARK: - Public Methods
    
    func updateDevices(_ newDevices: [CBPeripheral]) {
        // 转换为ScannedDevice数组
        scannedDevices = newDevices.compactMap { peripheral in
            BluetoothManager.shared.findScannedDevice(for: peripheral)
        }
        
        // 按信号强度排序
        scannedDevices.sort { $0.rssi > $1.rssi }
        
        updateDevicesDisplay()
        
        // 如果有设备，更新消息文本
        if !scannedDevices.isEmpty {
            let deviceCount = scannedDevices.count
            messageLabel.text = "扫描到 \(deviceCount) 个设备，请选择要连接的设备"
        }
    }
    
    func updateConnectionState(for peripheral: CBPeripheral, isConnecting: Bool, isConnected: Bool) {
        if isConnecting {
            connectingPeripheral = peripheral
        } else {
            connectingPeripheral = nil
        }
        
        // 刷新表格视图以更新状态
        DispatchQueue.main.async {
            self.devicesTableView.reloadData()
        }
    }
    
    func removeFromSuperview() {
        noFindImageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        messageLabel.removeFromSuperview()
        restartButton.removeFromSuperview()
        devicesTableView.removeFromSuperview()
        noDevicesView.removeFromSuperview()
    }
    
    // MARK: - Private Methods
    
    private func updateDevicesDisplay() {
        if scannedDevices.isEmpty {
            // 没有设备，显示无设备视图
            devicesTableView.isHidden = true
            noDevicesView.isHidden = false
        } else {
            // 有设备，显示设备列表
            devicesTableView.isHidden = false
            noDevicesView.isHidden = true
            devicesTableView.reloadData()
        }
    }
    
    @objc private func restartButtonTapped() {
        onRestartScanTapped?()
    }
}

// MARK: - UITableView扩展
extension ScanStoppedViewManager: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MiniDeviceScanningCell.identifier, for: indexPath) as? MiniDeviceScanningCell else {
            return UITableViewCell()
        }
        
        let scannedDevice = scannedDevices[indexPath.row]
        let peripheral = scannedDevice.peripheral
        
        // 判断连接状态
        let isConnecting = peripheral.identifier == connectingPeripheral?.identifier
        let isConnected = peripheral.identifier == BluetoothManager.shared.connectedPeripheral?.identifier
        
        // 配置Cell，传递完整的扫描设备信息
        cell.configure(
            with: peripheral,
            scannedDevice: scannedDevice,
            isConnecting: isConnecting,
            isConnected: isConnected
        )
        
        // 设置连接回调
        cell.onConnectTapped = { [weak self] (peripheral,scannedDevice) in
            self?.onDeviceSelected?(peripheral, scannedDevice)
            // 更新连接状态
            self?.updateConnectionState(for: peripheral, isConnecting: true, isConnected: false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}
