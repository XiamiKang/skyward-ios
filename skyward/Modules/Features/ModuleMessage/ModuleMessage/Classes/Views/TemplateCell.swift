//
//  TemplateCell.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/1/28.
//

import TXKit
import SWKit
import SWTheme


class TemplateCell: BaseCell {
    
    var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
    }
}
