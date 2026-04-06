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
        label.font = .pingFangFontBold(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
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
        label.font = .pingFangFontRegular(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
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
    
    private let startItemView: RouteItemView = {
        return RouteItemView(title: "起点", value: "--")
    }()
    
    private let endItemView: RouteItemView = {
        return RouteItemView(title: "终点", value: "--")
    }()
    
    private let distanceItemView: RouteItemView = {
        return RouteItemView(title: "距离", value: "--")
    }()
    
    private let durationItemView: RouteItemView = {
        return RouteItemView(title: "时长", value: "--")
    }()
    
    private let altitudeItemView: RouteItemView = {
        return RouteItemView(title: "最高海拔", value: "--")
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
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入介绍（选填）"
        label.textColor = UIColor(str: "#A0A3A7")
        label.font = .pingFangFontRegular(ofSize: 14)
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
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .custom)
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
    var confirmHandler: ((String, String?) -> Void)?
    
    // MARK: - Initialization
    init(route: Route) {
        super.init(frame: .zero)
        setupUI(route: route)
        setupConstraints(route: route)
        
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        closeButton.tag = 1000 + (route.type ?? 0)
        
        addTapGestureTarget(self, action: #selector(dismissKeyboard))

        nameTextField.delegate = self
        textView.delegate = self
        
        if let type = route.type, let name = RouteType(rawValue: type)?.name() {
            titleLabel.text = "保存\(name)"
            nameTextField.placeholder = "请输入\(name)名称"

            let prefix = "*"
            let middle = "\(name)名称"
            let suffix = "最长不超过60个字符"
            let attributedString = NSMutableAttributedString(string: prefix + " " + middle + "  " + suffix)
            if let prefixRange = attributedString.string.range(of: prefix) {
                let nsRange = NSRange(prefixRange, in: attributedString.string)
                attributedString.addAttributes([
                    .foregroundColor: ThemeManager.current.errorColor
                ], range: nsRange)
            }
            if let suffixRange = attributedString.string.range(of: suffix) {
                let nsRange = NSRange(suffixRange, in: attributedString.string)
                attributedString.addAttributes([
                    .foregroundColor: ThemeManager.current.textColor,
                    .font: UIFont.pingFangFontRegular(ofSize: 12)
                ], range: nsRange)
            }
            
            nameTitleLabel.attributedText = attributedString
        }
        
        // 设置路线名称
        if let routeName = route.routeName {
            nameTextField.text = routeName
        }
        
        // 设置起点信息
        if let startDesc = route.startDesc() {
            startItemView.valueLabel.attributedText = startDesc
        }
        
        // 设置终点信息
        if let endDesc = route.endDesc() {
            endItemView.valueLabel.attributedText = endDesc
        }
        
        // 设置距离信息
        if let distance = route.distance {
            distanceItemView.valueLabel.text = "\(String(format: "%.2f", distance))km"
        }
        
        // 设置时长信息
        if let duration = route.travelTime {
            durationItemView.valueLabel.text = duration.formatHMSDuration()
        }
        
        // 设置海拔信息
        if let altitude = route.maxAltitude {
            altitudeItemView.valueLabel.text = "\(String(format: "%.2f", altitude))米"
        }
        
        // 设置描述信息
        if let desc = route.description {
            textView.text = desc
            placeholderLabel.isHidden = !desc.isEmpty
        }
        
        debugPrint("startDesc: \(route.startDesc()?.string ?? "") endDesc: \(route.endDesc()?.string ?? "")")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI(route: Route) {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(closeButton)
        
        addSubview(nameTitleLabel)
        addSubview(nameTextField)
        
        addSubview(startItemView)
        addSubview(endItemView)
        addSubview(distanceItemView)
        if route.type == RouteType.track.rawValue {
            addSubview(durationItemView)
            addSubview(altitudeItemView)
        } else {
            addSubview(inputContainerView)
            inputContainerView.addSubview(textView)
            inputContainerView.addSubview(placeholderLabel)
            inputContainerView.addSubview(charCountLabel)
        }
        
        addSubview(confirmButton)
    }
    
    private func setupConstraints(route: Route) {

        titleLabel.snp.makeConstraints {
            $0.height.equalTo(swAdaptedValue(25))
            $0.top.left.equalToSuperview().inset(Layout.hMargin)
            $0.right.equalToSuperview().inset(32 + 9)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(swAdaptedValue(9))
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
        
        startItemView.snp.makeConstraints { make in
            make.top.equalTo(nameTextField.snp.bottom).offset(24)
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        endItemView.snp.makeConstraints { make in
            make.top.equalTo(startItemView.snp.bottom).offset(12)
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        distanceItemView.snp.makeConstraints { make in
            make.top.equalTo(endItemView.snp.bottom).offset(12)
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        
        if route.type == RouteType.track.rawValue {
            durationItemView.snp.makeConstraints { make in
                // 父视图的水平居中
                make.left.equalToSuperview().inset(ScreenUtil.screenWidth * 0.5)
                make.centerY.equalTo(distanceItemView)
            }
            altitudeItemView.snp.makeConstraints { make in
                make.top.equalTo(distanceItemView.snp.bottom).offset(12)
                make.bottom.equalTo(confirmButton.snp.top).offset(-28)
                make.left.equalToSuperview().inset(Layout.hMargin)
            }
        } else {
            inputContainerView.snp.makeConstraints { make in
                make.height.equalTo(swAdaptedValue(94))
                make.top.equalTo(distanceItemView.snp.bottom).offset(16)
                make.bottom.equalTo(confirmButton.snp.top).offset(-28)
                make.left.right.equalToSuperview().inset(Layout.hMargin)
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
        
        confirmButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + 12)
            make.left.right.equalToSuperview().inset(Layout.hMargin)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped(btn: UIButton) {
        dismissKeyboard()
        let tag = btn.tag - 1000
        let name = RouteType(rawValue: tag)?.name() ?? ""
        SWAlertView.showAlert(title: nil, message: "确定不保存\(name)吗？", confirmTitle: "继续编辑", cancelTitle: "不保存",  cancelHandler: {
            self.closeHandler?()
        })
    }
    
    @objc private func confirmButtonTapped() {
        dismissKeyboard()
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            sw_showWarningToast("名称不能为空")
            return
        }
        if name.count > 60 {
            sw_showWarningToast("最多输入30个字符")
            return
        }
        self.confirmHandler?(name, textView.text)
    }
    
    @objc private func dismissKeyboard() {
        if nameTextField.isFirstResponder {
            nameTextField.resignFirstResponder()
        }
        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }
}


// MARK: - UITextFieldDelegate

extension AddRoutePopupView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        return currentText.count < 60
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
