//
//  BingProDeviceViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit
import SystemConfiguration.CaptiveNetwork

class BindProDeviceViewController: PersonalBaseViewController {
    
    private let tipView = UIView()
    private let tipImageView = UIImageView()
    private let tipTextLabel = UILabel()
    private lazy var wifiTabelView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 60
        tableview.register(BindProDeviceCell.self, forCellReuseIdentifier: "BindProDeviceCell")
        return tableview
    }()
    
    private lazy var bindButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("开始绑定", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
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
        loadWifiData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "绑定设备"
        
        tipView.backgroundColor = UIColor(hex: "#FFF5E8")
        tipView.translatesAutoresizingMaskIntoConstraints = false
        
        tipImageView.image = PersonalModule.image(named: "default_warning2")
        tipImageView.contentMode = .scaleAspectFit
        tipImageView.translatesAutoresizingMaskIntoConstraints = false
        
        tipTextLabel.text = "请先连接行者Pro设备的WiFi网络，然后进行绑定"
        tipTextLabel.textColor = UIColor(hex: "#FF9447")
        tipTextLabel.font = .systemFont(ofSize: 12, weight: .medium)
        tipTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tipView)
        tipView.addSubview(tipImageView)
        tipView.addSubview(tipTextLabel)
        
        view.addSubview(wifiTabelView)
        view.addSubview(bindButton)
        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            tipView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tipView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tipView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tipView.heightAnchor.constraint(equalToConstant: 40),
            
            tipImageView.centerYAnchor.constraint(equalTo: tipView.centerYAnchor),
            tipImageView.leadingAnchor.constraint(equalTo: tipView.leadingAnchor, constant: 16),
            tipImageView.widthAnchor.constraint(equalToConstant: 12),
            tipImageView.heightAnchor.constraint(equalToConstant: 12),
            
            tipTextLabel.centerYAnchor.constraint(equalTo: tipView.centerYAnchor),
            tipTextLabel.leadingAnchor.constraint(equalTo: tipImageView.trailingAnchor, constant: 10),
            tipTextLabel.trailingAnchor.constraint(equalTo: tipView.trailingAnchor, constant: -16),
            
            wifiTabelView.topAnchor.constraint(equalTo: tipView.bottomAnchor, constant: 20),
            wifiTabelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wifiTabelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wifiTabelView.heightAnchor.constraint(equalToConstant: 120),
            
            bindButton.topAnchor.constraint(equalTo: wifiTabelView.bottomAnchor, constant: 10),
            bindButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bindButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bindButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    private func loadWifiData() {
        let titles = ["当前WiFi", "设备IP地址"]
        dataSource = [
            SettingData(
                titleStr: titles[0],
                contentStr: "HAO-LINK-B5B1",
                canChange: true
            ),
            SettingData(
                titleStr: titles[1],
                contentStr: "192.168.0.7",
                canChange: false
            )
        ]
        
        wifiTabelView.reloadData()
    }
    
    @objc private func stateBindProClick() {
//        let bindFailVC = BindProFailViewController()
//        self.navigationController?.pushViewController(bindFailVC, animated: true)
        
        let bindSuccessVC = BindProSuccessViewController()
        self.navigationController?.pushViewController(bindSuccessVC, animated: true)
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

extension BindProDeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindProDeviceCell") as! BindProDeviceCell
        let wifiData = dataSource[indexPath.row]
        cell.configure(with: wifiData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            openWiFiSettings()
        }
    }
    
}
