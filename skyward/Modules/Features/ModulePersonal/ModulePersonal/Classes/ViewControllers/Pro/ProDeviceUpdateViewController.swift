//
//  ProDeviceUpdateViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit

class ProDeviceUpdateViewController: PersonalBaseViewController {
    
    private var firmwareImageView = UIImageView()
    private var firmwareVersionLabel = UILabel()
    private var firmwareMessageLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setConstraint()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "固件升级"
        
        firmwareImageView.translatesAutoresizingMaskIntoConstraints = false
        firmwareImageView.image = PersonalModule.image(named: "device_mini_firmware_noUpdate")
        firmwareImageView.contentMode = .scaleAspectFit
        view.addSubview(firmwareImageView)
        
        firmwareVersionLabel.translatesAutoresizingMaskIntoConstraints = false
        firmwareVersionLabel.text = "当前版本：固件_0.0.0.1"
        firmwareVersionLabel.textColor = .black
        firmwareVersionLabel.textAlignment = .center
        firmwareVersionLabel.font = .systemFont(ofSize: 20, weight: .medium)
        view.addSubview(firmwareVersionLabel)
        
        firmwareMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        firmwareMessageLabel.text = "已是最新版本"
        firmwareMessageLabel.textColor = UIColor(hex: "#84888C")
        firmwareMessageLabel.textAlignment = .center
        firmwareMessageLabel.font = .systemFont(ofSize: 12, weight: .regular)
        view.addSubview(firmwareMessageLabel)
    }
    
    private func setConstraint() {
        NSLayoutConstraint.activate([
            firmwareImageView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 80),
            firmwareImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firmwareImageView.widthAnchor.constraint(equalToConstant: 100),
            firmwareImageView.heightAnchor.constraint(equalToConstant: 100),
            
            firmwareVersionLabel.topAnchor.constraint(equalTo: firmwareImageView.bottomAnchor, constant: 20),
            firmwareVersionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            firmwareMessageLabel.topAnchor.constraint(equalTo: firmwareVersionLabel.bottomAnchor, constant: 10),
            firmwareMessageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
}
