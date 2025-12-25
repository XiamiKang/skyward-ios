//
//  File.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/23.
//

import UIKit
import Combine
import SWKit

class PersonalNickNameViewController: PersonalBaseViewController {
    
    // MARK: - Properties
    
    private let viewModel = PersonalViewModel()
    public var nickName: String?
    private var cancellables = Set<AnyCancellable>()
    
    // UI Elements
    private let saveButton = UIButton()
    private let textBgView = UIView()
    private let textField = UITextField()
    private let tipTextLabel = UILabel()
    private let characterCountLabel = UILabel()
    
    // Constants
    private let maxNicknameLength = 20
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupKeyboardHandling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        self.view.backgroundColor = .white
        customTitle.text = "修改昵称"
        
        // Save Button
        saveButton.setTitle("保存", for: .normal)
        saveButton.setTitleColor(UIColor(str: "#FE6A00"), for: .normal)
        saveButton.setTitleColor(UIColor(str: "#FFE0B9"), for: .disabled)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveButton.addTarget(self, action: #selector(saveClick), for: .touchUpInside)
        saveButton.isEnabled = false
        customNavView.addSubview(saveButton)
        
        // Background View
        textBgView.backgroundColor = UIColor(str: "#F2F3F4")
        textBgView.layer.cornerRadius = 8
        textBgView.layer.masksToBounds = true
        view.addSubview(textBgView)
        
        // Text Field
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.delegate = self
        textField.placeholder = "请输入昵称"
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.textColor = UIColor(str: "#333333")
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // Set initial text if available
        if let nickName = nickName, nickName != "未设置" && !nickName.isEmpty {
            textField.text = nickName
        }
        textBgView.addSubview(textField)
        
        // Tip Label
        tipTextLabel.text = "最长20个字符"
        tipTextLabel.textColor = UIColor(str: "#84888C")
        tipTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        view.addSubview(tipTextLabel)
        
        // Character Count Label
//        characterCountLabel.text = "0/\(maxNicknameLength)"
//        characterCountLabel.textColor = UIColor(str: "#84888C")
//        characterCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
//        characterCountLabel.textAlignment = .right
//        view.addSubview(characterCountLabel)
        
        setConstraints()
        updateCharacterCount()
        updateSaveButtonState()
    }
    
    private func setConstraints() {
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        textBgView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        tipTextLabel.translatesAutoresizingMaskIntoConstraints = false
//        characterCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.centerYAnchor.constraint(equalTo: customTitle.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: customNavView.trailingAnchor, constant: -16),
            saveButton.widthAnchor.constraint(equalToConstant: 60),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            
            textBgView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            textBgView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textBgView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textBgView.heightAnchor.constraint(equalToConstant: 48),
            
            textField.topAnchor.constraint(equalTo: textBgView.topAnchor, constant: 12),
            textField.leadingAnchor.constraint(equalTo: textBgView.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: textBgView.trailingAnchor, constant: -12),
            textField.bottomAnchor.constraint(equalTo: textBgView.bottomAnchor, constant: -12),
            
            tipTextLabel.topAnchor.constraint(equalTo: textBgView.bottomAnchor, constant: 8),
            tipTextLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
//            characterCountLabel.topAnchor.constraint(equalTo: textBgView.bottomAnchor, constant: 8),
//            characterCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
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
    }
    
    // MARK: - Helper Methods
    
    private func updateCharacterCount() {
        let count = textField.text?.count ?? 0
        characterCountLabel.text = "\(count)/\(maxNicknameLength)"
        
        // Update color based on count
        if count > maxNicknameLength {
            characterCountLabel.textColor = .systemRed
            tipTextLabel.textColor = .systemRed
            tipTextLabel.text = "昵称长度不能超过\(maxNicknameLength)个字符"
        } else {
            characterCountLabel.textColor = UIColor(str: "#84888C")
            tipTextLabel.textColor = UIColor(str: "#84888C")
            tipTextLabel.text = "最长\(maxNicknameLength)个字符"
        }
    }
    
    private func updateSaveButtonState() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            saveButton.isEnabled = false
            return
        }
        
        let isValid = !text.isEmpty &&
                     text.count <= maxNicknameLength &&
                     text != nickName  // Only enable if different from original
        
        saveButton.isEnabled = isValid
    }
    
    private func validateNickname(_ nickname: String) -> Bool {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check empty
        if trimmedNickname.isEmpty {
            view.sw_showWarningToast("昵称不能为空")
            return false
        }
        
        // Check length
        if trimmedNickname.count > maxNicknameLength {
            view.sw_showWarningToast("昵称长度不能超过\(maxNicknameLength)个字符")
            return false
        }
        
        // Check if same as original
        if trimmedNickname == nickName {
            view.sw_showWarningToast("昵称未修改")
            return false
        }
        
        // Additional validation (optional)
        // You can add more validation rules here
        
        return true
    }
    
    private func handleKeyboardNotification(_ notification: Notification, isShowing: Bool) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
            return
        }
        
        // You can adjust view layout based on keyboard if needed
        // For example, if you have scrollable content
    }
    
    // MARK: - Actions
    
    @objc private func saveClick() {
        guard let nickname = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              validateNickname(nickname) else {
            return
        }
        
        dismissKeyboard()
        saveButton.isEnabled = false
        
        // Show loading state
        view.sw_showLoading()
        
        viewModel.updateNickName(nickName: nickname)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.view.sw_hideLoading()
                
                if case .failure(let error) = completion {
                    self?.handleUpdateError(error)
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.view.sw_showSuccessToast("修改昵称成功")
                    
                    // Notify other parts of the app if needed
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NicknameUpdated"),
                        object: nil,
                        userInfo: ["nickname": nickname]
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.navigationController?.popViewController(animated: true)
                    }
                } else {
                    self?.view.sw_showWarningToast("修改昵称失败")
                    self?.updateSaveButtonState()
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        updateCharacterCount()
        updateSaveButtonState()
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
            view.sw_showWarningToast("修改昵称失败")
        }
        
        updateSaveButtonState()
    }
}

// MARK: - UITextFieldDelegate

extension PersonalNickNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Get current text
        let currentText = textField.text ?? ""
        
        // Attempt to read the range they are trying to change
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        
        // Add new text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // Check if exceeds max length
        return updatedText.count <= maxNicknameLength
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if saveButton.isEnabled {
            saveClick()
        } else {
            dismissKeyboard()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Optional: Add visual feedback when editing begins
        textBgView.layer.borderWidth = 1
        textBgView.layer.borderColor = UIColor(str: "#FFA500").cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Remove visual feedback when editing ends
        textBgView.layer.borderWidth = 0
    }
}

// MARK: - UIScrollViewDelegate (if your base view controller is scrollable)

extension PersonalNickNameViewController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismissKeyboard()
    }
}
