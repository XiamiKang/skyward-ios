//
//  ProDeviceDebugViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

class ProDeviceDebugViewController: PersonalBaseViewController {
    
    private var statusUpdateTimer: Timer?
    
    // 控制界面
    private let controlBGView = UIView()
    private let controlTitle = UILabel()
    private let resetAUGView = ProDeviceDebugControlView()
    private let shareAUGLogView = ProDeviceDebugControlView()
    private let beaconStrengthView = ProDeviceDebugControlView()
    
    // 日志界面
    private let logGBView = UIView()
    private let logTitle = UILabel()
    private let logSwitch = UISwitch()
    private let logTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .white
        textView.textColor = UIColor(str: "#303236")
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLogSwitch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGetSignal()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGetSignal()
    }
    
    private func startGetSignal() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.getBeaconStrength()
        }
    }
    
    private func stopGetSignal() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        customTitle.text = "调试模式"
        
        controlBGView.backgroundColor = .white
        controlBGView.layer.cornerRadius = 8
        
        controlTitle.text = "设备控制"
        controlTitle.textColor = .black
        controlTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        resetAUGView.setUiData("device_pro_restAUG", text: "重启AUG")
        shareAUGLogView.setUiData("device_pro_shareAUGLog", text: "分享AUG存储日志")
        beaconStrengthView.setUiData("device_pro_satellite", text: "信标强度")
        
        resetAUGView.touchAction = { [weak self] in
            guard let self = self else { return }
            self.resetAUG()
        }
        shareAUGLogView.touchAction = { [weak self] in
            guard let self = self else { return }
            self.shareAUGLog()
        }
        beaconStrengthView.touchAction = { [weak self] in
            guard let self = self else { return }
            self.getBeaconStrength()
        }
        
        logGBView.backgroundColor = .white
        logGBView.layer.cornerRadius = 8
        
        logTitle.text = "ACU设备实时日志"
        logTitle.textColor = .black
        logTitle.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        
        logSwitch.onTintColor = UIColor.green
        
        view.addSubview(controlBGView)
        controlBGView.addSubview(controlTitle)
        controlBGView.addSubview(resetAUGView)
        controlBGView.addSubview(shareAUGLogView)
        controlBGView.addSubview(beaconStrengthView)
        view.addSubview(logGBView)
        logGBView.addSubview(logTitle)
        logGBView.addSubview(logSwitch)
        logGBView.addSubview(logTextView)
        
        setConstraint()
    }
    
    private func setupLogSwitch() {
        logSwitch.addTarget(self, action: #selector(logSwitchChanged), for: .valueChanged)
        
        // 初始化状态：关闭日志显示
        logSwitch.isOn = false
        
        // 设置WiFiManager的日志回调
        WiFiDeviceManager.shared.onLogReceived = { [weak self] log in
            DispatchQueue.main.async {
                self?.appendLog(log)
            }
        }
    }
    
    @objc private func logSwitchChanged() {
        if logSwitch.isOn {
            // 开启实时日志
            enableRealTimeLogging()
        } else {
            // 关闭实时日志
            disableRealTimeLogging()
        }
    }
    
    private func enableRealTimeLogging() {
        WiFiDeviceManager.shared.enableLogStreaming { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let enabled):
                    if enabled {
                        print("实时日志已开启")
                        self?.appendLog("📡 实时日志传输已开启")
                    } else {
                        print("开启实时日志失败")
                        self?.logSwitch.isOn = false
                        self?.appendLog("❌ 开启实时日志失败")
                    }
                case .failure(let error):
                    print("开启实时日志失败: \(error)")
                    self?.logSwitch.isOn = false
                    self?.appendLog("❌ 开启实时日志失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func disableRealTimeLogging() {
        WiFiDeviceManager.shared.disableLogStreaming { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let disabled):
                    if disabled {
                        print("实时日志已关闭")
                        self?.appendLog("📡 实时日志传输已关闭")
                    } else {
                        print("关闭实时日志失败")
                        self?.appendLog("❌ 关闭实时日志失败")
                    }
                case .failure(let error):
                    print("关闭实时日志失败: \(error)")
                    self?.appendLog("❌ 关闭实时日志失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func appendLog(_ log: String) {
        // 添加时间戳
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())
        let formattedLog = "[\(timestamp)] \(log)"
        
        // 添加到文本视图
        if let currentText = logTextView.text, !currentText.isEmpty {
            logTextView.text = "\(currentText)\n\(formattedLog)"
        } else {
            logTextView.text = formattedLog
        }
        
        // 滚动到底部
        let range = NSMakeRange(logTextView.text.count - 1, 1)
        logTextView.scrollRangeToVisible(range)
    }
    
    private func setConstraint() {
        controlBGView.translatesAutoresizingMaskIntoConstraints = false
        controlTitle.translatesAutoresizingMaskIntoConstraints = false
        resetAUGView.translatesAutoresizingMaskIntoConstraints = false
        shareAUGLogView.translatesAutoresizingMaskIntoConstraints = false
        beaconStrengthView.translatesAutoresizingMaskIntoConstraints = false
        logGBView.translatesAutoresizingMaskIntoConstraints = false
        logTitle.translatesAutoresizingMaskIntoConstraints = false
        logSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        let itemWidth = (UIScreen.main.bounds.width - 64)/3
        
        NSLayoutConstraint.activate([
            controlBGView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            controlBGView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlBGView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlBGView.heightAnchor.constraint(equalToConstant: 140),
            
            controlTitle.topAnchor.constraint(equalTo: controlBGView.topAnchor, constant: 16),
            controlTitle.leadingAnchor.constraint(equalTo: controlBGView.leadingAnchor, constant: 16),
            
            resetAUGView.topAnchor.constraint(equalTo: controlTitle.bottomAnchor, constant: 16),
            resetAUGView.leadingAnchor.constraint(equalTo: controlBGView.leadingAnchor, constant: 16),
            resetAUGView.widthAnchor.constraint(equalToConstant: itemWidth),
            resetAUGView.heightAnchor.constraint(equalToConstant: 70),
            
            shareAUGLogView.topAnchor.constraint(equalTo: controlTitle.bottomAnchor, constant: 16),
            shareAUGLogView.leadingAnchor.constraint(equalTo: resetAUGView.trailingAnchor),
            shareAUGLogView.widthAnchor.constraint(equalToConstant: itemWidth),
            shareAUGLogView.heightAnchor.constraint(equalToConstant: 70),
            
            beaconStrengthView.topAnchor.constraint(equalTo: controlTitle.bottomAnchor, constant: 16),
            beaconStrengthView.leadingAnchor.constraint(equalTo: shareAUGLogView.trailingAnchor),
            beaconStrengthView.widthAnchor.constraint(equalToConstant: itemWidth),
            beaconStrengthView.heightAnchor.constraint(equalToConstant: 70),
            
            logGBView.topAnchor.constraint(equalTo: controlBGView.bottomAnchor, constant: 16),
            logGBView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            logGBView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            logGBView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
        ])
        
        NSLayoutConstraint.activate([
            logTitle.topAnchor.constraint(equalTo: logGBView.topAnchor, constant: 16),
            logTitle.leadingAnchor.constraint(equalTo: logGBView.leadingAnchor, constant: 16),
            
            logSwitch.centerYAnchor.constraint(equalTo: logTitle.centerYAnchor),
            logSwitch.trailingAnchor.constraint(equalTo: logGBView.trailingAnchor, constant: -20),
            
            logTextView.topAnchor.constraint(equalTo: logTitle.bottomAnchor, constant: 16),
            logTextView.leadingAnchor.constraint(equalTo: logGBView.leadingAnchor, constant: 16),
            logTextView.trailingAnchor.constraint(equalTo: logGBView.trailingAnchor, constant: -16),
            logTextView.bottomAnchor.constraint(equalTo: logGBView.bottomAnchor, constant: -16),
        ])
    }
    
    private func resetAUG() {
        WiFiDeviceManager.shared.resetACU { [weak self] result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self?.view.sw_showSuccessToast("AUG重置成功")
                    self?.appendLog("🔄 AUG重置成功")
                }
            case .failure(let error):
                print("AUG重置失败: \(error)")
                DispatchQueue.main.async {
                    self?.view.sw_showSuccessToast("AUG重置失败")
                    self?.appendLog("❌ AUG重置失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func shareAUGLog() {
        WiFiDeviceManager.shared.queryStoredLogs { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let logs):
                    let content = logs.joined(separator: "\n")
                    self?.saveAndShareTXT(content: content)
                    self?.appendLog("📤 获取存储日志成功，共 \(logs.count) 条")
                case .failure(let error):
                    print("获取AUG日志失败: \(error)")
                    self?.view.sw_showSuccessToast("获取AUG日志失败")
                    self?.appendLog("❌ 获取存储日志失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getBeaconStrength() {
        WiFiDeviceManager.shared.queryBeaconSignal { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let signal):
                    self?.beaconStrengthView.contentText.text = "信标强度(\(signal))"
                    if self?.logSwitch.isOn == true {
                        self?.appendLog("📡 信标强度: \(signal)")
                    }
                case .failure(let error):
                    print("获取信标强度失败: \(error)")
                    if self?.logSwitch.isOn == true {
                        self?.appendLog("❌ 获取信标强度失败: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func saveAndShareTXT(content: String) {
        // 1. 使用当前时间生成文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "文档_\(dateFormatter.string(from: Date()))"
        
        // 2. 获取临时目录（分享后会自动清理）
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("\(fileName).txt")
        
        do {
            // 3. 写入文件
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("文件保存成功: \(fileURL.lastPathComponent)")
            
            // 4. 分享文件
            let activityViewController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // 5. 显示分享界面
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                
                // iPad 适配
                if UIDevice.current.userInterfaceIdiom == .pad {
                    activityViewController.popoverPresentationController?.sourceView = rootViewController.view
                    activityViewController.popoverPresentationController?.sourceRect = CGRect(
                        x: rootViewController.view.bounds.midX,
                        y: rootViewController.view.bounds.midY,
                        width: 0,
                        height: 0
                    )
                }
                
                present(activityViewController, animated: true)
                appendLog("📤 分享日志文件: \(fileName).txt")
            }
        } catch {
            print("保存文件失败: \(error)")
            appendLog("❌ 保存日志文件失败: \(error.localizedDescription)")
        }
    }
}

class ProDeviceDebugControlView: UIView {
    
    private let imageView = UIImageView()
    public var contentText = UILabel()
    private let button = UIButton()
    
    var touchAction:(()-> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentText.textColor = UIColor(str: "#303236")
        contentText.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        contentText.textAlignment = .center
        contentText.numberOfLines = 2
        contentText.translatesAutoresizingMaskIntoConstraints = false
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(touchupInsideClick), for: .touchUpInside)
        
        addSubview(imageView)
        addSubview(contentText)
        addSubview(button)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            
            contentText.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentText.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 5),
            contentText.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            contentText.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            contentText.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @objc private func touchupInsideClick() {
        touchAction?()
    }
    
    func setUiData(_ imageStr: String, text: String) {
        imageView.image = PersonalModule.image(named: imageStr)
        contentText.text = text
    }
}
