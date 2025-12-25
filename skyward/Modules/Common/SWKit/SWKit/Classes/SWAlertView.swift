//
//  SWAlertView.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import SWTheme

// MARK: - AlertView按钮配置
public struct SWAlertAction: Equatable {
    public let title: String
    public let style: Style
    public let handler: (() -> Void)?
    
    public enum Style: Equatable {
        case confirm
        case cancel
        case destructive
    }
    
    public init(title: String, style: Style = .destructive, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
    
    public static func == (lhs: SWAlertAction, rhs: SWAlertAction) -> Bool {
        return lhs.title == rhs.title && lhs.style == rhs.style
    }
}

// MARK: - AlertView配置
public struct SWAlertConfiguration {
    var cornerRadius: CGFloat = CornerRadius.medium.rawValue
    var titleFont: UIFont = .pingFangFontBold(ofSize: 16)
    var titleColor: UIColor = ThemeManager.current.titleColor
    var messageFont: UIFont = .pingFangFontRegular(ofSize: 14)
    var messageColor: UIColor = ThemeManager.current.secondaryColor
    var buttonHeight: CGFloat = swAdaptedValue(40)
    var buttonSpacing: CGFloat = 12
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 20, left: Layout.hMargin, bottom: Layout.vMargin, right: Layout.hMargin)
    var titleContentSpacing: CGFloat = 12
    var contentButtonSpacing: CGFloat = 20
    var buttonCornerRadius: CGFloat = CornerRadius.medium.rawValue
    
    public init() {}
}

// MARK: - 自定义视图协议
public protocol SWAlertCustomView: UIView {
    func shouldClickConfirmButton() -> Bool
}

// MARK: - 默认实现
public extension SWAlertCustomView {
    func shouldClickConfirmButton() -> Bool {
        return true
    }
}

// MARK: - AlertView类
public final class SWAlertView: UIView, SWPopupContentView {
    
    // MARK: - 属性
    private let configuration: SWAlertConfiguration
    private let title: String?
    private let message: String?
    private let customView: SWAlertCustomView?
    private let actions: [SWAlertAction]
    
    // UI组件
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        return stackView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    // MARK: - 初始化
    
    /// 初始化带有标题、消息和按钮的AlertView
    public init(
        title: String?,
        message: String?,
        actions: [SWAlertAction],
        configuration: SWAlertConfiguration = SWAlertConfiguration()
    ) {
        self.title = title
        self.message = message
        self.customView = nil
        self.actions = actions
        self.configuration = configuration
        super.init(frame: .zero)
        setupUI()
    }
    
    /// 初始化带有自定义视图和按钮的AlertView
    public init(
        title: String? = nil,
        customView: SWAlertCustomView,
        actions: [SWAlertAction],
        configuration: SWAlertConfiguration = SWAlertConfiguration()
    ) {
        self.title = title
        self.message = nil
        self.customView = customView
        self.actions = actions
        self.configuration = configuration
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = configuration.cornerRadius
        clipsToBounds = true
        
        // 添加内容栈视图
        addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置内容栈视图约束
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: configuration.contentInsets.top),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: configuration.contentInsets.left),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -configuration.contentInsets.right),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -configuration.contentInsets.bottom)
        ])
        
        // 添加标题标签
        if let title = title, !title.isEmpty {
            titleLabel.text = title
            titleLabel.font = configuration.titleFont
            titleLabel.textColor = configuration.titleColor
            contentStackView.addArrangedSubview(titleLabel)
        }
        
        // 添加自定义视图
        if let customView = customView {
            contentStackView.addArrangedSubview(customView)
            
            if titleLabel.superview != nil {
                contentStackView.setCustomSpacing(configuration.titleContentSpacing, after: titleLabel)
            }
        } else {
            // 添加消息标签
            if let message = message, !message.isEmpty {
                messageLabel.text = message
                messageLabel.font = configuration.messageFont
                messageLabel.textColor = configuration.messageColor
                contentStackView.addArrangedSubview(messageLabel)
                
                // 如果有标题，添加标题和消息之间的间距
                if titleLabel.superview != nil {
                    contentStackView.setCustomSpacing(configuration.titleContentSpacing, after: titleLabel)
                }
            }
        }
        
        // 添加按钮栈视图
        contentStackView.addArrangedSubview(buttonStackView)
        
        // 如果有内容，添加内容和按钮之间的间距
        if contentStackView.arrangedSubviews.count > 1 {
            let lastContentIndex = contentStackView.arrangedSubviews.count - 2
            contentStackView.setCustomSpacing(configuration.contentButtonSpacing, after: contentStackView.arrangedSubviews[lastContentIndex])
        }
        
        // 创建按钮
        createButtons()
    }
    
    private func createButtons() {
        guard !actions.isEmpty else { return }
        
        // 根据按钮数量调整布局
        if actions.count == 1 {
            // 单个按钮
            let button = createButton(action: actions.first!)
            buttonStackView.addArrangedSubview(button)
        } else {
            // 多个按钮
            let buttonContainerStackView = UIStackView()
            buttonContainerStackView.axis = .horizontal
            buttonContainerStackView.distribution = .fillEqually
            buttonContainerStackView.spacing = configuration.buttonSpacing
            
            for action in actions {
                let button = createButton(action: action)
                buttonContainerStackView.addArrangedSubview(button)
            }
            
            buttonStackView.addArrangedSubview(buttonContainerStackView)
        }
        
        // 设置按钮高度
        buttonStackView.heightAnchor.constraint(equalToConstant: configuration.buttonHeight).isActive = true
    }
    
    private func createButton(action: SWAlertAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 14)
        button.layer.cornerRadius = configuration.buttonCornerRadius
        button.clipsToBounds = true
        
        // 根据按钮样式设置颜色
        switch action.style {
        case .confirm:
            button.backgroundColor = ThemeManager.current.mainColor
            button.setTitleColor(.white, for: .normal)
        case .cancel:
            button.backgroundColor = ThemeManager.current.mediumGrayBGColor
            button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        case .destructive:
            button.backgroundColor = ThemeManager.current.errorColor
            button.setTitleColor(.white, for: .normal)
        }
        
        // 添加点击事件
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        button.tag = actions.firstIndex(of: action) ?? 0
        
        return button
    }
    
    // MARK: - 事件处理
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        if index < actions.count {
            let action = actions[index]
            action.handler?()
        }
    }
    
    // MARK: - SWPopupContentView协议实现
    
    public func popupWillShow() {}
    
    public func popupDidShow() {}
    
    public func popupWillDismiss() {}
    
    public func popupDidDismiss() {}
}

