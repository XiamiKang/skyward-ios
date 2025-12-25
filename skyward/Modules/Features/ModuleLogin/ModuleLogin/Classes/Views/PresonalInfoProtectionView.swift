//
//  PresonalInfoProtectionView.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit
import SnapKit

class PresonalInfoProtectionView: MaskView {
    
    var onUserAgreementTapped: (() -> Void)?
    var onPrivacyPolicyTapped: (() -> Void)?
    var onDisAgreeButtonTapped: (() -> Void)?
    var onAgreeButtonTapped: (() -> Void)?
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "个人信息保护指引"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.init(hex: "#070808")
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        let text = "为更好保障您的个人权益，请您在使用本应用前，仔细阅读《用户服务协议》及《隐私政策》，帮助您了解我们在收集、使用、存储和共享您个人信息的情况以及您享有的相关权利。\n1、您可以通过查看《用户服务协议》来简便快捷地了解我们可能收集、使用的您的个人信息情况；\n2、基于您的明示授权，我们可能调用您的重要设备权限。我们将在首次调用时逐项询问您是否允许使用该权限，您有权拒绝或取消授权；具体权限获取情况详见《隐私政策》；\n3、我们会采取业界先进的安全措施保护您的信息安全；\n4、您可以查询、更正、删除、撤回授权您的个人信息，我们也提供账户注销的渠道。"
        // 创建段落样式
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4 // 行间距
        paragraphStyle.paragraphSpacing = 6 // 段落间距
        paragraphStyle.alignment = .left
        
        // 创建属性字符串
        let attributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor(hex: "#3D3E40"),
                .paragraphStyle: paragraphStyle
            ]
        )
        
        label.attributedText = attributedString
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var agreementTextView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        
        let text = "点击“同意”，视为您已经充分理解并同意《用户服务协议》与《隐私政策》及上述内容。"
        
        // 创建属性字符串
        let attributedString = NSMutableAttributedString(string: text)
        
        // 设置整体样式
        let fullRange = NSRange(location: 0, length: text.count)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: fullRange)
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
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.backgroundColor = UIColor.init(hex: "#F2F3F4")
        button.setTitleColor(UIColor.init(hex: "#070808"), for: .normal)
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let agreeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("同意", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
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
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(agreeButton)
        contentView.addSubview(agreementTextView)
        
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
            make.height.equalTo(564)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        agreementTextView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            
        }
        
        closeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo((303-44)/2)
            make.height.equalTo(40)
        }
        
        agreeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo((303-44)/2)
            make.height.equalTo(40)
        }
        
    }
    
    @objc private func closeButtonTapped() {
        onDisAgreeButtonTapped?()
    }
    
    @objc private func agreeButtonTapped() {
        onAgreeButtonTapped?()
    }
}

extension PresonalInfoProtectionView: UITextViewDelegate {
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
