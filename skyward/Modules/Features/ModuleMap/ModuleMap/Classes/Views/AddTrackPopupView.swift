//
//  AddTrackPopupView.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/16.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

class AddTrackPopupView: UIView, SWPopupContentView {
    
    // MARK: - UI Components
    
    /// 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "保存轨迹记录"
        label.font = .pingFangFontBold(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 关闭按钮
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let nameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "轨迹名称"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入轨迹名称"
        textField.textColor = ThemeManager.current.titleColor
        textField.font = .pingFangFontMedium(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.clearButtonMode = .whileEditing
        textField.tintColor = ThemeManager.current.mainColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.backgroundColor = ThemeManager.current.mediumGrayBGColor
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("保存", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ThemeManager.current.mainColor
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    // MARK: - Properties
    
    var closeHandler: (() -> Void)?
    var confirmHandler: ((String?) -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        
        cancelButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        nameTextField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(closeButton)
        
        addSubview(nameTitleLabel)
        addSubview(nameTextField)
        
        addSubview(cancelButton)
        addSubview(confirmButton)
    }
    
    private func setupConstraints() {

        titleLabel.snp.makeConstraints {
            $0.height.equalTo(swAdaptedValue(25))
            $0.top.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        closeButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(swAdaptedValue(16))
            $0.centerY.equalTo(titleLabel)
            $0.width.height.equalTo(swAdaptedValue(30))
        }
        
        nameTitleLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(20))
            make.top.equalTo(swAdaptedValue(49))
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        nameTextField.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.equalTo(nameTitleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.equalTo(nameTextField.snp.bottom).offset(28)
            make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + 12)
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.right.equalTo(self.snp.centerX).offset(-10)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.height.top.equalTo(cancelButton)
            make.left.equalTo(cancelButton.snp.right).offset(20)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        nameTextField.resignFirstResponder()
        SWAlertView.showAlert(title: nil, message: "确定不保存轨迹记录吗？", confirmHandler: {
            self.closeHandler?()
        })
    }
    
    @objc private func confirmButtonTapped() {
        nameTextField.resignFirstResponder()
        self.confirmHandler?(nameTextField.text)
    }
}


// MARK: - UITextFieldDelegate

extension AddTrackPopupView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        return currentText.count < 30
    }
}

