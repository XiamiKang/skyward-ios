//
//  SOSButton.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/24.
//

import UIKit
import TXKit
import SWTheme

public protocol SOSButtonDelegate: AnyObject {
    func sosButtonDidCompleteLongPress(_ button: SOSButton)
}

public class SOSButton: UIButton {
    
    public weak var delegate: SOSButtonDelegate?
    
    // 进度条视图
    private let progressView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 长按手势识别器
    private let longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0
        return gesture
    }()
    
    // 进度条动画相关属性
    private var progressTimer: Timer?
    private var currentProgress: CGFloat = 0
    private let maxDuration: TimeInterval = 3.0  // 改为3秒，与ArcProgressView一致
    private let animationInterval: TimeInterval = 0.01
    
    // 是否完成长按
    private var isLongPressCompleted = false
    
    // 保持原有命名
    public var startLongPanAction: ((Bool) -> Void)?
    // 新增进度同步回调
    public var progressUpdateHandler: ((CGFloat) -> Void)?
    // 新增长按取消回调
    public var longPressCancelHandler: (() -> Void)?
    
    // 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    // 设置UI
    private func setupUI() {
        // 设置按钮基本属性
        let isInSOS = SOSManager.shared.checkUserSOSState()
        setTitle(isInSOS ? "长按关闭SOS报警" : "长按开启SOS报警", for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        backgroundColor = ThemeManager.current.errorColor
        setTitleColor(.white, for: .normal)
        layer.cornerRadius = 8
        clipsToBounds = true
        
        // 添加进度条
        addSubview(progressView)
        sendSubviewToBack(progressView)
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 0)
        ])
    }
    
    // 设置事件
    private func setupActions() {
        longPressGesture.addTarget(self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    // 处理长按手势
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startProgressAnimation()
            let isInSOS = SOSManager.shared.checkUserSOSState()
            startLongPanAction?(isInSOS)
        case .ended, .cancelled, .failed:
            resetProgress()
            // 通知外部长按取消，隐藏圆弧进度视图
            longPressCancelHandler?()
        default:
            break
        }
    }
    
    // 开始进度动画
    private func startProgressAnimation() {
        currentProgress = 0
        isLongPressCompleted = false
        
        // 重置进度条
        progressView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.isActive = false
            }
        }
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalToConstant: 0)
        ])
        layoutIfNeeded()
        
        // 创建定时器更新进度
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(timeInterval: animationInterval, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    // 更新进度
    @objc private func updateProgress() {
        currentProgress += CGFloat(animationInterval / maxDuration)
        
        if currentProgress >= 1.0 {
            currentProgress = 1.0
            completeLongPress()
        }
        
        // 更新内部进度条宽度
        progressView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.isActive = false
            }
        }
        let newWidth = bounds.width * currentProgress
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalToConstant: newWidth)
        ])
        
        // 动画更新内部进度条
        UIView.animate(withDuration: animationInterval) {
            self.layoutIfNeeded()
        }
        
        // 通知外部进度更新（用于ArcProgressView）
        progressUpdateHandler?(currentProgress)
    }
    
    // 完成长按
    private func completeLongPress() {
        isLongPressCompleted = true
        progressTimer?.invalidate()
        
        // 确保最终进度为1.0
        progressUpdateHandler?(1.0)
        
        // 通知代理
        delegate?.sosButtonDidCompleteLongPress(self)
    }
    
    // 重置进度
    private func resetProgress() {
        progressTimer?.invalidate()
        
        // 重置内部进度条
        progressView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width {
                constraint.isActive = false
            }
        }
        NSLayoutConstraint.activate([
            progressView.widthAnchor.constraint(equalToConstant: 0)
        ])
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
        
        // 只有在未完成长按的情况下才重置进度
        if !isLongPressCompleted {
            progressUpdateHandler?(0)
        }
    }
    
    // 清理资源
    deinit {
        progressTimer?.invalidate()
    }
}
