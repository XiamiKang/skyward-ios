//
//  ForgotPasswordViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//

import UIKit
import SnapKit
import SWKit

public class ForgotPasswordViewController: LoginBaseViewController {
    
    private let viewModel = LoginViewModel()
    public var isLoginVC: Bool = true
    
    // 新增：添加 ScrollView 作为容器
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let phoneField = PhoneInputField()
    private let verifyCodeField = DefaultInputField()
    private let newPasswordField = PasswordInputField()
    private let confirmPasswordField = PasswordInputField()
    
    // 新增元素
    private let passwordTipLabel = UILabel()
    private let confirmPasswordTipLabel = UILabel() // 新增：确认密码提示标签
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("确认", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.init(hex: "#FFE0B9")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        return button
    }()
    
    // 新增：键盘管理器
    private lazy var keyboardManager = KeyboardScrollManager(scrollView: scrollView, viewController: self)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupInputListeners() // 新增
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardManager.startObserving()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager.stopObserving()
    }
    
    private func setupUI() {
        if isLoginVC {
            titleLabel.text = "忘记密码"
        }else {
            titleLabel.text = "修改密码"
        }
        
        // 先添加 scrollView 和 contentView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 配置输入框
        phoneField.configure(placeholder: "请输入手机号")
        verifyCodeField.configure(placeholder: "请输入验证码", height: 70)
        newPasswordField.configure(placeholder: "请输入新密码", height: 70)
        confirmPasswordField.configure(placeholder: "请再次输入新密码", height: 70)
        
        passwordTipLabel.text = "需包含英文大小写和数字，长度6~20位"
        passwordTipLabel.textColor = UIColor.init(hex: "#84888C")
        passwordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        // 新增：确认密码提示标签
        confirmPasswordTipLabel.text = "前后密码保持一致"
        confirmPasswordTipLabel.textColor = UIColor.init(hex: "#84888C")
        confirmPasswordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        phoneField.onVerifyCodeTapped = { [weak self] in
            guard let phone = self?.phoneField.text else {return}
            self?.sendSmsCode(phone: phone, type: .forgetPassword)
        }
        
        // 将所有子视图添加到 contentView
        contentView.addSubview(phoneField)
        contentView.addSubview(verifyCodeField)
        contentView.addSubview(newPasswordField)
        contentView.addSubview(passwordTipLabel)
        contentView.addSubview(confirmPasswordField)
        contentView.addSubview(confirmPasswordTipLabel) // 新增
        contentView.addSubview(confirmButton)
        
        // 新增：添加点击手势回收键盘
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    private func setupConstraints() {
        // ScrollView 约束
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // ContentView 约束
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
            make.height.greaterThanOrEqualTo(scrollView).priority(.low)
        }
        
        // 修改所有约束，相对于 contentView
        phoneField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        verifyCodeField.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        newPasswordField.snp.makeConstraints { make in
            make.top.equalTo(verifyCodeField.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        passwordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(newPasswordField.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        
        confirmPasswordField.snp.makeConstraints { make in
            make.top.equalTo(passwordTipLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        confirmPasswordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordField.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(confirmPasswordTipLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-30) // 重要：设置底部约束
        }
    }
    
    // 新增：设置输入监听
    private func setupInputListeners() {
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        verifyCodeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        newPasswordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        confirmPasswordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange() {
        validateAllInputs()
    }
    
    // 新增：验证所有输入
    private func validateAllInputs() {
        // 验证手机号
        let isPhoneValid = phoneField.validatePhoneNumber()
        
        // 验证验证码
        let isVerificationCodeValid = !verifyCodeField.text.trimmingCharacters(in: .whitespaces).isEmpty
        
        // 验证新密码
        let newPassword = newPasswordField.text
        let isNewPasswordValid = validatePassword(newPassword)
        updatePasswordTipLabel(isValid: isNewPasswordValid)
        
        // 验证确认密码
        let confirmPassword = confirmPasswordField.text
        let isConfirmPasswordValid = validateConfirmPassword(newPassword, confirmPassword)
        updateConfirmPasswordTipLabel(isValid: isConfirmPasswordValid)
        
        // 更新确认按钮状态
        let allInputsValid = isPhoneValid && isVerificationCodeValid && isNewPasswordValid && isConfirmPasswordValid
        updateConfirmButtonState(isEnabled: allInputsValid)
    }
    
    // 新增：验证密码格式
    private func validatePassword(_ password: String) -> Bool {
        // 包含英文大小写和数字，长度6~20位
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{6,20}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    // 新增：验证确认密码
    private func validateConfirmPassword(_ password: String, _ confirmPassword: String) -> Bool {
        return !confirmPassword.isEmpty && password == confirmPassword
    }
    
    // 新增：更新密码提示标签
    private func updatePasswordTipLabel(isValid: Bool) {
        if newPasswordField.text.isEmpty {
            passwordTipLabel.text = "需包含英文大小写和数字，长度6~20位"
            passwordTipLabel.textColor = UIColor.init(hex: "#84888C")
        } else {
            passwordTipLabel.text = isValid ? "密码格式正确" : "需包含英文大小写和数字，长度6~20位"
            passwordTipLabel.textColor = isValid ? UIColor.systemGreen : UIColor.orange
        }
    }
    
    // 新增：更新确认密码提示标签
    private func updateConfirmPasswordTipLabel(isValid: Bool) {
        if confirmPasswordField.text.isEmpty {
            confirmPasswordTipLabel.text = "前后密码保持一致"
            confirmPasswordTipLabel.textColor = UIColor.init(hex: "#84888C")
        } else {
            confirmPasswordTipLabel.text = isValid ? "密码一致" : "两次输入的密码不一致"
            confirmPasswordTipLabel.textColor = isValid ? UIColor.systemGreen : UIColor.orange
        }
    }
    
    // 新增：更新确认按钮状态
    private func updateConfirmButtonState(isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
        confirmButton.backgroundColor = isEnabled ?
            UIColor.orange :
            UIColor.init(hex: "#FFE0B9")
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func submitTapped() {
        guard validateAllFields() else {
            return
        }
        
        // 执行重置密码逻辑
        performPasswordReset()
    }
    
    // 新增：最终验证所有字段
    private func validateAllFields() -> Bool {
        let phone = phoneField.text
        let verificationCode = verifyCodeField.text
        let newPassword = newPasswordField.text
        let confirmPassword = confirmPasswordField.text
        
        // 验证手机号
        if !phoneField.validatePhoneNumber() {
            view.sw_showWarningToast("请输入正确的手机号")
            return false
        }
        
        // 验证验证码
        if verificationCode.isEmpty {
            view.sw_showWarningToast("请输入验证码")
            return false
        }
        
        // 验证密码
        if !validatePassword(newPassword) {
            view.sw_showWarningToast("密码需包含英文大小写和数字，长度6~20位")
            return false
        }
        
        // 验证确认密码
        if newPassword != confirmPassword {
            view.sw_showWarningToast("两次输入的密码不一致")
            return false
        }
        
        return true
    }
    
    private func performPasswordReset() {
        let phone = phoneField.text
        let verificationCode = verifyCodeField.text
        let newPassword = newPasswordField.text
        
        // 这里添加实际的重置密码API调用
        print("开始重置密码: 手机号=\(phone), 验证码=\(verificationCode)")
        view.sw_showSuccessToast("重置密码请求已发送")
        
        viewModel.forgotPassword(phone: phone, smsCode: verificationCode, newPassword: newPassword) { [weak self] result in
            self?.handlePasswordResetResult(result)
        }
    }
    
    private func handlePasswordResetResult(_ result: LoginViewModel.CommonResult) {
        
        confirmButton.isEnabled = true
        
        switch result {
        case .success:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.view.sw_showSuccessToast("重置密码成功")
                print("🎉 重置密码成功")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // 重置密码成功后的操作，比如跳转到登录页面
                    self.navigationController?.popViewController(animated: true)
                }
            }
        case .failure(let error):
            handleError(error)
        }
    }
    
    // 发送验证码
    private func sendSmsCode(phone: String, type: SmsCodeType) {
        viewModel.sendSmsCode(phone: phone, type: type) { [weak self] result in
            switch result {
            case .success:
                self?.view.sw_showSuccessToast("验证码发送成功")
            case .failure(let error):
                self?.view.sw_showWarningToast(error.errorMessage)
            }
        }
    }
    
    private func handleError(_ error: LoginViewModel.LoginError) {
        switch error {
        case .networkError(let message):
            self.view.sw_showWarningToast(message)
        case .parseError(let message):
            self.view.sw_showWarningToast(message)
        case .businessError(let message, let code):
            print("业务错误码: \(code)")
            self.view.sw_showWarningToast(message)
        case .tokenDataMissing:
            self.view.sw_showWarningToast("操作失败")
        }
        
        print("❌ 操作失败: \(error)")
    }
}
