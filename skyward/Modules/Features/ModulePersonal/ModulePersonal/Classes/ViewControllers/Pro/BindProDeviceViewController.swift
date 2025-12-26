//
//  BingProDeviceViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/25.
//

import UIKit
import SWKit
import SystemConfiguration.CaptiveNetwork
import CoreLocation

class BindProDeviceViewController: PersonalBaseViewController {
    
    // 现有的属性...
    private let tipView = UIView()
    private let tipImageView = UIImageView()
    private let tipTextLabel = UILabel()
    
    // 添加 Loading 相关属性
    private let loadingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.isHidden = true
        view.alpha = 0
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "正在连接设备..."
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    // 原有的 lazy var 属性...
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
        button.setTitle("开始连接", for: .normal)
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
        
        // 添加 Loading 视图
        view.addSubview(loadingView)
        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(loadingLabel)
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
            
            // Loading 视图约束
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 120),
            loadingView.heightAnchor.constraint(equalToConstant: 120),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -10),
            
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 8),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -8),
        ])
    }
    
    // MARK: - Loading 方法
    
    private func showLoading() {
        // 禁用按钮防止重复点击
        bindButton.isEnabled = false
        bindButton.alpha = 0.6
        
        // 显示 loading 视图
        loadingView.isHidden = false
        activityIndicator.startAnimating()
        
        UIView.animate(withDuration: 0.3) {
            self.loadingView.alpha = 1
        }
    }
    
    private func hideLoading() {
        // 启用按钮
        bindButton.isEnabled = true
        bindButton.alpha = 1
        
        UIView.animate(withDuration: 0.3, animations: {
            self.loadingView.alpha = 0
        }) { _ in
            self.loadingView.isHidden = true
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - 按钮点击事件
    
    @objc private func stateBindProClick() {
        // 显示 loading
        showLoading()
        
        WiFiDeviceManager.shared.connect { [weak self] result in
            guard let self = self else { return }
            
            // 在主线程中隐藏 loading 并处理结果
            DispatchQueue.main.async {
                self.hideLoading()
                
                switch result {
                case .success(_):
                    self.proDeviceLineSuccess()
                case .failure(_):
                    self.proDeviceLineFail()
                }
            }
        }
    }
    
    private func proDeviceLineSuccess() {
        let bindSuccessVC = BindProSuccessViewController()
        self.navigationController?.pushViewController(bindSuccessVC, animated: true)
    }
    
    private func proDeviceLineFail() {
        let bindSuccessVC = BindProFailViewController()
        self.navigationController?.pushViewController(bindSuccessVC, animated: true)
    }
    
    // 其他方法保持不变...
    private func loadWifiData() {
        let titles = ["当前WiFi", "设备IP地址"]
        dataSource = [
            SettingData(
                titleStr: titles[0],
                contentStr: getWiFiSSID() ?? "无法获取WiFi信息",
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
    
    func openWiFiSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            print("获取系统设置URL失败")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:]) { success in
                if success {
                    print("成功跳转到系统设置")
                } else {
                    print("跳转系统设置失败")
                }
            }
        } else {
            print("设备不支持打开系统设置")
        }
    }
    
    func getWiFiSSID() -> String? {
        // ... 原有实现保持不变
        guard Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.networking.wifi-info") != nil else {
            print("❌ 未开启Access WiFi Information能力，请在项目配置中添加")
            return nil
        }
        
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            print("❌ 无法获取WiFi接口列表")
            return nil
        }
        
        for interface in interfaces {
            guard let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject] else {
                continue
            }
            
            guard let ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String else {
                continue
            }
            return ssid
        }
        
        return nil
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
