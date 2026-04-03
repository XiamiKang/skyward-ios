//
//  PasswordInputField.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit

class PasswordInputField: BaseInputField {
    
    // MARK: - UI Components
    private let toggleButton: UIButton = {
        let button = UIButton(type: .custom)
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
            button.setImage(UIImage(systemName: "eye"), for: .selected)
            button.tintColor = .gray
        } else {
            // iOS 13 以下的备用方案
            // 可以使用自定义图片或者表情符号
            button.setTitle("👁️", for: .normal)
            button.setTitle("🔒", for: .selected)
        }
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("忘记密码?", for: .normal)
        button.setTitleColor(UIColor.init(hex: "#84888C"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.isHidden = true // 默认隐藏
        return button
    }()
    
    // MARK: - Properties
    var onForgotPasswordTapped: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurePasswordSettings()
        setupButtons()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configurePasswordSettings()
        setupButtons()
    }
    
    // MARK: - Setup
    private func configurePasswordSettings() {
        textField.isSecureTextEntry = true
        placeholder = "请输入密码"
        setValidationRule(.password)
        
        containerHeight = 50
    }
    
    private func setupButtons() {
        // 添加切换按钮（在 containerView 内）
        containerView.addSubview(toggleButton)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加忘记密码按钮（在 containerView 外，下方右侧）
        addSubview(forgotPasswordButton)
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 切换按钮在 containerView 内右上角
            toggleButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            toggleButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            toggleButton.widthAnchor.constraint(equalToConstant: 24),
            toggleButton.heightAnchor.constraint(equalToConstant: 24),
            
            // 忘记密码按钮在 containerView 外右下角
            forgotPasswordButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            forgotPasswordButton.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 6),
            forgotPasswordButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // 调整文本字段的约束
        textField.trailingAnchor.constraint(equalTo: toggleButton.leadingAnchor, constant: -8).isActive = true
        
        // 添加按钮事件
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    func configure(placeholder: String = "请输入密码", showForgotPassword: Bool = false) {
        self.placeholder = placeholder
        setForgotPasswordVisible(showForgotPassword)
    }
    
    func setForgotPasswordVisible(_ visible: Bool) {
        forgotPasswordButton.isHidden = !visible
    }
    
    // MARK: - Actions
    @objc private func toggleButtonTapped() {
        toggleButton.isSelected.toggle()
        textField.isSecureTextEntry = !toggleButton.isSelected
    }
    
    @objc private func forgotPasswordButtonTapped() {
        print("忘记密码点击")
        onForgotPasswordTapped?()
    }
    
    // 重写 hitTest 方法确保按钮可以点击
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 1. 先检查是否点击了切换按钮
        let toggleButtonPoint = convert(point, to: toggleButton)
        if toggleButton.bounds.contains(toggleButtonPoint) && toggleButton.isUserInteractionEnabled {
            return toggleButton
        }
        
        // 2. 再检查是否点击了忘记密码按钮
        let forgotButtonPoint = convert(point, to: forgotPasswordButton)
        if forgotPasswordButton.bounds.contains(forgotButtonPoint) &&
            forgotPasswordButton.isUserInteractionEnabled &&
            !forgotPasswordButton.isHidden {
            return forgotPasswordButton
        }
        
        // 3. 最后检查是否点击了文本输入区域
        let textFieldPoint = convert(point, to: textField)
        if textField.bounds.contains(textFieldPoint) {
            return self // 返回自身，让手势处理文本输入
        }
        
        // 4. 其他区域不处理
        return nil
    }
    
}
