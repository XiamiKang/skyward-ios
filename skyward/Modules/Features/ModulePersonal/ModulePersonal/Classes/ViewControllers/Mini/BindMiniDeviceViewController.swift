//
//  BindDeviceViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//


import UIKit
import CoreBluetooth
import SWKit

class BindMiniDeviceViewController: UIViewController {
    
    // MARK: - 枚举
    enum ViewState {
        case permissionDenied    // 权限被拒绝
        case bluetoothOff        // 蓝牙关闭
        case scanning            // 扫描中
        case noDevicesFound      // 未发现设备
        case scanStopped         // 扫描停止
        case deviceLineSuccess   // 设备连接成功
    }
    
    // MARK: - UI组件
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let lineMiniDeviceTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "连接行者mini"
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(PersonalModule.image(named: "default_close"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    // MARK: - 子界面管理器
    private var currentState: ViewState = .scanning
    private let permissionViewManager = PermissionViewManager()
    private let scanningViewManager = ScanningViewManager()
    private let devicesLineSuccessViewManager = DevicesLineSuccessViewManager()
    private let noDevicesViewManager = NoDevicesViewManager()
    private let scanStoppedViewManager = ScanStoppedViewManager()
    
    // MARK: - 属性
    private var isScanning = false
    private var currentBluetoothState: CBManagerState = .unknown
    private var scannedDevice: ScannedDevice?
    private var scanTimer: Timer?
    private let scanDuration: TimeInterval = 30.0 // 30秒扫描时间
    private var CBPeripheralUUIDString: String = ""
    private let bluetoolManager = BluetoothManager.shared
    
    // MARK: - dismiss回调
    var onDismiss: ((_ uuidStr: String) -> Void)?
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupBluetoolDelegate()
        checkCurrentBluetoothState()
        updateViewForState(.scanning)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showWithAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
        invalidateScanTimer()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(containerView)
        containerView.addSubview(lineMiniDeviceTitle)
        containerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            // 容器视图
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9),
            
            // 标题
            lineMiniDeviceTitle.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            lineMiniDeviceTitle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // 关闭按钮
            closeButton.centerYAnchor.constraint(equalTo: lineMiniDeviceTitle.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // 点击背景关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupBluetoolDelegate() {
        bluetoolManager.delegate = self
    }
    
    private func checkCurrentBluetoothState() {
        // 可以通过 BluetoothManager 获取当前状态
        let currentState = BluetoothManager.shared.getCurrentBluetoothState()
        updateUIForBluetoothState(currentState)
    }
    
    // MARK: - 界面状态管理
    private func updateViewForState(_ state: ViewState) {
        currentState = state
        
        // 移除所有子界面
        permissionViewManager.removeFromSuperview()
        scanningViewManager.removeFromSuperview()
        devicesLineSuccessViewManager.removeFromSuperview()
        noDevicesViewManager.removeFromSuperview()
        scanStoppedViewManager.removeFromSuperview()
        
        // 添加对应的子界面
        switch state {
        case .permissionDenied:
            addPermissionView()
        case .bluetoothOff:
            addBluetoothOffView()
        case .scanning:
            addScanningView()
        case .noDevicesFound:
            addNoDevicesView()
        case .scanStopped:
            addScanStoppedView()
        case .deviceLineSuccess:
            addDeviceLineSuccessView()
        }
    }
    
    private func addPermissionView() {
        permissionViewManager.setup(in: containerView)
        permissionViewManager.onActionButtonTapped = { [weak self] in
            self?.showPermissionAlert()
        }
    }
    
    private func addBluetoothOffView() {
        permissionViewManager.setup(in: containerView)
        permissionViewManager.configureForBluetoothOff()
        permissionViewManager.onActionButtonTapped = { [weak self] in
            self?.showBluetoothAlert()
        }
    }
    
    private func addScanningView() {
        scanningViewManager.setup(in: containerView)
        scanningViewManager.startBreathingAnimation()
        scanningViewManager.onDeviceSelected = { [weak self] (peripheral, scannedDevice) in
            self?.scannedDevice = scannedDevice
            self?.connectToDevice(peripheral)
        }
    }
    
    private func addNoDevicesView() {
        noDevicesViewManager.setup(in: containerView)
        noDevicesViewManager.onRetryTapped = { [weak self] in
            self?.startScanning()
        }
    }
    
    private func addScanStoppedView() {
        scanStoppedViewManager.setup(in: containerView)
        scanStoppedViewManager.onRestartScanTapped = { [weak self] in
            self?.startScanning()
        }
        scanStoppedViewManager.onDeviceSelected = { [weak self] (peripheral, scannedDevice) in
            self?.scannedDevice = scannedDevice
            self?.connectToDevice(peripheral)
        }
        
        // 更新设备列表
        let currentDevices = BluetoothManager.shared.filteredPeripherals
        scanStoppedViewManager.updateDevices(currentDevices)
    }
    
    private func addDeviceLineSuccessView() {
        devicesLineSuccessViewManager.setup(in: containerView)
        
        // 配置设备名称
        if let connectedPeripheral = BluetoothManager.shared.connectedPeripheral {
            let deviceName = connectedPeripheral.name ?? "未知设备"
            devicesLineSuccessViewManager.configure(with: deviceName)
        }
        
        devicesLineSuccessViewManager.onDetailButtonTapped = { [weak self] in
            self?.showDeviceDetail()
        }
    }
    
    // MARK: - 扫描计时器管理
    private func startScanTimer() {
        invalidateScanTimer() // 先取消之前的计时器
        
        scanTimer = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { [weak self] _ in
            self?.handleScanTimeout()
        }
    }
    
    private func invalidateScanTimer() {
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    private func handleScanTimeout() {
        print("扫描超时（30秒）")
        stopScanning()
        
        let filteredDevices = BluetoothManager.shared.filteredPeripherals
        
        DispatchQueue.main.async {
            if filteredDevices.isEmpty {
                // 没有扫描到设备
                self.updateViewForState(.noDevicesFound)
            } else {
                // 扫描到设备，显示扫描停止界面
                self.updateViewForState(.scanStopped)
            }
        }
    }
    
    // MARK: - 蓝牙扫描
    private func startScanning() {
        guard currentBluetoothState == .poweredOn else {
            print("蓝牙未开启，无法开始扫描")
            return
        }
        
        isScanning = true
        BluetoothManager.shared.startScanningForFilteredDevices()
        updateViewForState(.scanning)
        startScanTimer() // 启动30秒计时器
        print("开始扫描设备，将在30秒后自动停止...")
    }
    
    private func stopScanning() {
        isScanning = false
        BluetoothManager.shared.stopScanning()
        invalidateScanTimer() // 停止计时器
        print("停止扫描设备")
    }
    
    // MARK: - 设备连接
    private func connectToDevice(_ peripheral: CBPeripheral) {
        if peripheral.identifier == BluetoothManager.shared.connectedPeripheral?.identifier {
            print("设备已连接")
            return
        }
        
        // 停止扫描和计时器
        stopScanning()
        
        BluetoothManager.shared.connectToPeripheral(peripheral)
        print("正在连接设备: \(peripheral.name ?? "未知设备")")
    }
    
    // MARK: - 蓝牙状态处理
    private func updateUIForBluetoothState(_ state: CBManagerState) {
        currentBluetoothState = state
        
        switch state {
        case .poweredOn:
            startScanning()
        case .poweredOff:
            updateViewForState(.bluetoothOff)
            stopScanning()
        case .unauthorized:
            updateViewForState(.permissionDenied)
            stopScanning()
        case .unsupported, .resetting, .unknown:
            updateViewForState(.scanStopped)
            stopScanning()
        @unknown default:
            break
        }
    }
    
    // MARK: - 动画
    private func showWithAnimation() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.frame.height)
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
        }
    }
    
    private func hideWithAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.frame.height)
            self.view.backgroundColor = .clear
        }) { _ in
            self.dismiss(animated: false) { [weak self] in
                self?.onDismiss?(self?.CBPeripheralUUIDString ?? "")
            }
        }
    }
    
    // MARK: - 按钮点击事件
    @objc private func closeButtonTapped() {
        hideWithAnimation()
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            hideWithAnimation()
        }
    }
    
    // MARK: - 弹窗
    private func showBluetoothAlert() {
        let alert = UIAlertController(
            title: "蓝牙未打开",
            message: "请在手机设置中打开蓝牙",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去打开蓝牙", style: .default, handler: { _ in
            if let url = URL(string: "App-Prefs:root=Bluetooth") {
                UIApplication.shared.open(url)
            }
        }))
        
        present(alert, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "未开启附近的设备权限",
            message: "请在设置-应用-Skyward权限管理中开启附近的设备权限",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "去设置", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        
        present(alert, animated: true)
    }
    
    // 查看设备详情方法
    private func showDeviceDetail() {
        // 这里可以跳转到设备详情页面
        print("跳转到设备详情页面")
        BluetoothManager.shared.requestStatusInfo()
        // 示例：关闭当前页面
        hideWithAnimation()
    }
    
    
}

