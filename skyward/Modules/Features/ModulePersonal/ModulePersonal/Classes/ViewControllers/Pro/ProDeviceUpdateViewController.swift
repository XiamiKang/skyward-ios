//
//  ProDeviceUpdateViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit
import Combine

class ProDeviceUpdateViewController: PersonalBaseViewController {
    
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var downloadStatusMessage = ""
    @Published var downloadedFileURL: URL?
    
    private let viewModel = PersonalViewModel()
    private var currentVersion: String = "1.0.0.0"
    private var currentFirmwareData: FirmwareData?
    private let firmwareManager = FirmwareManager.shared
    
    // UI
    private var firmwareImageView = UIImageView()
    private var firmwareVersionLabel = UILabel()
    private var firmwareMessageLabel = UILabel()
    private let firmwareWarnImageView = UIImageView()
    private var firmwareWarnLabel = UILabel()
    private let firmwareUpdateView = UIView()
    private var firmwareUpdateText = UILabel()
    private let firmwareUpdateActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setConstraint()
        setupTapGesture()
        getVersionMsg()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "固件升级"
        
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
        
        firmwareWarnImageView.translatesAutoresizingMaskIntoConstraints = false
        firmwareWarnImageView.image = PersonalModule.image(named: "device_pro_warnning")
        firmwareWarnImageView.contentMode = .scaleAspectFit
        firmwareWarnImageView.isHidden = true
        view.addSubview(firmwareWarnImageView)
        
        firmwareWarnLabel.translatesAutoresizingMaskIntoConstraints = false
        firmwareWarnLabel.text = "请先下载固件，然后连接设备Wi-Fi更新"
        firmwareWarnLabel.textColor = UIColor(str: "#FF9447")
        firmwareWarnLabel.font = .systemFont(ofSize: 12, weight: .medium)
        firmwareWarnLabel.isHidden = true
        view.addSubview(firmwareWarnLabel)
        
        firmwareUpdateView.translatesAutoresizingMaskIntoConstraints = false
        firmwareUpdateView.backgroundColor = UIColor(str: "#FE6A00")
        firmwareUpdateView.layer.cornerRadius = 8
        firmwareUpdateView.isHidden = true
        view.addSubview(firmwareUpdateView)
        
        firmwareUpdateText.translatesAutoresizingMaskIntoConstraints = false
        firmwareUpdateText.text = "下载固件"
        firmwareUpdateText.textColor = .white
        firmwareUpdateText.font = .systemFont(ofSize: 16, weight: .semibold)
        firmwareUpdateText.textAlignment = .center
        firmwareUpdateView.addSubview(firmwareUpdateText)
        
        firmwareUpdateActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        firmwareUpdateActivityIndicator.hidesWhenStopped = true
        firmwareUpdateActivityIndicator.color = .white
        firmwareUpdateView.addSubview(firmwareUpdateActivityIndicator)
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
            
            firmwareWarnLabel.topAnchor.constraint(equalTo: firmwareMessageLabel.bottomAnchor, constant: 12),
            firmwareWarnLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            firmwareWarnImageView.trailingAnchor.constraint(equalTo: firmwareWarnLabel.leadingAnchor, constant: 15),
            firmwareWarnImageView.centerYAnchor.constraint(equalTo: firmwareWarnLabel.centerYAnchor),
            firmwareWarnImageView.widthAnchor.constraint(equalToConstant: 12),
            firmwareWarnImageView.heightAnchor.constraint(equalToConstant: 12),
            
            firmwareUpdateView.topAnchor.constraint(equalTo: firmwareWarnLabel.bottomAnchor, constant: 40),
            firmwareUpdateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            firmwareUpdateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            firmwareUpdateView.heightAnchor.constraint(equalToConstant: 48),
            
            firmwareUpdateText.centerXAnchor.constraint(equalTo: firmwareUpdateView.centerXAnchor),
            firmwareUpdateText.centerYAnchor.constraint(equalTo: firmwareUpdateView.centerYAnchor),
            firmwareUpdateText.leadingAnchor.constraint(equalTo: firmwareUpdateView.leadingAnchor, constant: 16),
            firmwareUpdateText.trailingAnchor.constraint(equalTo: firmwareUpdateView.trailingAnchor, constant: -16),
            
