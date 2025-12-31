//
//  ProDeviceCell.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit

class BindProDeviceCell: UITableViewCell {
    static let identifier = "BindProDeviceCell"
    
    // MARK: - UI Components
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        label.numberOfLines = 1
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.masksToBounds = true
        iv.layer.cornerRadius = 16
        iv.contentMode = .scaleAspectFill
        iv.isHidden = true
        return iv
    }()
    
    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = PersonalModule.image(named: "cell_suffix")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(arrowImageView)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
//            nameLabel.trailingAnchor.constraint(equalTo: contentLabel.leadingAnchor, constant: -16),
            
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -5),
            
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -5),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        // 设置单元格样式
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    // MARK: - Configuration
    func configure(with settingData: SettingData) {
        // cell名称
        nameLabel.text = settingData.titleStr
        // cell内容
        contentLabel.text = settingData.contentStr
        
        arrowImageView.isHidden = !settingData.canChange
    }
    
    func settingConfigure(with settingData: SettingData) {
        nameLabel.text = settingData.titleStr
        contentLabel.isHidden = !settingData.canChange
        contentLabel.text = settingData.contentStr
        avatarImageView.isHidden = settingData.canChange
        if let avatarUrl = URL(string: settingData.contentStr) {
            avatarImageView.sd_setImage(with: avatarUrl, placeholderImage: PersonalModule.image(named: "my_avatar"))
        }else {
            avatarImageView.image = PersonalModule.image(named: "my_avatar")
        }
        arrowImageView.isHidden = false
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        contentLabel.text = nil
    }
}
