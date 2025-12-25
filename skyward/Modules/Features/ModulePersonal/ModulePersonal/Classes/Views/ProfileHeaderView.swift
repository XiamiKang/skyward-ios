//
//  ProfileHeaderView.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit
import SWKit
import SDWebImage

// MARK: - 个人资料头部视图
class ProfileHeaderView: UITableViewHeaderFooterView {
    
    static let identifier = "ProfileHeaderView"
    
    var editUserInfoAction: (() -> Void)?
    
    // MARK: - UI组件
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = .systemGray5
        imageView.tintColor = .systemGray
        imageView.image = PersonalModule.image(named: "my_avatar")
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor(str: "#070808")
        label.text = "行者"
        return label
    }()
    
    private let signatureLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#303236")
        label.text = "暂未填写签名"
        return label
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("编辑资料", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.backgroundColor = UIColor(str: "#FE6A00")
        button.layer.cornerRadius = 4
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        return button
    }()
    
    // MARK: - 初始化
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI设置
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(signatureLabel)
        contentView.addSubview(editButton)
        
        // 头像的约束
        NSLayoutConstraint.activate([
            avatarImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarImageView.widthAnchor.constraint(equalToConstant: 60),
            avatarImageView.heightAnchor.constraint(equalToConstant: 60),
        ])
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -20),
        ])
        
        // 签名标签的约束
        NSLayoutConstraint.activate([
            signatureLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            signatureLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            signatureLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
        ])
        
        // 编辑资料按钮的约束
        NSLayoutConstraint.activate([
            editButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            editButton.widthAnchor.constraint(equalToConstant: 80),
            editButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - 配置数据
    func configure(profile: UserInfoData?) {
        
        editButton.isHidden = false
        signatureLabel.isHidden = false
        nameLabel.textColor = .label
        
        if let avatarUrl = URL(string: profile?.avatar ?? "") {
            avatarImageView.sd_setImage(with: avatarUrl, placeholderImage: PersonalModule.image(named: "my_avatar"))
        }
        nameLabel.text = profile?.nickname ?? ""
        signatureLabel.text = profile?.personalitySign ?? "暂未填写签名"
    }
    
    @objc private func loginButtonTapped() {
        // 登录按钮点击事件
        print("登录/注册按钮被点击")
        // 这里可以跳转到登录页面
        NotificationCenter.default.post(name: NSNotification.Name("ShowLoginScreen"), object: nil)
    }
    
    @objc private func editButtonTapped() {
        // 编辑资料按钮点击事件
        print("编辑资料按钮被点击")
        editUserInfoAction?()
    }
}
