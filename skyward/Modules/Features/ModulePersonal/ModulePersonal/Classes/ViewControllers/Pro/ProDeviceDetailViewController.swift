//
//  ProDetailViewControll.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit
import SWKit
import ModuleLogin

class ProDeviceDetailViewController: PersonalBaseViewController {
    
    // 添加WiFi设备管理器
    private let wifiDeviceManager = WiFiDeviceManager.shared
    private var deviceStatus: ProDeviceStatus?
    private var environmentInfo: EnvironmentInfo?
    private var satelliteLinkStatus: SatelliteLinkStatus?
    private var rxSnr: Int?
    private var txSnr: Int?
    private var upText: String?
    private var downText: String?
    private var statusUpdateTimer: Timer?
    
    private let viewModel = PersonalViewModel()
    private var mode: Int = 1
    private var isHaveGetDeviceMsg: Bool = false
    private var connect = false
    private var collectingSuccess = false
    
    
    private lazy var proTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor(str: "#F2F3F4")
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(ProDeviceBaseMsgCell.self, forCellReuseIdentifier: "ProDeviceBaseMsgCell")
        tableView.register(ProDeviceStatusCell.self, forCellReuseIdentifier: "ProDeviceStatusCell")
        tableView.register(ProDeviceSettingCell.self, forCellReuseIdentifier: "ProDeviceSettingCell")
        
