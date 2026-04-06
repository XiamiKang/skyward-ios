

import UIKit
import SWKit
import Combine

class MiniDeviceUpdateViewController: PersonalBaseViewController {
    
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var downloadStatusMessage = ""
    @Published var downloadedFileURL: URL?
    
    private let viewModel = PersonalViewModel()
    private var cancellables = Set<AnyCancellable>()
    var currentVersion: String
    var currentFirmwareData: FirmwareData?
    private let frqBluetoothManager = FRQBluetoothManager.share()
    
    // UI
    private var firmwareImageView = UIImageView()
    private var firmwareVersionLabel = UILabel()
    private var firmwareMessageLabel = UILabel()
    private let firmwareWarnImageView = UIImageView()
    private var firmwareWarnLabel = UILabel()
    private let firmwareUpdateView = UIView()
    private var firmwareUpdateText = UILabel()
    private let firmwareUpdateActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    init(currentVersion: String = "1.0.0.0", currentFirmwareData: FirmwareData?) {
        self.currentVersion = currentVersion
        self.currentFirmwareData = currentFirmwareData
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setConstraint()
        setupTapGesture()
        getVersionMsg()
        setupFRQBluetoothManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 页面消失时暂停下载
        if isDownloading {
            FirmwareDownloadManager.shared.pauseDownload()
            updateButtonState(isDownloading: false, progress: downloadProgress, text: "下载暂停")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "固件升级"
        
        firmwareImageView.translatesAutoresizingMaskIntoConstraints = false
        firmwareImageView.image = PersonalModule.image(named: "device_mini_firmware_noUpdate")
        firmwareImageView.contentMode = .scaleAspectFit
        view.addSubview(firmwareImageView)
        
        firmwareVersionLabel.translatesAutoresizingMaskIntoConstraints = false
        firmwareVersionLabel.text = "当前版本：固件_\(self.currentVersion)"
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
    
    // MARK: - 设置下载监听
    private func setupDownloadObserver() {
        FirmwareDownloadManager.shared.$downloadStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleDownloadStatus(status)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 获取版本信息
    private func getVersionMsg() {
        if let firmwareData = currentFirmwareData
        {
            self.updateUI(firmwareData: firmwareData)
            setupDownloadObserver()
            // 检查是否已经下载过
            if FirmwareDownloadManager.shared.firmwareFileExists(firmwareData: firmwareData) {
                self.updateButtonState(isDownloading: false, progress: 1.0, text: "下载完成，立即安装")
            }
        }else {
            firmwareVersionLabel.text = "当前版本：固件_\(self.currentVersion)"
            firmwareMessageLabel.text = "已是最新版本"
            self.firmwareWarnLabel.isHidden = true
            self.firmwareWarnImageView.isHidden = true
            self.firmwareUpdateView.isHidden = true
        }
    }
    
    private func setupFRQBluetoothManager() {
        frqBluetoothManager.delegate = self
    }
    
    private func updateUI(firmwareData: FirmwareData) {
        DispatchQueue.main.async {
            if let versionName = firmwareData.versionName {
                self.firmwareVersionLabel.text = "发现新版本：固件_\(versionName)"
            }
            self.firmwareMessageLabel.text = "当前版本：固件_\(self.currentVersion)"
            self.firmwareWarnLabel.isHidden = false
            self.firmwareWarnImageView.isHidden = false
            self.firmwareUpdateView.isHidden = false
            
            // 检查是否需要强制更新
            if firmwareData.forceUpdate == true {
                self.firmwareWarnLabel.text = "此版本为强制更新，请务必下载并安装"
                self.firmwareWarnLabel.textColor = UIColor(str: "#FF3B30")
            }
        }
    }
    
    private func resetUI(with firmwareVersion: String) {
        DispatchQueue.main.async {
            self.firmwareVersionLabel.text = "当前版本：固件_\(firmwareVersion)"
            self.firmwareMessageLabel.text = "已是最新版本"
            self.firmwareWarnLabel.isHidden = true
            self.firmwareWarnImageView.isHidden = true
            self.firmwareUpdateView.isHidden = true
        }
    }
    
    // MARK: - 按钮点击事件
    @objc private func firmwareUpdateViewTapped() {
        guard let currentText = firmwareUpdateText.text else { return }
        
        switch currentText {
        case "下载固件", "重新下载":
            startDownload()
        case "下载完成，立即安装":
            installFirmware()
        case let text where text.contains("下载中"):
            // 点击下载中按钮可以暂停
            pauseDownload()
        case "下载暂停", "继续下载":
            resumeDownload()
        default:
            break
        }
    }
    
    // MARK: - 下载相关方法
    private func startDownload() {
        guard let firmwareData = currentFirmwareData else {
            showErrorAlert(message: "没有可下载的固件数据")
            return
        }
        
        updateButtonState(isDownloading: true, progress: 0, text: "下载中 (0%)")
        FirmwareDownloadManager.shared.downloadFirmware(firmwareData)
    }
    
    private func pauseDownload() {
        FirmwareDownloadManager.shared.pauseDownload()
    }
    
    private func resumeDownload() {
        FirmwareDownloadManager.shared.resumeDownload()
        updateButtonState(isDownloading: true, progress: downloadProgress, text: String(format: "下载中 (%.0f%%)", downloadProgress * 100))
    }
    
    private func installFirmware() {
        switch BluetoothManager.shared.deviceType {
        case .TXTS:
            guard let firmwareData = currentFirmwareData,
                  let fileURL = FirmwareDownloadManager.shared.getLocalFirmwareFileURL(firmwareData: firmwareData) else {
                showErrorAlert(message: "没有找到固件文件")
                return
            }
            
            // 这里可以实现通过Wi-Fi安装固件的逻辑
            showInstallAlert(fileURL: fileURL)
        case .K01:
            guard let firmwareData = currentFirmwareData, let fileURL = FirmwareDownloadManager.shared.getLocalFirmwareFileURL(firmwareData: firmwareData) else {
                showErrorAlert(message: "没有找到固件文件")
                return
            }
            print("固件URL---\(fileURL)")
            print("固件URL---\(fileURL.path)")
            startOTAUpgrade(with: fileURL.path)
        }
        
    }
    
    // MARK: - 处理下载状态
    private func handleDownloadStatus(_ status: FirmwareDownloadStatus) {
        DispatchQueue.main.async {
            switch status {
            case .idle:
                self.isDownloading = false
                self.downloadProgress = 0
                self.updateButtonState(isDownloading: false, progress: 0, text: "下载固件")
                
            case .downloading(let progress):
                self.isDownloading = true
                self.downloadProgress = progress
                let percentage = Int(progress * 100)
                self.updateButtonState(isDownloading: true, progress: progress, text: "下载中 (\(percentage)%)")
                
            case .paused(let progress):
                self.isDownloading = false
                self.downloadProgress = progress
                let percentage = Int(progress * 100)
                self.updateButtonState(isDownloading: false, progress: progress, text: "下载暂停 (\(percentage)%)")
                
            case .completed(let fileURL):
                self.isDownloading = false
                self.downloadedFileURL = fileURL
                self.downloadProgress = 1.0
                self.updateButtonState(isDownloading: false, progress: 1.0, text: "下载完成，立即安装")
                
            case .failed(let error):
                self.isDownloading = false
                self.downloadProgress = 0
                self.updateButtonState(isDownloading: false, progress: 0, text: "重新下载")
                
                // 显示错误提示
                if let firmwareError = error as? FirmwareDownloadError {
                    self.showErrorAlert(message: firmwareError.localizedDescription)
                } else {
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 更新按钮状态
    private func updateButtonState(isDownloading: Bool, progress: Double, text: String) {
        DispatchQueue.main.async {
            self.firmwareUpdateText.text = text
            
            if isDownloading {
                self.firmwareUpdateActivityIndicator.startAnimating()
                self.firmwareUpdateView.backgroundColor = UIColor(str: "#FE6A00").withAlphaComponent(0.7)
            } else {
                self.firmwareUpdateActivityIndicator.stopAnimating()
                self.firmwareUpdateView.backgroundColor = UIColor(str: "#FE6A00")
            }
        }
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
            let alert = UIAlertController(title: "安装固件", message: "请确保设备已连接，然后开始安装固件", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "开始安装", style: .default) { _ in
                self.startFirmwareUpgrade(fileURL: fileURL)
            })
            
            self.present(alert, animated: true)
        }
    }
    
}


extension MiniDeviceUpdateViewController {
    
    private func startFirmwareUpgrade(fileURL: URL) {
        guard let firmwareData = currentFirmwareData else {
            showErrorAlert(message: "没有可用的固件数据")
            return
        }
        
        // 检查蓝牙连接
        guard BluetoothManager.shared.isConnected else {
            showErrorAlert(message: "蓝牙设备未连接")
            return
        }
        
        // 获取固件版本
        guard let version = firmwareData.versionName else {
            showErrorAlert(message: "无效的固件版本")
            return
        }
        
        // 创建蓝牙升级管理器
        let upgradeManager = BLEFirmwareUpgradeManager()
        
        // 显示升级弹窗
        let dialog = MiniFirmwareUpgradeDialog.showAndStartUpgrade(
            in: self,
            upgradeManager: upgradeManager,
            firmwarePath: fileURL.path,
            version: version,
            onProgress: { progress in
                print("升级进度: \(progress * 100)%")
            },
            onComplete: { [weak self] result in
                switch result {
                case .success:
                    // 升级成功后可以在这里处理一些后续逻辑
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showUpgradeSuccessAlert()
                    }
                case .failure(let error):
                    self?.showUpgradeErrorAlert(error: error)
                }
            },
            onCancel: { [weak self] in
                self?.showCanceledAlert()
            }
        )
        dialog.onConfirmTapped = { [weak self] in
            self?.showUpgradeSuccessAlert()
        }
        
        // 保存dialog引用，防止被释放
        currentUpgradeDialog = dialog
    }
    
    private var currentUpgradeDialog: MiniFirmwareUpgradeDialog? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.upgradeDialog) as? MiniFirmwareUpgradeDialog }
        set { objc_setAssociatedObject(self, &AssociatedKeys.upgradeDialog, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private struct AssociatedKeys {
        static var upgradeDialog = "upgradeDialog"
    }
    
    private func showUpgradeSuccessAlert() {
        self.resetUI(with: self.currentFirmwareData?.versionName ?? "1.0.0.0")
        self.currentFirmwareData = nil
        
        let alert = UIAlertController(
            title: "升级成功",
            message: "固件升级已完成，设备将自动重启。请稍后重新连接设备。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            // 通知详情页的
            NotificationCenter.default.post(
                name: .didFirmwareUpdateOver,
                object: nil,
                userInfo: nil
            )
        })
        
        present(alert, animated: true)
    }
    
    private func showUpgradeErrorAlert(error: Error) {
        let errorMessage = error.localizedDescription
        
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

// MARK: - K01的升级方法
extension MiniDeviceUpdateViewController {
    
    private func startOTAUpgrade(with firmwarePath: String) {
        print("开始OTA升级")
        
        guard let peripheral = BluetoothManager.shared.connectedPeripheral else {
            print("❌ 没有连接的蓝牙设备")
            showErrorAlert(message: "没有连接的蓝牙设备")
            return
        }
        
        // 显示升级弹窗
        let upgradeManager = BLEFirmwareUpgradeManager()
        
        // 创建升级弹窗（复用相同的弹窗类，但处理不同的升级流程）
        let dialog = MiniFirmwareUpgradeDialog.showAndStartUpgrade(
            in: self,
            upgradeManager: upgradeManager,
            firmwarePath: firmwarePath,
            version: currentFirmwareData?.versionName ?? "未知版本",
            isK01Mode: true,  // 新增参数，标识是K01模式
            onProgress: { progress in
                print("K01升级进度: \(progress * 100)%")
                // 进度已经在FRQBluetoothManagerDelegate中处理
            },
            onComplete: { [weak self] result in
                switch result {
                case .success:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.showUpgradeSuccessAlert()
                    }
                case .failure(let error):
                    self?.showUpgradeErrorAlert(error: error)
                }
            },
            onCancel: { [weak self] in
                self?.showCanceledAlert()
            }
        )
        
        dialog.onConfirmTapped = { [weak self] in
            self?.showUpgradeSuccessAlert()
        }
        
        // 保存dialog引用
        currentUpgradeDialog = dialog
        
        BluetoothManager.shared.disconnectPeripheral()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            frqBluetoothManager.scanPeripherals()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            frqBluetoothManager.connect(to: peripheral)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            guard let self = self else { return }
            frqBluetoothManager.updateOTA(withFilePath: firmwarePath, to: peripheral)
        }
        
    }
}

extension MiniDeviceUpdateViewController: FRQBluetoothManagerDelegate {
    
    func onBLEManagerConnect(_ ability: any FRBleAbility, peripheral: CBPeripheral, error: (any Error)) {
        let nsError = error as NSError
        
        // 判断是否连接成功
        // 常见表示成功的特征：code=0 或 domain包含"success" 或描述包含"success"
        let isSuccess = nsError.code == 0 ||
                        nsError.domain.lowercased().contains("noerror") ||
                        nsError.localizedDescription.lowercased().contains("success") ||
                        nsError.localizedDescription.lowercased().contains("成功")
        
        if isSuccess {
            print("FRQBluetoothManager连接了蓝牙---\(peripheral)")
            DispatchQueue.main.async { [weak self] in
                self?.currentUpgradeDialog?.updateStatus("设备已连接，准备升级...")
            }
        } else {
            print("FRQBluetoothManager连接蓝牙失败---\(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.currentUpgradeDialog?.complete(
                    success: false,
                    message: "连接设备失败：\(error.localizedDescription)"
                )
            }
        }
    }
    
    func onBLEManagerBeginUpdateOTA(_ ability: any FRBleAbility) {
        print("FRQBluetoothManager开始升级")
        DispatchQueue.main.async { [weak self] in
            self?.currentUpgradeDialog?.updateStatus("开始升级...")
            self?.currentUpgradeDialog?.updateProgress(0.05) // 初始进度
        }
    }
    
    func onBLEManagerUpdateOTA(_ ability: any FRBleAbility, progress aProgress: Double) {
        print("FRQBluetoothManager升级进行中-----进度：\(aProgress)")
        
        // FRQBluetoothKit的进度可能是0-100的值，需要转换为0-1
        let normalizedProgress = aProgress / 100.0
        
        DispatchQueue.main.async { [weak self] in
            // 根据进度更新状态文本
            let progress = normalizedProgress
            if progress < 0.3 {
                self?.currentUpgradeDialog?.updateStatus("正在传输固件...")
            } else if progress < 0.6 {
                self?.currentUpgradeDialog?.updateStatus("正在写入固件...")
            } else if progress < 0.9 {
                self?.currentUpgradeDialog?.updateStatus("正在验证固件...")
            } else {
                self?.currentUpgradeDialog?.updateStatus("即将完成...")
            }
            
            // 更新进度条
            self?.currentUpgradeDialog?.updateProgress(progress)
        }
    }
    
    func onBLEManagerUpdateOTAFinish(_ ability: any FRBleAbility, error: (any Error)) {
        let nsError = error as NSError
        
        // 判断是否连接成功
        // 常见表示成功的特征：code=0 或 domain包含"success" 或描述包含"success"
        let isSuccess = nsError.code == 0 ||
                        nsError.domain.lowercased().contains("noerror") ||
                        nsError.localizedDescription.lowercased().contains("success") ||
                        nsError.localizedDescription.lowercased().contains("成功")
        
        if isSuccess {
            print("FRQBluetoothManager升级成功")
            DispatchQueue.main.async { [weak self] in
                self?.currentUpgradeDialog?.complete(
                    success: true,
                    message: "固件升级成功！设备将自动重启"
                )
            }
        } else {
            print("FRQBluetoothManager升级失败----错误：\(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.currentUpgradeDialog?.complete(
                    success: false,
                    message: "升级失败：\(error.localizedDescription)"
                )
            }
        }
        // 移除代理
        frqBluetoothManager.delegate = nil
    }
    
    // 可选：处理连接断开
    func onBLEManagerDiscoverPeripheral(_ ability: any FRBleAbility, peripheral: CBPeripheral, advertisement advertisementData: [AnyHashable : Any], rssi RSSI: NSNumber) {
        print("FRQBluetoothManager断开连接---\(peripheral)")
        
        // 如果不是正常升级完成导致的断开，可能是异常
        if let currentDialog = currentUpgradeDialog,
           !currentDialog.isUpgradeComplete {  // 需要给MiniFirmwareUpgradeDialog添加isUpgradeComplete属性
            DispatchQueue.main.async { [weak self] in
                self?.currentUpgradeDialog?.updateStatus("设备连接已断开")
            }
        }
    }
}

