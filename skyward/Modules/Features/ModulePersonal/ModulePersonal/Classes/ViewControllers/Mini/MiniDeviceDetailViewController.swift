//
//  DeviceDetailViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/18.
//


import UIKit
import CoreBluetooth
import SWKit
import Combine

public class MiniDeviceDetailViewController: PersonalBaseViewController {
    
    // MARK: - Properties
    public var deviceInfo: BluetoothDeviceInfo? {
        didSet {
            if let connectedPeripheral = BluetoothManager.shared.connectedPeripheral {
                deviceConnetedStatus = deviceInfo?.uuid == connectedPeripheral.identifier.uuidString ? 1 : 0
            }
        }
    }
    var deviceConnetedStatus: Int = 0
    private var miniDeviceInfo: DeviceInfo?
    private var statusInfo: StatusInfo?
    private let viewModel = PersonalViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var newVersion = false
    private var miniVersion = "1.0.0.0"
    private var currentFirmwareData: FirmwareData?
    
    private lazy var miniTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(str: "#F2F3F4")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(MiniDeviceBaseMsgCell.self, forCellReuseIdentifier: "MiniDeviceBaseMsgCell")
        tableView.register(MiniDeviceStatusCell.self, forCellReuseIdentifier: "MiniDeviceStatusCell")
        tableView.register(MiniDeviceSettingCell.self, forCellReuseIdentifier: "MiniDeviceSettingCell")
        
        return tableView
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBluetooth()
        updateBasicInfo()
        setupNotifications()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        customTitle.text = "详情"
        
        view.addSubview(miniTableView)
        
