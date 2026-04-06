//
//  LocationMessageCell.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/03/26.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SDWebImage

class LocationMessageCell: MessageCell {
    
    private static let paragraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        return paragraphStyle
    }()
    
    var onLocationTapHandler: (() -> Void)?

    // MARK: - Location Message UI Components

    private let locationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = MessageModule.image(named: "message_location")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let addressNameLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        return label
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.secondaryColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        bubbleView.addSubview(locationIcon)
        bubbleView.addSubview(addressLabel)
        bubbleView.addSubview(addressNameLabel)

        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLocationTap))
        addressNameLabel.addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    override func configure(message: Message) {
        super.configure(message: message)
        
        let location = message.location

        // 设置地址并添加下划线
        if let addressName = location?.addressName, !addressName.isEmpty {
            let attributedString = NSMutableAttributedString(string: addressName, attributes: [.paragraphStyle: LocationMessageCell.paragraphStyle])
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: addressName.count))
            addressNameLabel.attributedText = attributedString
        } else {
            // 使用经纬度生成地址
            if let lon = location?.longitude?.convertToDMSString(isLongitude: true), let lat = location?.latitude?.convertToDMSString(isLongitude: false) {
                let attributedString = NSMutableAttributedString(string: "\(lon), \(lat)", attributes: [.paragraphStyle: LocationMessageCell.paragraphStyle])
                attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributedString.length))
                addressNameLabel.attributedText = attributedString
            }
        }

        addressLabel.text = location?.address
        
        let isSelf = message.sender?.id == UserManager.shared.userId
        if isSelf {
            layoutSent()
        } else {
            layoutReceived()
        }

    }

    // MARK: - Layout
    
    override func layoutSent() {
        super.layoutSent()
        layoutContent()
    }
    
    override func layoutReceived() {
        super.layoutReceived()
        layoutContent()
    }
    
    func layoutContent() {
        let hasAddress = addressLabel.text?.isEmpty == false
        
        // 定位图标
        locationIcon.snp.remakeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(20))
            make.top.equalToSuperview().inset(swAdaptedValue(10))
            make.left.equalToSuperview().inset(swAdaptedValue(12))
        }
        
        if hasAddress {
            // 地址名标签
            addressNameLabel.snp.remakeConstraints { make in
                make.width.lessThanOrEqualTo(swAdaptedValue(191))
                make.top.equalToSuperview().inset(swAdaptedValue(8))
                make.left.equalTo(locationIcon.snp.right).offset(swAdaptedValue(4))
                make.right.equalToSuperview().inset(swAdaptedValue(12))
            }
            // 地址标签
            addressLabel.snp.remakeConstraints { make in
                make.height.greaterThanOrEqualTo(swAdaptedValue(17))
                make.left.right.equalTo(addressNameLabel)
                make.top.equalTo(addressNameLabel.snp.bottom).offset(swAdaptedValue(4))
                make.bottom.equalToSuperview().inset(swAdaptedValue(8))
            }
        } else {
            // 地址名标签
            addressNameLabel.snp.remakeConstraints { make in
                make.width.lessThanOrEqualTo(swAdaptedValue(191))
                make.top.equalToSuperview().inset(swAdaptedValue(8))
                make.left.equalTo(locationIcon.snp.right).offset(swAdaptedValue(4))
                make.right.equalToSuperview().inset(swAdaptedValue(12))
                
                make.bottom.equalToSuperview().inset(swAdaptedValue(8))
            }
            // 地址标签
            addressLabel.snp.removeConstraints()
        }
    }

    // MARK: - Actions

    @objc private func handleLocationTap() {
        onLocationTapHandler?()
    }

    // MARK: - Reset

    override func prepareForReuse() {
        super.prepareForReuse()

        // 清理文本内容
        addressLabel.text = nil
        addressNameLabel.attributedText = nil
        addressNameLabel.text = "位置信息"

        // 移除所有约束，避免复用时的约束冲突
        addressNameLabel.snp.removeConstraints()
        addressLabel.snp.removeConstraints()
        locationIcon.snp.removeConstraints()
    }
}