            firmwareUpdateActivityIndicator.centerYAnchor.constraint(equalTo: firmwareUpdateView.centerYAnchor),
            firmwareUpdateActivityIndicator.trailingAnchor.constraint(equalTo: firmwareUpdateText.leadingAnchor, constant: -8)
        ])
    }
    
    // MARK: - 设置点击手势
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(firmwareUpdateViewTapped))
        firmwareUpdateView.addGestureRecognizer(tapGesture)
        firmwareUpdateView.isUserInteractionEnabled = true
    }
    
    // MARK: - 获取版本信息
    private func getVersionMsg() {
        WiFiDeviceManager.shared.queryDeviceInfo { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let info):
                self.currentVersion = String(info.ACUVersion.dropFirst())
                DispatchQueue.main.async {
                    self.firmwareVersionLabel.text = "当前版本：固件_\(self.currentVersion)"
                }
                let savedVersion = firmwareManager.getCurrentStoredVersion()
                
                switch currentVersion.compareVersion(savedVersion) {
                case .orderedAscending:
                    print("\(currentVersion) < \(savedVersion)")
                    if let firmwareData = firmwareManager.getDownloadedFirmware() {
                        updateUI(firmwareData: firmwareData)
                    }
                case .orderedDescending:
                    print("\(currentVersion) > \(savedVersion)")
                case .orderedSame:
                    print("\(currentVersion) == \(savedVersion)")
                }
                

                
            case .failure(let error):
                // 处理错误
                print("获取设备信息失败: \(error)")
            }
        }
    }
    
    private func updateUI(firmwareData: LocalFirmwareInfo) {
        DispatchQueue.main.async {
            let versionName = firmwareData.versionName
            self.firmwareVersionLabel.text = "发现新版本：固件_\(versionName)"
            self.firmwareWarnLabel.isHidden = false
            self.firmwareWarnImageView.isHidden = false
            self.firmwareUpdateView.isHidden = false
            self.firmwareUpdateText.text = "下载完成，立即安装"
            // 检查是否需要强制更新
            if firmwareData.forceUpdate == true {
                self.firmwareWarnLabel.text = "此版本为强制更新，请务必下载并安装"
                self.firmwareWarnLabel.textColor = UIColor(str: "#FF3B30")
            }
        }
    }
    
    // MARK: - 按钮点击事件
    @objc private func firmwareUpdateViewTapped() {
        installFirmware()
    }
    
    // MARK: - 下载相关方法
    private func installFirmware() {
        guard let fileURL = firmwareManager.getDownloadedFirmwarePath() else {
            showErrorAlert(message: "没有找到固件文件")
            return
        }
        
        // 这里可以实现通过Wi-Fi安装固件的逻辑
        showInstallAlert(fileURL: fileURL)
    }
    
    
    // MARK: - 弹窗提示
    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func showSuccessAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "成功", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func showInstallAlert(fileURL: URL) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "安装固件", message: "请确保设备已连接Wi-Fi，然后开始安装固件", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "开始安装", style: .default) { _ in
                self.startFirmwareUpgrade(fileURL: fileURL)
            })
            
            self.present(alert, animated: true)
        }
    }
    
}


extension ProDeviceUpdateViewController {
    
    private func startFirmwareUpgrade(fileURL: URL) {
        guard WiFiDeviceManager.shared.isConnected == false else {
            showErrorAlert(message: "设备未连接")
            return
        }
        
        let upgradeManager = AdvancedFirmwareUpdateManager(deviceManager: WiFiDeviceManager.shared)
        
        // 显示升级弹窗并开始升级
        let dialog = FirmwareUpgradeDialog.showAndStartUpgrade(
            in: self.view,
            upgradeManager: upgradeManager,
            firmwarePath: fileURL.path,
            onComplete: { [weak self] result in
                switch result {
                case .success:
                    self?.showUpgradeSuccessAlert()
                case .failure(let error):
                    self?.showUpgradeErrorAlert(error: error)
                }
            },
            onCancel: { [weak self] in
                self?.showCanceledAlert()
            }
        )
        
        // 保存dialog引用，防止被释放
        currentUpgradeDialog = dialog
    }
    
    private var currentUpgradeDialog: FirmwareUpgradeDialog? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.upgradeDialog) as? FirmwareUpgradeDialog }
        set { objc_setAssociatedObject(self, &AssociatedKeys.upgradeDialog, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private struct AssociatedKeys {
        static var upgradeDialog = "upgradeDialog"
    }
    
    private func showUpgradeSuccessAlert() {
        let alert = UIAlertController(
            title: "升级成功",
            message: "固件升级已完成，设备将自动重启。请稍后重新连接设备。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            // 返回到设备列表或首页
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showUpgradeErrorAlert(error: Error) {
        let errorMessage: String
        if let firmwareError = error as? FirmwareUpdateError {
            errorMessage = firmwareError.errorDescription ?? error.localizedDescription
        } else if let otaError = error as? OTAUpgradeError {
            errorMessage = otaError.errorDescription ?? error.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        
        let alert = UIAlertController(
            title: "升级失败",
            message: "\(errorMessage)\n\n请检查设备连接并重试。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "重试", style: .default) { _ in
            // 重新尝试升级
            if let fileURL = self.downloadedFileURL {
                self.startFirmwareUpgrade(fileURL: fileURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showCanceledAlert() {
        let alert = UIAlertController(
            title: "升级已取消",
            message: "固件升级已被取消，设备可能需要重新启动。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        
        present(alert, animated: true)
    }
}
