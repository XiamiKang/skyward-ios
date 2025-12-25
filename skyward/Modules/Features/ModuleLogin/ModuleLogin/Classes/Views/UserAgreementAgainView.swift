//
//  UserAgreementAgainView.swift
//  ModuleLogin
//
//  Created by TXTS on 2025/11/25.
//

import Foundation
import SnapKit

class UserAgreementAgainView: MaskView {
    
    var onUserAgreementTapped: (() -> Void)?
    var onPrivacyPolicyTapped: (() -> Void)?
    var onAgreeButtonTapped: (() -> Void)?
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var agreementTextView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        
        let text = "我已阅读并同意《用户服务协议》与《隐私政策》"
        
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4 // 行间距
        paragraphStyle.alignment = .left
        // 创建属性字符串
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [
                                                             .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                             .foregroundColor: UIColor(hex: "#3D3E40"),
                                                             .paragraphStyle: paragraphStyle
                                                         ])
        
        // 设置整体样式
        let fullRange = NSRange(location: 0, length: text.count)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14, weight: .regular), range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor(hex: "#3D3E40"), range: fullRange)
        
        // 设置用户服务协议样式
        if let userAgreementRange = text.range(of: "《用户服务协议》") {
            let nsRange = NSRange(userAgreementRange, in: text)
            attributedString.addAttribute(.link, value: "userAgreement://", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: nsRange)
        }
        
        // 设置隐私政策样式
        if let privacyPolicyRange = text.range(of: "《隐私政策》") {
            let nsRange = NSRange(privacyPolicyRange, in: text)
            attributedString.addAttribute(.link, value: "privacyPolicy://", range: nsRange)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: nsRange)
        }
        
        textView.attributedText = attributedString
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        return textView
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("不同意", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.init(hex: "#F2F3F4")
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let agreeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("同意", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = UIColor.init(hex: "#FE6A00")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 6
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCustomUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCustomUI()
    }
    
    private func setupCustomUI() {
        
        self.setTapToDismiss(false)
        
        // 添加子视图
        addSubview(contentView)
        contentView.addSubview(agreementTextView)
        contentView.addSubview(closeButton)
        contentView.addSubview(agreeButton)
        
        
        // 设置约束
        setupConstraints()
        
        // 按钮事件
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(303)
            make.height.equalTo(144)
        }
        
        agreementTextView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        closeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo((303 - 44)/2)
            make.height.equalTo(40)
        }
        
        agreeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo((303 - 44)/2)
            make.height.equalTo(40)
        }
        
    }
    
    @objc private func closeButtonTapped() {
        hide()
    }
    
    @objc private func agreeButtonTapped() {
        onAgreeButtonTapped?()
        hide()
    }
}

extension UserAgreementAgainView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "userAgreement" {
            onUserAgreementTapped?()
            return false
        } else if URL.scheme == "privacyPolicy" {
            onPrivacyPolicyTapped?()
            return false
        }
        return true
    }
}

