//
//  HomeMessageTabCell.swift
//  ModuleHome
//
//  Created by 赵波 on 2025/11/17.
//

import UIKit
import SWKit
import SWTheme

class HomeMessageTabCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = ThemeManager.current.titleColor
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ThemeManager.current.mediumGrayBGColor
        layer.cornerRadius = CornerRadius.large.rawValue
        contentView.addSubview(titleLabel)
        setupConstraints()
    }
    
    func setSelected(_ selected: Bool) {
        backgroundColor = selected ? ThemeManager.current.secondaryColor : ThemeManager.current.mediumGrayBGColor
        titleLabel.textColor = selected ? UIColor.white : ThemeManager.current.titleColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    func configure(with item: NoticeTypeItem) {
        titleLabel.text = item.desc
        setSelected(item.selected)
    }
}
