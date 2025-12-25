//
//  TeamListCell.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

// MARK: - 团队列表Cell
class TeamListCell: BaseCell {
    
    // MARK: - UI Components
    
    /// 团队头像
    private let teamAvatarImageView: UIImageView = {
        let imageView = UIImageView(image: TeamModule.image(named: "team_group_avatar"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = swAdaptedValue(30)
        return imageView
    }()
    
    /// 团队名称
    private let teamNameLabel: UILabel = {
        let label = UILabel()
        label.text = "北极12月出行（27）"
        label.font = .pingFangFontMedium(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 1
        return label
    }()
    
    /// 团队描述
    private let teamDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "队长：欢迎进群哈哈哈哈..."
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 1
        return label
    }()
    
    /// 分隔线
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeManager.current.mediumGrayBGColor
        return view
    }()
    
    /// 红点
    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeManager.current.errorColor
        view.cornerRadius = 4
        return view
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.backgroundColor = .white
        
        contentView.addSubview(teamAvatarImageView)
        contentView.addSubview(teamNameLabel)
        contentView.addSubview(teamDescriptionLabel)
        contentView.addSubview(separatorView)
        contentView.addSubview(badgeView)
    }
    
    private func setupConstraints() {
        teamAvatarImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(16)
            $0.width.height.equalTo(swAdaptedValue(60))
            $0.bottom.equalToSuperview().offset(-16).priority(999)
        }
        
        teamNameLabel.snp.makeConstraints {
            $0.left.equalTo(teamAvatarImageView.snp.right).offset(12)
            $0.top.equalToSuperview().offset(16)
            $0.right.lessThanOrEqualToSuperview().offset(-16 - 8)
        }
        
        teamDescriptionLabel.snp.makeConstraints {
            $0.left.equalTo(teamNameLabel)
            $0.top.equalTo(teamNameLabel.snp.bottom).offset(8)
            $0.right.equalToSuperview().offset(-16)
            $0.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        
        separatorView.snp.makeConstraints {
            $0.left.equalTo(teamNameLabel)
            $0.right.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        
        badgeView.snp.makeConstraints{
            $0.width.height.equalTo(8)
            $0.left.equalTo(teamNameLabel.snp.right).offset(Layout.hSpacing)
            $0.top.equalTo(teamNameLabel).offset(5)
        }
    }
    
    // MARK: - Configuration
    func configure(with conv: Conversation) {
        teamNameLabel.text = conv.name ?? "" + "(\(conv.teamSize ?? 0)"
        if let senderName = conv.latestMessage?.senderName, let content = conv.latestMessage?.content {
            teamDescriptionLabel.text = senderName + ":" + content
        } else {
            teamDescriptionLabel.text = conv.latestMessage?.content
        }
        
        teamAvatarImageView.image = TeamModule.image(named: "team_group_avatar")
        if let unreadCount = conv.unreadCount, unreadCount > 0 {
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        teamAvatarImageView.image = nil
        teamNameLabel.text = nil
        teamDescriptionLabel.text = nil
        badgeView.isHidden = true
    }
}

