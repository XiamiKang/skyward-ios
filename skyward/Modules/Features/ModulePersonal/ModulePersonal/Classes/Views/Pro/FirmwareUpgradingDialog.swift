//
//  FirmwareUpgradingDialog.swift
//  Pods
//
//  Created by yifan kang on 2025/12/26.
//


import UIKit
import SWKit

class FirmwareUpgradeDialog: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "正在升级"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(hex: "#000000")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = "正在升级，请保持在当前页面\n请勿断开设备WiFi或退出升级"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hex: "#666666")
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "正在检查设备状态..."
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#333333")
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.progressTintColor = UIColor(hex: "#FE6A00")
        progressView.trackTintColor = UIColor(hex: "#F0F0F0")
        progressView.progress = 0
        progressView.layer.cornerRadius = 2
        progressView.layer.masksToBounds = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(hex: "#FE6A00")
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建旋转动画
        let images = (1...12).compactMap { UIImage(named: "loading_\($0)") }
        if images.isEmpty {
            // 如果没有图片资源，创建一个系统loading
            imageView.image = UIImage(systemName: "arrow.2.circlepath")
            imageView.tintColor = UIColor(hex: "#FE6A00")
        } else {
            imageView.animationImages = images
            imageView.animationDuration = 1.0
        }
        return imageView
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F0F0F0")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消升级", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(hex: "#666666"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
//    private let logTextView: UITextView = {
//        let textView = UITextView()
//        textView.isEditable = false
//        textView.isSelectable = false
//        textView.font = .systemFont(ofSize: 12)
//        textView.textColor = UIColor(hex: "#666666")
//        textView.backgroundColor = UIColor(hex: "#F8F8F8")
//        textView.layer.cornerRadius = 4
//        textView.layer.masksToBounds = true
//        textView.isHidden = true
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }()
//    
//    private let showLogButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("显示日志", for: .normal)
//        button.setTitle("隐藏日志", for: .selected)
//        button.titleLabel?.font = .systemFont(ofSize: 12)
//        button.setTitleColor(UIColor(hex: "#999999"), for: .normal)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
    
    // MARK: - Properties
    private var upgradeManager: AdvancedFirmwareUpdateManager?
    private var firmwarePath: String = ""
    private var logMessages: [String] = []
    private var isShowingLog = false
    
    // 回调
    var onUpgradeComplete: ((Result<Bool, Error>) -> Void)?
    var onCancelTapped: (() -> Void)?
    
    // MARK: - Initialization
    init(upgradeManager: AdvancedFirmwareUpdateManager, firmwarePath: String) {
        self.upgradeManager = upgradeManager
        self.firmwarePath = firmwarePath
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        setupUpgradeManager()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(tipLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(progressLabel)
        containerView.addSubview(loadingImageView)
        containerView.addSubview(separatorLine)
        containerView.addSubview(cancelButton)
//        containerView.addSubview(logTextView)
//        containerView.addSubview(showLogButton)
        
        startLoadingAnimation()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Tip Label
            tipLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tipLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            tipLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Separator Line
            separatorLine.topAnchor.constraint(equalTo: tipLabel.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Progress View
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Progress Label
            progressLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor),
            progressLabel.leadingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: 8),
            progressLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            progressLabel.widthAnchor.constraint(equalToConstant: 40),
            
            // Loading Image View
            loadingImageView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 30),
            loadingImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingImageView.widthAnchor.constraint(equalToConstant: 40),
            loadingImageView.heightAnchor.constraint(equalToConstant: 40),
            
