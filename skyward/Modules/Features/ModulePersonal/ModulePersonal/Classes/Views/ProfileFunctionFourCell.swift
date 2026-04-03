//
//  ProfileFunctionOneCell.swift
//  Pods
//
//  Created by TXTS on 2025/12/18.
//


import UIKit

// MARK: - 功能列表Cell
class ProfileFunctionFourCell: UITableViewCell {
    
    static let identifier = "ProfileFunctionFourCell"
    
    // MARK: - UI组件
    private let canvasView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = PersonalModule.image(named: "profile_cell_setting")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "设置"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = UIColor(str: "#A0A3A7")
        return label
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
        self.backgroundColor = .clear
        
        contentView.addSubview(canvasView)
        canvasView.addSubview(iconImageView)
        canvasView.addSubview(titleLabel)
        canvasView.addSubview(infoLabel)
        canvasView.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: contentView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            canvasView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            canvasView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            
            arrowImageView.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 12),
            
            infoLabel.trailingAnchor.constraint(equalTo: arrowImageView.leadingAnchor, constant: -8),
            infoLabel.centerYAnchor.constraint(equalTo: canvasView.centerYAnchor)
        ])
    }
    
    // MARK: - 配置数据
    func configure(with item: FunctionItem) {
        iconImageView.image = item.icon
        titleLabel.text = item.title
        infoLabel.text = item.info
        arrowImageView.isHidden = !item.hasArrow
    }
}
