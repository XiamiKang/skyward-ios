//
//  DevieceSettingCell.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/19.
//

import UIKit
import CoreBluetooth

class DevieceSettingCell: UITableViewCell {
    static let identifier = "DevieceSettingCell"
    
    // MARK: - UI Components
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = PersonalModule.image(named: "default_arrow")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    // MARK: - Constraints
    private var contentLabelTrailingConstraint: NSLayoutConstraint!
    private var contentLabelTrailingToArrowConstraint: NSLayoutConstraint!
    private var contentLabelTrailingToContentViewConstraint: NSLayoutConstraint!
    
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
        contentView.addSubview(arrowImageView)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentLabel.leadingAnchor, constant: -16),
            
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -5),
            
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.widthAnchor.constraint(equalToConstant: 16),
            arrowImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
        
        // 创建两个可选的约束
        contentLabelTrailingToArrowConstraint = contentLabel.trailingAnchor.constraint(
            equalTo: arrowImageView.leadingAnchor,
            constant: -5
        )
        
        contentLabelTrailingToContentViewConstraint = contentLabel.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -16
        )
        
        // 初始设置为约束到箭头
        contentLabelTrailingToArrowConstraint.isActive = true
        
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
        
        // 更新约束
        if settingData.canChange {
            arrowImageView.isHidden = false
            contentLabelTrailingToArrowConstraint.isActive = true
            contentLabelTrailingToContentViewConstraint.isActive = false
        } else {
            arrowImageView.isHidden = true
            contentLabelTrailingToArrowConstraint.isActive = false
            contentLabelTrailingToContentViewConstraint.isActive = true
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        contentLabel.text = nil
    }
}
