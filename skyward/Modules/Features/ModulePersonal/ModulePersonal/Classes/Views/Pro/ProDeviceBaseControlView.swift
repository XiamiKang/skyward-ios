//
//  ProDeviceButtonState.swift
//  Pods
//
//  Created by TXTS on 2026/2/10.
//


import UIKit
import SWKit
import SWTheme

enum ProDeviceButtonState {
    case incomplete   //未完成
    case inprogress   //进行中
    case completed    //已完成
}

class ProDeviceBaseControlView: UIView {

    private let collectButton = UIButton(type: .custom)
    private let lineStarButton = UIButton(type: .custom)
    
    // 为每个按钮创建水平堆栈
    private let collectStackView = UIStackView()
    private let lineStarStackView = UIStackView()
    
    // 按钮标题标签
    private let collectTitleLabel = UILabel()
    private let lineStarTitleLabel = UILabel()
    
    // 活动指示器
    private let collectActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let lineStarActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    private let lowPowerTitle = UILabel()
    private let lowPowerswitch = UISwitch()
    
    var collectionAction: (() -> Void)?
    var lineStarAction: (() -> Void)?
    
    // 定时器
    private var collectTimer: Timer?
    private var lineStarTimer: Timer?
    
    // 按钮状态
    private var isCollecting: ProDeviceButtonState = .incomplete {
        didSet {
            updateCollectButtonState()
            // 当收藏状态变化时，检查是否需要更新对星按钮的可用性
            updateButtonInteractionState()
        }
    }
    