        return tableView
    }()
    
    private let baseControlView = ProDeviceBaseControlView()
    
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
        }else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        customTitle.text = "详情"
        
        view.addSubview(proTableView)
        baseControlView.translatesAutoresizingMaskIntoConstraints = false
        baseControlView.collectionAction = { [weak self] in
            guard let self = self else {return}
            self.performAutoOff()
            
        }
        baseControlView.lineStarAction = { [weak self] in
            guard let self = self else {return}
            self.performAutoSatellite()
        }
        view.addSubview(baseControlView)
        
        NSLayoutConstraint.activate([
            
            proTableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            proTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            proTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            proTableView.bottomAnchor.constraint(equalTo: baseControlView.topAnchor),
            
            baseControlView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            baseControlView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            baseControlView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            baseControlView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    private func setupWiFiDeviceManager() {
        wifiDeviceManager.onConnectionStatusChanged = { [weak self] isConnected in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(isConnected)
                self?.proTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                
                if !isConnected {
                    self?.stopStatusUpdates()
                }
            }
        }
        
        wifiDeviceManager.onStatusUpdate = { [weak self] status in
            DispatchQueue.main.async {
                self?.deviceStatus = status
                self?.proTableView.reloadData()
            }
        }
        
        wifiDeviceManager.onLogReceived = { log in
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
        self.connect = wifiDeviceManager.isConnected
        self.proTableView.reloadData()
        
        if wifiDeviceManager.isConnected {
            statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.updateDeviceStatus()
                self?.updateEnvironmentInfo()
                self?.updateProNetworkStatus()
                self?.updateProNetworkSpeed()
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
                    if status.antennaStatus == .stableTracking {
                        self?.getProDeviceMsg()
                    }
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
                    self?.proTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                }
            case .failure(let error):
                print("环境信息更新失败: \(error)")
            }
        }
    }
    
    private func updateProNetworkStatus() {
        guard let url = URL(string: "http://192.168.0.8/action/homestatus") else {
            print("无效的URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("请求错误: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("服务器返回错误")
                return
            }
            
            if let data = data {
                do {
                    let homeStatus = try JSONDecoder().decode(HomeStatusData.self, from: data)
                    DispatchQueue.main.async {
                        self.satelliteLinkStatus = homeStatus.satelliteLinkStatus
                        self.rxSnr = homeStatus.rf_rx_snr
                        self.txSnr = homeStatus.rf_tx_snr
                        self.proTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
                    }
                } catch {
                    print("JSON解析错误: \(error)")
                }
            }
        }
        
        task.resume()
    }
    
    private func updateProNetworkSpeed() {
        guard let url = URL(string: "http://192.168.0.8/action/sysTrafficGet") else {
            print("无效的URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("请求错误: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("服务器返回错误")
                return
            }
            
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(SysTrafficResponse.self, from: data)
                    // 检查返回码
                    guard response.code == "0" else {
                        print("返回的数据不可以使用")
                        return
                    }
                    print("解析成功:")
                    let receiveFormatted = FormattedBandwidth.format(bytes: response.receiveBandwidth).displayString
                    let transmitFormatted = FormattedBandwidth.format(bytes: response.transmitBandwidth).displayString
                    print("receiveFormatted: \(receiveFormatted)")
                    print("transmitFormatted: \(transmitFormatted)")
                    DispatchQueue.main.async {
                        self.upText = receiveFormatted
                        self.downText = transmitFormatted
                        self.proTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                    }
                } catch {
                    print("JSON解析错误: \(error)")
                }
            }
        }
        
        task.resume()
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
                    self?.connect = true
                    self?.proTableView.reloadData()
                    self?.updateConnectionStatus(true)
                }
            case .failure(_):
                DispatchQueue.main.async {
                    self?.view.sw_showWarningToast("连接失败: 请确认您的WiFi连接正确")
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
                
                
            }
        }
    }
    
    private func performAutoSatellite() {
        guard wifiDeviceManager.isConnected else {
            view.sw_showWarningToast("请先连接设备")
            return
        }
        
        let customView = ProDeviceModelChooseView()
        customView.modeChooleWithIndex = { index in
            self.mode = index
        }
        SWAlertView.showCustomAlert(title: "选择模式", customView: customView, confirmTitle: "确定", cancelTitle: "取消", confirmHandler: { [weak self] in
            self?.satelliteClick()
        })
        
        
    }
    
    private func satelliteClick() {
        guard let location = LocationManager.lastLocation() else { return }
        // 对中国经纬度进行限制处理
        var longitude = location.coordinate.longitude
        var latitude = location.coordinate.latitude
        
        // 中国经度范围：73°E 到 135°E
        // 东经为正，西经为负，所以都是正值
        if longitude > 135 {
            longitude = 135
        } else if longitude < 73 {
            longitude = 73
        }
        
        // 中国纬度范围：3°N 到 54°N
        // 北纬为正，南纬为负
        if latitude > 54 {
            latitude = 54
        } else if latitude < 3 {
            latitude = 3
        }
        wifiDeviceManager.halfSatellite(longitude: longitude, latitude: latitude, altitude: location.altitude, mode: mode) { [weak self] result in
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
    
    private func getProDeviceMsg() {
        if !isHaveGetDeviceMsg {
            WiFiDeviceManager.shared.queryDeviceInfo { [weak self] result in
                switch result {
                case .success(let deviceInfo):
                    DispatchQueue.main.async {
                        self?.isHaveGetDeviceMsg = true
                        // 保存设备信息到后台
                        UserManager.shared.bindDevice(serialNum: deviceInfo.deviceSN, macAddress: deviceInfo.catMAC) { result in
                            
                        }
                    }
                case .failure(let error):
                    print("设备信息失败: \(error)")
                    DispatchQueue.main.async {
                        self?.view.sw_showSuccessToast("获取设备信息失败")
                    }
                }
            }
        }
    }
    
}

extension ProDeviceDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceBaseMsgCell") as! ProDeviceBaseMsgCell
            cell.changeStatus(isConnect: connect)
            cell.quintupleTapAction = { [weak self] in
                guard let self = self else {return}
                self.pushToDebugVC()
            }
            if let upText = upText, let downText = downText {
                cell.updateNetworkSpeed(upText: upText, downText: downText)
            }
            if let rxSnr = rxSnr, let txSnr = txSnr {
                cell.updateNetworkSNR(rxSnr: rxSnr, txSnr: txSnr)
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceStatusCell") as! ProDeviceStatusCell
            if let deviceStatus = deviceStatus {
                cell.configon(with: deviceStatus)
            }
            if let environmentInfo = environmentInfo {
                cell.configonEnvironment(with: environmentInfo)
            }
            if let satelliteLinkStatus = satelliteLinkStatus {
                cell.configRunStatus(with: satelliteLinkStatus)
            }
            cell.refreshAction = { [weak self] in
                guard let self = self else { return }
                self.updateDeviceStatus()
            }
            return cell
        case 2:
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
                    self.pushToWebVC(with: "http://192.168.0.1", title: "路由器设置")
                    return
                case 5:
                    self.pushToWebVC(with: "http://192.168.0.8", title: "卫星参数")
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
            return 200
        case 1:
            return 260
        case 2:
            return 220
        default:
            return 200
        }
    }
}

extension ProDeviceDetailViewController {
    
    private func pushToAlarmVC() {
        stopStatusUpdates()
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
    
    private func pushToWebVC(with url: String, title: String) {
        let webVC = WebViewController(urlString: url, title: title)
        self.navigationController?.pushViewController(webVC, animated: true)
        
    }
    
    private func pushToDebugVC() {
        let vc = ProDeviceDebugViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
