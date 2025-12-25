//
//  DeviceUpdateViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/20.
//

import UIKit
import SWKit

class MiniDeviceUpdateViewController: PersonalBaseViewController {
    
    private var deviceInfo: DeviceInfo?
    
    private var firmwareImageView = UIImageView()
    private var firmwareVersionLabel = UILabel()
    private var firmwareMessageLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setConstraint()
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getDeviceInfo()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "固件"
        
        firmwareImageView.translatesAutoresizingMaskIntoConstraints = false
        firmwareImageView.image = PersonalModule.image(named: "device_mini_firmware_noUpdate")
        firmwareImageView.contentMode = .scaleAspectFit
        view.addSubview(firmwareImageView)
        
        firmwareVersionLabel.translatesAutoresizingMaskIntoConstraints = false
        firmwareVersionLabel.text = "当前版本：固件_0.0.0.1"
        firmwareVersionLabel.textColor = .black
        firmwareVersionLabel.textAlignment = .center
        firmwareVersionLabel.font = .systemFont(ofSize: 20, weight: .medium)
        view.addSubview(firmwareVersionLabel)
        
        firmwareMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        firmwareMessageLabel.text = "已是最新版本"
        firmwareMessageLabel.textColor = UIColor(hex: "#84888C")
        firmwareMessageLabel.textAlignment = .center
        firmwareMessageLabel.font = .systemFont(ofSize: 12, weight: .regular)
        view.addSubview(firmwareMessageLabel)
    }
    
    private func setConstraint() {
        NSLayoutConstraint.activate([
            firmwareImageView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 80),
            firmwareImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firmwareImageView.widthAnchor.constraint(equalToConstant: 100),
            firmwareImageView.heightAnchor.constraint(equalToConstant: 100),
            
            firmwareVersionLabel.topAnchor.constraint(equalTo: firmwareImageView.bottomAnchor, constant: 20),
            firmwareVersionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            firmwareMessageLabel.topAnchor.constraint(equalTo: firmwareVersionLabel.bottomAnchor, constant: 10),
            firmwareMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceInfoUpdate(_:)),
            name: .didReceiveDeviceInfo,
            object: nil
        )
    }
    
    @objc private func handleDeviceInfoUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let deviceInfo = userInfo["deviceInfo"] as? DeviceInfo else {
            return
        }
        
        DispatchQueue.main.async {
            self.deviceInfo = deviceInfo
//            self.updateParametersView()
            self.firmwareVersionLabel.text = "当前版本：固件_\(formatVersion(deviceInfo.mcuSoftwareVersion))"
        }
    }
    
    private func getDeviceInfo() {
        BluetoothManager.shared.requestDeviceInfo()
    }
    
    // 固件升级
    func startFirmwareUpgrade() {
        let firmwarePath = Bundle.main.path(forResource: "txw_v1.0.0.7", ofType: "bin") ?? ""
        let version = "1.0.0.7"
        
        BluetoothManager.shared.startCompleteFirmwareUpgrade(
            version: version,
            firmwarePath: firmwarePath
        )
    }
}
