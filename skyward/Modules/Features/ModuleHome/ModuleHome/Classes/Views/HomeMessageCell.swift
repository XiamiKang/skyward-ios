//
//  HomeMessageCell.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/18.
//

import Foundation
import SWKit
import SWTheme
import SnapKit

class HomeMessageCell: UITableViewCell {
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 14)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 1
        return label
    }()
    
    private let msgTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontMedium(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 1
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 1
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let nextImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = HomeModule.image(named: "home_cell_next")
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(iconImageView)
        contentView.addSubview(msgTitleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(nextImageView)
    }
    
    private func setupConstraints() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        msgTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        nextImageView.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(40))
            make.left.centerY.equalToSuperview()
        }
        
        nextImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(16))
            make.right.centerY.equalToSuperview()
        }
        
        contentLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(swAdaptedValue(20))
            make.left.equalTo(iconImageView.snp.right).offset(Layout.hSpacing)
            make.right.equalTo(nextImageView.snp.left).offset(-Layout.hSpacing)
            make.top.equalTo(msgTitleLabel.snp.bottom).offset(swAdaptedValue(4))
            make.bottom.equalToSuperview().inset(swAdaptedValue(10))
        }
        
        msgTitleLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(22))
            make.top.equalToSuperview().inset(swAdaptedValue(10))
            make.left.equalTo(iconImageView.snp.right).offset(Layout.hSpacing)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(msgTitleLabel)
            make.left.equalTo(msgTitleLabel.snp.right).offset(swAdaptedValue(4))
        }
        
    }
    
    func configure(with message: HomeNoticeItem) {
        msgTitleLabel.text = message.noticeType?.title
        if let noticeTime = message.noticeTimeTimestamp {
            timeLabel.text = DateFormatter.fullPretty.string(from: Date(timeIntervalSince1970: Double(noticeTime) / 1000))
        } else {
            timeLabel.text = nil
        }
        if let icon = message.noticeType?.icon {
            iconImageView.image = HomeModule.image(named: icon)
        } else {
            iconImageView.image = nil
        }
        if let content = message.noticeContent {
            contentLabel.text = content
        } else {
            contentLabel.text = nil
        }
        if message.noticeType == .weather {
            contentLabel.numberOfLines = 2
        }else {
            contentLabel.numberOfLines = 1
        }
    }
}
