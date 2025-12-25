//
//  RegisterViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//

import UIKit
import SnapKit
import SWKit

class RegisterViewController: LoginBaseViewController {
    
    private let viewModel = LoginViewModel()
    
    // UI
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private var usernameField = DefaultInputField()
    private var phoneField = PhoneInputField()
    private var verificationCodeField = DefaultInputField()
    private var passwordField = PasswordInputField()
    private var rePasswordField = PasswordInputField()
    private lazy var nameTitleView = creatTitleView(titleName: "昵称")
    private lazy var phoneTitleView = creatTitleView(titleName: "手机号")
    private lazy var verficationCodeTitleView = creatTitleView(titleName: "验证码")
    private lazy var passwordTitleView = creatTitleView(titleName: "密码")
    private lazy var rePasswordTitleView = creatTitleView(titleName: "密码")
    // 新增元素
    private let passwordTipLabel = UILabel()
    private let rePasswordTipLabel = UILabel()
    
    private let userAgreementView = UserAgreementView()
    
    // 新增：输入验证状态
    private var isUsernameValid = false
    private var isPhoneValid = false
    private var isVerificationCodeValid = false
    private var isPasswordValid = false
    private var isRePasswordValid = false
    
    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("注册", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.init(hex: "#FFE0B9")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var keyboardManager = KeyboardScrollManager(scrollView: scrollView, viewController: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupTapGesture()
        setupInputListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardManager.startObserving()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager.stopObserving()
    }
    
    private func setupUI() {
        titleLabel.text = "注册"
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        usernameField.placeholder = "请输入昵称"
        phoneField.placeholder = "请输入手机号"
        phoneField.onVerifyCodeTapped = { [weak self] in
            guard let phone = self?.phoneField.text else {return}
            self?.sendSmsCode(phone: phone, type: .appRegister)
        }
        verificationCodeField.placeholder = "请输入验证码"
        passwordField.placeholder = "请输入密码"
        rePasswordField.placeholder = "请再次输入密码"
        
        passwordTipLabel.text = "需包含英文大小写和数字，长度6~20位"
        passwordTipLabel.textColor = UIColor.init(hex: "#84888C")
        passwordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        rePasswordTipLabel.text = "前后密码保持一致"
        rePasswordTipLabel.textColor = UIColor.init(hex: "#84888C")
        rePasswordTipLabel.font = UIFont.systemFont(ofSize: 12)
        
        userAgreementView.delegate = self
        
        contentView.addSubview(nameTitleView)
        contentView.addSubview(usernameField)
        contentView.addSubview(phoneTitleView)
        contentView.addSubview(phoneField)
        contentView.addSubview(verficationCodeTitleView)
        contentView.addSubview(verificationCodeField)
        contentView.addSubview(passwordTitleView)
        contentView.addSubview(passwordField)
        contentView.addSubview(passwordTipLabel)
        contentView.addSubview(rePasswordTitleView)
        contentView.addSubview(rePasswordField)
        contentView.addSubview(rePasswordTipLabel)
        contentView.addSubview(userAgreementView)
        contentView.addSubview(registerButton)
        
    }
    
    private func setupConstraints() {
        
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
        
        nameTitleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        usernameField.snp.makeConstraints { make in
            make.top.equalTo(nameTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        phoneTitleView.snp.makeConstraints { make in
            make.top.equalTo(usernameField.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        phoneField.snp.makeConstraints { make in
            make.top.equalTo(phoneTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        verficationCodeTitleView.snp.makeConstraints { make in
            make.top.equalTo(phoneField.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        verificationCodeField.snp.makeConstraints { make in
            make.top.equalTo(verficationCodeTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        
        passwordTitleView.snp.makeConstraints { make in
            make.top.equalTo(verificationCodeField.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        passwordField.snp.makeConstraints { make in
            make.top.equalTo(passwordTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        passwordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(passwordField.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
        }
        
        rePasswordTitleView.snp.makeConstraints { make in
            make.top.equalTo(passwordTipLabel.snp.bottom).offset(25)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(20)
        }
        rePasswordField.snp.makeConstraints { make in
            make.top.equalTo(rePasswordTitleView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        rePasswordTipLabel.snp.makeConstraints { make in
            make.top.equalTo(rePasswordField.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
        }
        
        userAgreementView.snp.makeConstraints { make in
            make.top.equalTo(rePasswordTipLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        registerButton.snp.makeConstraints { make in
            make.top.equalTo(userAgreementView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.keyboardManager.scrollToTop(animated: true)
        }
    }
    
    private func setupInputListeners() {
        usernameField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        phoneField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        verificationCodeField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        rePasswordField.textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func creatTitleView(titleName: String) -> UIView {
        let view = UIView()
        let iv = UIImageView()
        let img = LoginModule.image(named: "remind")
        iv.image = img
        view.addSubview(iv)
        
        let label = UILabel()
        label.text = titleName
        label.textColor = defaultBlackColor
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(label)
        
        iv.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.height.equalTo(6)
        }
        
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iv.snp.trailing).offset(5)
        }
        
        return view
    }
}

// MARK: - textFieldDidChange
extension RegisterViewController {
    @objc private func textFieldDidChange() {
        validateAllInputs()
    }
    
    // 新增：验证所有输入
    private func validateAllInputs() {
        // 验证用户名
        isUsernameValid = !usernameField.text.trimmingCharacters(in: .whitespaces).isEmpty
        
        // 验证手机号
        isPhoneValid = phoneField.validatePhoneNumber()
        
        // 验证验证码
        isVerificationCodeValid = !verificationCodeField.text.trimmingCharacters(in: .whitespaces).isEmpty
        
        // 验证密码
        let password = passwordField.text
        isPasswordValid = validatePassword(password)
        updatePasswordTipLabel(isValid: isPasswordValid)
        
        // 验证确认密码
        let rePassword = rePasswordField.text
        isRePasswordValid = validateRePassword(password, rePassword)
        updateRePasswordTipLabel(isValid: isRePasswordValid)
        
        // 更新注册按钮状态
        updateRegisterButtonState()
    }
    
    // 新增：验证密码格式
    private func validatePassword(_ password: String) -> Bool {
        // 包含英文大小写和数字，长度6~20位
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{6,20}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    // 新增：验证确认密码
    private func validateRePassword(_ password: String, _ rePassword: String) -> Bool {
        return !rePassword.isEmpty && password == rePassword
    }
    
    // 新增：更新密码提示标签
    private func updatePasswordTipLabel(isValid: Bool) {
        if passwordField.text.isEmpty {
            passwordTipLabel.text = "需包含英文大小写和数字，长度6~20位"
            passwordTipLabel.textColor = UIColor.init(hex: "#84888C")
        } else {
            passwordTipLabel.text = isValid ? "密码格式正确" : "需包含英文大小写和数字，长度6~20位"
            passwordTipLabel.textColor = isValid ? UIColor.systemGreen : UIColor.orange
        }
    }
    
    // 新增：更新确认密码提示标签
    private func updateRePasswordTipLabel(isValid: Bool) {
        if rePasswordField.text.isEmpty {
            rePasswordTipLabel.text = "前后密码保持一致"
            rePasswordTipLabel.textColor = UIColor.init(hex: "#84888C")
        } else {
            rePasswordTipLabel.text = isValid ? "密码一致" : "两次输入的密码不一致"
            rePasswordTipLabel.textColor = isValid ? UIColor.systemGreen : UIColor.orange
        }
    }
    
    // 新增：更新注册按钮状态
    private func updateRegisterButtonState() {
        let allInputsValid = isUsernameValid &&
        isPhoneValid &&
        isVerificationCodeValid &&
        isPasswordValid &&
        isRePasswordValid
        
        registerButton.isEnabled = allInputsValid
        registerButton.backgroundColor = allInputsValid ?
        UIColor.orange : // 可用时的颜色
        UIColor.init(hex: "#FFE0B9") // 禁用时的颜色
    }
    
    // 修改现有的注册按钮点击方法
    @objc private func registerButtonTapped() {
        guard userAgreementView.isSelected else {
            view.sw_showWarningToast("请阅读并同意用户协议")
            return
        }
        
        // 执行注册逻辑
        performRegistration()
    }
    
    private func performRegistration() {
        let username = usernameField.text.trimmingCharacters(in: .whitespaces)
        let phone = phoneField.text
        let verificationCode = verificationCodeField.text
        let password = passwordField.text
        
        // 这里添加实际的注册API调用
        print("开始注册: 用户名=\(username), 手机号=\(phone), 验证码=\(verificationCode)")
        
        viewModel.register(nickname: username, phone: phone, smsCode: verificationCode, password: password) { [weak self] result in
            self?.handleRegistrationResult(result)
        }
        
    }
    
    private func handleRegistrationResult(_ result: LoginViewModel.CommonResult) {
        
        registerButton.isEnabled = true
        
        switch result {
        case .success:
            self.view.sw_showSuccessToast("注册成功")
            print("🎉 注册成功")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // 注册成功后的操作，比如跳转到登录页面
                self.navigationController?.popViewController(animated: true)
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
    
    private func showUserAgreement() {
        // 跳转到用户服务协议页面
        let webVC = WebViewController(
            fileName: "UserAgreement",
            title: "用户服务协议"
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showPrivacyPolicy() {
        // 跳转到隐私政策页面
        let webVC = WebViewController(
            fileName: "PrivacyPolicy",
            title: "隐私协议"
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
}

extension RegisterViewController: UserAgreementViewDelegate {
    
    func userAgreementViewDidTapCheckbox(_ view: UserAgreementView, isSelected: Bool) {
        
    }
    
    func userAgreementViewDidTapAgreement(_ view: UserAgreementView, type: AgreementType) {
        switch type {
        case .privacy:
            self.showPrivacyPolicy()
        case .service:
            self.showUserAgreement()
        }
    }
    
    
}
