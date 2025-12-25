//
//  BottomSheetConfig.swift
//  33333
//
//  Created by TXTS on 2025/12/24.
//


import UIKit

// 底部弹出视图配置
public struct BottomSheetConfig {
    let heightPercentages: [CGFloat] // 高度百分比数组 (0-1)，从小到大排序
    let cornerRadius: CGFloat
    let handleBarHeight: CGFloat
    let backgroundColor: UIColor
    let dimColor: UIColor
    let dimAlpha: CGFloat
    let animationDuration: TimeInterval
    let showIndicator: Bool // 是否显示手柄
    
    public init(heightPercentages: [CGFloat] = [0.3, 0.5, 0.8],
         cornerRadius: CGFloat = 12,
         handleBarHeight: CGFloat = 24,
         backgroundColor: UIColor = .systemBackground,
         dimColor: UIColor = .black,
         dimAlpha: CGFloat = 0.4,
         animationDuration: TimeInterval = 0.3,
         showIndicator: Bool = true) {
        // 确保从小到大排序
        self.heightPercentages = heightPercentages.sorted()
        self.cornerRadius = cornerRadius
        self.handleBarHeight = handleBarHeight
        self.backgroundColor = backgroundColor
        self.dimColor = dimColor
        self.dimAlpha = dimAlpha
        self.animationDuration = animationDuration
        self.showIndicator = showIndicator
    }
}

// 手势方向枚举
enum PanDirection {
    case up, down, none
}

// 代理协议
public protocol BottomSheetViewDelegate: AnyObject {
    func bottomSheetWillAppear()
    func bottomSheetDidAppear()
    func bottomSheetWillDisappear()
    func bottomSheetDidDisappear()
    func bottomSheetHeightChanged(to percentage: CGFloat)
    func bottomSheetWillChangeHeight(from oldPercentage: CGFloat, to newPercentage: CGFloat)
}

public extension BottomSheetViewDelegate {
    func bottomSheetWillAppear() {}
    func bottomSheetDidAppear() {}
    func bottomSheetWillDisappear() {}
    func bottomSheetDidDisappear() {}
    func bottomSheetHeightChanged(to percentage: CGFloat) {}
    func bottomSheetWillChangeHeight(from oldPercentage: CGFloat, to newPercentage: CGFloat) {}
}

public class BottomSheetView: UIView {
    
    // MARK: - 属性
    private let config: BottomSheetConfig
    private var currentLevel: Int = 0 // 总是从0开始（最小高度）
    public weak var delegate: BottomSheetViewDelegate?
    
    // 视图引用
    private weak var parentView: UIView?
    private let dimView = UIView()
    private let contentView = UIView()
    private let handleBar = UIView()
    private var customContentView: UIView?
    
    // 手势相关
    private var initialTouchPoint: CGPoint = .zero
    private var isPanning = false
    
    // 计算属性
    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    private var maxHeight: CGFloat {
        return config.heightPercentages.last! * screenHeight
    }
    
    private var minHeight: CGFloat {
        return config.heightPercentages.first! * screenHeight
    }
    
    private var currentHeightPercentage: CGFloat {
        return config.heightPercentages[currentLevel]
    }
    
