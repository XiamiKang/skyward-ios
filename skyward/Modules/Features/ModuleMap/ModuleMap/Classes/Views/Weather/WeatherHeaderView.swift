//
//  SectionHeaderView.swift
//  Pods
//
//  Created by TXTS on 2025/12/8.
//

import UIKit

class WeatherHeaderView: UITableViewHeaderFooterView {
    
    let locationLabel = UILabel()
    let addressLabel = UILabel()
    let closeButton = UIButton(type: .custom)
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        // 添加底部阴影或边框，增强悬停效果
//        contentView.layer.shadowColor = UIColor.black.cgColor
//        contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
//        contentView.layer.shadowRadius = 2
//        contentView.layer.shadowOpacity = 0.1
        
        // 位置信息
        locationLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        locationLabel.textColor = .black
        contentView.addSubview(locationLabel)
        
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = .systemGray
        contentView.addSubview(addressLabel)
        
        // 关闭按钮
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        contentView.addSubview(closeButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            addressLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 5),
            addressLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            closeButton.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func configure(title: String, subtitle: String) {
        locationLabel.text = title
        addressLabel.text = subtitle
    }
}
