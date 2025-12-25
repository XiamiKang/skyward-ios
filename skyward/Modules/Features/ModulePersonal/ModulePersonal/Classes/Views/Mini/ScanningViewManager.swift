//
//  ScanningViewManager.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit
import CoreBluetooth
import Lottie
import SWKit

// MARK: - 扫描中界面管理器
class ScanningViewManager: NSObject {
        
    private var animationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "scanning")
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.animationSpeed = 1.0
        return animationView
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
        label.text = "正在扫描中..."
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "请确保设备已开机，电量灯常亮"
        return label
    }()
    
    private let devicesTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.rowHeight = 90
        tableView.isHidden = true // 初始隐藏，扫描到设备后显示
        tableView.alpha = 0.0 // 初始透明
        return tableView
    }()
    
    private var scannedDevices: [ScannedDevice] = []
    var onDeviceSelected: ((CBPeripheral, ScannedDevice) -> Void)?
    // 添加连接状态跟踪
    private var connectingPeripheral: CBPeripheral?
    
    override init() {
        super.init()
    }
    
    func setup(in container: UIView) {
        
        container.addSubview(animationView)
        container.addSubview(deviceLogoImageView)
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(devicesTableView)
        
        NSLayoutConstraint.activate([
            // 呼吸灯视图
            animationView.topAnchor.constraint(equalTo: container.topAnchor, constant: 80),
            animationView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 240),
            animationView.heightAnchor.constraint(equalToConstant: 240),
            
            // 设备logo
            deviceLogoImageView.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            deviceLogoImageView.centerYAnchor.constraint(equalTo: animationView.centerYAnchor),
            deviceLogoImageView.widthAnchor.constraint(equalToConstant: 60),
            deviceLogoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // 标题
            titleLabel.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 消息
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 设备列表
            devicesTableView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            devicesTableView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            devicesTableView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            devicesTableView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -34),
        ])
        
        devicesTableView.delegate = self
        devicesTableView.dataSource = self
        devicesTableView.register(MiniDeviceScanningCell.self, forCellReuseIdentifier: MiniDeviceScanningCell.identifier)
    }
    
    private func setupAnimation(_ view: UIView) {
        // 播放动画
        animationView.play()
    }
    
    func startBreathingAnimation() {
        animationView.play()
    }
    
    func updateDevices(_ newPeripherals: [CBPeripheral]) {
        // 转换为ScannedDevice数组
        scannedDevices = newPeripherals.compactMap { peripheral in
            BluetoothManager.shared.findScannedDevice(for: peripheral)
        }
        
        // 按信号强度排序
        scannedDevices.sort { $0.rssi > $1.rssi }
        
        if scannedDevices.isEmpty {
            // 没有设备
            devicesTableView.isHidden = true
        } else {
            // 有设备
            devicesTableView.isHidden = false
            
            // 淡入动画显示设备列表
            UIView.animate(withDuration: 0.3) {
                self.devicesTableView.alpha = 1.0
            }
            
            devicesTableView.reloadData()
            
            // 更新标题和消息
            titleLabel.text = "正在扫描中..."
            messageLabel.text = "搜索到以下设备，请点击连接"
        }
    }
    
    // 添加连接状态更新方法
    func updateConnectionState(for peripheral: CBPeripheral, isConnecting: Bool, isConnected: Bool) {
        if isConnecting {
            connectingPeripheral = peripheral
        } else {
            connectingPeripheral = nil
        }
        
        // 刷新表格视图以更新状态
        devicesTableView.reloadData()
    }
    
    func showScanningState() {
        // 显示扫描中的状态
        titleLabel.text = "正在扫描中..."
        messageLabel.text = "请确保设备已开机，电量灯常亮"
        devicesTableView.isHidden = true
        devicesTableView.alpha = 0.0
    }
    
    func removeFromSuperview() {
        animationView.stop()
        animationView.removeFromSuperview()
        deviceLogoImageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        messageLabel.removeFromSuperview()
        devicesTableView.removeFromSuperview()
    }
    
}

// MARK: - UITableView扩展
extension ScanningViewManager: UITableViewDataSource, UITableViewDelegate {
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
        
        // 配置Cell
        cell.configure(
            with: peripheral,
            scannedDevice: scannedDevice,
            isConnecting: isConnecting,
            isConnected: isConnected
        )
        
        // 设置连接回调
        cell.onConnectTapped = { [weak self] (peripheral, scannedDevice) in
            self?.onDeviceSelected?(peripheral, scannedDevice)
            // 更新连接状态
            self?.updateConnectionState(for: peripheral, isConnecting: true, isConnected: false)
        }
        
        return cell
    }
    
    // 可选：添加自定义行高或其他UITableViewDelegate方法
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}
