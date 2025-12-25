//
//  AddRouteViewController.swift
//  yifan_test
//
//  Created by TXTS on 2025/12/2.
//

import UIKit

class AddRouteViewController: UIViewController {
    
    var customTransitioningDelegate: CustomTransitioningDelegate?
    
    // MARK: - Properties
    var coordinate: POICoordinate?
    
    // 添加变量跟踪当前编辑的控件
    private var activeField: UIView?
    private let scrollViewBottomInset: CGFloat = 0 // 底部边距
    
    // MARK: - UI Components - 头部
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "添加路线"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        return button
    }()
    
    // MARK: - UI Components - 内容区域
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - 表单组件
    // 路线名称
    private let nameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "路线名称"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        return label
    }()
    
    private let requiredLabel1: UILabel = {
        let label = UILabel()
        label.text = "*"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .red
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入路线名称"
        textField.font = .systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.clearButtonMode = .whileEditing
        return textField
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.layer.masksToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }()
    
    // 添加占位符Label
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入介绍（选填）"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightGray
        label.numberOfLines = 0
        return label
    }()
    
    private let charCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0/100"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    // 底部按钮
    private let buttonContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor(str: "#070808"), for: .normal)
        button.backgroundColor = UIColor(str: "#F2F3F4")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("添加", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(str: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    // MARK: - Lifecycle
    init(coordinate: POICoordinate) {
        self.coordinate = coordinate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupKeyboardObservers()
        
        // 设置占位符初始状态
        updatePlaceholder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 头部
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        
        // 滚动区域
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 名称
        contentView.addSubview(nameTitleLabel)
        contentView.addSubview(requiredLabel1)
        contentView.addSubview(nameTextField)
        
        // 简介
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(placeholderLabel) // 添加占位符
        contentView.addSubview(charCountLabel)
        
        // 底部按钮
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(cancelButton)
        buttonContainerView.addSubview(addButton)
        
        // 设置代理
        nameTextField.delegate = self
        descriptionTextView.delegate = self
    }
    
    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 头部约束
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 滚动区域约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupFormConstraints()
        setupButtonConstraints()
    }
    
    private func setupFormConstraints() {
        nameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        requiredLabel1.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 名称部分
        NSLayoutConstraint.activate([
            requiredLabel1.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            requiredLabel1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            nameTitleLabel.centerYAnchor.constraint(equalTo: requiredLabel1.centerYAnchor),
            nameTitleLabel.leadingAnchor.constraint(equalTo: requiredLabel1.trailingAnchor, constant: 4),
            
            nameTextField.topAnchor.constraint(equalTo: nameTitleLabel.bottomAnchor, constant: 12),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        setupDescriptionConstraints()
    }
    
    private func setupDescriptionConstraints() {
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        charCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            descriptionTextView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 120),
            descriptionTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // 占位符约束
            placeholderLabel.topAnchor.constraint(equalTo: descriptionTextView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: descriptionTextView.trailingAnchor, constant: -8),
            
            charCountLabel.bottomAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: -8),
            charCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),
        ])
    }
    
    private func setupButtonConstraints() {
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            cancelButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 60) / 2),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            
            addButton.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 60) / 2),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addButtonTapped() {
        guard validateForm() else { return }
        
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    private func updatePlaceholder() {
        placeholderLabel.isHidden = !descriptionTextView.text.isEmpty
    }
    
    private func validateForm() -> Bool {
        // 验证名称
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(title: "提示", message: "请输入路线名称")
            return false
        }
        
        // 验证坐标
        guard coordinate != nil else {
            showAlert(title: "提示", message: "位置信息无效")
            return false
        }
        
        return true
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        // 计算键盘高度
        let keyboardHeight = keyboardFrame.height
        
        // 获取按钮容器的高度，确保内容不会被底部按钮遮挡
        let buttonContainerHeight = buttonContainerView.bounds.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight - buttonContainerHeight, right: 0)
        
        // 设置滚动视图的内边距
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // 计算需要滚动的距离
        guard let activeField = activeField else { return }
        
        // 将activeField的frame转换到scrollView的坐标系
        let activeRect = activeField.convert(activeField.bounds, to: scrollView)
        
        // 计算可见区域（减去键盘高度）
        let visibleRect = CGRect(
            x: 0,
            y: 0,
            width: scrollView.bounds.width,
            height: scrollView.bounds.height - keyboardHeight + buttonContainerHeight
        )
        
        // 如果输入框在键盘下面，需要滚动
        if !visibleRect.contains(activeRect.origin) {
            // 计算需要滚动的距离：输入框底部 - (可见区域高度 - 额外间距)
            let scrollPoint = CGPoint(
                x: 0,
                y: activeRect.origin.y - (visibleRect.height - activeRect.height) + 30
            )
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
                self.scrollView.setContentOffset(scrollPoint, animated: false)
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
            // 恢复滚动视图的内边距
            self.scrollView.contentInset = .zero
            self.scrollView.scrollIndicatorInsets = .zero
        }
        
        activeField = nil
    }

}

// MARK: - UITextFieldDelegate
extension AddRouteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            descriptionTextView.becomeFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }
}

// MARK: - UITextViewDelegate
extension AddRouteViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let currentCount = textView.text.count
        charCountLabel.text = "\(currentCount)/100"
        
        if currentCount > 100 {
            textView.text = String(textView.text.prefix(100))
            charCountLabel.textColor = .red
        } else {
            charCountLabel.textColor = currentCount == 100 ? .red : .secondaryLabel
        }
        
        placeholderLabel.isHidden = true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        DispatchQueue.main.async {
            self.updatePlaceholder()
        }
        
        return updatedText.count <= 100
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeField = textView
        // 开始编辑时滚动到可见位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let textViewRect = textView.convert(textView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(textViewRect, animated: true)
        }
        updatePlaceholder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        activeField = nil
        // 结束编辑时保持占位符状态
        updatePlaceholder()
    }
}