    // MARK: - 初始化
    public init(config: BottomSheetConfig = BottomSheetConfig()) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        self.config = BottomSheetConfig()
        super.init(coder: coder)
        setupUI()
        setupGestures()
    }
    
    // MARK: - 公开方法
    
    /// 在指定视图中显示底部弹窗
    /// - Parameter view: 父视图，默认为 keyWindow
    public func show(in view: UIView? = nil) {
        guard let parent = view ?? UIApplication.shared.keyWindow else { return }
        parentView = parent
        
        // 每次显示都重置为最小高度
        currentLevel = 0
        
        delegate?.bottomSheetWillAppear()
        
        // 添加模糊背景
        dimView.backgroundColor = config.dimColor.withAlphaComponent(0)
        dimView.frame = parent.bounds
        dimView.alpha = 0
        parent.addSubview(dimView)
        
        // 计算初始位置（最小高度）
        let initialHeight = config.heightPercentages.first! * screenHeight
        let yPosition = screenHeight - initialHeight
        
        // 添加内容视图
        contentView.frame = CGRect(
            x: 0,
            y: screenHeight,
            width: screenWidth,
            height: maxHeight
        )
        parent.addSubview(contentView)
        
        // 如果有自定义内容视图，添加到内容区域
        if let customView = customContentView {
            addCustomContentView(customView)
        }
        
        // 淡入背景
        UIView.animate(withDuration: config.animationDuration * 0.5) {
            self.dimView.alpha = 1
        }
        
        // 添加上移动画
        UIView.animate(
            withDuration: config.animationDuration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.contentView.frame.origin.y = yPosition
        } completion: { _ in
            self.delegate?.bottomSheetDidAppear()
            self.delegate?.bottomSheetHeightChanged(to: self.currentHeightPercentage)
        }
    }
    
    /// 隐藏底部弹窗
    public func hide(completion: (() -> Void)? = nil) {
        delegate?.bottomSheetWillDisappear()
        
        UIView.animate(withDuration: config.animationDuration * 0.7) {
            self.dimView.alpha = 0
            self.contentView.frame.origin.y = self.screenHeight
        } completion: { _ in
            self.dimView.removeFromSuperview()
            self.contentView.removeFromSuperview()
            self.delegate?.bottomSheetDidDisappear()
            completion?()
        }
    }
    
    /// 切换到指定级别
    /// - Parameter level: 级别索引
    func switchToLevel(_ level: Int, animated: Bool = true) {
        guard level >= 0 && level < config.heightPercentages.count else { return }
        
        let oldPercentage = currentHeightPercentage
        currentLevel = level
        let targetHeight = config.heightPercentages[level] * screenHeight
        let yPosition = screenHeight - targetHeight
        
        delegate?.bottomSheetWillChangeHeight(from: oldPercentage, to: currentHeightPercentage)
        
        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseOut
            ) {
                self.contentView.frame.origin.y = yPosition
            } completion: { _ in
                self.delegate?.bottomSheetHeightChanged(to: self.currentHeightPercentage)
            }
        } else {
            contentView.frame.origin.y = yPosition
            delegate?.bottomSheetHeightChanged(to: currentHeightPercentage)
        }
    }
    
    // MARK: - 私有方法
    
    private func setupUI() {
        // 设置内容视图
        contentView.backgroundColor = config.backgroundColor
        contentView.layer.cornerRadius = config.cornerRadius
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.clipsToBounds = true
        
        // 设置手柄条（如果启用）
        if config.showIndicator {
            setupHandleBar()
        }
        
        // 设置模糊视图点击事件
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        dimView.addGestureRecognizer(tapGesture)
    }
    
    private func setupHandleBar() {
        handleBar.backgroundColor = UIColor.systemGray3.withAlphaComponent(0.8)
        handleBar.layer.cornerRadius = 5
        handleBar.frame = CGRect(
            x: (screenWidth - 40) / 2,
            y: 8,
            width: 50,
            height: config.handleBarHeight
        )
        contentView.addSubview(handleBar)
    }
    
    private func addCustomContentView(_ view: UIView) {
        // 移除之前的内容视图（除了手柄条）
        contentView.subviews.forEach {
            if $0 != handleBar {
                $0.removeFromSuperview()
            }
        }
        
        // 为内容视图留出handleBar的空间（如果显示）
        let contentY = config.showIndicator ? config.handleBarHeight + 16 : 0
        let contentHeight = maxHeight - contentY
        
        view.frame = CGRect(
            x: 0,
            y: contentY,
            width: screenWidth,
            height: contentHeight
        )
        contentView.addSubview(view)
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        contentView.addGestureRecognizer(panGesture)
    }
    
    @objc private func dimViewTapped() {
        hide()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView)
        let velocity = gesture.velocity(in: contentView)
        
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: contentView)
            isPanning = true
            
        case .changed:
            let currentY = contentView.frame.origin.y
            var newY = currentY + translation.y
            
            // 限制拖动范围
            let minY = screenHeight - maxHeight
            let maxY = screenHeight - minHeight
            newY = min(maxY, max(minY, newY))
            
            contentView.frame.origin.y = newY
            
            // 重置translation以便连续拖动
            gesture.setTranslation(.zero, in: contentView)
            
        case .ended, .cancelled:
            isPanning = false
            handlePanEnded(translation: translation, velocity: velocity)
            
        default:
            break
        }
    }
    
    private func handlePanEnded(translation: CGPoint, velocity: CGPoint) {
        let velocityY = velocity.y
        let currentY = contentView.frame.origin.y
        let currentHeight = screenHeight - currentY
        let currentPercentage = currentHeight / screenHeight
        
        // 计算距离最近的高度级别
        var nearestLevel = 0
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for (index, percentage) in config.heightPercentages.enumerated() {
            let distance = abs(percentage - currentPercentage)
            if distance < minDistance {
                minDistance = distance
                nearestLevel = index
            }
        }
        
        // 根据手势方向、速度和距离决定行为
        let isFastDownSwipe = velocityY > 800
        let isDownward = velocityY > 0
        
        if isFastDownSwipe {
            // 快速下滑时直接隐藏
            hide()
            return
        }
        
        if isDownward && translation.y > 50 {
            // 明显的下滑手势，隐藏
            hide()
            return
        }
        
        // 切换到最近的高度级别
        switchToLevel(nearestLevel)
    }
    
    // MARK: - 内容区域管理
    
    /// 设置自定义内容视图
    /// - Parameter view: 要添加的内容视图
    public func setContentView(_ view: UIView) {
        self.customContentView = view
    }
    
    /// 获取当前高度百分比
    func getCurrentHeightPercentage() -> CGFloat {
        return currentHeightPercentage
    }
    
    /// 获取所有可用高度百分比
    func getAllHeightPercentages() -> [CGFloat] {
        return config.heightPercentages
    }
    
    /// 获取最小高度百分比
    func getMinHeightPercentage() -> CGFloat {
        return config.heightPercentages.first ?? 0
    }
    
    /// 获取最大高度百分比
    func getMaxHeightPercentage() -> CGFloat {
        return config.heightPercentages.last ?? 0
    }
}

