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
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
        label.numberOfLines = 1
        return label
    }()
    
    private let msgTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(str: "#070808")
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
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
            make.width.height.equalTo(40)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        nextImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(Layout.hSpacing)
            make.right.equalTo(nextImageView.snp.left).offset(-Layout.hSpacing)
            make.bottom.equalToSuperview().inset(10)
        }
        
        msgTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.left.equalTo(iconImageView.snp.right).offset(Layout.hSpacing)
            make.bottom.equalTo(contentLabel.snp.top).offset(-5)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(msgTitleLabel.snp.centerY)
            make.left.equalTo(msgTitleLabel.snp.right).offset(Layout.hSpacing)
        }
        
    }
    
    func configure(with message: HomeNoticeItem) {
        msgTitleLabel.text = message.noticeType.title
        timeLabel.text = convertMillisecondsToDateTime(message.noticeTime ?? Date().timeIntervalSince1970 * 1000)
        if let icon = message.noticeType.icon {
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
    
    func convertMillisecondsToDateTime(_ milliseconds: TimeInterval) -> String {
        // 毫秒转换为秒
        let seconds = milliseconds / 1000
        let date = Date(timeIntervalSince1970: seconds)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        
        return formatter.string(from: date)
    }
}
