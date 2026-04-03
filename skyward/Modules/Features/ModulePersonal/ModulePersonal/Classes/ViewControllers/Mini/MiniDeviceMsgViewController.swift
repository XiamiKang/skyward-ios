//
//  ProDeviceMsgInfo.swift
//  Pods
//
//  Created by TXTS on 2025/12/31.
//

import UIKit
import SWKit

class MiniDeviceMsgViewController: PersonalBaseViewController {
    
    var deviceInfo: DeviceInfo
    var imeiStr: String
    
    var dataSource: [[ProDeviceMsgInfo]]?
    
    init(deviceInfo: DeviceInfo, imeiStr: String, dataSource: [[ProDeviceMsgInfo]]? = nil) {
        self.deviceInfo = deviceInfo
        self.imeiStr = imeiStr
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(ProDeviceMsgCell.self, forCellReuseIdentifier: "ProDeviceMsgCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        setNotification()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "设备信息"
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
    }
    
    private func loadData() {
        dataSource = [
            [ProDeviceMsgInfo(title: "IMEI", value: imeiStr),
             ProDeviceMsgInfo(title: "设备型号", value: BluetoothManager.shared.deviceType == .TXTS ? "TXTS-NB-01" : uint64ToAsciiString(deviceInfo.deviceId)),
             ProDeviceMsgInfo(title: "协议版本号", value: formatVersion(deviceInfo.protocolVersion)),
            ProDeviceMsgInfo(title: "固件版本号", value: formatVersion(deviceInfo.mcuSoftwareVersion))]
        ]
        saveDeviceInfoToCache(deviceInfo)
        tableView.reloadData()
    }
    
    private func setNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showDeviceInfo(_:)),
                                               name: .didReceiveDeviceInfo,
                                               object: nil)
    }
    
    @objc private func showDeviceInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let deviceInfo = userInfo["deviceInfo"] as? DeviceInfo {
            print("Mini设备信息---\(deviceInfo)")
            self.deviceInfo = deviceInfo
            dataSource = [
                [ProDeviceMsgInfo(title: "IMEI", value: imeiStr),
                 ProDeviceMsgInfo(title: "设备型号", value: BluetoothManager.shared.deviceType == .TXTS ? "TXTS-NB-01" : uint64ToAsciiString(deviceInfo.deviceId)),
                 ProDeviceMsgInfo(title: "协议版本号", value: formatVersion(deviceInfo.protocolVersion)),
                 ProDeviceMsgInfo(title: "固件版本号", value: formatVersion(deviceInfo.mcuSoftwareVersion))]
            ]
            saveDeviceInfoToCache(deviceInfo)
            tableView.reloadData()
        }
    }

    
    private func saveDeviceInfoToCache(_ deviceInfo: DeviceInfo) {
        // 使用UserDefaults缓存设备信息
        let userDefaults = UserDefaults.standard
        let IMEIStr = imeiStr
        let protocolVersionStr = formatVersion(deviceInfo.protocolVersion)
        let mcuSoftwareVersionStr = formatVersion(deviceInfo.mcuSoftwareVersion)
        userDefaults.set(IMEIStr, forKey: "LastMiniDeviceIMEI")
        userDefaults.set(protocolVersionStr, forKey: "LastMiniDeviceProVer")
        userDefaults.set(mcuSoftwareVersionStr, forKey: "LastMiniDeviceSoftVer")
        userDefaults.synchronize()
    }
    
    private func loadDeviceInfoFromCache() {
        let userDefaults = UserDefaults.standard
        let IMEIStr = userDefaults.string(forKey: "LastMiniDeviceIMEI") ?? "--"
        let protocolVersionStr = userDefaults.string(forKey: "LastMiniDeviceProVer") ?? "--"
        let mcuSoftwareVersionStr = userDefaults.string(forKey: "LastMiniDeviceSoftVer") ?? "--"
        
        dataSource = [
            [ProDeviceMsgInfo(title: "IMEI", value: IMEIStr),
            ProDeviceMsgInfo(title: "设备型号", value: BluetoothManager.shared.deviceType == .TXTS ? "TXTS-NB-01" : uint64ToAsciiString(deviceInfo.deviceId)),
             ProDeviceMsgInfo(title: "协议版本号", value: protocolVersionStr),
            ProDeviceMsgInfo(title: "固件版本号", value: mcuSoftwareVersionStr)]
        ]
    }
}

extension MiniDeviceMsgViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowData = dataSource?[section]
        return rowData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceMsgCell") as! ProDeviceMsgCell
        if let data = dataSource?[indexPath.section][indexPath.row] {
            cell.configure(with: data)
        }
        return cell
    }
}
