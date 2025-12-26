//
//  Pro.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

class ProDeviceLowPowerCell: UITableViewCell {
    
    private let bgView = UIView()
    private let lowPowerTitle = UILabel()
    private let lowPowerswitch = UISwitch()
    
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
        
        lowPowerTitle.text = "低功耗"
        lowPowerTitle.textColor = UIColor(str: "#070808")
        lowPowerTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        bgView.addSubview(lowPowerTitle)
        
        lowPowerswitch.onTintColor = UIColor(str: "#16C282")
        lowPowerswitch.addTarget(self, action: #selector(logSwitchChanged), for: .valueChanged)
        bgView.addSubview(lowPowerswitch)
        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        lowPowerTitle.translatesAutoresizingMaskIntoConstraints = false
        lowPowerswitch.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            lowPowerTitle.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            lowPowerTitle.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            lowPowerswitch.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            lowPowerswitch.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
        ])
    }
    
    @objc private func logSwitchChanged() {
        WiFiDeviceManager.shared.deepSleep(enable: lowPowerswitch.isOn) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let alignmentResult):
                    print("低功耗指令成功")
                case .failure(let error):
                    print("低功耗指令失败")
                }
            }
        }
    }
}
