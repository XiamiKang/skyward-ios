//
//  EmergencyContactViewController.swift
//  ModulePersonal
//
//  Created by zhaobo on 2025/12/15.
//

import UIKit
import TXKit
import SWKit
import SWTheme

class EmergencyContactViewController: PersonalBaseViewController {
    
    private let viewModel = PersonalViewModel()
    
    // 昵称输入框
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入紧急联系人昵称"
        textField.font = .pingFangFontRegular(ofSize: 14)
        textField.textColor = ThemeManager.current.titleColor
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftViewMode = .always
        return textField
    }()
    
    // 昵称输入框标题
    private let nicknameTitleLabel: UILabel = {
        let label = UILabel()
        let prefix = "*"
        let title = prefix + " 紧急联系人昵称"
        let range = NSRange(location: 0, length: prefix.count)
        let attributedString = NSMutableAttributedString(string: title,
                                                         attributes: [
                                                             .font: UIFont.pingFangFontRegular(ofSize: 14),
                                                             .foregroundColor: ThemeManager.current.titleColor
                                                         ])
        attributedString.addAttribute(.foregroundColor, value: ThemeManager.current.errorColor, range: range)
        label.attributedText = attributedString
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
        textField.font = .pingFangFontRegular(ofSize: 14)
        textField.textColor = ThemeManager.current.titleColor
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
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
        let prefix = "*"
        let title = prefix + " 紧急联系人电话"
        let range = NSRange(location: 0, length: prefix.count)
        let attributedString = NSMutableAttributedString(string: title,
                                                         attributes: [
                                                             .font: UIFont.pingFangFontRegular(ofSize: 14),
                                                             .foregroundColor: ThemeManager.current.titleColor
                                                         ])
        attributedString.addAttribute(.foregroundColor, value: ThemeManager.current.errorColor, range: range)
        label.attributedText = attributedString
        return label
    }()
    
    private lazy var bottomButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("保存", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ThemeManager.current.mainColor
        button.titleLabel?.font = .pingFangFontBold(ofSize: 16)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(bottomButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "紧急联系人"
        
        view.addSubview(nicknameTitleLabel)
        view.addSubview(nicknameDescriptionLabel)
        view.addSubview(nicknameTextField)
        view.addSubview(phoneTitleLabel)
        view.addSubview(phoneTextField)
        
        view.addSubview(bottomButton)
    }
    
    // MARK: - 输入信息获取
    var nickname: String? {
        return nicknameTextField.text
    }
    
    var phoneNumber: String? {
        return phoneTextField.text
    }
    
    // MARK: - 约束设置
    private func setupConstraints() {
        let margin: CGFloat = Layout.hMargin
        let spacing: CGFloat = 24
    
        nicknameTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(customNavView.snp.bottom).offset(Layout.vMargin)
            make.leading.equalToSuperview().inset(margin)
        }
        
        nicknameDescriptionLabel.snp.makeConstraints { make in
            make.leading.equalTo(nicknameTitleLabel.snp.trailing).offset(8)
            make.centerY.equalTo(nicknameTitleLabel)
        }
        
        nicknameTextField.snp.makeConstraints { make in
            make.top.equalTo(nicknameTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(margin)
            make.height.equalTo(48)
        }
        
        phoneTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(nicknameTextField.snp.bottom).offset(spacing)
            make.leading.equalToSuperview().inset(margin)
        }
        
        phoneTextField.snp.makeConstraints { make in
            make.top.equalTo(phoneTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(margin)
            make.height.equalTo(48)
        }
        
        bottomButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.leading.trailing.equalToSuperview().inset(margin)
            make.top.equalTo(phoneTextField.snp.bottom).offset(swAdaptedValue(36))
        }
    }
    
    @objc private func bottomButtonTapped() {
        view.endEditing(true)
        
        guard let nickname = nickname, !nickname.isEmpty else {
            view.sw_showWarningToast("请输入紧急联系人昵称")
            return
        }
        
        guard let phoneNumber = phoneNumber, !phoneNumber.isEmpty else {
            view.sw_showWarningToast("请输入紧急联系人电话")
            return
        }
        
        guard phoneNumber.count == 11 else {
            view.sw_showWarningToast("请输入正确的紧急联系人电话")
            return
        }
        let emergencyModel = EmergencyContactModel(name: nickname, phone: phoneNumber)
        viewModel.updateEmergencyContact(model: emergencyModel)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("设置紧急联系人成功")
                    Task {
                        await UserManager.shared.requestUserInfo()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.navigationController?.popToRootViewController(animated: true)
                    }
                }else {
                    self?.view.sw_showSuccessToast("设置紧急联系人失败")
                }
            }
            .store(in: &viewModel.cancellables)
        
    }
    
}
