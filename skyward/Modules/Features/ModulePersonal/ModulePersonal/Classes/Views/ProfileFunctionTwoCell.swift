//
//  ProfileFunctionOneCell.swift
//  Pods
//
//  Created by TXTS on 2025/12/18.
//


import UIKit
import SWKit

// MARK: - 功能列表Cell
class ProfileFunctionTwoCell: UITableViewCell {
    
    static let identifier = "ProfileFunctionTwoCell"
    
    // MARK: - UI组件
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = PersonalModule.image(named: "profile_cell_device")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "我的卫星装备"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    public var miniImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_mini_noLine")
        return imageView
    }()
    
    public var proImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_pro_noLine")
        return imageView
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
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(miniImageView)
        contentView.addSubview(proImageView)
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
            
            proImageView.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -5),
            proImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            proImageView.widthAnchor.constraint(equalToConstant: 20),
            proImageView.heightAnchor.constraint(equalToConstant: 20),
            
            miniImageView.trailingAnchor.constraint(equalTo: proImageView.leadingAnchor, constant: -5),
            miniImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            miniImageView.widthAnchor.constraint(equalToConstant: 20),
            miniImageView.heightAnchor.constraint(equalToConstant: 20),
            
        ])
    }
    
    func changeDeviceImage() {
        if let _ = BluetoothManager.shared.connectedPeripheral {
            miniImageView.image = PersonalModule.image(named: "device_mini")
        }else {
            miniImageView.image = PersonalModule.image(named: "device_mini_noLine")
        }
        
        if WiFiDeviceManager.shared.isConnected {
            proImageView.image = PersonalModule.image(named: "device_pro")
        }else {
            proImageView.image = PersonalModule.image(named: "device_pro_noLine")
        }
    }
}
