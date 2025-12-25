//
//  SWPopupView.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/19.
//

import UIKit
import TXKit

// MARK: - 弹窗位置枚举
public enum SWPopupPosition {
    case top
    case center
    case bottom
}

// MARK: - 弹窗配置
public struct SWPopupConfiguration {
    var position: SWPopupPosition = .center
    var animationDuration: TimeInterval = 0.3
    var maskColor: UIColor = UIColor.black.withAlphaComponent(0.5)
    var cornerRadius: CGFloat = 0
    var contentInsets: UIEdgeInsets = .zero
    public var dismissOnMaskTap: Bool = true
    var springAnimation: Bool = true
    var springDamping: CGFloat = 0.8
    var springVelocity: CGFloat = 0.5
    
    public init(
        position: SWPopupPosition = .center,
        animationDuration: TimeInterval = 0.3,
        maskColor: UIColor = UIColor.black.withAlphaComponent(0.5),
        cornerRadius: CGFloat = 0,
        contentInsets: UIEdgeInsets = .zero,
        dismissOnMaskTap: Bool = true,
        springAnimation: Bool = true,
        springDamping: CGFloat = 0.8,
        springVelocity: CGFloat = 0.5
    ) {
        self.position = position
        self.animationDuration = animationDuration
        self.maskColor = maskColor
        self.cornerRadius = cornerRadius
        self.contentInsets = contentInsets
        self.dismissOnMaskTap = dismissOnMaskTap
        self.springAnimation = springAnimation
        self.springDamping = springDamping
        self.springVelocity = springVelocity
    }
}

// MARK: - 弹窗协议
public protocol SWPopupContentView: UIView {
    func popupWillShow()
    func popupDidShow()
    func popupWillDismiss()
    func popupDidDismiss()
}

// MARK: - 默认实现
public extension SWPopupContentView {
    func popupWillShow() {}
    func popupDidShow() {}
    func popupWillDismiss() {}
    func popupDidDismiss() {}
}

// MARK: - 主弹窗类
public final class SWPopupView: UIView {
    
    // MARK: - 静态属性
    public static var currentPopup: SWPopupView?
    
    // MARK: - 属性
    private let configuration: SWPopupConfiguration
    private let contentView: UIView
    private var backgroundMaskView: UIView!
    private var containerView: UIView!
    private var isShowing = false
    private var isDismissing = false
    
    // 位置约束
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var centerYConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    // 键盘相关
    private var keyboardHeight: CGFloat = 0
    private var originalPositionConstant: CGFloat = 0
    private var isKeyboardVisible = false
    
    // MARK: - 初始化
    
