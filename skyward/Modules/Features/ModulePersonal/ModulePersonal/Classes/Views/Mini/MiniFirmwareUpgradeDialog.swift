//
//  FirmwareUpgradingDialog.swift
//  Pods
//
//  Created by yifan kang on 2025/12/26.
//

import UIKit
import SWKit

class MiniFirmwareUpgradeDialog: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "固件升级"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(hex: "#000000")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "正在升级，请保持在当前页面\n请勿断开设备连接或退出升级"
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
        label.textAlignment = .center
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
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 如果有图片资源
        let images = (1...12).compactMap { UIImage(named: "loading_\($0)") }
        if !images.isEmpty {
            imageView.animationImages = images
            imageView.animationDuration = 1.0
        } else {
            // 使用系统图标
            imageView.image = UIImage(systemName: "arrow.clockwise")
            imageView.tintColor = UIColor(hex: "#FE6A00")
        }
        return imageView
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "升级中..."
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hex: "#666666")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F0F0F0")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(hex: "#666666"), for: .normal)
        button.backgroundColor = UIColor(hex: "#F5F5F5")
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("确定", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    private var upgradeManager: BLEFirmwareUpgradeManager?
    private var firmwarePath: String = ""
    
    // 回调
    var onUpgradeComplete: ((Result<Bool, Error>) -> Void)?
    var onCancelTapped: (() -> Void)?
    var onConfirmTapped: (() -> Void)?
    
    private var isUpgradeComplete = false
    
    // MARK: - Initialization
    convenience init(upgradeManager: BLEFirmwareUpgradeManager, firmwarePath: String) {
        self.init(frame: .zero)
        self.upgradeManager = upgradeManager
        self.firmwarePath = firmwarePath
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(progressView)
        containerView.addSubview(progressLabel)
        containerView.addSubview(loadingView)
        
        loadingView.addSubview(loadingImageView)
        loadingView.addSubview(loadingLabel)
        
        containerView.addSubview(separatorLine)
        containerView.addSubview(buttonStackView)
        
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(confirmButton)
        
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
            
            // Message Label
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Status Label
            statusLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Progress View
            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Progress Label
            progressLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 8),
            progressLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Loading View
            loadingView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
            loadingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 80),
            loadingView.heightAnchor.constraint(equalToConstant: 60),
            
            // Loading Image
            loadingImageView.topAnchor.constraint(equalTo: loadingView.topAnchor),
            loadingImageView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingImageView.widthAnchor.constraint(equalToConstant: 40),
            loadingImageView.heightAnchor.constraint(equalToConstant: 40),
            
            // Loading Label
            loadingLabel.topAnchor.constraint(equalTo: loadingImageView.bottomAnchor, constant: 4),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            
            // Separator Line
            separatorLine.topAnchor.constraint(equalTo: loadingView.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Button Stack View
            buttonStackView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 16),
            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            buttonStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // Container bottom constraint
            containerView.bottomAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 20)
        ])
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }
    
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
    
    // MARK: - Public Methods
    
    /// 显示弹窗并开始升级
    static func showAndStartUpgrade(
        in viewController: UIViewController,
        upgradeManager: BLEFirmwareUpgradeManager,
        firmwarePath: String,
        version: String,
        onProgress: ((Double) -> Void)? = nil,
        onComplete: ((Result<Bool, Error>) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> MiniFirmwareUpgradeDialog {
        
        let dialog = MiniFirmwareUpgradeDialog(
            upgradeManager: upgradeManager,
            firmwarePath: firmwarePath
        )
        
        dialog.onUpgradeComplete = onComplete
        dialog.onCancelTapped = onCancel
        
        viewController.view.addSubview(dialog)
        dialog.frame = viewController.view.bounds
        
        // 添加淡入动画
        dialog.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        dialog.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            dialog.containerView.transform = .identity
            dialog.alpha = 1
        }
        
        // 开始升级
        dialog.startUpgrade(version: version, onProgress: onProgress)
        
        return dialog
    }
    
    /// 开始升级
    func startUpgrade(version: String, onProgress: ((Double) -> Void)? = nil) {
        guard let upgradeManager = upgradeManager else {
            complete(success: false, message: "升级管理器未初始化")
            return
        }
        
        upgradeManager.startUpgrade(version: version, firmwarePath: firmwarePath) { [weak self] progress in
            DispatchQueue.main.async {
                self?.updateProgress(progress)
                onProgress?(progress)
                
                // 根据进度更新状态文本
                if progress < 0.3 {
                    self?.updateStatus("正在准备升级...")
                } else if progress < 0.6 {
                    self?.updateStatus("正在传输固件数据...")
                } else if progress < 0.9 {
                    self?.updateStatus("正在验证固件...")
                } else {
                    self?.updateStatus("正在完成升级...")
                }
            }
        } onComplete: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUpgradeResult(result)
            }
        }
    }
    
    /// 更新进度
    func updateProgress(_ progress: Double) {
        print("升级控制器中---弹框----\(progress)")
        let clampedProgress = max(0, min(1, progress/100))
        let percentage = Int(progress)
        
        UIView.animate(withDuration: 0.3) {
            self.progressView.setProgress(Float(clampedProgress), animated: true)
        }
        
        progressLabel.text = "\(percentage)%"
    }
    
    /// 更新状态文本
    func updateStatus(_ text: String) {
        statusLabel.text = text
    }
    
    /// 完成升级
    func complete(success: Bool, message: String? = nil) {
        isUpgradeComplete = true
        stopLoadingAnimation()
        
        let successImage = UIImage(systemName: "checkmark.circle.fill") ?? UIImage(named: "success_icon")
        let failImage = UIImage(systemName: "xmark.circle.fill") ?? UIImage(named: "error_icon")
        
        loadingImageView.image = success ? successImage : failImage
        loadingImageView.tintColor = success ? UIColor(hex: "#34C759") : UIColor(hex: "#FF3B30")
        loadingLabel.text = success ? "升级完成" : "升级失败"
        
        titleLabel.text = success ? "升级成功" : "升级失败"
        
        // 更新按钮状态
        cancelButton.setTitle("取消", for: .normal)
        confirmButton.isHidden = false
        confirmButton.setTitle(success ? "完成" : "重试", for: .normal)
        
        if let message = message {
            statusLabel.text = message
        } else {
            let defaultMessage = success ? "固件升级已完成，设备将自动重启" : "固件升级失败，请重试"
            statusLabel.text = defaultMessage
        }
        
        if success {
            updateProgress(1.0)
            // 成功后10秒自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
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
    private func handleUpgradeResult(_ result: Result<Bool, Error>) {
        switch result {
        case .success:
            complete(success: true, message: "固件升级成功！设备将自动重启")
        case .failure(let error):
            var errorMessage = error.localizedDescription
            
            // 根据错误类型提供更具体的提示
            if let firmwareError = error as? FirmwareUpdateError {
                errorMessage = firmwareError.errorDescription ?? errorMessage
            }
            
            complete(success: false, message: errorMessage)
        }
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        if isUpgradeComplete {
            dismiss()
            onCancelTapped?()
        } else {
            // 确认取消
            showCancelConfirmation()
        }
    }
    
    @objc private func confirmButtonTapped() {
        if let buttonTitle = confirmButton.title(for: .normal), buttonTitle == "重试" {
            // 重新升级
            confirmButton.isHidden = true
            confirmButton.setTitle("确定", for: .normal)
            startLoadingAnimation()
            
            // 这里可以添加重试逻辑
//            let version = upgradeManager?.currentVersion
//            startUpgrade(version: version, onProgress: nil)
        } else {
            dismiss()
            onConfirmTapped?()
        }
    }
    
    private func showCancelConfirmation() {
        guard let viewController = self.window?.rootViewController else { return }
        
        let alert = UIAlertController(
            title: "确认取消",
            message: "确定要取消固件升级吗？这可能导致设备无法正常启动。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "继续升级", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定取消", style: .destructive) { _ in
            self.upgradeManager?.cancelUpgrade()
            self.complete(success: false, message: "升级已取消")
        })
        
        viewController.present(alert, animated: true)
    }
}
