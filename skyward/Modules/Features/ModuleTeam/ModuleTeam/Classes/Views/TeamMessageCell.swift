//
//  TeamMessageCell.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import TXKit
import SWTheme
import SnapKit
import SDWebImage

class TeamMessageCell: BaseCell {
    
    private let bubbleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.5)
        view.layer.cornerRadius = swAdaptedValue(14)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = swAdaptedValue(10)
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        label.font = UIFont.pingFangFontMedium(ofSize: 14)
        return label
    }()
    
    // 存储messageLabel的leading约束，用于动态调整
    private var messageLabelLeadingConstraint: NSLayoutConstraint?
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(bubbleContainerView)
        bubbleContainerView.addSubview(avatarImageView)
        bubbleContainerView.addSubview(messageLabel)
        
        bubbleContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().inset(0)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(20))
            make.top.left.equalToSuperview().inset(4)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.left.equalToSuperview().inset(4 + swAdaptedValue(20) + 4)
            make.right.equalToSuperview().inset(8)
        }
    }
    
    func configure(with message: Message) {
        // background color
        switch message.messageType {
        case .sos:
            bubbleContainerView.backgroundColor = ThemeManager.current.errorColor
        case .safety:
            bubbleContainerView.backgroundColor = ThemeManager.current.successColor
        case .location:
            bubbleContainerView.backgroundColor = UIColor(str: "#007AFF")
        default:
            bubbleContainerView.backgroundColor = .black.withAlphaComponent(0.5)
        }
        
        // other
        switch message.messageType {
        case .system:
            avatarImageView.isHidden = true
            messageLabel.text = message.content
            messageLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(swAdaptedValue(8))
            }
            
        default:
            avatarImageView.isHidden = false
            avatarImageView.sd_setImage(with: URL(string: message.sender?.avatar ?? ""), placeholderImage: TeamModule.image(named: "team_default_avatar"))
            messageLabel.text = (message.sender?.nickname ?? "") + ": " + (message.content ?? "")
            messageLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(4 + swAdaptedValue(20) + 4)
            }
        }
    }
    
}
