//
//  ProDetailViewControll.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit
import SWKit

class ProDeviceDetailViewController: PersonalBaseViewController {
    
    // 添加WiFi设备管理器
    private let wifiDeviceManager = WiFiDeviceManager.shared
    private var deviceStatus: ProDeviceStatus?
    private var environmentInfo: EnvironmentInfo?
    private var statusUpdateTimer: Timer?
    
    private lazy var proTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(str: "#F2F3F4")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(ProDeviceBaseMsgCell.self, forCellReuseIdentifier: "ProDeviceBaseMsgCell")
        tableView.register(ProDeviceStatusCell.self, forCellReuseIdentifier: "ProDeviceStatusCell")
        tableView.register(ProDeviceEveromentCell.self, forCellReuseIdentifier: "ProDeviceEveromentCell")
        tableView.register(ProDeviceLowPowerCell.self, forCellReuseIdentifier: "ProDeviceLowPowerCell")
        tableView.register(ProDeviceSettingCell.self, forCellReuseIdentifier: "ProDeviceSettingCell")
        
        return tableView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupWiFiDeviceManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startStatusUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopStatusUpdates()
    }
    
    override func backButtonTapped() {
        if let vc = self.navigationController?.viewControllers.first(where: { $0 is DeviceListViewController }) {
            self.navigationController?.popToViewController(vc, animated: true)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        customTitle.text = "详情"
        
        view.addSubview(proTableView)
        
        NSLayoutConstraint.activate([
            
            proTableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            proTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            proTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            proTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
        ])
    }
    
    private func setupWiFiDeviceManager() {
        wifiDeviceManager.onConnectionStatusChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(isConnected)
                self?.proTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        }
        
        wifiDeviceManager.onStatusUpdate = { [weak self] status in
            DispatchQueue.main.async {
                self?.deviceStatus = status
                self?.proTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
        }
        
        wifiDeviceManager.onLogReceived = { [weak self] log in
            print("WiFi设备日志: \(log)")
        }
        
        wifiDeviceManager.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.view.sw_showWarningToast(error.localizedDescription)
            }
        }
    }
    
    // MARK: - 状态更新
    private func startStatusUpdates() {
        // 如果已经连接，开始定时更新状态
        if wifiDeviceManager.isConnected {
            // 连接成功后立即获取一次状态
            if let cell = self.proTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProDeviceBaseMsgCell {
                cell.changeStatus(isConnect: true)
            }
            statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
                self?.updateDeviceStatus()
            }
        }else {
            connectToWiFiDevice()
        }
    }
    
    private func stopStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    private func updateDeviceStatus() {
        wifiDeviceManager.queryLocation { [weak self] result in
            switch result {
            case .success(let status):
                DispatchQueue.main.async {
                    self?.deviceStatus = status
                    self?.proTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                    
                }
            case .failure(let error):
                print("状态更新失败: \(error)")
            }
        }
    }
    
    private func updateEnvironmentInfo() {
        wifiDeviceManager.queryEnvironment { [weak self] result in
            switch result {
            case .success(let envInfo):
                DispatchQueue.main.async {
                    self?.environmentInfo = envInfo
                    self?.proTableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
                }
            case .failure(let error):
                print("环境信息更新失败: \(error)")
            }
        }
    }
    
    private func updateConnectionStatus(_ isConnected: Bool) {
        if isConnected {
            updateDeviceStatus()
            updateEnvironmentInfo()
            startStatusUpdates()
        } else {
            stopStatusUpdates()
        }
    }
    
    // MARK: - 设备控制方法
    private func connectToWiFiDevice() {
        wifiDeviceManager.connect { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    // 连接成功后立即获取一次状态
                    if let cell = self?.proTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProDeviceBaseMsgCell {
                        cell.changeStatus(isConnect: true)
                    }
                    self?.updateConnectionStatus(true)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.view.sw_showWarningToast("连接失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func disconnectFromWiFiDevice() {
        wifiDeviceManager.disconnect()
        view.sw_showSuccessToast("设备已断开连接")
    }
    
    private func performAutoOff() {
        guard wifiDeviceManager.isConnected else {
            view.sw_showWarningToast("请先连接设备")
            return
        }
        
        // 在BaseMsgCell中会处理按钮状态
        wifiDeviceManager.autoOff { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    let message = success ? "一键收藏成功" : "一键收藏失败"
                    self?.view.sw_showSuccessToast(message)
                case .failure(let error):
                    self?.view.sw_showWarningToast("收藏失败: \(error.localizedDescription)")
                }
                
                // 通知Cell更新按钮状态
                if let cell = self?.proTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProDeviceBaseMsgCell {
                    cell.stopCollecting()
                }
            }
        }
    }
    
    private func performAutoSatellite() {
        guard wifiDeviceManager.isConnected else {
            view.sw_showWarningToast("请先连接设备")
            return
        }
        
        guard let location = LocationManager.lastLocation() else { return }
        wifiDeviceManager.halfSatellite(longitude: location.coordinate.longitude, latitude: location.coordinate.latitude, altitude: location.altitude) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let alignmentResult):
                    self.view.sw_showSuccessToast("自动对星成功")
                    // 更新状态显示
                    self.deviceStatus = ProDeviceStatus(
                        lockStatus: alignmentResult.lockStatus,
                        antennaStatus: alignmentResult.antennaStatus,
                        azimuth: alignmentResult.azimuth,
                        elevation: alignmentResult.elevation,
                        altitude: alignmentResult.altitude,
                        longitude: alignmentResult.longitude,
                        latitude: alignmentResult.latitude,
                        powerSavingMode: false,
                        logStreaming: false,
                        mode: 1
                    )
                    self.proTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                    
                case .failure(let error):
                    self.view.sw_showWarningToast("对星失败: \(error.localizedDescription)")
                }
                
                // 通知Cell更新按钮状态
                if let cell = self.proTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProDeviceBaseMsgCell {
                    cell.stopLiningStar()
                }
            }
        }
    }
    
    private func performDeepSleep(enable: Bool) {
        guard wifiDeviceManager.isConnected else {
            view.sw_showWarningToast("请先连接设备")
            return
        }
        
        wifiDeviceManager.deepSleep(enable: enable) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    let message = enable ? (success ? "低功耗模式已开启" : "开启失败") : (success ? "低功耗模式已关闭" : "关闭失败")
                    if success {
                        self?.view.sw_showSuccessToast(message)
                    }else {
                        self?.view.sw_showWarningToast(message)
                    }
                case .failure(let error):
                    self?.view.sw_showWarningToast("低功耗模式操作失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
}

extension ProDeviceDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceBaseMsgCell") as! ProDeviceBaseMsgCell
            cell.collectionAction = { [weak self] in
                guard let self = self else {return}
                self.performAutoOff()
            }
            cell.lineStarAction = { [weak self] in
                guard let self = self else {return}
                self.performAutoSatellite()
            }
            cell.quintupleTapAction = { [weak self] in
                guard let self = self else {return}
                self.pushToDebugVC()
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceStatusCell") as! ProDeviceStatusCell
            if let deviceStatus = deviceStatus {
                cell.configon(with: deviceStatus)
            }
            cell.refreshAction = { [weak self] in
                guard let self = self else { return }
                self.updateDeviceStatus()
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceEveromentCell") as! ProDeviceEveromentCell
            if let environmentInfo = environmentInfo {
                cell.configon(with: environmentInfo)
            }
            cell.refreshAction = { [weak self] in
                guard let self = self else { return }
                self.updateEnvironmentInfo()
            }
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceLowPowerCell") as! ProDeviceLowPowerCell
            
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceSettingCell") as! ProDeviceSettingCell
            cell.selectedCallback = { [weak self] index in
                guard let self = self else {return}
                switch index {
                case 0:
                    self.pushToAlarmVC()
                    return
                case 1:
                    self.showResetAlertView()
                    return
                case 2:
                    self.pushToMsgVC()
                    return
                case 3:
                    self.pushToUpdateVC()
                    return
                case 4:
                    self.pushToWebVC()
                    return
                case 5:
                    self.pushToWebVC()
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 150
        case 1:
            return 240
        case 2:
            return 120
        case 3:
            return 60
        case 4:
            return 220
        default:
            return 200
        }
    }
}

extension ProDeviceDetailViewController {
    
    private func pushToAlarmVC() {
        let vc = ProDeviceAlarmViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showResetAlertView() {
        print("展示重启弹框")
        SWAlertView.showAlert(
            title: "复位重启",
            message: "您确定要重启设备吗？"
        ) {
            // 点击确定后的回调
            print("用户点击了确定")
            self.wifiDeviceManager.reset { [weak self] result in
                switch result {
                case .success(let status):
                    DispatchQueue.main.async {
                        self?.view.sw_showSuccessToast("重启成功")
                    }
                case .failure(let error):
                    print("状态更新失败: \(error)")
                    DispatchQueue.main.async {
                        self?.view.sw_showWarningToast("重启失败")
                    }
                }
            }
        }
    }
    
    private func pushToMsgVC() {
        let vc = ProDeviceMsgViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushToUpdateVC() {
        let vc = ProDeviceUpdateViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushToWebVC() {
        print("跳转web")
    }
    
    private func pushToDebugVC() {
        let vc = ProDeviceDebugViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
