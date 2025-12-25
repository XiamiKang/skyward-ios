//
//  SWNavigationBar.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/2.
//

import UIKit
import SWTheme

public class SWNavigationBar: UIView {
    
    // MARK: - 懒加载 UI 元素
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.current.titleColor
        label.font = UIFont.pingFangFontMedium(ofSize: 18)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var leftStackView: UIStackView = {
        makeButtonStackView()
    }()
    
    private lazy var rightStackView: UIStackView = {
        makeButtonStackView()
    }()
    
    private lazy var centerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - 回调
    
    var onLeftButtonTapped: (() -> Void)?
    var onRightButtonsTapped: ((Int) -> Void)?
    var onRightTitleButtonTapped: (() -> Void)?

    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func makeButtonStackView() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        
        
        // 添加子视图层级
        addSubview(leftStackView)
        addSubview(centerContainer)
        addSubview(rightStackView)
        
        centerContainer.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            // 左侧区域：紧贴左边，宽度由内容决定
            leftStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            leftStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            leftStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            
            // 右侧区域：紧贴右边，宽度由内容决定
            rightStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rightStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 8),
            rightStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            
            // 中间容器：夹在左右之间，可伸缩
            centerContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leftStackView.trailingAnchor, constant: 8),
            centerContainer.trailingAnchor.constraint(lessThanOrEqualTo: rightStackView.leadingAnchor, constant: -8),
            centerContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // 标题填满中间容器
            titleLabel.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: centerContainer.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: centerContainer.bottomAnchor),
            
            // 高度兜底
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        // 关键：防止标题挤压按钮
        leftStackView.setContentHuggingPriority(.required, for: .horizontal)
        rightStackView.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    // MARK: - Public API
    
    public func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    public func setLeftBackButton(action: @escaping () -> Void) {
        setLeftButton(image: SWKitModule.image(named: "nav_arrow"), action: action)
    }
    
    public func setLeftButton(image: UIImage?, action: @escaping () -> Void) {
        onLeftButtonTapped = action
        configureStackView(leftStackView, images: image != nil ? [image] : [], isLeft: true)
    }
    
    public func setRightTitleButton(title: String, action: @escaping () -> Void) {
        onRightTitleButtonTapped = action
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.addTarget(self, action: #selector(handleRightTitleTap), for: .touchUpInside)
        rightStackView.addArrangedSubview(button)
    }
    
    public func setRightButtons(images: [UIImage?], action: @escaping (Int) -> Void) {
        onRightButtonsTapped = action
        configureStackView(rightStackView, images: images, isLeft: false)
    }
    
    private func configureStackView(_ stack: UIStackView, images: [UIImage?], isLeft: Bool) {
        // 清空
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, image) in images.enumerated() {
            let button = UIButton(type: .custom)
            button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            button.addTarget(self, action: isLeft ? #selector(handleLeftTap) : #selector(handleRightTap(_:)), for: .touchUpInside)
            if !isLeft {
                button.tag = index + 1000
            }
            stack.addArrangedSubview(button)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleLeftTap() {
        onLeftButtonTapped?()
    }
    
    @objc private func handleRightTap(_ sender: UIButton) {
        let index = sender.tag - 1000
        onRightButtonsTapped?(index)
    }
    
    @objc private func handleRightTitleTap() {
        onRightTitleButtonTapped?()
    }
}
