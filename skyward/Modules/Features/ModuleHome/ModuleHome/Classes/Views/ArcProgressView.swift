//
//  ArcProgressView.swift
//  Pods
//
//  Created by TXTS on 2026/3/19.
//

import UIKit
import SWTheme
import SnapKit

enum SOSStateType {
    case open
    case close
}

/// 圆弧进度条视图
/// 通过CAShapeLayer绘制圆弧，支持从0%到100%的动画进度
class ArcProgressView: UIView {
    
    // MARK: - 公开属性
    /// 当前进度 (0.0 ~ 1.0)
    var progress: CGFloat = 0.0 {
        didSet {
            progress = max(0.0, min(1.0, progress))
            updateProgress(animated: true)
        }
    }
    
    /// 圆弧线条颜色
    var arcColor: UIColor = ThemeManager.current.mainColor {
        didSet {
            progressLayer.strokeColor = arcColor.cgColor
        }
    }
    
    /// 背景轨道颜色
    var trackColor: UIColor = UIColor.systemGray.withAlphaComponent(0.3) {
        didSet {
            backgroundLayer.strokeColor = trackColor.cgColor
        }
    }
    
    /// 线条宽度
    var lineWidth: CGFloat = 3.0 {
        didSet {
            backgroundLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }
    
    var type: SOSStateType = .open {
        didSet {
            titleLabel.text = type == .open ? "开启SOS中" : "关闭SOS中"
        }
    }
    
    // MARK: - 私有属性
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    private let countdownLabel = UILabel()
    private var hasLayoutedSubviews = false
    private var isAnimating = false
    private let totalDuration: CGFloat = 3.0
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        self.layer.cornerRadius = 12
        self.alpha = 0 // 默认隐藏
        
        // 配置背景轨道
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = trackColor.cgColor
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)
        
        // 配置进度圆弧
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = arcColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
        
        // 配置标题标签
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        // 配置倒计时标签
        countdownLabel.textColor = .white
        countdownLabel.font = .systemFont(ofSize: 24, weight: .bold)
        countdownLabel.textAlignment = .center
        countdownLabel.text = "3"
        self.addSubview(countdownLabel)
        
        // 设置约束
        countdownLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(self.snp.centerY).offset(-15)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.snp.centerY).offset(35)
            make.centerX.equalToSuperview()
        }
    }
    
    // MARK: - 布局
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY - 15)
        let radius: CGFloat = 30.0
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = 2 * .pi - .pi / 2
        
        let arcPath = UIBezierPath(arcCenter: center,
                                    radius: radius,
                                    startAngle: startAngle,
                                    endAngle: endAngle,
                                    clockwise: true)
        
        backgroundLayer.path = arcPath.cgPath
        progressLayer.path = arcPath.cgPath
        
        if !hasLayoutedSubviews {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = 0.0
            CATransaction.commit()
            hasLayoutedSubviews = true
        }
    }
    
    // MARK: - 进度更新
    private func updateProgress(animated: Bool) {
        if animated {
            guard hasLayoutedSubviews else { return }
            
            isAnimating = true
            
            // 移除之前的动画
            progressLayer.removeAnimation(forKey: "progressAnim")
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.presentation()?.strokeEnd ?? 0
            animation.toValue = progress
            animation.duration = 0.2  // 快速响应外部进度
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            progressLayer.add(animation, forKey: "progressAnim")
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = progress
            CATransaction.commit()
            
            // 更新倒计时显示
            updateCountdownLabel(progress: progress)
            
            if progress >= 1.0 {
                isAnimating = false
            }
        } else {
            progressLayer.removeAnimation(forKey: "progressAnim")
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = progress
            CATransaction.commit()
            
            updateCountdownLabel(progress: progress)
            isAnimating = false
        }
    }
    
    // 更新倒计时显示
    private func updateCountdownLabel(progress: CGFloat) {
        if progress >= 1.0 {
            countdownLabel.text = "✓"
            countdownLabel.font = .systemFont(ofSize: 32, weight: .bold)
        } else {
            let remainingSeconds = Int(ceil(totalDuration * (1.0 - progress)))
            countdownLabel.text = "\(max(remainingSeconds, 1))"
            countdownLabel.font = .systemFont(ofSize: 24, weight: .bold)
        }
    }
    
    // MARK: - 外部控制方法
    /// 从外部更新进度（由SOSButton的进度回调调用）
    func updateProgressFromExternal(_ progress: CGFloat) {
        self.progress = progress
    }
    
    func resetProgress() {
        progressLayer.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = 0.0
        CATransaction.commit()
        
        progress = 0.0
        isAnimating = false
        
        countdownLabel.text = "3"
        countdownLabel.font = .systemFont(ofSize: 24, weight: .bold)
    }
    
    // MARK: - 显示/隐藏方法
    func show(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3) { self.alpha = 1 }
        } else { self.alpha = 1 }
    }
    
    func hide(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3) { self.alpha = 0 }
        } else { self.alpha = 0 }
    }
    
    func hideAndReset(animated: Bool = true) {
        hide(animated: animated)
        resetProgress()
    }
    
    func showAndStartAnimation(type: SOSStateType? = nil) {
        if let newType = type { self.type = newType }
        resetProgress()
        show()
        // 注意：这里不再自动开始动画，而是等待SOSButton的进度更新
    }
}
