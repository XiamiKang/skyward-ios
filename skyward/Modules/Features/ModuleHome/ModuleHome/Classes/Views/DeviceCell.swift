//
//  DeviceCell.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/21.
//

import TXKit
import SWKit
import SWTheme

class DeviceCell: BaseCell {
    
    public var iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    public var deviceInfoView: DeviceInfoView = {
        let view = DeviceInfoView()
        return view
    }()
    
    public var rightButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.pingFangFontRegular(ofSize: 14)
    
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Layout.hInset, bottom: 0, trailing: Layout.hInset)
            configuration.background.cornerRadius = CornerRadius.small.rawValue
            button.configuration = configuration
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.hInset, bottom: 0, right: Layout.hInset)
            button.layer.cornerRadius = CornerRadius.small.rawValue
        }
        
        return button
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
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(iconImageView)
        contentView.addSubview(deviceInfoView)
        contentView.addSubview(rightButton)
    }
    
    private func setupConstraints() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        deviceInfoView.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
        
        deviceInfoView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(16))
            make.left.equalTo(iconImageView.snp.right).offset(Layout.hSpacing)
            make.right.lessThanOrEqualTo(rightButton.snp.left).offset(-Layout.hSpacing)
            make.centerY.equalToSuperview()
        }
        
        rightButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(32))
            make.right.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
    }
}

