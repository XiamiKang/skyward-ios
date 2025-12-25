//
//  InputFieldDelegate.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//


import UIKit

// MARK: - 输入框协议
protocol InputFieldDelegate: AnyObject {
    func inputFieldDidBeginEditing(_ inputField: BaseInputField)
    func inputFieldDidEndEditing(_ inputField: BaseInputField)
    func inputFieldTextDidChange(_ inputField: BaseInputField, text: String)
}

// MARK: - 输入验证规则
enum InputValidationRule {
    case none
    case phone
    case password
    case custom(regex: String)
    
    func validate(_ text: String) -> Bool {
        switch self {
        case .none:
            return true
        case .phone:
            let phoneRegex = "^1[0-9]{10}$"
            return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: text)
        case .password:
            return text.count >= 6 && text.count <= 20
        case .custom(let regex):
            return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
        }
    }
}

class BaseInputField: UIView {
    
    // MARK: - UI Components
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#F2F3F4")
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()
    
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.textColor = .black
        textField.tintColor = .black
        return textField
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor(hex: "#999999")
        label.isHidden = true
        return label
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .orange
        label.isHidden = true
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - 简化的高度约束
    private var containerHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    weak var delegate: InputFieldDelegate?
    var validationRule: InputValidationRule = .none
    var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(hex: "#999999")]
            )
        }
    }
    
    var text: String {
        return textField.text ?? ""
    }
    
    var containerHeight: CGFloat = 50 {
        didSet {
            containerHeightConstraint.constant = containerHeight
        }
    }
    
    var errorColor: UIColor = defaultOrangeColor
    var normalBorderColor: UIColor = .clear
    
    // MARK: - 状态管理
    private var isErrorShowing: Bool = false
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    // MARK: - UI Setup (修复约束)
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(textField)
        containerView.addSubview(placeholderLabel)
        addSubview(errorLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 容器约束
        containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: containerHeight)
        
        NSLayoutConstraint.activate([
            // 容器约束
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerHeightConstraint,
            
            // 文本字段约束 - 简化版本
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // 占位符标签约束
            placeholderLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            
            // 错误标签约束 - 简化版本
            errorLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        
        // 设置内容拥抱优先级，避免拉伸
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }
    
    private func setupActions() {
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.delegate = self
        
        // 添加点击手势来收起键盘
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - 修复 hitTest 方法
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 首先调用父类的 hitTest
        let hitView = super.hitTest(point, with: event)
        
        // 如果点击的是子视图（比如按钮），直接返回该子视图
        if let subview = hitView, subview != self {
            return subview
        }
        
        // 如果点击的是当前视图本身，检查是否需要成为第一响应者
        if bounds.contains(point) {
            return self
        }
        
        return hitView
    }
    
    // MARK: - Public Methods
    func configure(placeholder: String, height: CGFloat = 50) {
        self.placeholder = placeholder
        self.containerHeight = height
    }
    
    func setValidationRule(_ rule: InputValidationRule) {
        self.validationRule = rule
    }
    
    func validate() -> Bool {
        let isValid = validationRule.validate(text)
        if !isValid && !text.isEmpty {
            switch validationRule {
            case .phone:
                showError("请输入正确的手机号码")
            case .password:
                showError("密码长度为6-20位")
            default:
                showError("输入格式不正确")
            }
        } else {
            hideError()
        }
        return isValid
    }
    
    // MARK: - Actions
    @objc func textFieldDidChange() {
        delegate?.inputFieldTextDidChange(self, text: text)
        updatePlaceholderVisibility()
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // 检查是否点击在文本输入区域
        let textFieldFrame = textField.frame
        if textFieldFrame.contains(location) {
            if textField.isFirstResponder {
                textField.resignFirstResponder()
            } else {
                textField.becomeFirstResponder()
            }
        }
    }
    
    private func updatePlaceholderVisibility() {
        let shouldShowPlaceholder = text.isEmpty && !textField.isFirstResponder
        UIView.animate(withDuration: 0.2) {
            self.placeholderLabel.isHidden = !shouldShowPlaceholder
            self.placeholderLabel.alpha = shouldShowPlaceholder ? 1.0 : 0.0
        }
    }
    
    // MARK: - 错误状态管理 (优化版本)
    func showError(_ message: String) {
        guard !isErrorShowing else { return }
        
        isErrorShowing = true
        errorLabel.text = message
        errorLabel.isHidden = false
        
        // 设置错误状态
        containerView.layer.borderColor = errorColor.cgColor
        containerView.layer.borderWidth = 1
        
        // 简单的动画，避免性能问题
        UIView.animate(withDuration: 0.2) {
            self.errorLabel.alpha = 1.0
            self.layoutIfNeeded()
        }
    }
    
    func hideError() {
        guard isErrorShowing else { return }
        
        isErrorShowing = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.errorLabel.alpha = 0.0
            self.updateBorderColor()
        }) { _ in
            self.errorLabel.isHidden = true
            self.errorLabel.text = nil
        }
    }
    
    func clearErrorWhenEditing() {
        if isErrorShowing {
            hideError()
        }
    }
    
    private func updateBorderColor() {
        let borderColor: UIColor = textField.isFirstResponder ? .black : normalBorderColor
        let borderWidth: CGFloat = textField.isFirstResponder ? 1 : (normalBorderColor == .clear ? 0 : 1)
        
        containerView.layer.borderColor = borderColor.cgColor
        containerView.layer.borderWidth = borderWidth
    }
}

// MARK: - UITextFieldDelegate
extension BaseInputField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorderColor()
        updatePlaceholderVisibility()
        clearErrorWhenEditing()
        delegate?.inputFieldDidBeginEditing(self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBorderColor()
        updatePlaceholderVisibility()
        
        // 结束编辑时验证
        if !text.isEmpty {
            _ = validate()
        }
        
        delegate?.inputFieldDidEndEditing(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
