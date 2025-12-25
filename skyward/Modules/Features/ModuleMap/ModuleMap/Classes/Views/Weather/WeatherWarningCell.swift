//
//  WeatherWarningCell.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/8.
//

import UIKit

class WeatherWarningCell: UITableViewCell {

    private let title = UILabel()
    private let warningView = WarningView()
    private let noWarningView = NoWarningView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        title.text = "灾害预警"
        title.textColor = .black
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(title)
        
        warningView.layer.cornerRadius = 8
        warningView.isHidden = true
        warningView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(warningView)
        
        noWarningView.layer.cornerRadius = 8
        noWarningView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(noWarningView)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            warningView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            warningView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            warningView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            noWarningView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            noWarningView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            noWarningView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            noWarningView.heightAnchor.constraint(equalToConstant: 150),
        ])
    }
    
    func configure(_ warningData: WeatherWarningData) {
        warningView.isHidden = false
        noWarningView.isHidden = true
        warningView.configure(warningData)
        
        // 强制布局更新
        contentView.layoutIfNeeded()
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        // 1. 布局contentView
        contentView.layoutIfNeeded()
        
        // 2. 计算自适应高度
        var fittingSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        
        // 3. 确保高度不为0
        if fittingSize.height == 0 {
            // 计算标题高度 + 视图高度 + 间距
            let titleHeight: CGFloat = 10 + 16 + 16 // top + font height + bottom
            let warningHeight: CGFloat = 140 // 预估高度
            fittingSize.height = titleHeight + warningHeight + 16
        }
        
        return fittingSize
    }
}

class WarningView: UIView {
    
    private let warningIcon = UIImageView()
    private let warningTitleLabel = UILabel()
    private let warningDateLabel = UILabel()
    private let warningContentLabel = UILabel()
    private let warningDescLabel = UILabel()
    private var bottomConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(str: "#EDF9FF")
        layer.cornerRadius = 8
        
        warningIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        warningIcon.tintColor = .systemOrange
        addSubview(warningIcon)
        
        warningTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        warningTitleLabel.textColor = .systemOrange
        addSubview(warningTitleLabel)
        
        warningDateLabel.font = .systemFont(ofSize: 12)
        warningDateLabel.textColor = .systemGray
        addSubview(warningDateLabel)
        
        warningContentLabel.font = .systemFont(ofSize: 14)
        warningContentLabel.textColor = .black
        warningContentLabel.numberOfLines = 0
        addSubview(warningContentLabel)
        
        warningDescLabel.font = .systemFont(ofSize: 12)
        warningDescLabel.textColor = .systemGray
        warningDescLabel.numberOfLines = 0
        addSubview(warningDescLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        warningTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        warningDateLabel.translatesAutoresizingMaskIntoConstraints = false
        warningContentLabel.translatesAutoresizingMaskIntoConstraints = false
        warningDescLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            warningIcon.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            warningIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            warningIcon.widthAnchor.constraint(equalToConstant: 24),
            warningIcon.heightAnchor.constraint(equalToConstant: 24),
            
            warningTitleLabel.topAnchor.constraint(equalTo: warningIcon.topAnchor),
            warningTitleLabel.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 8),
            warningTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            warningDateLabel.topAnchor.constraint(equalTo: warningTitleLabel.bottomAnchor, constant: 5),
            warningDateLabel.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 8),
            warningDateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            warningContentLabel.topAnchor.constraint(equalTo: warningDateLabel.bottomAnchor, constant: 12),
            warningContentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            warningContentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            warningDescLabel.topAnchor.constraint(equalTo: warningContentLabel.bottomAnchor, constant: 12),
            warningDescLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            warningDescLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
        
        // 创建底部约束但不激活
        bottomConstraint = warningDescLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
    }
    
    func configure(_ data: WeatherWarningData) {
        
        warningTitleLabel.text = data.title
        warningDateLabel.text = "发布时间：\(data.pubTime ?? "2025.01.01")"
        warningContentLabel.text = data.text ?? ""
        warningDescLabel.text = ""
        
        // 激活底部约束
        bottomConstraint?.isActive = true
        
        // 强制刷新布局
        setNeedsLayout()
        layoutIfNeeded()
        
    }
}


class NoWarningView: UIView {
    
    private let warningIcon = UIImageView()
    private let warningTitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(str: "#EDF9FF")
        layer.cornerRadius = 8
        
        warningIcon.image = MapModule.image(named: "noWarnIng")
        addSubview(warningIcon)
        
        warningTitleLabel.text = "暂无预警"
        warningTitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        warningTitleLabel.textColor = .black
        addSubview(warningTitleLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        warningTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            warningIcon.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            warningIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            warningIcon.widthAnchor.constraint(equalToConstant: 48),
            warningIcon.heightAnchor.constraint(equalToConstant: 48),
            
            warningTitleLabel.topAnchor.constraint(equalTo: warningIcon.bottomAnchor, constant: 12),
            warningTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}
