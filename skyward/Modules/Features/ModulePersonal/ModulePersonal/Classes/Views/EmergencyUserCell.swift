//
//  EmergencyUserCell.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/2/9.
//

import UIKit

class EmergencyUserCell: UITableViewCell {
    
    private let bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let userImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = PersonalModule.image(named: "emergency_user")
        return iv
    }()
    
    private var userNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(hex: "#070808")
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    
    private var userPhoneLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(hex: "#070808")
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .right
        return label
    }()
    
    private let cellNextImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = PersonalModule.image(named: "cell_suffix")
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(bgView)
        bgView.addSubview(userImageView)
        bgView.addSubview(userNameLabel)
        bgView.addSubview(userPhoneLabel)
        bgView.addSubview(cellNextImageView)
    }
    
    private func setConstraint() {
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            bgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),
            
            userImageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            userImageView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            userImageView.widthAnchor.constraint(equalToConstant: 24),
            userImageView.heightAnchor.constraint(equalToConstant: 24),
            
            userNameLabel.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            userNameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 5),
            userNameLabel.widthAnchor.constraint(equalToConstant: 160),
            
            userPhoneLabel.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            userPhoneLabel.trailingAnchor.constraint(equalTo: cellNextImageView.leadingAnchor, constant: -1),
            userPhoneLabel.leadingAnchor.constraint(equalTo: userNameLabel.trailingAnchor, constant: 2),
            
            cellNextImageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            cellNextImageView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            cellNextImageView.widthAnchor.constraint(equalToConstant: 16),
            cellNextImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
    
    func config(with emergecyData: EmergencyInfoData) {
        userNameLabel.text = emergecyData.name
        userPhoneLabel.text = emergecyData.phone
    }
}
