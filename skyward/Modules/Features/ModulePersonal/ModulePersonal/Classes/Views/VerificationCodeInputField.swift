//
//  VerificationCodeInputField.swift
//  Pods
//
//  Created by TXTS on 2026/3/25.
//

import UIKit
import SWKit

// MARK: - 验证码输入框组件
class VerificationCodeInputField: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(hex: "#E5E5E5").cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .black
        textField.tintColor = UIColor(hex: "#FE6A00")
        textField.keyboardType = .numberPad
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("获取验证码", for: .normal)
        button.setTitleColor(UIColor(hex: "#C4C7CA"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 4
        button.isEnabled = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(hex: "#FE6A00")
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    var onGetVerificationCode: (() -> Void)? // 获取验证码回调
    var onVerificationCodeChanged: ((String) -> Void)? // 验证码变化回调
    
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var countdownSeconds = 60
    private var isCountingDown = false
    
    // 当前输入的手机号（由外部设置）
    var phoneNumber: String = "" {
        didSet {
            updateVerifyButtonState()
        }
    }
    
    // 当前输入的验证码
    var verificationCode: String {
        return textField.text ?? ""
    }
    
    // 是否处于验证码输入模式（已获取验证码）
    private(set) var isVerificationMode = false
    
    // MARK: - Initialization
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
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(textField)
        containerView.addSubview(verifyButton)
        addSubview(errorLabel)
        
        NSLayoutConstraint.activate([
            // 容器视图约束
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 48),
            
            // 验证码按钮约束
            verifyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            verifyButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            verifyButton.widthAnchor.constraint(equalToConstant: 88),
            verifyButton.heightAnchor.constraint(equalToConstant: 32),
            
            // 文本输入框约束
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: verifyButton.leadingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 错误标签约束
            errorLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupActions() {
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.addTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        verifyButton.addTarget(self, action: #selector(verifyButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    func setPlaceholder(_ placeholder: String) {
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(hex: "#C4C7CA")]
        )
    }
    
    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        containerView.layer.borderColor = UIColor(hex: "#FE6A00").cgColor
        containerView.layer.borderWidth = 1
    }
    
    func hideError() {
        errorLabel.isHidden = true
        // 如果有错误状态，恢复边框颜色时需要考虑当前是否处于编辑状态
        updateBorderColor(isEditing: textField.isFirstResponder)
    }
    
    func startCountdown() {
        guard !isCountingDown else { return }
        
        isCountingDown = true
        verifyButton.isEnabled = false
        verifyButton.setTitle("60s", for: .normal)
        verifyButton.setTitleColor(UIColor(hex: "#C4C7CA"), for: .normal)
        countdownSeconds = 60
        
        lastUpdateTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateCountdown))
        displayLink?.add(to: .main, forMode: .common)
        
        // 切换到验证码输入模式
        isVerificationMode = true
        textField.text = ""
        setPlaceholder("请输入验证码")
    }
    
    func reset() {
        stopCountdown()
        isVerificationMode = false
        textField.text = ""
        setPlaceholder("请输入验证码")
        hideError()
        updateVerifyButtonState()
    }
    
    func clearVerificationCode() {
        textField.text = ""
        onVerificationCodeChanged?("")
    }
    
    // MARK: - Private Methods
    private func stopCountdown() {
        displayLink?.invalidate()
        displayLink = nil
        isCountingDown = false
        countdownSeconds = 60
        
        verifyButton.isEnabled = true
        verifyButton.setTitle("获取验证码", for: .normal)
        updateVerifyButtonState()
    }
    
    @objc private func updateCountdown() {
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastUpdateTime >= 1.0 {
            countdownSeconds -= 1
            lastUpdateTime = currentTime
            
            if countdownSeconds > 0 {
                UIView.performWithoutAnimation {
                    verifyButton.setTitle("\(countdownSeconds)s", for: .normal)
                    verifyButton.layoutIfNeeded()
                }
            } else {
                stopCountdown()
            }
        }
    }
    
    private func updateVerifyButtonState() {
        // 手机号有效且不在倒计时中时，按钮才可点击
        let isValidPhone = isValidPhoneNumber(phoneNumber)
        verifyButton.isEnabled = isValidPhone && !isCountingDown
        verifyButton.setTitleColor(isValidPhone && !isCountingDown ? UIColor(hex: "#FE6A00") : UIColor(hex: "#C4C7CA"), for: .normal)
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^1[0-9]{10}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }
    
    private func updateBorderColor(isEditing: Bool) {
        // 如果当前有错误状态，优先显示错误边框颜色
        if !errorLabel.isHidden {
            containerView.layer.borderColor = UIColor(hex: "#FE6A00").cgColor
            containerView.layer.borderWidth = 1
        } else if isEditing {
            // 编辑状态时边框变为黑色
            containerView.layer.borderColor = UIColor.black.cgColor
            containerView.layer.borderWidth = 1
        } else {
            // 默认状态
            containerView.layer.borderColor = UIColor(hex: "#E5E5E5").cgColor
            containerView.layer.borderWidth = 1
        }
    }
    
    // MARK: - Actions
    @objc private func textFieldDidBeginEditing() {
        updateBorderColor(isEditing: true)
    }
    
    @objc private func textFieldDidEndEditing() {
        updateBorderColor(isEditing: false)
    }
    
    @objc private func textFieldDidChange() {
        let code = textField.text ?? ""
        onVerificationCodeChanged?(code)
        
        // 验证码变化时自动隐藏错误
        if !errorLabel.isHidden {
            hideError()
        }
    }
    
    @objc private func verifyButtonTapped() {
        // 验证手机号
        guard isValidPhoneNumber(phoneNumber) else {
            showError("请输入正确的手机号")
            return
        }
        
        hideError()
        onGetVerificationCode?()
    }
    
    // MARK: - First Responder
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
}
