//
//  ChangePhoneViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/3/25.
//

import UIKit
import SWKit
import ModuleLogin

class ChangePhoneViewController: PersonalBaseViewController {
    
    var userInfo: UserInfoData?
    private let viewModel = PersonalViewModel()
    
    private let oldPhoneTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "原手机号验证"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private lazy var oldPhoneContent: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "当前手机号\(userInfo?.phone?.hidePhoneNumber() ?? "")，请点击下方按钮获取验证码以完成验证。"
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    // 使用新的验证码输入框
    private let verificationCodeField = VerificationCodeInputField()
    
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
        setupCallbacks()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "修改手机号"
        
        verificationCodeField.translatesAutoresizingMaskIntoConstraints = false
        verificationCodeField.setPlaceholder("请输入验证码")
        
        // 设置当前手机号
        verificationCodeField.phoneNumber = userInfo?.phone ?? ""
        
        view.addSubview(oldPhoneTitle)
        view.addSubview(oldPhoneContent)
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
            
            verificationCodeField.topAnchor.constraint(equalTo: oldPhoneContent.bottomAnchor, constant: 20),
            verificationCodeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            verificationCodeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            verificationCodeField.heightAnchor.constraint(equalToConstant: 72), // 48(输入框) + 24(错误提示)
            
            confirmButton.topAnchor.constraint(equalTo: verificationCodeField.bottomAnchor, constant: 20),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    private func setupCallbacks() {
        // 获取验证码回调
        verificationCodeField.onGetVerificationCode = { [weak self] in
            self?.requestVerificationCode()
        }
        
        // 验证码输入变化回调
        verificationCodeField.onVerificationCodeChanged = { [weak self] code in
            self?.updateConfirmButtonState(code: code)
        }
    }
    
    // 请求验证码
    private func requestVerificationCode() {
        // TODO: 调用发送验证码接口
        print("请求发送验证码到手机号: \(userInfo?.phone ?? "")")
        let phone = userInfo?.phone ?? ""
        viewModel.changePhoneSendSmsCode()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("短信发送成功")
                }else {
                    self?.view.sw_showSuccessToast("短信发送失败")
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    // 更新确认按钮状态
    private func updateConfirmButtonState(code: String) {
        // 验证码不为空且长度合理（假设验证码是6位数字）
        let isValidCode = code.count == 6
        
        confirmButton.isEnabled = isValidCode
        confirmButton.backgroundColor = isValidCode ? UIColor(hex: "#FE6A00") : UIColor(hex: "#FFE0B9")
    }
    
    @objc private func confirmButtonTapped() {
        // 验证验证码
        let code = verificationCodeField.verificationCode
        
        guard code.count == 6 else {
            verificationCodeField.showError("请输入6位验证码")
            return
        }
        
        // TODO: 调用验证接口
        print("验证码: \(code)")
        
        // 显示加载状态
        confirmButton.isEnabled = false
        
        // 模拟验证请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.verifyCode(code)
        }
    }
    
    private func verifyCode(_ code: String) {
        // TODO: 调用验证接口，成功后跳转到下一步
        viewModel.checkPhone(smsCode: code)
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
                        self?.view.sw_showWarningToast("验证手机号失败：\(message)")
                    case .parseError(let message):
                        self?.view.sw_showWarningToast("验证手机号失败：\(message)")
                    }
                }
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("验证通过")
                    // 延迟1秒后返回
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        let newPhoneVC = NewPhoneViewController()
                        self?.navigationController?.pushViewController(newPhoneVC, animated: true)
                    }
                }else {
                    //我需要提示失败原因
                    self?.view.sw_showSuccessToast("验证手机号失败")
                }
            }
            .store(in: &viewModel.cancellables)
        // 恢复按钮状态
        confirmButton.isEnabled = true
    }
}
