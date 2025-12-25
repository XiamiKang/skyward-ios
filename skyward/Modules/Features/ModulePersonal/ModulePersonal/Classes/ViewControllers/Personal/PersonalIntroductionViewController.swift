//
//  File.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/23.
//

import UIKit
import Combine
import SWKit

class PersonalIntroductionViewController: PersonalBaseViewController {
    
    // MARK: - Properties
    
    private let viewModel = PersonalViewModel()
    public var introduction: String?
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let saveButton = UIButton()
    private let textBgView = UIView()
    private let textView = UITextView()
    private let characterCountLabel = UILabel()
    private let placeholderLabel = UILabel()
    
    // Constants
    private let maxIntroductionLength = 100
    private let minIntroductionLength = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupKeyboardHandling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 延迟一点让视图完全加载后再获取焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.textView.becomeFirstResponder()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        self.view.backgroundColor = .white
        customTitle.text = "修改简介"
        
        // Save Button
        configureSaveButton()
        
        // Background View
        configureBackgroundView()
        
        // Text View
        configureTextView()
        
        // Placeholder Label
        configurePlaceholderLabel()
        
        // Character Count Label
        configureCharacterCountLabel()
        
        setConstraints()
        updateCharacterCount()
        updateSaveButtonState()
        updatePlaceholderVisibility()
    }
    
    private func configureSaveButton() {
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(UIColor(str: "#FFE0B9"), for: .normal)
        saveButton.setTitleColor(UIColor(str: "#CCCCCC"), for: .disabled)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveButton.addTarget(self, action: #selector(saveClick), for: .touchUpInside)
        saveButton.isEnabled = false
        customNavView.addSubview(saveButton)
    }
    
    private func configureBackgroundView() {
        textBgView.backgroundColor = UIColor(str: "#F2F3F4")
        textBgView.layer.cornerRadius = 8
        textBgView.layer.masksToBounds = true
        textBgView.layer.borderWidth = 1
        textBgView.layer.borderColor = UIColor.clear.cgColor
        view.addSubview(textBgView)
    }
    
    private func configureTextView() {
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = UIColor(str: "#333333")
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.returnKeyType = .default
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
        textView.keyboardDismissMode = .interactive
        
        // Set initial text if available
        if let introduction = introduction, introduction != "一句话介绍自己" && !introduction.isEmpty {
            textView.text = introduction
            placeholderLabel.isHidden = true
        }
        
        textBgView.addSubview(textView)
    }
    
    private func configurePlaceholderLabel() {
        placeholderLabel.text = "一句话介绍自己"
        placeholderLabel.textColor = UIColor(str: "#999999")
        placeholderLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        placeholderLabel.numberOfLines = 0
        textBgView.addSubview(placeholderLabel)
    }
    
    private func configureCharacterCountLabel() {
        characterCountLabel.text = "0/\(maxIntroductionLength)"
        characterCountLabel.textColor = UIColor(str: "#84888C")
        characterCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        characterCountLabel.textAlignment = .right
        view.addSubview(characterCountLabel)
    }
    
    private func setConstraints() {
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        textBgView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.centerYAnchor.constraint(equalTo: customTitle.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: customNavView.trailingAnchor, constant: -16),
            saveButton.widthAnchor.constraint(equalToConstant: 60),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            
            textBgView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            textBgView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textBgView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textBgView.heightAnchor.constraint(equalToConstant: 120),
            
            textView.topAnchor.constraint(equalTo: textBgView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textBgView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textBgView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textBgView.bottomAnchor),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -12),
            
            characterCountLabel.bottomAnchor.constraint(equalTo: textBgView.bottomAnchor, constant: -12),
            characterCountLabel.trailingAnchor.constraint(equalTo: textBgView.trailingAnchor, constant: -12),
        ])
    }
    
    private func setupBindings() {
        // Listen for keyboard notifications
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification, isShowing: true)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardNotification(notification, isShowing: false)
            }
            .store(in: &cancellables)
    }
    
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // 添加工具栏
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 44))
        toolbar.barStyle = .default
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.items = [flexibleSpace, doneButton]
        toolbar.sizeToFit()
        
        textView.inputAccessoryView = toolbar
    }
    
    // MARK: - Helper Methods
    
    private func updateCharacterCount() {
        let count = textView.text.count
        characterCountLabel.text = "\(count)/\(maxIntroductionLength)"
        
        // Update color based on count
        if count > maxIntroductionLength {
            characterCountLabel.textColor = .systemRed
        } else if count > Int(maxIntroductionLength*4/5) {
            characterCountLabel.textColor = UIColor(str: "#FF9900") // 橙色警告
        } else {
            characterCountLabel.textColor = UIColor(str: "#84888C")
        }
    }
    
    private func updateSaveButtonState() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let isValid = text.count <= maxIntroductionLength &&
                     text.count >= minIntroductionLength &&
                     text != (introduction ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        saveButton.isEnabled = isValid
    }
    
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    private func validateIntroduction(_ introduction: String) -> (isValid: Bool, message: String?) {
        let trimmedIntroduction = introduction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if same as original
        let original = (self.introduction ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedIntroduction == original {
            return (false, "个人简介未修改")
        }
        
        // Check length
        if trimmedIntroduction.count > maxIntroductionLength {
            return (false, "个人简介不能超过\(maxIntroductionLength)个字符")
        }
        
        // Check for only whitespace
        if trimmedIntroduction.isEmpty {
            return (true, nil) // 允许清空简介
        }
        
        // 可选：检查敏感词或特殊字符
        if containsInvalidCharacters(trimmedIntroduction) {
            return (false, "包含不支持的特殊字符")
        }
        
        return (true, nil)
    }
    
    private func containsInvalidCharacters(_ text: String) -> Bool {
        // 这里可以添加敏感词或特殊字符检查
        // 例如：检查是否包含某些特殊字符
        let invalidCharacters = CharacterSet(charactersIn: "<>\"'&")
        return text.rangeOfCharacter(from: invalidCharacters) != nil
    }
    
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        // 如果是长文本，可以考虑调整textView的高度或添加滚动
        if isShowing {
            let keyboardHeight = keyboardFrame.height
            // 可以在这里调整布局
        }
        
        // 动画更新布局
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    // MARK: - Actions
    
    @objc private func saveClick() {
        let introductionText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let validation = validateIntroduction(introductionText)
        guard validation.isValid else {
            if let message = validation.message {
                view.sw_showWarningToast(message)
            }
            return
        }
        
        dismissKeyboard()
        saveButton.isEnabled = false
        
        // Show loading state
        view.sw_showLoading()
        
        viewModel.updateIntroduction(introduction: introductionText)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.view.sw_hideLoading()
                
                if case .failure(let error) = completion {
                    self?.handleUpdateError(error)
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.view.sw_showSuccessToast("修改成功")
                    
                    // Notify other parts of the app if needed
                    NotificationCenter.default.post(
                        name: NSNotification.Name("IntroductionUpdated"),
                        object: nil,
                        userInfo: ["introduction": introductionText]
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.navigationController?.popViewController(animated: true)
                    }
                } else {
                    self?.view.sw_showWarningToast("修改失败，请重试")
                    self?.updateSaveButtonState()
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Error Handling
    
    private func handleUpdateError(_ error: Error) {
        // Customize error messages based on error type
        if let networkError = error as? URLError {
            switch networkError.code {
            case .notConnectedToInternet:
                view.sw_showWarningToast("网络连接失败，请检查网络")
            case .timedOut:
                view.sw_showWarningToast("请求超时，请稍后重试")
            default:
                view.sw_showWarningToast("网络异常，请稍后重试")
            }
        } else {
            view.sw_showWarningToast("修改失败")
        }
        
        updateSaveButtonState()
    }
}

// MARK: - UITextViewDelegate

extension PersonalIntroductionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateCharacterCount()
        updateSaveButtonState()
        updatePlaceholderVisibility()
        
        // 限制最大字符数
        let text = textView.text ?? ""
        if text.count > maxIntroductionLength {
            let index = text.index(text.startIndex, offsetBy: maxIntroductionLength)
            textView.text = String(text[..<index])
            
            // 提供触觉反馈（如果有的话）
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // 添加编辑状态视觉效果
        textBgView.layer.borderColor = UIColor(str: "#FFA500").cgColor
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // 移除编辑状态视觉效果
        textBgView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 允许换行
        if text == "\n" {
            // 可以在这里处理换行逻辑，比如限制最大行数
            let currentText = textView.text ?? ""
            let newText = (currentText as NSString).replacingCharacters(in: range, with: text)
            
            // 计算行数（可选）
            let lines = newText.components(separatedBy: .newlines)
            if lines.count > 10 { // 限制最大行数
                return false
            }
        }
        
        return true
    }
}

// MARK: - UIScrollViewDelegate

extension PersonalIntroductionViewController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
}
