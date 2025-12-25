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
        label.textColor = UIColor(str: "#74777B")
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(iconImageView)
        contentView.addSubview(contentLabel)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(Layout.hSpacing)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
    
    func configure(with message: HomeNoticeItem) {
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
    }
}
