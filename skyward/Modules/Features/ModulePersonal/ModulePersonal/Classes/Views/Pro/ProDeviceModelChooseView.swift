//
//  ProDeviceModelChooseView.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/1/12.
//

import UIKit
import SWKit
import SWTheme
import SnapKit

class ProDeviceModelChooseView: UIView, SWAlertCustomView {
    
    var modeChooleWithIndex: ((Int) -> Void)?
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.text = "请根据安装方式切换工作模式：固定于车辆上时请选择“车载模式”，置于水平地面时请选择“地面模式”"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var modeCarImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = PersonalModule.image(named: "device_pro_mode_sel")
        return iv
    }()
    
    private lazy var modeCarLabel: UILabel = {
        let label = UILabel()
        label.text = "车载模式"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var modeCarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(chooseCarClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var modeGroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = PersonalModule.image(named: "device_pro_mode")
        return iv
    }()
    
    private lazy var modeGroundLabel: UILabel = {
        let label = UILabel()
        label.text = "地面模式"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    private lazy var modeGroundButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(chooseGroundClick), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(contentLabel)
        addSubview(modeCarImageView)
        addSubview(modeCarLabel)
        addSubview(modeCarButton)
        addSubview(modeGroundImageView)
        addSubview(modeGroundLabel)
        addSubview(modeGroundButton)
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        modeCarImageView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(16)
        }
        
        modeCarLabel.snp.makeConstraints { make in
            make.centerY.equalTo(modeCarImageView.snp.centerY)
            make.leading.equalTo(modeCarImageView.snp.trailing).offset(18)
        }
        
        modeCarButton.snp.makeConstraints { make in
            make.centerY.equalTo(modeCarImageView.snp.centerY)
            make.leading.equalTo(modeCarImageView.snp.leading)
            make.trailing.equalTo(modeCarLabel.snp.trailing)
            make.height.equalTo(25)
            make.bottom.equalToSuperview().offset(-10)
        }
        
        modeGroundImageView.snp.makeConstraints { make in
            make.centerY.equalTo(modeCarImageView.snp.centerY)
            make.leading.equalTo(modeCarLabel.snp.trailing).offset(20)
            make.width.height.equalTo(16)
        }
        
        modeGroundLabel.snp.makeConstraints { make in
            make.centerY.equalTo(modeGroundImageView.snp.centerY)
            make.leading.equalTo(modeGroundImageView.snp.trailing).offset(18)
        }
        
        modeGroundButton.snp.makeConstraints { make in
            make.centerY.equalTo(modeGroundImageView.snp.centerY)
            make.leading.equalTo(modeGroundImageView.snp.leading)
            make.trailing.equalTo(modeGroundLabel.snp.trailing)
            make.height.equalTo(25)
        }
        
    }
    
    @objc private func chooseCarClick() {
        modeChooleWithIndex?(1)
        modeCarImageView.image = PersonalModule.image(named: "device_pro_mode_sel")
        modeGroundImageView.image = PersonalModule.image(named: "device_pro_mode")
    }
    
    @objc private func chooseGroundClick() {
        modeChooleWithIndex?(0)
        modeCarImageView.image = PersonalModule.image(named: "device_pro_mode")
        modeGroundImageView.image = PersonalModule.image(named: "device_pro_mode_sel")
    }
}