    private var isLiningStar: ProDeviceButtonState = .incomplete {
        didSet {
            updateLineStarButtonState()
            // 当对星状态变化时，检查是否需要更新收藏按钮的可用性
            updateButtonInteractionState()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // 清理定时器
        collectTimer?.invalidate()
        lineStarTimer?.invalidate()
    }
    
    private func setupUI() {
        // 设置收藏按钮
        setupCollectButton()
        
        // 设置对星按钮
        setupLineStarButton()
        
        // 低功耗控件
        lowPowerTitle.translatesAutoresizingMaskIntoConstraints = false
        lowPowerTitle.text = "低功耗"
        lowPowerTitle.textColor = UIColor(str: "#070808")
        lowPowerTitle.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(lowPowerTitle)
        
        lowPowerswitch.translatesAutoresizingMaskIntoConstraints = false
        lowPowerswitch.onTintColor = UIColor(str: "#16C282")
        lowPowerswitch.addTarget(self, action: #selector(logSwitchChanged), for: .valueChanged)
        self.addSubview(lowPowerswitch)
        
        setConstraint()
        
        // 初始化按钮状态
        updateButtonInteractionState()
    }
    
    private func setupCollectButton() {
        // 配置收藏按钮
        collectButton.translatesAutoresizingMaskIntoConstraints = false
        collectButton.backgroundColor = ThemeManager.current.mediumGrayBGColor
        collectButton.layer.cornerRadius = 6
        collectButton.addTarget(self, action: #selector(collectionButtonTapped), for: .touchUpInside)
        self.addSubview(collectButton)
        
        // 创建堆栈视图
        collectStackView.translatesAutoresizingMaskIntoConstraints = false
        collectStackView.axis = .horizontal
        collectStackView.alignment = .center
        collectStackView.distribution = .fill
        collectStackView.spacing = 8
        collectStackView.isUserInteractionEnabled = false // 让点击穿透到按钮
        collectButton.addSubview(collectStackView)
        
        // 添加活动指示器
        collectActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        collectActivityIndicator.hidesWhenStopped = true
        collectActivityIndicator.color = .white
        collectStackView.addArrangedSubview(collectActivityIndicator)
        
        // 添加标题标签
        collectTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        collectTitleLabel.text = "收藏"
        collectTitleLabel.textColor = UIColor(str: "#C4C7CA")
        collectTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        collectStackView.addArrangedSubview(collectTitleLabel)
        
        // 约束堆栈视图到按钮中心
        NSLayoutConstraint.activate([
            collectStackView.centerXAnchor.constraint(equalTo: collectButton.centerXAnchor),
            collectStackView.centerYAnchor.constraint(equalTo: collectButton.centerYAnchor)
        ])
    }
    
    private func setupLineStarButton() {
        // 配置对星按钮
        lineStarButton.translatesAutoresizingMaskIntoConstraints = false
        lineStarButton.backgroundColor = ThemeManager.current.mainColor
        lineStarButton.layer.cornerRadius = 6
        lineStarButton.addTarget(self, action: #selector(lineStarButtonTapped), for: .touchUpInside)
        self.addSubview(lineStarButton)
        
        // 创建堆栈视图
        lineStarStackView.translatesAutoresizingMaskIntoConstraints = false
        lineStarStackView.axis = .horizontal
        lineStarStackView.alignment = .center
        lineStarStackView.distribution = .fill
        lineStarStackView.spacing = 8
        lineStarStackView.isUserInteractionEnabled = false // 让点击穿透到按钮
        lineStarButton.addSubview(lineStarStackView)
        
        // 添加活动指示器
        lineStarActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        lineStarActivityIndicator.hidesWhenStopped = true
        lineStarActivityIndicator.color = .white
        lineStarStackView.addArrangedSubview(lineStarActivityIndicator)
        
        // 添加标题标签
        lineStarTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        lineStarTitleLabel.text = "对星"
        lineStarTitleLabel.textColor = .white
        lineStarTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        lineStarStackView.addArrangedSubview(lineStarTitleLabel)
        
        // 约束堆栈视图到按钮中心
        NSLayoutConstraint.activate([
            lineStarStackView.centerXAnchor.constraint(equalTo: lineStarButton.centerXAnchor),
            lineStarStackView.centerYAnchor.constraint(equalTo: lineStarButton.centerYAnchor)
        ])
    }
    
    private func setConstraint() {
        NSLayoutConstraint.activate([
            lineStarButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            lineStarButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            lineStarButton.widthAnchor.constraint(equalToConstant: 135),
            lineStarButton.heightAnchor.constraint(equalToConstant: 48),
            
            collectButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            collectButton.trailingAnchor.constraint(equalTo: lineStarButton.leadingAnchor, constant: -16),
            collectButton.widthAnchor.constraint(equalToConstant: 135),
            collectButton.heightAnchor.constraint(equalToConstant: 48),
            
            lowPowerswitch.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            lowPowerswitch.trailingAnchor.constraint(equalTo: collectButton.leadingAnchor, constant: -16),
            
            lowPowerTitle.topAnchor.constraint(equalTo: lowPowerswitch.bottomAnchor, constant: 5),
            lowPowerTitle.centerXAnchor.constraint(equalTo: lowPowerswitch.centerXAnchor),
        ])
    }
    
    // MARK: - 定时器管理
    private func startCollectTimer() {
        // 取消之前的定时器
        collectTimer?.invalidate()
        
        // 创建新的定时器，5秒后自动完成
        collectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                print("收藏操作5秒超时，自动完成")
                self.stopCollecting(with: true)
                self.collectTimer = nil
            }
        }
    }
    
    private func startLineStarTimer() {
        // 取消之前的定时器
        lineStarTimer?.invalidate()
        
        // 创建新的定时器，5秒后自动完成
        lineStarTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                print("对星操作5秒超时，自动完成")
                self.stopLiningStar(with: true)
                self.lineStarTimer = nil
            }
        }
    }
    
    private func cancelCollectTimer() {
        collectTimer?.invalidate()
        collectTimer = nil
    }
    
    private func cancelLineStarTimer() {
        lineStarTimer?.invalidate()
        lineStarTimer = nil
    }
    
    // MARK: - 互斥逻辑
    private func updateButtonInteractionState() {
        // 如果任一按钮正在进行中，另一个按钮应该不可点击
        let isAnyOperationInProgress = (isCollecting == .inprogress) || (isLiningStar == .inprogress)
        
        // 收藏按钮只有在以下情况才能点击：
        // 1. 没有操作在进行中 或 当前正在进行的是收藏操作本身
        // 2. 收藏按钮本身不是在进行中状态
        collectButton.isEnabled = !isAnyOperationInProgress || isCollecting == .inprogress
        
        // 对星按钮只有在以下情况才能点击：
        // 1. 没有操作在进行中 或 当前正在进行的是对星操作本身
        // 2. 对星按钮本身不是在进行中状态
        lineStarButton.isEnabled = !isAnyOperationInProgress || isLiningStar == .inprogress
        
        print("按钮互斥状态更新 - 收藏: \(collectButton.isEnabled), 对星: \(lineStarButton.isEnabled), 进行中: \(isAnyOperationInProgress)")
    }
    
