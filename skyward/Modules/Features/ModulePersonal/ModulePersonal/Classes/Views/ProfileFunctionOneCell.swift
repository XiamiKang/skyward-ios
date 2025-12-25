//
//  FunctionTableViewCell.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit
import SWKit

// MARK: - 功能列表Cell
class ProfileFunctionOneCell: UITableViewCell {
    
    static let identifier = "ProfileFunctionOneCell"
    
    // MARK: - UI组件
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = PersonalModule.image(named: "profile_cell_sosPhone")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "紧急救援服务"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray    //#84888C
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "cell_suffix")
        return imageView
    }()
    
    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        self.selectionStyle = .none
        
        if let phone = UserManager.shared.emergencyContact?.phone {
            infoLabel.text = phone.hidePhoneNumber()
        }else {
            infoLabel.text = "未设置"
        }
        
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 12),
            
            infoLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            infoLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func changeInfoLabel(_ data: EmergencyInfoData?) {
        if let phone = data?.phone {
            infoLabel.text = phone.hidePhoneNumber()
            infoLabel.textColor = .black
        }else {
            infoLabel.text = "未设置"
            infoLabel.textColor = .systemGray
        }
    }
    
    
}

extension String {
    /// 隐藏电话号码中间4位
    func hidePhoneNumber() -> String {
        // 移除所有非数字字符
        let phoneNumber = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // 检查是否为有效手机号（11位）
        guard phoneNumber.count == 11 else {
            return self // 如果不是11位，返回原字符串
        }
        
        // 格式：前3位 + 4个星号 + 后4位
        let startIndex = phoneNumber.startIndex
        let prefix = phoneNumber.prefix(3)
        let suffix = phoneNumber.suffix(4)
        
        return "\(prefix)****\(suffix)"
    }
}
