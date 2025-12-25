//
//  TeamMemberCell.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme
import SDWebImage

// MARK: - 团队成员Cell
class TeamMemberCell: BaseCell {
    
    // MARK: - UI Components
    
    /// 成员头像
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = swAdaptedValue(24)
        imageView.image = TeamModule.image(named: "team_default_avatar")
        return imageView
    }()
    
    /// 成员姓名
    public let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontMedium(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 1
        return label
    }()
    
    /// 成员手机号
    private let phoneLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 1
        return label
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
        contentView.backgroundColor = ThemeManager.current.backgroundColor
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(phoneLabel)
    }
    
    private func setupConstraints() {
        avatarImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(swAdaptedValue(16))
            $0.top.equalToSuperview().offset(swAdaptedValue(12))
            $0.width.height.equalTo(swAdaptedValue(48))
            $0.bottom.lessThanOrEqualToSuperview().offset(swAdaptedValue(-12))
        }
        
        nameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarImageView.snp.right).offset(swAdaptedValue(12))
            $0.top.equalTo(avatarImageView.snp.top).offset(swAdaptedValue(4))
            $0.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        phoneLabel.snp.makeConstraints {
            $0.left.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(swAdaptedValue(4))
            $0.right.equalTo(nameLabel)
        }
    }
    
    // MARK: - Configuration
    func configure(with member: Member) {
        nameLabel.text = member.nickname
        phoneLabel.text = "手机号：\(member.phone ?? "")"
        avatarImageView.sd_setImage(with: URL(string: member.avatar ?? ""), placeholderImage: TeamModule.image(named: "team_default_avatar"))
    }
    
    
    // MARK: - Properties
    
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        phoneLabel.text = nil
    }
}


class TeamMemberLoactionCell: TeamMemberCell {
    
    var getLocationHandler: (() -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        getLocationHandler = nil
    }
    
    /// 获取位置按钮
    private let getLocationButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("获取位置", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 14)
        button.backgroundColor = ThemeManager.current.mainColor
        button.layer.cornerRadius = CornerRadius.small.rawValue
        return button
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(getLocationButton)
        getLocationButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(Layout.hInset)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(swAdaptedValue(80))
            $0.height.equalTo(swAdaptedValue(32))
        }
        
        self.nameLabel.snp.updateConstraints {
            $0.right.equalToSuperview().inset(Layout.hMargin + swAdaptedValue(80 + 12))
        }

        getLocationButton.addTarget(self, action: #selector(getLocationButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func getLocationButtonTapped() {
        getLocationHandler?()
    }
}


class TeamMemberRemoveCell: TeamMemberCell {
    
    var onCheckBoxHandler: (() -> Void)?
    
    // MARK: - Over ride
    override func prepareForReuse() {
        super.prepareForReuse()
        onCheckBoxHandler = nil
    }
    
    /// 获取位置按钮
    public let checkBoxButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(TeamModule.image(named: "team_member_normal"), for: .normal)
        button.setBackgroundImage(TeamModule.image(named: "team_member_selected"), for: .selected)
        return button
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(checkBoxButton)
        checkBoxButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(Layout.hInset)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(swAdaptedValue(24))
        }
        
        self.nameLabel.snp.updateConstraints {
            $0.right.equalToSuperview().inset(Layout.hMargin + swAdaptedValue(24 + 12))
        }

        checkBoxButton.addTarget(self, action: #selector(getLocationButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func getLocationButtonTapped() {
        // 触发获取位置事件
        onCheckBoxHandler?()
    }
}