    public init(contentView: UIView, configuration: SWPopupConfiguration = SWPopupConfiguration()) {
        self.contentView = contentView
        self.configuration = configuration
        super.init(frame: UIScreen.main.bounds)
        setupUI()
        setupGestures()
        setupKeyboardObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeKeyboardObservers()
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 创建遮罩视图
        backgroundMaskView = UIView()
        backgroundMaskView.backgroundColor = configuration.maskColor
        backgroundMaskView.alpha = 0
        addSubview(backgroundMaskView)
        backgroundMaskView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundMaskView.topAnchor.constraint(equalTo: topAnchor),
            backgroundMaskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundMaskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundMaskView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 创建容器视图
        containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = configuration.cornerRadius
        containerView.layer.masksToBounds = true
        containerView.alpha = 0
        addSubview(containerView)
        
        // 根据position设置圆角
        if configuration.position == .bottom, configuration.cornerRadius > 0 {
            // 底部弹出只切左上和右上圆角
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加内容视图
        containerView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: configuration.contentInsets.top),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: configuration.contentInsets.left),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -configuration.contentInsets.right),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -configuration.contentInsets.bottom)
        ])
        
        setupPositionConstraints()
    }
    
    private func setupPositionConstraints() {
        // 清除之前的约束
        topConstraint?.isActive = false
        bottomConstraint?.isActive = false
        centerYConstraint?.isActive = false
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        
        let safeArea = safeAreaLayoutGuide
        
        switch configuration.position {
        case .top:
            // 顶部弹出
            topConstraint = containerView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: -containerView.frame.height)
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor)
            trailingConstraint = containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
            
        case .center:
            // 中间弹出
            centerYConstraint = containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -containerView.frame.height)
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 36)
            trailingConstraint = containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -36)
            
        case .bottom:
            // 底部弹出
            bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: containerView.frame.height)
            leadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor)
            trailingConstraint = containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        }
        
        // 激活约束
        topConstraint?.isActive = true
        bottomConstraint?.isActive = true
        centerYConstraint?.isActive = true
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
    }
    
    private func setupGestures() {
        if configuration.dismissOnMaskTap {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundMaskViewTapped))
            backgroundMaskView.addGestureRecognizer(tapGesture)
        }
    }
    
    // MARK: - 显示动画
    
    public func show(in superView: UIView? = nil, completion: (() -> Void)? = nil) {
        guard !isShowing && !isDismissing else { return }
        
        // 添加到视图
        guard let targetView = superView ?? ScreenUtil.getKeyWindow() else {
            return
        }
        targetView.addSubview(self)
        
        isShowing = true
        
        // 设置初始位置
        setupInitialPosition()
        
        // 更新当前弹窗引用
        SWPopupView.currentPopup = self
        
        // 调用内容视图的即将显示方法
        if let popupContent = contentView as? SWPopupContentView {
            popupContent.popupWillShow()
        }
        
        // 执行显示动画
        performShowAnimation {
            self.isShowing = false
            if let popupContent = self.contentView as? SWPopupContentView {
                popupContent.popupDidShow()
            }
            completion?()
        }
    }
    
    private func setupInitialPosition() {
        layoutIfNeeded()
        
        let containerHeight = containerView.frame.height
        
        switch configuration.position {
        case .top:
            topConstraint?.constant = -containerHeight
        case .center:
            centerYConstraint?.constant = -containerHeight
        case .bottom:
            bottomConstraint?.constant = containerHeight
        }
        
        layoutIfNeeded()
    }
    
    private func performShowAnimation(completion: @escaping () -> Void) {
        layoutIfNeeded()
        
        switch configuration.position {
        case .top:
            topConstraint?.constant = 0
        case .center:
            centerYConstraint?.constant = 0
        case .bottom:
            bottomConstraint?.constant = 0
        }
        
        if configuration.springAnimation {
            // 弹簧动画
            UIView.animate(
                withDuration: configuration.animationDuration,
                delay: 0,
                usingSpringWithDamping: configuration.springDamping,
                initialSpringVelocity: configuration.springVelocity,
                options: [.curveEaseOut],
                animations: {
                    self.backgroundMaskView.alpha = 1
                    if let containerView = self.containerView {
                        containerView.alpha = 1
                    }
                    self.layoutIfNeeded()
                },
                completion: { _ in
                    completion()
                }
            )
        } else {
            // 普通动画
            UIView.animate(
                withDuration: configuration.animationDuration,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    self.backgroundMaskView.alpha = 1
                    self.containerView.alpha = 1
                    self.layoutIfNeeded()
                },
                completion: { _ in
                    completion()
                }
            )
        }
    }
    
    // MARK: - 隐藏动画
    
    public func dismiss(completion: (() -> Void)? = nil) {
        guard !isShowing && !isDismissing else { return }
        
        isDismissing = true
        
        // 调用内容视图的即将消失方法
        if let popupContent = contentView as? SWPopupContentView {
            popupContent.popupWillDismiss()
        }
        
        // 执行隐藏动画
        performDismissAnimation {
            self.removeFromSuperview()
            self.isDismissing = false
            if let popupContent = self.contentView as? SWPopupContentView {
                popupContent.popupDidDismiss()
            }
            completion?()
        }
    }
    
    @objc private func backgroundMaskViewTapped() {
        dismiss()
    }
    
    private func performDismissAnimation(completion: @escaping () -> Void) {
        guard let containerView = containerView else {
            completion()
            return
        }
        let containerHeight = containerView.frame.height
        
        // 设置最终位置
        switch configuration.position {
        case .top:
            topConstraint?.constant = -containerHeight
        case .center:
            centerYConstraint?.constant = -containerHeight
        case .bottom:
            bottomConstraint?.constant = containerHeight
        }
        
        UIView.animate(
            withDuration: configuration.animationDuration,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                    self.backgroundMaskView.alpha = 0
                    if let containerView = self.containerView {
                        containerView.alpha = 0
                    }
                    self.layoutIfNeeded()
                },
            completion: { _ in
                // 如果当前弹窗是自己，则清除引用
                if SWPopupView.currentPopup === self {
                    SWPopupView.currentPopup = nil
                }
                // 恢复原始位置常量
                self.restoreOriginalPosition()
                completion()
            }
        )
    }
}

// MARK: - 便捷构造方法
public extension SWPopupView {
    
    /// 从顶部弹出的便捷方法
    @discardableResult
    static func showFromTop(
        contentView: UIView,
        in superView: UIView? = nil,
        configuration: SWPopupConfiguration = SWPopupConfiguration(position: .top),
        completion: (() -> Void)? = nil
    ) -> SWPopupView {
        var config = configuration
        config.position = .top
        let popup = SWPopupView(contentView: contentView, configuration: config)
        popup.show(in: superView, completion: completion)
        return popup
    }
    
