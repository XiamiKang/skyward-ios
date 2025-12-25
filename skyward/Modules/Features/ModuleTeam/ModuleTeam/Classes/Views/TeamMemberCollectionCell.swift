//
//  TeamMemberCollectionCell.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SDWebImage

// MARK: - 团队成员集合单元格
enum TeamMemberCollectionCellType {
    case member(Member)  // 普通成员
    case invite              // 邀请按钮
    case remove              // 移除按钮
}

class TeamMemberCollectionCell: UICollectionViewCell {
    // MARK: - UI Components
    /// 头像视图
    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = swAdaptedValue(24)
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = ThemeManager.current.lightGrayBGColor
        return imageView
    }()
    
    /// 昵称标签
    private lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    /// 队长标识文字
    private lazy var captainLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = ThemeManager.current.mainColor
        label.layer.cornerRadius = swAdaptedValue(8)
        label.layer.masksToBounds = true
        label.isHidden = true
        label.font = .pingFangFontBold(ofSize: 10)
        label.textColor = .white
        label.text = "队长"
        label.textAlignment = .center
        return label
    }()
    
    /// 邀请图标
    private lazy var inviteIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = TeamModule.image(named: "team_member_add")
        imageView.isHidden = true
        return imageView
    }()
    
    /// 移除图标
    private lazy var removeIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = TeamModule.image(named: "team_member_subtract")
        imageView.isHidden = true
        return imageView
    }()
    
    // MARK: - Properties
    public var cellType: TeamMemberCollectionCellType? {
        didSet {
            configureCellType()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(avatarView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(captainLabel)
        contentView.addSubview(inviteIcon)
        contentView.addSubview(removeIcon)
    }
    
    private func setupConstraints() {
        avatarView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.height.equalTo(swAdaptedValue(48))
        }
        
        nicknameLabel.snp.makeConstraints {
            $0.top.equalTo(avatarView.snp.bottom).offset(swAdaptedValue(4))
            $0.left.right.equalToSuperview()
            $0.height.equalTo(swAdaptedValue(18))
        }
        
        captainLabel.snp.makeConstraints {
            $0.bottom.equalTo(avatarView)
            $0.centerX.equalTo(avatarView)
            $0.width.equalTo(swAdaptedValue(28))
            $0.height.equalTo(swAdaptedValue(14))
        }
        
        inviteIcon.snp.makeConstraints {
            $0.edges.equalTo(avatarView)
        }
        
        removeIcon.snp.makeConstraints {
            $0.edges.equalTo(avatarView)
        }
    }
    
    // MARK: - Configuration
    private func configureCellType() {
        guard let cellType = cellType else { return }
        
        switch cellType {
        case .member(let member):
            // 配置普通成员
            avatarView.isHidden = false
            nicknameLabel.isHidden = false
            captainLabel.isHidden = member.type == .employee
            inviteIcon.isHidden = true
            removeIcon.isHidden = true
            
            // 设置头像
            avatarView.sd_setImage(with: URL(string: member.avatar ?? ""), placeholderImage: TeamModule.image(named: "team_default_avatar"))
            
            // 设置昵称
            nicknameLabel.text = member.nickname
            
        case .invite:
            // 配置邀请按钮
            avatarView.isHidden = true
            nicknameLabel.isHidden = false
            captainLabel.isHidden = true
            inviteIcon.isHidden = false
            removeIcon.isHidden = true
            
            avatarView.image = nil
            nicknameLabel.text = "邀请"
            
        case .remove:
            // 配置移除按钮
            avatarView.isHidden = true
            nicknameLabel.isHidden = false
            captainLabel.isHidden = true
            inviteIcon.isHidden = true
            removeIcon.isHidden = false
            
            avatarView.image = nil
            nicknameLabel.text = "移除"
        }
    }
    
    // MARK: - Public Methods
    /// 配置单元格
    func configure(with type: TeamMemberCollectionCellType) {
        self.cellType = type
    }
    
    /// 重置单元格
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = nil
        nicknameLabel.text = nil
        captainLabel.isHidden = true
        inviteIcon.isHidden = true
        removeIcon.isHidden = true
    }
}