//            // Show Log Button
//            showLogButton.topAnchor.constraint(equalTo: loadingImageView.bottomAnchor, constant: 20),
//            showLogButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            
//            // Log Text View
//            logTextView.topAnchor.constraint(equalTo: showLogButton.bottomAnchor, constant: 8),
//            logTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
//            logTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
//            logTextView.heightAnchor.constraint(equalToConstant: 100),
            
            // Cancel Button
            cancelButton.topAnchor.constraint(equalTo: loadingImageView.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Bottom padding
            containerView.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
//        showLogButton.addTarget(self, action: #selector(toggleLog), for: .touchUpInside)
    }
    
    private func setupUpgradeManager() {
        upgradeManager?.onProgressUpdate = { [weak self] progress, phase in
            DispatchQueue.main.async {
                self?.updateProgress(progress)
                self?.updateStatus(phase)
            }
        }
        
        upgradeManager?.onLogReceived = { [weak self] log in
            DispatchQueue.main.async {
//                self?.addLogMessage(log)
            }
        }
        
        upgradeManager?.onUpgradeComplete = { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUpgradeResult(result)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 显示弹窗并开始升级
    static func showAndStartUpgrade(
        in view: UIView? = nil,
        upgradeManager: AdvancedFirmwareUpdateManager,
        firmwarePath: String,
        onComplete: ((Result<Bool, Error>) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> FirmwareUpgradeDialog {
        
        let dialog = FirmwareUpgradeDialog(
            upgradeManager: upgradeManager,
            firmwarePath: firmwarePath
        )
        
        dialog.onUpgradeComplete = onComplete
        dialog.onCancelTapped = onCancel
        
        let targetView = view ?? UIApplication.shared.keyWindow
        targetView?.addSubview(dialog)
        dialog.frame = targetView?.bounds ?? CGRect.zero
        
        // 添加淡入动画
        dialog.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        dialog.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            dialog.containerView.transform = .identity
            dialog.alpha = 1
        }
        
        // 开始升级
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dialog.startUpgrade()
        }
        
        return dialog
    }
    
    /// 开始升级
    func startUpgrade() {
//        addLogMessage("🚀 开始固件升级流程")
//        addLogMessage("📁 固件文件: \(firmwarePath)")
        
        upgradeManager?.startUpgrade(firmwarePath: firmwarePath) { result in
            // 结果通过回调处理
            print("升级完成回调: \(result)")
        }
    }
    
    /// 更新进度
    func updateProgress(_ progress: Double) {
        let clampedProgress = max(0, min(1, progress))
        let percentage = Int(clampedProgress * 100)
        
        UIView.animate(withDuration: 0.3) {
            self.progressView.setProgress(Float(clampedProgress), animated: true)
        }
        
        progressLabel.text = "\(percentage)%"
    }
    
    /// 更新状态文本
    func updateStatus(_ text: String) {
        statusLabel.text = text
        
        // 特殊状态的特殊显示
        if text.contains("擦除Flash") {
//            addLogMessage("🧹 " + text)
        } else if text.contains("发送固件") {
//            addLogMessage("📤 " + text)
        } else if text.contains("发送数据包") {
            // 数据包发送不频繁记录日志
        } else {
//            addLogMessage("📋 " + text)
        }
    }
    
    /// 完成升级
    func complete(success: Bool, message: String? = nil) {
        stopLoadingAnimation()
        
        let successImage = UIImage(systemName: "checkmark.circle.fill") ?? UIImage(named: "success_icon")
        let failImage = UIImage(systemName: "xmark.circle.fill") ?? UIImage(named: "error_icon")
        
        loadingImageView.image = success ? successImage : failImage
        loadingImageView.tintColor = success ? UIColor(hex: "#34C759") : UIColor(hex: "#FF3B30")
        
        titleLabel.text = success ? "升级成功" : "升级失败"
        cancelButton.setTitle("完成", for: .normal)
        
        if let message = message {
            statusLabel.text = message
//            addLogMessage(success ? "✅ " + message : "❌ " + message)
        } else {
            let defaultMessage = success ? "固件升级已完成，设备将重启" : "固件升级失败，请重试"
            statusLabel.text = defaultMessage
//            addLogMessage(success ? "✅ " + defaultMessage : "❌ " + defaultMessage)
        }
        
        if success {
            updateProgress(1.0)
        }
        
        // 成功后5秒自动消失
        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.dismiss()
            }
        }
    }
    
    /// 关闭弹窗
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.containerView.alpha = 0
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
    
    // MARK: - Private Methods
    private func startLoadingAnimation() {
        if loadingImageView.animationImages != nil {
            loadingImageView.startAnimating()
        } else {
            // 使用系统动画
            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.fromValue = 0
            rotation.toValue = CGFloat.pi * 2
            rotation.duration = 1
            rotation.repeatCount = .infinity
            loadingImageView.layer.add(rotation, forKey: "rotationAnimation")
        }
    }
    
    private func stopLoadingAnimation() {
        if loadingImageView.animationImages != nil {
            loadingImageView.stopAnimating()
        } else {
            loadingImageView.layer.removeAnimation(forKey: "rotationAnimation")
        }
    }
    
//    private func addLogMessage(_ message: String) {
//        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
//        let logMessage = "[\(timestamp)] \(message)"
//        
//        logMessages.append(logMessage)
//        
//        // 保持最多50条日志
//        if logMessages.count > 50 {
//            logMessages.removeFirst(logMessages.count - 50)
//        }
//        
//        // 更新日志文本
//        logTextView.text = logMessages.joined(separator: "\n")
//        
//        // 自动滚动到底部
//        if logTextView.text.count > 0 {
//            let bottom = NSMakeRange(logTextView.text.count - 1, 1)
//            logTextView.scrollRangeToVisible(bottom)
//        }
//    }
    
    private func handleUpgradeResult(_ result: Result<Bool, Error>) {
        switch result {
        case .success:
            complete(success: true)
        case .failure(let error):
            var errorMessage = error.localizedDescription
            
            // 根据错误类型提供更具体的提示
            if let firmwareError = error as? FirmwareUpdateError {
                errorMessage = firmwareError.errorDescription ?? errorMessage
            } else if let otaError = error as? OTAUpgradeError {
                errorMessage = otaError.errorDescription ?? errorMessage
            } else if let wifiError = error as? WiFiDeviceError {
                errorMessage = wifiError.errorDescription ?? errorMessage
            }
            
//            addLogMessage("❌ 升级失败: \(errorMessage)")
            complete(success: false, message: errorMessage)
        }
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        if let buttonTitle = cancelButton.title(for: .normal), buttonTitle == "取消升级" {
            // 确认取消
            showCancelConfirmation()
        } else {
            // 完成或关闭
            dismiss()
            onCancelTapped?()
        }
    }
    
    @objc private func toggleLog() {
        isShowingLog.toggle()
//        showLogButton.isSelected = isShowingLog
        
        UIView.animate(withDuration: 0.3) {
//            self.logTextView.isHidden = !self.isShowingLog
            self.layoutIfNeeded()
        }
    }
    
    private func showCancelConfirmation() {
        let alert = UIAlertController(title: "确认取消",
                                    message: "确定要取消固件升级吗？这可能导致设备无法正常启动。",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "继续升级", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定取消", style: .destructive) { _ in
            self.upgradeManager?.cancelUpgrade()
//            self.addLogMessage("⏹️ 用户取消了升级")
            self.complete(success: false, message: "升级已取消")
        })
        
        // 在当前View的window上显示alert
        self.window?.rootViewController?.present(alert, animated: true)
    }
}

