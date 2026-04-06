//
//  ConversationCell.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import SWKit
import SWTheme

class ConversationCell: BaseCell {
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView(image: MessageModule.image(named: "avatar_group"))
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.cornerRadius = swAdaptedValue(48) * 0.5
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeManager.medium16Font
        label.textColor = ThemeManager.current.titleColor
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.placeholderColor
        label.textAlignment = .right
        return label
    }()
    
    private var hub: BadgeHub?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(timeLabel)
        
        hub = BadgeHub(view: contentView)
        hub?.setCircleAtFrame(CGRect(x: ScreenUtil.screenWidth - 2*Layout.hMargin, y: swAdaptedValue(20), width: swAdaptedValue(16), height: swAdaptedValue(16)))
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(48))
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(24))
            make.left.equalTo(avatarImageView.snp.right).offset(Layout.hInset)
            make.top.equalTo(avatarImageView.snp.top).offset(swAdaptedValue(1))
        }
        
        contentLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.left.equalTo(titleLabel)
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-swAdaptedValue(1))
        }
        
        timeLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.left.equalTo(contentLabel.snp.right).offset(4)
            make.right.equalToSuperview().inset(Layout.hMargin)
            make.bottom.equalTo(avatarImageView.snp.bottom).offset(-swAdaptedValue(1))
        }
        
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    func configure(with conversation: Conversation) {
        
        if let title = conversation.name {
            titleLabel.text = title
        } else {
            titleLabel.text = nil
        }
        
        let latestMessage = conversation.latestMessage
        
        if let content = latestMessage?.displayText(), !content.isEmpty {
            contentLabel.text = content
            contentLabel.isHidden = false
        } else {
            contentLabel.text = nil
            contentLabel.isHidden = true
        }
        
        if let time = latestMessage?.sendTimeTimestamp {
            timeLabel.isHidden = false
            timeLabel.text = DateFormatter.fullPretty.string(from: Date(timeIntervalSince1970: Double(time) / 1000))
        } else {
            timeLabel.isHidden = true
            timeLabel.text = nil
        }
        
        if contentLabel.isHidden, timeLabel.isHidden {
            titleLabel.snp.updateConstraints { make in
                make.top.equalTo(avatarImageView.snp.top).offset(swAdaptedValue(12))
            }
        } else {
            titleLabel.snp.updateConstraints { make in
                make.top.equalTo(avatarImageView.snp.top).offset(swAdaptedValue(1))
            }
        }
        
        if let unreadCount = conversation.unreadCount, unreadCount > 0 {
            hub?.setCount(unreadCount)
        } else {
            hub?.hideCount()
        }
    }
}

