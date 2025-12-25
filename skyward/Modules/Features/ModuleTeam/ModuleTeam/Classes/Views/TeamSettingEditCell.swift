//
//  TeamSettingEditCell.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SDWebImage

// MARK: - 团队设置编辑单元格
enum TeamSettingEditCellType {
    case text(content: String)  // 文本标题
    case image(url: String?)  // 图片标题
}

class TeamSettingEditCell: BaseCell {
    // MARK: - UI Components
    /// 左侧标题标签
    private lazy var leftTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontMedium(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    /// 右侧图片
    private lazy var rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()
    
    /// 右侧内容标签
    private lazy var rightContentLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()
    
    /// 右侧箭头图标
    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView(image: TeamModule.image(named: "team_arrow_gray"))
        imageView.contentMode = .scaleAspectFit
        return imageView
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
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white
        
        contentView.addSubview(leftTitleLabel)
        contentView.addSubview(rightImageView)
        contentView.addSubview(rightContentLabel)
        contentView.addSubview(arrowImageView)
    }
    
    private func setupConstraints() {
        leftTitleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(Layout.hMargin)
            $0.centerY.equalToSuperview()
        }
        
        rightImageView.snp.makeConstraints {
            $0.width.height.equalTo(swAdaptedValue(32))
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(swAdaptedValue(36))
        }
        
        rightContentLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(swAdaptedValue(36))
        }
        
        arrowImageView.snp.makeConstraints {
            $0.right.equalToSuperview().inset(Layout.hMargin)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(swAdaptedValue(16))
        }
    }
    
    // MARK: - Configuration
    /// 配置单元格
    func configure(with type: TeamSettingEditCellType, title: String?) {
        leftTitleLabel.text = title
        
        // 配置左侧内容
        switch type {
        case .text(let content):
            rightContentLabel.isHidden = false
            rightImageView.isHidden = true
            rightContentLabel.text = content
            
        case .image(let url):
            rightContentLabel.isHidden = true
            rightImageView.isHidden = false
            rightImageView.sd_setImage(with: URL(string: url ?? ""), placeholderImage: TeamModule.image(named: "team_group_avatar"))
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        leftTitleLabel.text = nil
        rightImageView.image = nil
        rightContentLabel.text = nil
    }
}
