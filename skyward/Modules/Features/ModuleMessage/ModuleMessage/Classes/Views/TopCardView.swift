//
//  TopCardView.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import SWTheme
import SWKit
import SnapKit

class TopCardView: UIView {
    
    var onActionCallback: (() -> Void)?
    
    enum TopCardType {
        case sos
        case safety
    }
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeManager.bold16Font
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bottomButton: UIButton = {
        let  button = UIButton()
        button.layer.cornerRadius = 6
        return button
    }()
    
    // MARK: - 初始化
    
    init(frame: CGRect, type: TopCardType) {
        super.init(frame: frame)
        
        setupViews()
        setupConstraints()
        
        var title = "SOS报警"
        var icon = "message_sos_icon"
        var subtitle = "自动发送给紧急联系人"
        var btnTitle = "长按SOS报警"
        var btnBGColor = ThemeManager.current.errorColor
        if type == .safety {
            title = "报平安"
            icon = "message_safety_icon"
            subtitle = "自动发送给紧急联系人"
            btnTitle = "报平安"
            btnBGColor = ThemeManager.current.successColor
            
            bottomButton.addTarget(self, action: #selector(reportSafetyTapped), for: .touchUpInside)
        } else {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressSOSTapped))
            bottomButton.addGestureRecognizer(longPress)
        }
        iconImageView.image = MessageModule.image(named: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        bottomButton.setTitle(btnTitle, for: .normal)
        bottomButton.backgroundColor = btnBGColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 私有方法
    
    private func setupViews() {
        backgroundColor = ThemeManager.current.mediumGrayBGColor
        layer.cornerRadius = CornerRadius.medium.rawValue
        clipsToBounds = true
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(bottomButton)
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.hInset)
            make.top.equalToSuperview().inset(Layout.vMargin)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(4)
            make.trailing.equalToSuperview().inset(4)
            make.centerY.equalTo(iconImageView)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.height.equalTo(17)
            make.leading.equalToSuperview().inset(Layout.hInset)
            make.top.equalTo(iconImageView.snp.bottom).offset(4)
        }
        
        bottomButton.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(Layout.hInset)
        }
    }
    
    @objc private func reportSafetyTapped() {
        print("报平安点击")
        onActionCallback?()
    }
    
    @objc private func longPressSOSTapped(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            print("开始长按 SOS 报警")
        } else if gesture.state == .ended {
            print("结束长按 SOS 报警")
            onActionCallback?()
        }
    }
}

