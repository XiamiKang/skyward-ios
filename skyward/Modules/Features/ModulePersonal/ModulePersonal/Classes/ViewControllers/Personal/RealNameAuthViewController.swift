//
//  RealNameAuthViewController.swift
//  ModulePersonal
//
//  Created by zhaobo on 2025/12/15.
//

import UIKit
import TXKit
import SWKit
import SWTheme

class RealNameAuthViewController: PersonalBaseViewController {
    
    var isRealName: Bool = false
    var userInfo: UserInfoData?
    private let viewModel = PersonalViewModel()
    
    private let phoneTitleLabel = creatTextLabel(text: "手机号码")
    private let IDTypeTitleLabel = creatTextLabel(text: "证件类型")
    private let realNameTitleLabel = creatTextLabel(text: "真实姓名")
    private let IDCardTitleLabel = creatTextLabel(text: "证件号码")
    
    private let phoneContentLabel = creatTextLabel(text: "")
    private let IDTypeContentLabel = creatTextLabel(text: "居民身份证")
    private let realNameTextField = UITextField()
    private let IDCardTextField = UITextField()
    
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
        setupConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "实名认证"
        
        phoneContentLabel.text = userInfo?.phone?.hidePhoneNumber() ?? ""
        
        realNameTextField.translatesAutoresizingMaskIntoConstraints = false
        realNameTextField.borderStyle = .none
        realNameTextField.delegate = self
        realNameTextField.tintColor = ThemeManager.current.mainColor
        realNameTextField.placeholder = "请填写真实姓名"
        
        IDCardTextField.translatesAutoresizingMaskIntoConstraints = false
        IDCardTextField.borderStyle = .none
        IDCardTextField.delegate = self
        IDCardTextField.tintColor = ThemeManager.current.mainColor
        IDCardTextField.placeholder = "请填写身份证件号码"
        
        view.addSubview(phoneTitleLabel)
        view.addSubview(IDTypeTitleLabel)
        view.addSubview(realNameTitleLabel)
        view.addSubview(IDCardTitleLabel)
        view.addSubview(phoneContentLabel)
        view.addSubview(IDTypeContentLabel)
        view.addSubview(realNameTextField)
        view.addSubview(IDCardTextField)
        view.addSubview(confirmButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            phoneTitleLabel.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            phoneTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
           
            IDTypeTitleLabel.topAnchor.constraint(equalTo: phoneTitleLabel.bottomAnchor, constant: 32),
            IDTypeTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            realNameTitleLabel.topAnchor.constraint(equalTo: IDTypeTitleLabel.bottomAnchor, constant: 32),
            realNameTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            IDCardTitleLabel.topAnchor.constraint(equalTo: realNameTitleLabel.bottomAnchor, constant: 32),
            IDCardTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            phoneContentLabel.centerYAnchor.constraint(equalTo: phoneTitleLabel.centerYAnchor),
            phoneContentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 116),
            phoneContentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            IDTypeContentLabel.centerYAnchor.constraint(equalTo: IDTypeTitleLabel.centerYAnchor),
            IDTypeContentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 116),
            IDTypeContentLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            realNameTextField.centerYAnchor.constraint(equalTo: realNameTitleLabel.centerYAnchor),
            realNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 116),
            realNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            realNameTextField.heightAnchor.constraint(equalToConstant: 40),
            
            IDCardTextField.centerYAnchor.constraint(equalTo: IDCardTitleLabel.centerYAnchor),
            IDCardTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 116),
            IDCardTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            IDCardTextField.heightAnchor.constraint(equalToConstant: 40),
            
            confirmButton.topAnchor.constraint(equalTo: IDCardTextField.bottomAnchor, constant: 52),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func confirmButtonTapped() {
        let realNameModel = RealNameModel(realName: realNameTextField.text ?? "", idCard: IDCardTextField.text ?? "")
        viewModel.checkRealNameAuth(model: realNameModel)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("实名认证成功")
                    
                }else {
                    self?.view.sw_showSuccessToast("实名认证失败")
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    private func updateConfirmButtonState() {
        
        let realName = realNameTextField.text ?? ""
        let IDCard = IDCardTextField.text ?? ""
        let isEnabled = !realName.isEmpty && !IDCard.isEmpty
        
        confirmButton.isEnabled = isEnabled
        confirmButton.backgroundColor = isEnabled ? ThemeManager.current.mainColor : UIColor(hex: "#FFE0B9")
    }
    
    static func creatTextLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .black
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}

extension RealNameAuthViewController: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        updateConfirmButtonState()
    }
}


