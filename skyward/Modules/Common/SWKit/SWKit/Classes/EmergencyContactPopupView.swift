//
//  EmergencyContactPopupView.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import SWTheme
import SnapKit

class EmergencyContactPopupView: UIView,  SWAlertCustomView {
    
    // 说明文字标签
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        let text = "完成绑定后，SOS紧急求助与报平安通知将自动发送给您的紧急联系人，让您在任何时候能获得及时的帮助。"
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(str: "#6A6B6D")
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    // 昵称输入框
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入紧急联系人昵称"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.textColor = UIColor(str: "#070808")
        textField.backgroundColor = UIColor(str: "#F2F3F4")
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftViewMode = .always
        return textField
    }()
    
    // 昵称输入框标题
    private let nicknameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "紧急联系人昵称"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(str: "#070808")
        return label
    }()
    
    // 昵称输入框说明
    private let nicknameDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "仅支持中英文，最长10个字符"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(str: "#6A6B6D")
        return label
    }()
    
    // 电话输入框
    private let phoneTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入紧急联系人电话"
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.textColor = UIColor(str: "#070808")
        textField.backgroundColor = UIColor(str: "#F2F3F4")
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.keyboardType = .numberPad
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftViewMode = .always
        return textField
    }()
    
    // 电话输入框标题
    private let phoneTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "紧急联系人电话"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(str: "#070808")
        return label
    }()
    
    // MARK: - 输入信息获取
    var nickname: String? {
        return nicknameTextField.text
    }
    
    var phoneNumber: String? {
        return phoneTextField.text
    }
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        addSubview(descriptionLabel)
        addSubview(nicknameTitleLabel)
        addSubview(nicknameDescriptionLabel)
        addSubview(nicknameTextField)
        addSubview(phoneTitleLabel)
        addSubview(phoneTextField)
    }
    
    // MARK: - 约束设置
    private func setupConstraints() {
        let margin: CGFloat = 0
        let spacing: CGFloat = 12
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(margin)
        }
        
        nicknameTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(spacing * 2)
            make.leading.equalToSuperview().inset(margin)
        }
        
        nicknameDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameTitleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(margin)
        }
        
        nicknameTextField.snp.makeConstraints { make in
            make.top.equalTo(nicknameDescriptionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(margin)
            make.height.equalTo(44)
        }
        
        phoneTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameTextField.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(margin)
        }
        
        phoneTextField.snp.makeConstraints { make in
            make.top.equalTo(phoneTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(margin)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(margin)
        }
    }
    
    // MARK: - 事件设置
    private func setupActions() {
        // 不需要设置按钮事件，因为按钮由SWAlertView处理
    }
    
    // MARK: - 输入处理
    func becomeFirstResponderToNickname() {
        nicknameTextField.becomeFirstResponder()
    }
    
    func endEdit(_ force: Bool) -> Bool {
        return nicknameTextField.resignFirstResponder() && phoneTextField.resignFirstResponder()
    }
    
    //MARK: - SWAlertCustomView协议实现
    
    func shouldClickConfirmButton() -> Bool {
        guard let nickname = nickname, !nickname.isEmpty else {
            sw_showWarningToast("请输入紧急联系人昵称")
            return false
        }
        
        guard let phoneNumber = phoneNumber, !phoneNumber.isEmpty else {
            sw_showWarningToast("请输入紧急联系人电话")
            return false
        }
        
        guard phoneNumber.count == 11 else {
            sw_showWarningToast("请输入正确的紧急联系人电话")
            return false
        }

        return true
    }
}
