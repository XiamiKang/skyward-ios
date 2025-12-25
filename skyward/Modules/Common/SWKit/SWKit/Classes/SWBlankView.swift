//
//  SWBlankView.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/28.
//

import UIKit
import TXKit
import SWTheme

// MARK: - 空白视图配置
public struct SWBlankViewConfiguration {
    var iconSize: CGSize = CGSize(width: 72, height: 72)
    var titleFont: UIFont = UIFont.pingFangFontRegular(ofSize: 14)
    var titleColor: UIColor = UIColor(str: "#A0A3A7")
    var buttonFont: UIFont = UIFont.pingFangFontRegular(ofSize: 14)
    var buttonTitleColor: UIColor = .white
    var buttonBackgroundColor: UIColor = ThemeManager.current.mainColor
    var buttonCornerRadius: CGFloat = CornerRadius.medium.rawValue
    var buttonHeight: CGFloat = swAdaptedValue(36)
    var buttonWidth: CGFloat? = swAdaptedValue(88)
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: Layout.hMargin, bottom: 0, right: Layout.hMargin)
    var iconTitleSpacing: CGFloat = 16
    var titleButtonSpacing: CGFloat = 24
    
    public init() {}
}

// MARK: - 空白视图类
public final class SWBlankView: UIView {
    
    // MARK: - 属性
    private let configuration: SWBlankViewConfiguration
    private let title: String
    private let icon: UIImage?
    private let buttonTitle: String?
    private let buttonAction: (() -> Void)?
    
    // UI组件
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.textAlignment = .center
        button.clipsToBounds = true
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()
    
    // MARK: - 初始化
    
    /// 初始化空白视图
    /// - Parameters:
    ///   - title: 提示文本
    ///   - buttonTitle: 按钮标题（可选，为nil时隐藏按钮）
    ///   - buttonAction: 按钮点击事件（可选）
    ///   - configuration: 配置（可选）
    public init(
        title: String,
        icon: UIImage? = SWKitModule.image(named: "blank_icon"),
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil,
        configuration: SWBlankViewConfiguration = SWBlankViewConfiguration()
    ) {
        self.title = title
        self.icon = icon
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.configuration = configuration
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        backgroundColor = .clear
        
        // 添加栈视图
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 配置栈视图约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: configuration.contentInsets.top),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: configuration.contentInsets.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -configuration.contentInsets.right),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -configuration.contentInsets.bottom)
        ])
        
        // 添加图标
        iconImageView.image = icon
        stackView.addArrangedSubview(iconImageView)
        
        // 设置图标大小
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: configuration.iconSize.width),
            iconImageView.heightAnchor.constraint(equalToConstant: configuration.iconSize.height)
        ])
        
        // 添加标题
        titleLabel.text = title
        titleLabel.font = configuration.titleFont
        titleLabel.textColor = configuration.titleColor
        stackView.addArrangedSubview(titleLabel)
        
        // 设置图标和标题之间的间距
        if iconImageView.superview != nil && titleLabel.superview != nil {
            stackView.setCustomSpacing(configuration.iconTitleSpacing, after: iconImageView)
        }
        
        // 添加按钮
        if let buttonTitle = buttonTitle {
            actionButton.setTitle(buttonTitle, for: .normal)
            actionButton.titleLabel?.font = configuration.buttonFont
            actionButton.setTitleColor(configuration.buttonTitleColor, for: .normal)
            actionButton.backgroundColor = configuration.buttonBackgroundColor
            actionButton.layer.cornerRadius = configuration.buttonCornerRadius
            
            // 添加点击事件
            actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            
            stackView.addArrangedSubview(actionButton)
            
            // 设置按钮大小
            NSLayoutConstraint.activate([
                actionButton.heightAnchor.constraint(equalToConstant: configuration.buttonHeight)
            ])
            
            if let buttonWidth = configuration.buttonWidth {
                actionButton.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
            }
            
            // 设置标题和按钮之间的间距
            if titleLabel.superview != nil && actionButton.superview != nil {
                stackView.setCustomSpacing(configuration.titleButtonSpacing, after: titleLabel)
            }
        }
    }
    
    // MARK: - 事件处理
    @objc private func buttonTapped() {
        buttonAction?()
    }
}

// MARK: - 便捷构造方法
//public extension SWBlankView {
//    static func createDefaultBlankView(
//        title: String,
//        buttonTitle: String? = "立即登录",
//        buttonAction: (() -> Void)? = nil
//    ) -> SWBlankView {
//        var configuration = SWBlankViewConfiguration()
//        
//        configuration.icon = UIImage(systemName: "doc.text")
//        
//        return SWBlankView(
//            title: title,
//            buttonTitle: buttonTitle,
//            buttonAction: buttonAction,
//            configuration: configuration
//        )
//    }
//    
//    static func createNoDataBlankView(
//        title: String = "暂无数据",
//        buttonTitle: String? = nil,
//        buttonAction: (() -> Void)? = nil
//    ) -> SWBlankView {
//        var configuration = SWBlankViewConfiguration()
//     
//        configuration.icon = UIImage(systemName: "doc.text")
//        
//        return SWBlankView(
//            title: title,
//            buttonTitle: buttonTitle,
//            buttonAction: buttonAction,
//            configuration: configuration
//        )
//    }
//    
//    static func createNoLoginBlankView(
//        title: String = "暂无消息，请登录查看",
//        buttonTitle: String = "立即登录",
//        buttonAction: (() -> Void)? = nil
//    ) -> SWBlankView {
//        var configuration = SWBlankViewConfiguration()
//        
//        configuration.icon = UIImage(systemName: "doc.text")
//        
//        return SWBlankView(
//            title: title,
//            buttonTitle: buttonTitle,
//            buttonAction: buttonAction,
//            configuration: configuration
//        )
//    }
//}
