//
//  BindProSuccessViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit
import SWKit

class BindProSuccessViewController: PersonalBaseViewController {
    
    private let tipImageView = UIImageView()
    private let tipTitleLabel = UILabel()
    
    private lazy var bindButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("查看设备详情", for: .normal)
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
        
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        
        tipImageView.image = PersonalModule.image(named: "device_line_success")
        tipImageView.contentMode = .scaleAspectFit
        tipImageView.translatesAutoresizingMaskIntoConstraints = false
        
        tipTitleLabel.text = "设备绑定成功"
        tipTitleLabel.textColor = UIColor(hex: "#070808")
        tipTitleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        tipTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.addSubview(tipImageView)
        view.addSubview(tipTitleLabel)
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
           
            bindButton.topAnchor.constraint(equalTo: tipTitleLabel.bottomAnchor, constant: 24),
            bindButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bindButton.widthAnchor.constraint(equalToConstant: 132),
            bindButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    @objc private func stateBindProClick() {
        let proDetailVC = ProDeviceDetailViewController()
        self.navigationController?.pushViewController(proDetailVC, animated: true)
    }
    
}

