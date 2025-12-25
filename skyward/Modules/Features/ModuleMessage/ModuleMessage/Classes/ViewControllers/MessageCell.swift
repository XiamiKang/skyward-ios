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
    
    private var messageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var bubbleView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = CornerRadius.medium.rawValue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(str: "#A0A3A7")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = ThemeManager.current.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        nameLabel.text = nil
        messageLabel.text = nil
        timeLabel.text = nil
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(bubbleView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(timeLabel)
    }
    
//    func configure(with message: Message) {
//        messageLabel.text = message.content
//        nameLabel.text = message.sender?.name
//        
//        if let avatarUrl = message.sender?.avatarUrl {
//            avatarImageView.image = MessageModule.image(named: avatarUrl)
//        } else {
//            avatarImageView.image = MessageModule.image(named: "avatar_default")
//        }
//        
//        if let timestamp = message.timestamp {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "HH:mm"
//            timeLabel.text = formatter.string(from: timestamp)
//        } else {
//            timeLabel.text = ""
//        }
//        
//        if "current_user" == message.sender?.id {
//            layoutSent()
//        } else {
//            layoutReceived()
//        }
//    }
    
    /**
     enum NoticeType: Int, Codable {
         case all = -1        // 所有
         case sos = 1         // SOS紧急求助
         case safety = 2      // 报平安
         case weather = 3     // 天气通知
         case service = 4     // 紧急联系人
     */
//    func configure(with message: NoticeItem) {
//        messageLabel.text = message.noticeContent
//        nameLabel.text = message.noticeType == 4 ? "紧急联系人" : "天行探索平台"
//        
//        if message.noticeType == 1 {
//            avatarImageView.image = MessageModule.image(named: "avatar_sos")
//        } else if message.noticeType == 2 {
//            avatarImageView.image = MessageModule.image(named: "avatar_safety")
//        } else if message.noticeType == 3 {
//            avatarImageView.image = MessageModule.image(named: "avatar_weather")
//        } else {
//            avatarImageView.image = MessageModule.image(named: "avatar_default")
//        }
//        
//        if let timestamp = message.noticeTime {
//            let date = Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
//            let formatter = DateFormatter()
//            formatter.dateFormat = "HH:mm"
//            timeLabel.text = formatter.string(from: date)
//        } else {
//            timeLabel.text = ""
//        }
//        
//        if message.noticeType == 4 {
//            layoutSent()
//        } else {
//            layoutReceived()
//        }
//    }
    
    func configure(with message: UrgentMessage) {
        messageLabel.text = message.content
        let isSelf = message.sendId == UserManager.shared.userId
        if isSelf {
            avatarImageView.sd_setImage(with: URL(string: UserManager.shared.userInfo?.avatar ?? ""), placeholderImage: MessageModule.image(named: "avatar_default"))
            nameLabel.text = UserManager.shared.userInfo?.nickname
            layoutSent()
        } else {
            avatarImageView.image = MessageModule.image(named: "avatar_txts")
            nameLabel.text = "天行探索平台"
            layoutReceived()
        }
        if let sendTime = message.sendTime { 
            let timestamp = TimeInterval(sendTime) / 1000 // 然后进行转换和除法运算
            // 创建日期格式化器
            timeLabel.text = DateFormatter.fullPretty.string(from: Date(timeIntervalSince1970: timestamp))
        } else {
            timeLabel.text = ""
        }
    }
    
    private func layoutSent() {
        bubbleView.backgroundColor = UIColor(str: "#FFE0B9")
        bubbleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        nameLabel.textAlignment = .right
        
        avatarImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(40))
            make.top.equalToSuperview()
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
        nameLabel.snp.remakeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.right.equalTo(bubbleView)
            make.top.equalToSuperview()
        }
        messageLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(swAdaptedValue(30))
            make.bottom.equalToSuperview().inset(swAdaptedValue(54))
            make.left.greaterThanOrEqualToSuperview().inset(swAdaptedValue(80))
            make.right.equalToSuperview().inset(swAdaptedValue(80))
        }
        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(messageLabel.snp.top).offset(-swAdaptedValue(8))
            make.bottom.equalTo(messageLabel.snp.bottom).offset(swAdaptedValue(8))
            make.left.equalTo(messageLabel.snp.left).offset(-swAdaptedValue(12))
            make.right.equalTo(messageLabel.snp.right).offset(swAdaptedValue(12))
        }
        timeLabel.snp.remakeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.right.equalTo(bubbleView)
            make.top.equalTo(bubbleView.snp.bottom).offset(swAdaptedValue(4))
        }
    }
    
    private func layoutReceived() {
        bubbleView.backgroundColor = ThemeManager.current.mediumGrayBGColor
        bubbleView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        
        nameLabel.textAlignment = .left

        avatarImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(40))
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        nameLabel.snp.remakeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.left.equalTo(bubbleView)
            make.top.equalToSuperview()
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(swAdaptedValue(30))
            make.bottom.equalToSuperview().inset(swAdaptedValue(54))
            make.left.equalToSuperview().inset(swAdaptedValue(80))
            make.right.lessThanOrEqualToSuperview().inset(swAdaptedValue(80))
        }
        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(messageLabel.snp.top).offset(-swAdaptedValue(8))
            make.bottom.equalTo(messageLabel.snp.bottom).offset(swAdaptedValue(8))
            make.left.equalTo(messageLabel.snp.left).offset(-swAdaptedValue(12))
            make.right.equalTo(messageLabel.snp.right).offset(swAdaptedValue(12))
        }
        timeLabel.snp.remakeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.left.equalTo(bubbleView)
            make.top.equalTo(bubbleView.snp.bottom).offset(swAdaptedValue(4))
        }
    }
}
