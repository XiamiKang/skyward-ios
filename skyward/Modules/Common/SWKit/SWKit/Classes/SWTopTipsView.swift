//
//  SWTopTipsView.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/24.
//

import UIKit
import SWTheme

public final class SWTopTipsView: UIView {
    
    // UI组件
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: SWKitModule.image(named: "tips_icon"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.current.titleColor
        label.font = .pingFangFontRegular(ofSize: 12)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    
    // MARK: - 初始化
    
    /// 初始化空白视图
    /// - Parameters:
    ///   - title: 提示文本
    ///   - buttonTitle: 按钮标题（可选，为nil时隐藏按钮）
    ///   - buttonAction: 按钮点击事件（可选）
    ///   - configuration: 配置（可选）
    public init(title: String) {
        super.init(frame: .zero)
        setupUI()
        
        titleLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        backgroundColor = UIColor(str: "#FFEBEB")
        addSubview(iconImageView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: swAdaptedValue(12)),
            iconImageView.heightAnchor.constraint(equalToConstant: swAdaptedValue(12)),
            iconImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: Layout.hMargin),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: swAdaptedValue(17)),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: swAdaptedValue(11)),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -swAdaptedValue(11)),
            titleLabel.leftAnchor.constraint(equalTo: iconImageView.rightAnchor, constant: 8)
        ])
    }
}