        NSLayoutConstraint.activate([
            
            miniTableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            miniTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            miniTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            miniTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
        ])
    }
    
    private func setupBluetooth() {
        BluetoothManager.shared.delegate = self
    }
    
    // MARK: - Data Management
    private func updateBasicInfo() {
        if deviceConnetedStatus == 1 {
            refreshMiniDeviceData()
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showDeviceInfo(_:)),
                                               name: .didReceiveDeviceInfo,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showStatusInfo(_:)),
                                               name: .didReceiveStatusInfo,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showSatelliteInfo(_:)),
                                               name: .didReceiveSatelliteInfo,
                                               object: nil)
    }
    
    @objc private func showDeviceInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let deviceInfo = userInfo["deviceInfo"] as? DeviceInfo {
            print("Mini设备信息---\(deviceInfo)")
            self.miniDeviceInfo = deviceInfo
            let mcuSoftwareVersion = formatVersion(deviceInfo.mcuSoftwareVersion)
            miniVersion = String(mcuSoftwareVersion.dropFirst())
            print("Mini设备固件版本信息---\(miniVersion)")
            let hardwareModel = "1.0"
            let model = DeviceFirmwareModel(deviceType: 1, versionCode: miniVersion, hardwareModel: hardwareModel)
            self.checkNewVersion(model: model)
        }
    }
    
    @objc private func showStatusInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let statusInfo = userInfo["statusInfo"] as? StatusInfo {
            print("Mini设备状态---\(statusInfo)")
            self.statusInfo = statusInfo
            if let cell = self.miniTableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? MiniDeviceStatusCell {
                cell.configon(with: statusInfo)
            }
            if let cell = self.miniTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MiniDeviceBaseMsgCell {
                cell.updateMsg(statusInfo)
            }
            
            self.miniTableView.reloadData()
        }
    }
    
    @objc private func showSatelliteInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let satelliteInfo = userInfo["satelliteInfo"] as? String {
            print("Mini设备卫星状态---\(satelliteInfo)")
            if let cell = self.miniTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MiniDeviceBaseMsgCell {
                cell.updateSatelliteImage(with: Int(satelliteInfo) ?? 0)
            }
            
            self.miniTableView.reloadData()
        }
    }
    
    private func checkNewVersion(model: DeviceFirmwareModel) {
        viewModel.input.deviceFirmwareRequest.send(model)
        
        viewModel.$deviceFirmwareData
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] firmwareData in
                guard let self = self else { return }
                print("固件信息-----\(firmwareData)")
                if firmwareData.firmwareUrl != nil {
                    self.newVersion = true
                }else {
                    self.newVersion = false
                }
                self.currentFirmwareData = firmwareData
                DispatchQueue.main.async {
                    self.miniTableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { error in
                // 处理错误
                print("检查新版本失败: \(error)")
                self.newVersion = false
                self.miniTableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    
    // MARK: - Actions
    @objc private func connectionButtonTapped() {
        print("连接按钮点击")
        
        if deviceConnetedStatus == 0 {
            guard let device = deviceInfo else { return }
            
            let scannedDevices = BluetoothManager.shared.getAllScannedDevices()
            print("保存后的扫描设备--\(scannedDevices)")
            for scannedDevice in scannedDevices {
                if device.uuid == scannedDevice.peripheral.identifier.uuidString {
                    BluetoothManager.shared.connectToPeripheral(scannedDevice.peripheral)
                    return
                }
            }
            print("未找到当前设备，请保持设备开启")
            self.view.sw_showWarningToast("未找到当前设备，请保持设备开启")
        }else {
            BluetoothManager.shared.disconnectPeripheral()
        }

    }
    
    @objc private func refreshButtonTapped() {
        print("刷新设备参数...")
        refreshMiniDeviceData()
    }
    
    @objc private func settingsButtonTapped() {
        print("设置按钮点击")
        let settingVC = MiniDeviceSettingViewController()
        settingVC.deviceInfo = deviceInfo
        settingVC.statusInfo = statusInfo
        self.navigationController?.pushViewController(settingVC, animated: true)
    }
    
    private func pushToMsgVC() {
        if deviceConnetedStatus == 0 {
            // 弹框提醒，连接设备
            print("请先连接设备")
            view.sw_showWarningToast("请先连接设备")
            return
        }
        let vc = MiniDeviceMsgViewController()
        vc.deviceInfo = self.miniDeviceInfo
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func firmwareButtonTapped() {
        print("固件升级按钮点击")
        if deviceConnetedStatus == 0 {
            // 弹框提醒，连接设备
            print("请先连接设备")
            view.sw_showWarningToast("请先连接设备")
            return
        }
        // 跳转到固件升级页面
        let updateVC = MiniDeviceUpdateViewController()
        updateVC.currentVersion = miniVersion
        updateVC.currentFirmwareData = currentFirmwareData
        self.navigationController?.pushViewController(updateVC, animated: true)
    }
    
    @objc private func recordButtonTapped() {
        print("信息记录按钮点击")
        if deviceConnetedStatus == 0 {
            // 弹框提醒，连接设备
            print("请先连接设备")
            view.sw_showWarningToast("请先连接设备")
            return
        }
        BluetoothManager.shared.getSatelliteRecords()
        
        let msgVC = MiniDeviceNoSendMsgViewController()
        self.navigationController?.pushViewController(msgVC, animated: true)
    }
    
    @objc private func reSetButtonTapped() {
        print("复位按钮点击")
        if deviceConnetedStatus == 0 {
            // 弹框提醒，连接设备
            print("请先连接设备")
            view.sw_showWarningToast("请先连接设备")
            return
        }
        SWAlertView.showAlert(title: "复位设备", message: "您确定要复位该设备吗？") {
            BluetoothManager.shared.resetDevice()
        }

    }
    
    private func refreshMiniDeviceData() {
        BluetoothManager.shared.requestDeviceInfo()
        BluetoothManager.shared.requestStatusInfo()
        BluetoothManager.shared.getSatelliteSignal()
    }
}

// MARK: - BluetoothManagerDelegate
extension MiniDeviceDetailViewController: BluetoothManagerDelegate {
    public func didUpdateBluetoothState(_ state: CBManagerState) {
        
    }
    
    public func didDiscoverPeripheral(_ peripheral: CBPeripheral) {
        
    }
    
    public func didConnectPeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async { [weak self] in
            print("设备连接成功: \(peripheral.name ?? "未知设备")")
            self?.refreshMiniDeviceData()
            self?.deviceConnetedStatus = 1
            self?.miniTableView.reloadData()
        }
    }
    
    public func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
        // 处理断开连接
        print("设备断开连接: \(peripheral.name ?? "未知设备")")
        DispatchQueue.main.async { [weak self] in
            self?.deviceConnetedStatus = 0
            self?.miniTableView.reloadData()
        }
    }
    
    public func didFailToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        // 处理连接失败
        print("设备连接失败: \(peripheral.name ?? "未知设备") - \(error?.localizedDescription ?? "未知错误")")
        
    }
}

extension MiniDeviceDetailViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MiniDeviceBaseMsgCell") as! MiniDeviceBaseMsgCell
            if let deviceInfo = deviceInfo {
                cell.configure(with: deviceInfo.displayName, imei: deviceInfo.imei)
            }
            cell.changeStatus(isConnect: deviceConnetedStatus == 1)
            
            cell.connectionAction = { [weak self] in
                guard let self = self else {return}
                self.connectionButtonTapped()
            }
            cell.quintupleTapAction = { [weak self] in
                guard let self = self else {return}
                self.recordButtonTapped()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MiniDeviceStatusCell") as! MiniDeviceStatusCell
            cell.resetStatus(isConnect: deviceConnetedStatus == 1)
            cell.refreshAction = { [weak self] in
                guard let self = self else {return}
                self.refreshButtonTapped()
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MiniDeviceSettingCell") as! MiniDeviceSettingCell
            cell.upDateFrimwareTip(showTip: newVersion)
            cell.selectedCallback = { [weak self] index in
                guard let self = self else {return}
                switch index {
                case 0:
                    self.settingsButtonTapped()
                    return
                case 1:
                    self.reSetButtonTapped()
                    return
                case 2:
                    self.pushToMsgVC()
                    return
                case 3:
                    self.firmwareButtonTapped()
                    return
                default:
                    return
                }
            }
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 180
        case 1:
            return 180
        case 2:
            return 130
        default:
            return 200
        }
    }
}

