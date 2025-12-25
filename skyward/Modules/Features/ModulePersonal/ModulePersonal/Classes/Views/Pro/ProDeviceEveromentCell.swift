//
//  Pro.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

class ProDeviceEveromentCell: UITableViewCell {
    
    private let bgView = UIView()
    private let envrionmentTitle = UILabel()
    private let refreshButton = UIButton(type: .custom)
    private let msgTemText = UILabel()
    private let msgHumText = UILabel()
    private let temLabel = UILabel()
    private let humLabel = UILabel()
    
    var refreshAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor(str: "#F2F3F4")
        
        bgView.backgroundColor = .white
        bgView.layer.cornerRadius = 8
        contentView.addSubview(bgView)
        
        envrionmentTitle.text = "环境"
        envrionmentTitle.textColor = UIColor(str: "#070808")
        envrionmentTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        bgView.addSubview(envrionmentTitle)
        
        refreshButton.setImage(PersonalModule.image(named: "device_pro_refresh"), for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshClick), for: .touchUpInside)
        bgView.addSubview(refreshButton)
        
        msgTemText.text = "--"
        msgTemText.textColor = UIColor(str: "#070808")
        msgTemText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgTemText.textAlignment = .left
        bgView.addSubview(msgTemText)
        
        msgHumText.text = "--"
        msgHumText.textColor = UIColor(str: "#070808")
        msgHumText.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        msgHumText.textAlignment = .center
        bgView.addSubview(msgHumText)
        
        temLabel.text = "温度"
        temLabel.textColor = UIColor(str: "#84888C")
        temLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        temLabel.textAlignment = .left
        bgView.addSubview(temLabel)
        
        humLabel.text = "湿度"
        humLabel.textColor = UIColor(str: "#84888C")
        humLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        humLabel.textAlignment = .center
        bgView.addSubview(humLabel)
        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        envrionmentTitle.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        msgTemText.translatesAutoresizingMaskIntoConstraints = false
        msgHumText.translatesAutoresizingMaskIntoConstraints = false
        temLabel.translatesAutoresizingMaskIntoConstraints = false
        humLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            envrionmentTitle.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 16),
            envrionmentTitle.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            refreshButton.centerYAnchor.constraint(equalTo: envrionmentTitle.centerYAnchor),
            refreshButton.leadingAnchor.constraint(equalTo: envrionmentTitle.trailingAnchor, constant: 8),
            refreshButton.widthAnchor.constraint(equalToConstant: 16),
            refreshButton.heightAnchor.constraint(equalToConstant: 16),
            
            msgTemText.topAnchor.constraint(equalTo: envrionmentTitle.bottomAnchor, constant: 16),
            msgTemText.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            msgHumText.topAnchor.constraint(equalTo: envrionmentTitle.bottomAnchor, constant: 16),
            msgHumText.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            
            temLabel.topAnchor.constraint(equalTo: msgTemText.bottomAnchor, constant: 5),
            temLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            humLabel.topAnchor.constraint(equalTo: msgHumText.bottomAnchor, constant: 5),
            humLabel.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
        ])
    }
    
    @objc private func refreshClick() {
        refreshAction?()
    }
    
    func configon(with data: EnvironmentInfo) {
        msgTemText.text = String(data.temperature)
        msgHumText.text = String(data.humidity)
    }
}
