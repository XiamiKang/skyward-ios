//
//  BindProFailViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit
import SWKit

class BindProFailViewController: PersonalBaseViewController {
    
    private let tipImageView = UIImageView()
    private let tipTitleLabel = UILabel()
    private let tipContentLabel = UILabel()
    
    private lazy var bindButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("去查看WIFI", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(stateBindProClick), for: .touchUpInside)
        return button
    }()
    
    var dataSource: [SettingData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        WiFiDeviceManager.shared.disconnect()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        
        tipImageView.image = PersonalModule.image(named: "device_pro_wifiOff")
        tipImageView.contentMode = .scaleAspectFit
        tipImageView.translatesAutoresizingMaskIntoConstraints = false
        
        tipTitleLabel.text = "绑定失败"
        tipTitleLabel.textColor = UIColor(hex: "#070808")
        tipTitleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        tipTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tipContentLabel.text = "请检查是否已连接设备WiFi"
        tipContentLabel.textColor = UIColor(hex: "#84888C")
        tipContentLabel.font = .systemFont(ofSize: 12, weight: .regular)
        tipContentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.addSubview(tipImageView)
        view.addSubview(tipTitleLabel)
        view.addSubview(tipContentLabel)
        view.addSubview(bindButton)
        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            tipImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipImageView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 60),
            tipImageView.widthAnchor.constraint(equalToConstant: 72),
            tipImageView.heightAnchor.constraint(equalToConstant: 72),
            
            tipTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipTitleLabel.topAnchor.constraint(equalTo: tipImageView.bottomAnchor, constant: 20),
            
            tipContentLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tipContentLabel.topAnchor.constraint(equalTo: tipTitleLabel.bottomAnchor, constant: 10),
           
            bindButton.topAnchor.constraint(equalTo: tipContentLabel.bottomAnchor, constant: 30),
            bindButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bindButton.widthAnchor.constraint(equalToConstant: 120),
            bindButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    @objc private func stateBindProClick() {
        openWiFiSettings()
    }
    
    func openWiFiSettings() {
        if let url = URL(string: "App-Prefs:root=WIFI") {
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
}