    // MARK: - 按钮状态更新
    private func updateCollectButtonState() {
        switch isCollecting {
        case .incomplete:
            collectTitleLabel.text = "收藏"
            collectTitleLabel.textColor = ThemeManager.current.mainColor
            collectActivityIndicator.stopAnimating()
            collectButton.backgroundColor = ThemeManager.current.mediumGrayBGColor
            cancelCollectTimer()
            
        case .inprogress:
            collectTitleLabel.text = "收藏中"
            collectTitleLabel.textColor = .white
            collectActivityIndicator.startAnimating()
            collectButton.backgroundColor = ThemeManager.current.mainColor.withAlphaComponent(0.7)
            
        case .completed:
            collectTitleLabel.text = "收藏"
            collectTitleLabel.textColor = .white
            collectActivityIndicator.stopAnimating()
            collectButton.backgroundColor = ThemeManager.current.mainColor
            cancelCollectTimer()
        }
    }
    
    private func updateLineStarButtonState() {
        switch isLiningStar {
        case .incomplete:
            lineStarTitleLabel.text = "对星"
            lineStarTitleLabel.textColor = .white
            lineStarButton.backgroundColor = ThemeManager.current.mainColor
            lineStarActivityIndicator.stopAnimating()
            cancelLineStarTimer()
            
        case .inprogress:
            lineStarTitleLabel.text = "对星中"
            lineStarTitleLabel.textColor = .white
            lineStarButton.backgroundColor = ThemeManager.current.mainColor.withAlphaComponent(0.7)
            lineStarActivityIndicator.startAnimating()
            
        case .completed:
            lineStarTitleLabel.text = "对星"
            lineStarTitleLabel.textColor = ThemeManager.current.mainColor
            lineStarButton.backgroundColor = ThemeManager.current.mediumGrayBGColor
            lineStarActivityIndicator.stopAnimating()
            cancelLineStarTimer()
        }
    }
    
    // MARK: - 公开方法
    func startCollecting() {
        // 如果对星正在进行中，不允许开始收藏
        guard isLiningStar != .inprogress else {
            print("对星正在进行中，无法开始收藏")
            return
        }
        isCollecting = .inprogress
        startCollectTimer()
    }
    
    public func stopCollecting(with collectedSuccess: Bool) {
        isCollecting = collectedSuccess ? .incomplete : .completed
        isLiningStar = collectedSuccess ? .incomplete : .completed
    }
    
    func startLiningStar() {
        // 如果收藏正在进行中，不允许开始对星
        guard isCollecting != .inprogress else {
            print("收藏正在进行中，无法开始对星")
            return
        }
        isLiningStar = .inprogress
        startLineStarTimer()
    }
    
    public func stopLiningStar(with lineSuccese: Bool) {
        isLiningStar = lineSuccese ? .completed : .incomplete
        isCollecting = lineSuccese ? .completed : .incomplete
    }
    
    // 重置所有按钮状态
    func resetAllStates() {
        isCollecting = .incomplete
        isLiningStar = .incomplete
        cancelCollectTimer()
        cancelLineStarTimer()
    }
    
    @objc private func collectionButtonTapped() {
        print("收藏按钮点击")
        
        // 检查是否可以开始收藏（互斥检查）
        guard isLiningStar != .inprogress else {
            print("对星正在进行中，不能开始收藏")
            return
        }
        
        // 开始收藏动画和定时器
        startCollecting()
        
        // 执行回调
        DispatchQueue.main.async {
            self.collectionAction?()
        }
    }
    
    @objc private func lineStarButtonTapped() {
        print("对星按钮点击")
        
        // 检查是否可以开始对星（互斥检查）
        guard isCollecting != .inprogress else {
            print("收藏正在进行中，不能开始对星")
            return
        }
        
        // 开始对星动画和定时器
        startLiningStar()
        
        // 执行回调
        DispatchQueue.main.async {
            self.lineStarAction?()
        }
    }
    
    @objc private func logSwitchChanged() {
        WiFiDeviceManager.shared.deepSleep(enable: lowPowerswitch.isOn) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    print("低功耗指令成功")
                case .failure(_):
                    print("低功耗指令失败")
                }
            }
        }
    }
}