    /// 从中间弹出的便捷方法
    @discardableResult
    static func showFromCenter(
        contentView: UIView,
        in superView: UIView? = nil,
        configuration: SWPopupConfiguration = SWPopupConfiguration(position: .center),
        completion: (() -> Void)? = nil
    ) -> SWPopupView {
        var config = configuration
        config.position = .center
        let popup = SWPopupView(contentView: contentView, configuration: config)
        popup.show(in: superView, completion: completion)
        return popup
    }
    
    /// 从底部弹出的便捷方法
    @discardableResult
    static func showFromBottom(
        contentView: UIView,
        in superView: UIView? = nil,
        configuration: SWPopupConfiguration = SWPopupConfiguration(),
        completion: (() -> Void)? = nil
    ) -> SWPopupView {
        var config = configuration
        config.position = .bottom
        config.cornerRadius = CornerRadius.large.rawValue
        let popup = SWPopupView(contentView: contentView, configuration: config)
        popup.show(in: superView, completion: completion)
        return popup
    }
}

extension SWPopupView {
    // MARK: - 键盘处理
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard !isKeyboardVisible, let userInfo = notification.userInfo else { return }
        
        // 获取键盘高度
        if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = keyboardFrame.height
        }
        
        // 获取动画时间
        let animationDuration: TimeInterval = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.3
        let animationCurve: UIView.AnimationOptions = {
            if let curveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
                return UIView.AnimationOptions(rawValue: UInt(curveRawValue << 16))
            }
            return .curveEaseInOut
        }()
        
        // 保存原始位置常量
        saveOriginalPosition()
        
        // 调整弹窗位置
        adjustPositionForKeyboard(animationDuration: animationDuration, animationCurve: animationCurve)
        
        isKeyboardVisible = true
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard isKeyboardVisible, let userInfo = notification.userInfo else { return }
        
        // 获取动画时间
        let animationDuration: TimeInterval = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.3
        let animationCurve: UIView.AnimationOptions = {
            if let curveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
                return UIView.AnimationOptions(rawValue: UInt(curveRawValue << 16))
            }
            return .curveEaseInOut
        }()
        
        // 恢复弹窗位置
        restoreOriginalPosition(animationDuration: animationDuration, animationCurve: animationCurve)
        
        isKeyboardVisible = false
        keyboardHeight = 0
    }
    
    private func saveOriginalPosition() {
        // 保存当前的位置约束常量
        switch configuration.position {
        case .top:
            if let constant = topConstraint?.constant {
                originalPositionConstant = constant
            }
        case .center:
            if let constant = centerYConstraint?.constant {
                originalPositionConstant = constant
            }
        case .bottom:
            if let constant = bottomConstraint?.constant {
                originalPositionConstant = constant
            }
        }
    }
    
    private func adjustPositionForKeyboard(animationDuration: TimeInterval, animationCurve: UIView.AnimationOptions) {
        guard keyboardHeight > 0 else { return }
        
        // 计算弹窗底部与屏幕底部的距离
        let screenHeight = UIScreen.main.bounds.height
        let containerBottom = containerView.frame.origin.y + containerView.frame.height
        let distanceToBottom = screenHeight - containerBottom
        
        // 只在键盘会遮挡弹窗时调整位置
        if distanceToBottom < keyboardHeight {
            // 需要调整的距离
            let adjustDistance = keyboardHeight - distanceToBottom
            
            // 根据弹窗位置进行调整
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                switch self.configuration.position {
                case .top:
                    // 顶部弹窗向下移动
                    if let topConstraint = self.topConstraint {
                        topConstraint.constant += adjustDistance
                    }
                case .center:
                    // 中间弹窗向上移动
                    if let centerYConstraint = self.centerYConstraint {
                        centerYConstraint.constant -= adjustDistance
                    }
                case .bottom:
                    // 底部弹窗向上移动
                    if let bottomConstraint = self.bottomConstraint {
                        bottomConstraint.constant -= adjustDistance
                    }
                }
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    private func restoreOriginalPosition(animationDuration: TimeInterval = 0, animationCurve: UIView.AnimationOptions = .curveEaseInOut) {
        // 恢复到原始位置
        if animationDuration > 0 {
            UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
                self.applyOriginalPosition()
                self.layoutIfNeeded()
            }, completion: nil)
        } else {
            applyOriginalPosition()
        }
    }
    
    private func applyOriginalPosition() {
        switch configuration.position {
        case .top:
            if let topConstraint = self.topConstraint {
                topConstraint.constant = originalPositionConstant
            }
        case .center:
            if let centerYConstraint = self.centerYConstraint {
                centerYConstraint.constant = originalPositionConstant
            }
        case .bottom:
            if let bottomConstraint = self.bottomConstraint {
                bottomConstraint.constant = originalPositionConstant
            }
        }
    }
}
