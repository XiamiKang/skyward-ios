//
//  EmergencyContactViewController.swift
//  Pods
//
//  Created by TXTS on 2026/1/14.
//


import UIKit
import TXKit
import SWKit
import SWTheme

class LoginEmergencyContactViewController: LoginBaseViewController {
    
    private let viewModel = LoginViewModel()
    
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("登录", for: .normal)
        button.setTitleColor(ThemeManager.current.mainColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(popLoginVC), for: .touchUpInside)
        return button
    }()
    
    private let successImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = LoginModule.image(named: "CEX_circlefilled_success")
        return imageView
    }()
    
    private let titleTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.text = "注册成功，请绑定紧急联系人"
        return label
    }()
    
    private let contentTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(hex: "#303236")
        label.numberOfLines = 0
        label.text = "完成绑定后，对你的安全进行保驾护航：SOS紧急求助与报平安通知将自动发送给您的紧急联系人，让您在任何时候都能安心，并获得最及时的帮助。"
        return label
    }()

    
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
        let title = "紧急联系人昵称"
        let attributedString = NSMutableAttributedString(string: title,
                                                         attributes: [
                                                             .font: UIFont.pingFangFontRegular(ofSize: 14),
                                                             .foregroundColor: ThemeManager.current.titleColor
                                                         ])
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
        let title = "紧急联系人电话"
        let attributedString = NSMutableAttributedString(string: title,
                                                         attributes: [
                                                             .font: UIFont.pingFangFontRegular(ofSize: 14),
                                                             .foregroundColor: ThemeManager.current.titleColor
                                                         ])
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
        titleLabel.text = ""
        
        navigationView.addSubview(loginButton)
        view.addSubview(successImageView)
        view.addSubview(titleTextLabel)
        view.addSubview(contentTextLabel)
        view.addSubview(nicknameTitleLabel)
        view.addSubview(nicknameDescriptionLabel)
        view.addSubview(nicknameTextField)
        view.addSubview(phoneTitleLabel)
        view.addSubview(phoneTextField)
        
        view.addSubview(bottomButton)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // 添加手势到视图
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
    
        loginButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalToSuperview().offset(-10)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
        
        successImageView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(40)
            make.centerX.equalTo(view.snp.centerX)
            make.width.height.equalTo(72)
        }
        
        titleTextLabel.snp.makeConstraints { make in
            make.top.equalTo(successImageView.snp.bottom).offset(10)
            make.centerX.equalTo(view.snp.centerX)
        }
        
        contentTextLabel.snp.makeConstraints { make in
            make.top.equalTo(titleTextLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        nicknameTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentTextLabel.snp.bottom).offset(40)
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
//        let emergencyModel = LoginEmergencyContactModel(name: nickname, phone: phoneNumber)
        // 保存紧急联系人信息到本地
        UserDefaults.standard.set(nickname, forKey: "EmergencyName")
        UserDefaults.standard.set(phoneNumber, forKey: "EmergencyPhone")
        view.sw_showSuccessToast("保存成功")
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            self.popLoginVC()
        }
        
    }
    
    @objc private func popLoginVC() {
        if let vc = self.navigationController?.viewControllers.first(where: { $0 is LoginViewController }) {
            self.navigationController?.popToViewController(vc, animated: true)
        }else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}



