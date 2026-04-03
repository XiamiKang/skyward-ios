//
//  MessageCell.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import SWKit
import SWTheme
import SDWebImage

class MessageCell: BaseCell {
    
    var onReSendHandler: (() -> Void)?

    // MARK: - Common UI Components

    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.placeholderColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.cornerRadius = 20
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let bubbleView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = CornerRadius.medium.rawValue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statusButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let statusView = DeviceMessageStatusView()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
        prepareForReuse()
        statusButton.addTarget(self, action: #selector(clickReSend), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(timeLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        contentView.addSubview(statusButton)
        contentView.addSubview(statusView)
    }

    // MARK: - Configure Base Info
    
    func configure(message: Message) {
        // 配置时间
        if let timestamp = message.sendTimeTimestamp {
            timeLabel.text = DateFormatter.fullPretty.string(from: Date(timeIntervalSince1970: Double(timestamp) / 1000))

            let shouldShowTime: Bool
            if let previousTimestamp = message.previousMessageTimestamp {
                let timeInterval = timestamp - previousTimestamp
                shouldShowTime = timeInterval > 300000
            } else {
                shouldShowTime = true
            }
            timeLabel.isHidden = !shouldShowTime
        } else {
            timeLabel.isHidden = true
        }

        // 配置发送者信息
        let isSelf = message.sender?.id == UserManager.shared.userId
        let avatar = message.sender?.avatar ?? (isSelf ? UserManager.shared.userInfo?.avatar : nil)
        let nickname = message.sender?.nickname ?? (isSelf ? UserManager.shared.userInfo?.nickname : nil)
        let phone = message.sender?.phone ?? (isSelf ? UserManager.shared.userInfo?.phone : nil)
        
        if let avatar = avatar {
            avatarImageView.sd_setImage(with: URL(string: avatar), placeholderImage: MessageModule.image(named: "avatar_default"))
        } else {
            avatarImageView.image = MessageModule.image(named: "avatar_default")
        }
        
        if let nickname = nickname {
            if let phone = phone, !phone.isEmpty {
                nameLabel.text = nickname + " (\(phone))"
            } else {
                nameLabel.text = nickname
            }
        } else {
            nameLabel.text = phone
        }

        // 状态处理
        if isSelf {
            if message.offline == true {
                statusView.isHidden = false
                if message.id?.hasPrefix("-") == false {
                    statusView.statusLabel.text = "已收到回执"
                } else {
                    statusView.statusLabel.text = "已发送行者mini"
                }
            } else {
                if message.status == .sending {
                    statusButton.isHidden = false
                    statusButton.setImage(MessageModule.image(named: "message_sending"), for: .normal)
                    startLoadingAnimation()
                } else if message.status == .failed {
                    statusButton.isHidden = false
                    statusButton.setImage(MessageModule.image(named: "message_failed"), for: .normal)
                }
            }
        }
    }

    // MARK: - Layout
    
    func layoutCommnon() {
        // Time Label
        if timeLabel.isHidden {
            timeLabel.snp.removeConstraints()
        } else {
            timeLabel.snp.remakeConstraints { make in
                make.height.equalTo(swAdaptedValue(18))
                make.top.centerX.equalToSuperview()
            }
        }
    }
    
    func layoutSent() {
        layoutCommnon()
        bubbleView.backgroundColor = UIColor(str: "#FFC78B")
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        nameLabel.textAlignment = .right
        
        bubbleView.snp.remakeConstraints { make in
            if timeLabel.isHidden {
                make.top.equalToSuperview().inset(swAdaptedValue(22))
            } else {
                make.top.equalToSuperview().inset(swAdaptedValue(60))
            }
            if statusView.isHidden {
                make.bottom.equalToSuperview().inset(swAdaptedValue(20)).priority(.medium)
            } else {
                make.bottom.equalToSuperview().inset(swAdaptedValue(38)).priority(.medium)
            }
            make.left.greaterThanOrEqualToSuperview().inset(swAdaptedValue(68))
            make.right.equalToSuperview().inset(swAdaptedValue(68))
        }
        
        // Avatar
        avatarImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(40))
            make.centerY.equalTo(bubbleView.snp.top)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }

        // Name Label
        nameLabel.snp.remakeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.bottom.equalTo(bubbleView.snp.top).offset(-swAdaptedValue(4))
            make.right.equalTo(bubbleView)
        }
        
        statusButton.snp.remakeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(32))
            make.centerY.equalTo(bubbleView)
            make.right.equalTo(bubbleView.snp.left)
        }
        
        if statusView.isHidden {
            statusView.snp.removeConstraints()
        } else {
            statusView.snp.remakeConstraints { make in
                make.height.equalTo(swAdaptedValue(14))
                make.top.equalTo(bubbleView.snp.bottom).offset(swAdaptedValue(4))
                make.right.equalTo(bubbleView)
            }
        }
    }
    
    func layoutReceived() {
        layoutCommnon()
        bubbleView.backgroundColor = .white
        bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        nameLabel.textAlignment = .left
        
        bubbleView.snp.remakeConstraints { make in
            if timeLabel.isHidden {
                make.top.equalToSuperview().inset(swAdaptedValue(22))
            } else {
                make.top.equalToSuperview().inset(swAdaptedValue(60))
            }
            make.bottom.equalToSuperview().inset(swAdaptedValue(20)).priority(.medium)

            make.left.equalToSuperview().inset(swAdaptedValue(68))
            make.right.lessThanOrEqualToSuperview().inset(swAdaptedValue(68))
        }
        
        // Avatar
        avatarImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(40))
            make.centerY.equalTo(bubbleView.snp.top)
            make.left.equalToSuperview().inset(Layout.hMargin)
        }

        // Name Label
        nameLabel.snp.remakeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.bottom.equalTo(bubbleView.snp.top).offset(-swAdaptedValue(4))
            make.left.equalTo(bubbleView)
        }
    }

    // MARK: - Reset

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        timeLabel.text = nil
        timeLabel.isHidden = true
        statusButton.isHidden = true
        statusButton.snp.removeConstraints()
        stopLoadingAnimation()
        statusView.isHidden = true
        statusView.snp.removeConstraints()
    }
    
    // MARK: - Loading Animation

    private func startLoadingAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1.0
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)

        statusButton.layer.add(rotation, forKey: "rotationAnimation")
    }

    private func stopLoadingAnimation() {
        statusButton.layer.removeAnimation(forKey: "rotationAnimation")
    }
    
    // MARK: - Target Action
    @objc private func clickReSend() {
        onReSendHandler?()
    }
}


class DeviceMessageStatusView: UIView {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: MessageModule.image(named: "message_sent"))
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "已发送行者mini"
        label.font = .pingFangFontRegular(ofSize: 10)
        label.textColor = ThemeManager.current.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        addSubview(statusLabel)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(swAdaptedValue(14))
        }

        statusLabel.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right)
        }
    }
}
