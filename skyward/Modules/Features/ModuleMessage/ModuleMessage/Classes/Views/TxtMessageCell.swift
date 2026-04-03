//
//  TxtMessageCell.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/03/26.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SDWebImage

class TxtMessageCell: MessageCell {

    // MARK: - Text Message UI Components

    private var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        bubbleView.addSubview(messageLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    
    override func configure(message: Message) {
        super.configure(message: message)
        messageLabel.text = message.content ?? " "
        
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
        messageLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(swAdaptedValue(8))
            make.bottom.equalToSuperview().inset(swAdaptedValue(8)).priority(.medium)
            make.left.right.equalToSuperview().inset(swAdaptedValue(12))
        }
    }

    // MARK: - Reset

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
    }
}