// MARK: - BluetoothManagerDelegate
extension BindMiniDeviceViewController: BluetoothManagerDelegate {
    func didUpdateBluetoothState(_ state: CBManagerState) {
        DispatchQueue.main.async {
            self.updateUIForBluetoothState(state)
        }
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            // 更新扫描界面的设备列表
            let filteredDevices = BluetoothManager.shared.filteredPeripherals
            self.scanningViewManager.updateDevices(filteredDevices)
        }
    }
    
    func didConnectPeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            
            self.CBPeripheralUUIDString = peripheral.identifier.uuidString
            // 停止扫描和计时器
            self.stopScanning()
            
            // 更新连接状态
            self.scanningViewManager.updateConnectionState(
                for: peripheral,
                isConnecting: false,
                isConnected: true
            )
            
            // 延迟一下显示成功界面，让用户看到连接成功状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.updateViewForState(.deviceLineSuccess)
            }
        }
    }
    
    func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
        // 处理断开连接
        print("设备断开连接: \(peripheral.name ?? "未知设备")")
        DispatchQueue.main.async {
            self.scanningViewManager.updateConnectionState(
                for: peripheral,
                isConnecting: false,
                isConnected: false
            )
        }
    }
    
    func didFailToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        // 处理连接失败
        print("设备连接失败: \(peripheral.name ?? "未知设备") - \(error?.localizedDescription ?? "未知错误")")
        
        DispatchQueue.main.async {
            // 更新连接失败状态
            self.scanningViewManager.updateConnectionState(
                for: peripheral,
                isConnecting: false,
                isConnected: false
            )
            
            // 连接失败后，根据当前是否有设备来决定显示哪个界面
            let filteredDevices = BluetoothManager.shared.filteredPeripherals
            if filteredDevices.isEmpty {
                self.updateViewForState(.noDevicesFound)
            } else {
                self.updateViewForState(.scanStopped)
            }
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension BindMiniDeviceViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}
