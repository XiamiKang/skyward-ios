//
//  PhoneInputField.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit

@MainActor
class PhoneInputField: BaseInputField {
    
    // MARK: - UI Components
    private let verifyCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("获取验证码", for: .normal)
        button.setTitleColor(UIColor.init(hex: "#C4C7CA"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.isEnabled = false // 默认禁用，直到输入有效手机号
        button.alpha = 0.6 // 禁用时降低透明度
        return button
    }()
    
    // MARK: - Properties
    var onVerifyCodeTapped: (() -> Void)?
    
    // 使用 CADisplayLink 替代 Timer
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var countdownSeconds = 60
    private var isCountingDown = false
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurePhoneSettings()
        setupVerifyButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configurePhoneSettings()
        setupVerifyButton()
    }
    
    
    // MARK: - Setup
    private func configurePhoneSettings() {
        textField.keyboardType = .numberPad
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        placeholder = "请输入手机号"
        setValidationRule(.phone)
        // 设置正常状态的边框颜色
        normalBorderColor = UIColor(hex: "#E5E5E5")
        
        // 设置合适的高度
        containerHeight = 50  // 调整为合适的高度
    }
    
    private func setupVerifyButton() {
        containerView.addSubview(verifyCodeButton)
        verifyCodeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 移除 textField 原有的trailing约束
        for constraint in containerView.constraints {
            if (constraint.firstItem as? UITextField == textField || constraint.secondItem as? UITextField == textField) &&
                (constraint.firstAttribute == .trailing || constraint.secondAttribute == .trailing) {
                constraint.isActive = false
                break
            }
        }
        
        // 移除textField已有的trailing约束（更彻底的方法）
        textField.removeConstraints(textField.constraints)
        
        NSLayoutConstraint.activate([
            verifyCodeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            verifyCodeButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            verifyCodeButton.widthAnchor.constraint(equalToConstant: 80),
            verifyCodeButton.heightAnchor.constraint(equalToConstant: 32),
            
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: verifyCodeButton.leadingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        verifyCodeButton.addTarget(self, action: #selector(verifyCodeButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    func configure(placeholder: String = "请输入手机号") {
        self.placeholder = placeholder
    }
    
    func startCountdown() {
        guard !isCountingDown else { return }
        
        isCountingDown = true
        verifyCodeButton.isEnabled = false
        verifyCodeButton.alpha = 0.6
        verifyCodeButton.setTitle("60s", for: .normal)
        countdownSeconds = 60
        
        // 设置显示链接
        lastUpdateTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateCountdown))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopCountdown() {
        displayLink?.invalidate()
        displayLink = nil
        isCountingDown = false
        countdownSeconds = 60
        
        verifyCodeButton.isEnabled = true
        verifyCodeButton.alpha = 1.0
        verifyCodeButton.setTitle("获取验证码", for: .normal)
        
        // 根据当前手机号验证状态更新按钮状态
        updateVerifyButtonState()
    }
    
    // MARK: - Private Methods
    @objc private func updateCountdown() {
        let currentTime = CACurrentMediaTime()
        
        // 每秒更新一次
        if currentTime - lastUpdateTime >= 1.0 {
            countdownSeconds -= 1
            lastUpdateTime = currentTime
            
            if countdownSeconds > 0 {
                // 使用 UIView 的无动画更新避免闪烁
                UIView.performWithoutAnimation {
                    verifyCodeButton.setTitle("\(countdownSeconds)s", for: .normal)
                    verifyCodeButton.layoutIfNeeded()
                }
            } else {
                stopCountdown()
            }
        }
    }
    
    private func updateVerifyButtonState() {
        let isValidPhone = validate()
        verifyCodeButton.isEnabled = isValidPhone && !isCountingDown
        verifyCodeButton.setTitleColor(isValidPhone ? defaultOrangeColor : UIColor.init(hex: "#C4C7CA"), for: .normal)
    }
    
    // MARK: - Actions
    @objc private func verifyCodeButtonTapped() {
        guard validate() else {
            showError("请输入正确的手机号")
            return
        }
        
        // 隐藏可能的错误状态
        hideError()
        
        onVerifyCodeTapped?()
        startCountdown()
    }
    
    // MARK: - Override Methods
    override func textFieldDidChange() {
        super.textFieldDidChange()
        
        // 实时更新验证码按钮状态
        updateVerifyButtonState()
        
        // 如果正在倒计时，不处理其他逻辑
        guard !isCountingDown else { return }
        
        // 手机号格式实时验证（可选）
        if !text.isEmpty && !validate() {
            // 可以在这里添加实时验证提示
        } else {
            hideError()
        }
    }
    
    override func textFieldDidEndEditing(_ textField: UITextField) {
        super.textFieldDidEndEditing(textField)
        
        // 结束编辑时验证手机号格式
        if !text.isEmpty && !validate() {
            showError("请输入正确的手机号")
        }
    }
    
    // 提供手动验证方法
    func validatePhoneNumber() -> Bool {
        if text.isEmpty {
            showError("请输入手机号")
            return false
        }
        
        if !validate() {
            showError("请输入正确的手机号")
            return false
        }
        
        hideError()
        return true
    }
    
    // 重置输入框状态
    func reset() {
        textField.text = ""
        stopCountdown()
        hideError()
        updateVerifyButtonState()
    }
}
