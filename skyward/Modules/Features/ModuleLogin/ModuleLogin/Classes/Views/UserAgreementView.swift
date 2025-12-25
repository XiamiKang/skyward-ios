//
//  UserAgreementViewDelegate.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//


import UIKit

protocol UserAgreementViewDelegate: AnyObject {
    func userAgreementViewDidTapCheckbox(_ view: UserAgreementView, isSelected: Bool)
    func userAgreementViewDidTapAgreement(_ view: UserAgreementView, type: AgreementType)
}

enum AgreementType {
    case service
    case privacy
}

class UserAgreementView: UIView {
    
    // MARK: - UI Components
    private let checkButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(LoginModule.image(named: "unselected"), for: .normal)
        button.setImage(LoginModule.image(named: "selected"), for: .selected)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    private let agreementLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hex: "#666666")
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()
    
    // MARK: - Properties
    weak var delegate: UserAgreementViewDelegate?
    
    var isSelected: Bool {
        get { checkButton.isSelected }
        set { checkButton.isSelected = newValue }
    }
    
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
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(checkButton)
        addSubview(agreementLabel)
        
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            checkButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkButton.widthAnchor.constraint(equalToConstant: 20),
            checkButton.heightAnchor.constraint(equalToConstant: 20),
            
            agreementLabel.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: 4),
            agreementLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            agreementLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            agreementLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupAgreementText()
    }
    
    private func setupAgreementText() {
        let fullText = "我已阅读并同意《用户服务协议》与《隐私政策》"
        let attributedString = NSMutableAttributedString(string: fullText)
        
        // 设置整体样式
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: fullText.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor(hex: "#84888C"), range: NSRange(location: 0, length: fullText.count))
        
        // 设置《用户服务协议》为可点击样式
        let serviceRange = (fullText as NSString).range(of: "《用户服务协议》")
        attributedString.addAttribute(.foregroundColor, value: defaultBlackColor, range: serviceRange)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: serviceRange)
        
        // 设置《隐私政策》为可点击样式
        let privacyRange = (fullText as NSString).range(of: "《隐私政策》")
        attributedString.addAttribute(.foregroundColor, value: defaultBlackColor, range: privacyRange)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: privacyRange)
        
        agreementLabel.attributedText = attributedString
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        agreementLabel.addGestureRecognizer(tapGesture)
    }
    
    private func setupActions() {
        checkButton.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func checkButtonTapped() {
        checkButton.isSelected.toggle()
        delegate?.userAgreementViewDidTapCheckbox(self, isSelected: checkButton.isSelected)
    }
    
    @objc private func handleLabelTap(_ gesture: UITapGestureRecognizer) {
        let label = agreementLabel
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        
        let locationOfTouchInLabel = gesture.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (label.bounds.size.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (label.bounds.size.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )
        
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        
        let characterIndex = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        let fullText = "我已阅读并同意《用户服务协议》与《隐私政策》"
        
        // 检查点击的是否是《用户服务协议》
        let serviceRange = (fullText as NSString).range(of: "《用户服务协议》")
        if NSLocationInRange(characterIndex, serviceRange) {
            delegate?.userAgreementViewDidTapAgreement(self, type: .service)
            return
        }
        
        // 检查点击的是否是《隐私政策》
        let privacyRange = (fullText as NSString).range(of: "《隐私政策》")
        if NSLocationInRange(characterIndex, privacyRange) {
            delegate?.userAgreementViewDidTapAgreement(self, type: .privacy)
            return
        }
        
        // 点击其他区域切换勾选状态
        checkButtonTapped()
    }
    
    // MARK: - Public Methods
    func setSelected(_ selected: Bool, animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.checkButton.isSelected = selected
            }
        } else {
            checkButton.isSelected = selected
        }
    }
}