// MARK: - 便捷构造方法
public extension SWAlertView {
    
    static func showAlert(
        title: String?,
        message: String?,
        confirmTitle: String = "确定",
        cancelTitle: String? = "取消",
        confirmHandler: (() -> Void)? = nil,
        cancelHandler: (() -> Void)? = nil,
        configuration: SWAlertConfiguration = SWAlertConfiguration()
    ) {
        var popupContainer: SWPopupView?
        var actions: [SWAlertAction] = []
        
        if let cancelTitle = cancelTitle, !cancelTitle.isEmpty {
            actions.append(SWAlertAction(title: cancelTitle, style: .cancel, handler: {
                popupContainer?.dismiss {
                    cancelHandler?()
                }
                
            }))
        }
        actions.append(SWAlertAction(title: confirmTitle, style: .confirm, handler: {
            popupContainer?.dismiss {
                confirmHandler?()
            }
        }))
        
        let alert = SWAlertView(title: title, message: message, actions: actions, configuration: configuration)
        
        popupContainer = SWPopupView(contentView: alert, configuration: defaultPopupConfiguration())
        popupContainer?.show()
    }
    
    /// 显示只有确认按钮的AlertView
    static func showConfirmAlert(
        title: String?,
        message: String?,
        confirmTitle: String = "确定",
        confirmHandler: (() -> Void)? = nil,
        configuration: SWAlertConfiguration = SWAlertConfiguration()
    ) {
        var popupContainer: SWPopupView?
        
        let action = SWAlertAction(title: confirmTitle, style: .confirm, handler: {
            popupContainer?.dismiss {
                confirmHandler?()
            }
        })
        
        let alert = SWAlertView(title: title, message: message, actions: [action], configuration: configuration)
        
        popupContainer = SWPopupView(contentView: alert, configuration: defaultPopupConfiguration())
        popupContainer?.show()
    }
    
    /// 显示自定义视图的AlertView
    static func showCustomAlert(
        title: String?,
        customView: SWAlertCustomView,
        confirmTitle: String = "确定",
        cancelTitle: String? = "取消",
        confirmHandler: (() -> Void)? = nil,
        cancelHandler: (() -> Void)? = nil,
        configuration: SWAlertConfiguration = SWAlertConfiguration()
    ) {
        var popupContainer: SWPopupView?
        var actions: [SWAlertAction] = []

        if let cancelTitle = cancelTitle, !cancelTitle.isEmpty  {
            actions.append(SWAlertAction(title: cancelTitle, style: .cancel, handler: {
                popupContainer?.dismiss {
                    cancelHandler?()
                }
            }))
        }
        actions.append(SWAlertAction(title: confirmTitle, style: .confirm, handler: {
            if customView.shouldClickConfirmButton() == true {
                popupContainer?.dismiss {
                    confirmHandler?()
                }
            }
        }))
        
        let alert = SWAlertView(title: title, customView: customView, actions: actions, configuration: configuration)
        
        popupContainer = SWPopupView(contentView: alert, configuration: defaultPopupConfiguration())
        popupContainer?.show()
    }
    
    static func showDestructiveAlert(
        title: String?,
        message: String?,
        destructiveTitle: String = "确定",
        cancelTitle: String? = "取消",
        destructiveHandler: (() -> Void)? = nil,
        cancelHandler: (() -> Void)? = nil,
        configuration: SWAlertConfiguration = SWAlertConfiguration()
    ) {
        
        var popupContainer: SWPopupView?
        var actions: [SWAlertAction] = []
        
        if let cancelTitle = cancelTitle, !cancelTitle.isEmpty  {
            actions.append(SWAlertAction(title: cancelTitle, style: .cancel, handler: {
                popupContainer?.dismiss {
                    cancelHandler?()
                }
            }))
        }
        
        actions.append(SWAlertAction(title: destructiveTitle, style: .destructive, handler: {
            popupContainer?.dismiss {
                destructiveHandler?()
            }
        }))
        
        let alert = SWAlertView(title: title, message: message, actions: actions, configuration: configuration)
    
        popupContainer = SWPopupView(contentView: alert, configuration: defaultPopupConfiguration())
        popupContainer?.show()
    }
    
    
    static func defaultPopupConfiguration() -> SWPopupConfiguration {
        var popupConfiguration = SWPopupConfiguration(position: .center)
        popupConfiguration.dismissOnMaskTap = false
        popupConfiguration.cornerRadius = CornerRadius.medium.rawValue
        popupConfiguration.springAnimation = true
        return popupConfiguration
    }
}
