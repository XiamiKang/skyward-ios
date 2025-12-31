//
//  AddRoutePopupView.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/18.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

class AddRoutePopupView: UIView, SWPopupContentView {
    
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
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.placeholder = "请输入轨迹名称"
        textField.textColor = ThemeManager.current.titleColor
        textField.font = .pingFangFontMedium(ofSize: 14)
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.clearButtonMode = .whileEditing
        textField.tintColor = ThemeManager.current.mainColor
        textField.cornerRadius = CornerRadius.medium.rawValue
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Layout.hMargin, height: 0))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeManager.current.mediumGrayBGColor
        view.cornerRadius = CornerRadius.medium.rawValue
        return view
    }()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.tintColor = ThemeManager.current.mainColor
        textView.textColor = ThemeManager.current.titleColor
        textView.font = .pingFangFontMedium(ofSize: 14)
        return textView
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入介绍（选填）"
        label.textColor = UIColor(str: "#A0A3A7")
        label.font = .pingFangFontMedium(ofSize: 14)
        return label
    }()
    
    private let charCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0/100"
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = UIColor(str: "#A0A3A7")
        label.textAlignment = .right
        return label
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
        button.setTitle("添加", for: .normal)
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
    var confirmHandler: ((String, String?) -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        
        cancelButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        nameTextField.delegate = self
        textView.delegate = self
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
        
        addSubview(inputContainerView)
        inputContainerView.addSubview(textView)
        inputContainerView.addSubview(placeholderLabel)
        inputContainerView.addSubview(charCountLabel)
        
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
        
        inputContainerView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(94))
            make.top.equalTo(nameTextField.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.equalTo(inputContainerView.snp.bottom).offset(28)
            make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + 12)
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.right.equalTo(self.snp.centerX).offset(-10)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.height.top.equalTo(cancelButton)
            make.left.equalTo(cancelButton.snp.right).offset(20)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        
        // inputContainerView subview
        
        textView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.left.right.equalToSuperview().inset(Layout.hInset)
        }
        placeholderLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(20))
            make.top.left.right.equalToSuperview().inset(Layout.hInset)
        }
        charCountLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(14))
            make.bottom.right.equalToSuperview().inset(Layout.hInset)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        nameTextField.resignFirstResponder()
        textView.resignFirstResponder()
        SWAlertView.showAlert(title: "确定不保存路线吗？", message: nil, confirmTitle: "继续编辑", cancelTitle: "不保存",  cancelHandler: {
            self.closeHandler?()
        })
    }
    
    @objc private func confirmButtonTapped() {
        nameTextField.resignFirstResponder()
        textView.resignFirstResponder()
        guard let name = nameTextField.text, !name.isEmpty else {
            sw_showWarningToast("名称不能为空")
            return
        }
        self.confirmHandler?(name, textView.text)
    }
}


// MARK: - UITextFieldDelegate

extension AddRoutePopupView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        return currentText.count < 30
    }
}

// MARK: - UITextViewDelegate
extension AddRoutePopupView: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let currentCount = textView.text.count
        charCountLabel.text = "\(currentCount)/100"
        
        if currentCount > 100 {
            textView.text = String(textView.text.prefix(100))
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

        return updatedText.count <= 100
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
