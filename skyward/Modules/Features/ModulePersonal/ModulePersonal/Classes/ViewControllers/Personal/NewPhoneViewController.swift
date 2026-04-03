//
//  ChangePhoneViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/3/25.
//

import UIKit
import SWKit
import ModuleLogin
import SWTheme

class NewPhoneViewController: PersonalBaseViewController {
    
    var userInfo: UserInfoData?
    private let loginViewModel = LoginViewModel()
    private let personalViewModel = PersonalViewModel()
    
    private let oldPhoneTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "请输入新手机号码"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private lazy var oldPhoneContent: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "点击下方按钮获取验证码以完成验证。"
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    // 使用新的验证码输入框
    private var phoneField = PhoneInputField()
    private var verificationCodeField = DefaultInputField()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("确认", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(str: "#FFE0B9")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraint()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "修改手机号"
        
        phoneField.configure(placeholder: "请输入手机号", height: 50)
        phoneField.onVerifyCodeTapped = { [weak self] in
            guard let phone = self?.phoneField.text else {return}
            self?.sendSmsCode(phone: phone)
        }
        phoneField.delegate = self
        phoneField.translatesAutoresizingMaskIntoConstraints = false
        
        // 密码输入框 - 现在包含忘记密码按钮
        verificationCodeField.configure(placeholder: "请输入验证码", height: 50)
        verificationCodeField.delegate = self
        verificationCodeField.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(oldPhoneTitle)
        view.addSubview(oldPhoneContent)
        view.addSubview(phoneField)
        view.addSubview(verificationCodeField)
        view.addSubview(confirmButton)
    }
    
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            
            oldPhoneTitle.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 24),
            oldPhoneTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            oldPhoneContent.topAnchor.constraint(equalTo: oldPhoneTitle.bottomAnchor, constant: 5),
            oldPhoneContent.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            oldPhoneContent.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            phoneField.topAnchor.constraint(equalTo: oldPhoneContent.bottomAnchor, constant: 20),
            phoneField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            phoneField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            phoneField.heightAnchor.constraint(equalToConstant: 72), // 48(输入框) + 24(错误提示)
            
            verificationCodeField.topAnchor.constraint(equalTo: phoneField.bottomAnchor, constant: 20),
            verificationCodeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            verificationCodeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            verificationCodeField.heightAnchor.constraint(equalToConstant: 72), // 48(输入框) + 24(错误提示)
            
            confirmButton.topAnchor.constraint(equalTo: verificationCodeField.bottomAnchor, constant: 20),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    // 请求验证码
    private func sendSmsCode(phone: String) {
        // TODO: 调用发送验证码接口
        print("请求发送验证码到手机号: \(phone)")
        loginViewModel.sendSmsCode(phone: phone, type: .bindPhone) { [weak self] result in
            switch result {
            case .success:
                self?.view.sw_showSuccessToast("验证码发送成功")
            case .failure(let error):
                self?.view.sw_showWarningToast(error.errorMessage)
            }
        }
    }
    
    // 更新确认按钮状态
    private func updateConfirmButtonState(code: String) {
        // 验证码不为空且长度合理（假设验证码是6位数字）
        let isValidCode = code.count == 6
        
        confirmButton.isEnabled = isValidCode
        confirmButton.backgroundColor = isValidCode ? UIColor(hex: "#FE6A00") : UIColor(hex: "#FFE0B9")
    }
    
    @objc private func confirmButtonTapped() {
        let phone = phoneField.text
        let code = verificationCodeField.text
        personalViewModel.updateUserPhone(phone: phone, smsCode: code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                // 处理完成状态
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    // 处理错误
                    self?.confirmButton.isEnabled = true
                    switch error {
                    case .businessError(let message, let code):
                        self?.view.sw_showWarningToast(message)
                    case .networkError(let message):
                        self?.view.sw_showWarningToast("修改手机号失败：\(message)")
                    case .parseError(let message):
                        self?.view.sw_showWarningToast("修改手机号失败：\(message)")
                    }
                }
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("修改手机号成功")
                    // 方式1：直接 pop 到指定类
                    if let navigationController = self?.navigationController {
                        for controller in navigationController.viewControllers {
                            if controller.isKind(of: AccountAndSafeViewController.self) {
                                navigationController.popToViewController(controller, animated: true)
                                break
                            }
                        }
                    }
                }else {
                    self?.view.sw_showSuccessToast("修改手机号失败")
                }
            }
            .store(in: &personalViewModel.cancellables)
    }
    
    private func updateConfirmButtonState() {
        let phone = phoneField.text
        let code = verificationCodeField.text
        let isEnabled = !phone.isEmpty && !code.isEmpty
        
        confirmButton.isEnabled = isEnabled
        confirmButton.backgroundColor = isEnabled ? ThemeManager.current.mainColor : UIColor(hex: "#FFE0B9")
    }
}

extension NewPhoneViewController: InputFieldDelegate {
    public func inputFieldDidBeginEditing(_ inputField: BaseInputField) {
        
    }
    
    public func inputFieldDidEndEditing(_ inputField: BaseInputField) {
        
    }
    
    public func inputFieldTextDidChange(_ inputField: BaseInputField, text: String) {
        // 输入内容变化时更新登录按钮状态
        updateConfirmButtonState()
    }
    
    
}
