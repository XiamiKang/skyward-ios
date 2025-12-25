//
//  NoDevicesViewManager.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit

// MARK: - 无设备界面管理器
class NoDevicesViewManager: NSObject {
    private let noFindImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_nofind")
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        label.text = "没有扫描到设备"
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor(hex: "#84888C")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "请确保设备处于以下状态"
        return label
    }()
    
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(hex: "#F2F3F4")
        button.setTitle("重新扫描", for: .normal)
        button.setTitleColor(UIColor(hex: "#FE6A00"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        return button
    }()
    
    private let tipsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 80
        return tableView
    }()
    
    private let tipsData: [TipItem] = [
        TipItem(
            icon: "device_mini_open",
            title: "确保设备已开机（按开机键）",
            content: "请排除设备充电时灯亮未开机的情况"
        ),
        TipItem(
            icon: "device_mini_open",
            title: "确保设备在手机附近",
            content: "30CM内最佳"
        )
    ]
    
    var onRetryTapped: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func setup(in container: UIView) {
        container.addSubview(noFindImageView)
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(retryButton)
        container.addSubview(tipsTableView)
        
        NSLayoutConstraint.activate([
            // 无设备图片
            noFindImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 100),
            noFindImageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            noFindImageView.widthAnchor.constraint(equalToConstant: 72),
            noFindImageView.heightAnchor.constraint(equalToConstant: 72),
            
            // 标题
            titleLabel.topAnchor.constraint(equalTo: noFindImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 消息
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            // 重新扫描按钮
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            retryButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.widthAnchor.constraint(equalToConstant: 120),
            
            // 提示列表
            tipsTableView.topAnchor.constraint(equalTo: retryButton.bottomAnchor, constant: 35),
            tipsTableView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            tipsTableView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            tipsTableView.heightAnchor.constraint(equalToConstant: 160) // 2个cell * 80高度
        ])
        
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        
        tipsTableView.delegate = self
        tipsTableView.dataSource = self
        tipsTableView.register(TipTableViewCell.self, forCellReuseIdentifier: "TipTableViewCell")
    }
    
    func removeFromSuperview() {
        noFindImageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        messageLabel.removeFromSuperview()
        retryButton.removeFromSuperview()
        tipsTableView.removeFromSuperview()
    }
    
    @objc private func retryButtonTapped() {
        onRetryTapped?()
    }
}

// MARK: - 提示项数据模型
struct TipItem {
    let icon: String
    let title: String
    let content: String
}

// MARK: - 提示列表Cell
class TipTableViewCell: UITableViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.numberOfLines = 1
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(hex: "#84888C")
        label.numberOfLines = 2
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        
        NSLayoutConstraint.activate([
            // 图标
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // 标题
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 内容
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            contentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    func configure(with tip: TipItem) {
        iconImageView.image = PersonalModule.image(named: tip.icon)
        titleLabel.text = tip.title
        contentLabel.text = tip.content
    }
}

// MARK: - UITableView扩展
extension NoDevicesViewManager: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tipsData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TipTableViewCell", for: indexPath) as? TipTableViewCell else {
            return UITableViewCell()
        }
        
        let tip = tipsData[indexPath.row]
        cell.configure(with: tip)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
