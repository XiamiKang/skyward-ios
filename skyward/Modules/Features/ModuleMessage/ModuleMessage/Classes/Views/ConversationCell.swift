//
//  ConversationCell.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import SWKit
import SWTheme
import SnapKit

class ConversationCell: UITableViewCell {
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = swAdaptedValue(48) * 0.5
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = ThemeManager.regular16Font
        label.textColor = ThemeManager.current.titleColor
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#74777B")
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(48))
            make.left.equalToSuperview().inset(Layout.hInset)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(23))
            make.left.equalToSuperview().offset(swAdaptedValue(72))
            make.top.right.equalToSuperview().inset(Layout.hInset)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(17))
            make.left.equalToSuperview().offset(swAdaptedValue(72))
            make.bottom.right.equalToSuperview().inset(Layout.hInset)
        }
    }
    
    func configure(with conversation: Conversation?) {
        if conversation?.type == .service {
            contentView.backgroundColor = ThemeManager.current.lightGrayBGColor
        } else {
            contentView.backgroundColor = ThemeManager.current.backgroundColor
        }
        
        if let icon = conversation?.avatarUrl, !icon.isEmpty {
            avatarImageView.image = MessageModule.image(named: icon)
        } else {
            avatarImageView.image = MessageModule.image(named: "avatar_default")
        }
        
        if let title = conversation?.title {
            titleLabel.text = title
        } else {
            titleLabel.text = nil
        }
        
        if let content = conversation?.lastMessage?.content, !content.isEmpty {
            contentLabel.text = content
            contentLabel.isHidden = false
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(Layout.hInset)
            }
        } else {
            contentLabel.text = nil
            contentLabel.isHidden = true
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(swAdaptedValue(24.5))
            }
            
        }
    }
}

