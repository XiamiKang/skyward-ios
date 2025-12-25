//
//  ProDeviceMsgViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

struct ProDeviceMsgInfo {
    let title: String
    let value: String
}

class ProDeviceMsgViewController: PersonalBaseViewController {
    
    var dataSource: [[ProDeviceMsgInfo]] = [
        [ProDeviceMsgInfo(title: "设备SN", value: "正在获取..."),
         ProDeviceMsgInfo(title: "设备型号", value: "正在获取..."),
         ProDeviceMsgInfo(title: "固件版本号", value: "正在获取...")],
        [ProDeviceMsgInfo(title: "基带MAC", value: "正在获取..."),
        ProDeviceMsgInfo(title: "基带SN", value: "正在获取...")]
    ]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(ProDeviceMsgCell.self, forCellReuseIdentifier: "ProDeviceMsgCell")
        return tableView
    }()
    
    private lazy var unBindButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("取消绑定", for: .normal)
        button.setTitleColor(UIColor(hex: "#F7594B"), for: .normal)
        button.backgroundColor = UIColor(hex: "#F2F3F4")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(unBindClick), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getProDeviceMsg()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadDeviceInfoFromCache()
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "设备信息"
        
        view.addSubview(tableView)
//        view.addSubview(unBindButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
//            unBindButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
//            unBindButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            unBindButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            unBindButton.heightAnchor.constraint(equalToConstant: 48),
        ])
        
    }
    
    @objc private func unBindClick() {
        WiFiDeviceManager.shared.disconnect()
        // 展示一个弹框，然后跳转
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.post(name: .deviceListNeedToUpdate, object: nil)
            if let vc = self.navigationController?.viewControllers.first(where: { $0 is DeviceListViewController }) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
        
    }
    
    private func getProDeviceMsg() {
        WiFiDeviceManager.shared.queryDeviceInfo { [weak self] result in
            switch result {
            case .success(let deviceInfo):
                DispatchQueue.main.async {
                    self?.updateDeviceInfo(deviceInfo)
                }
            case .failure(let error):
                print("设备信息失败: \(error)")
                DispatchQueue.main.async {
                    self?.view.sw_showSuccessToast("获取设备信息失败")
                }
            }
        }
    }
    
    private func updateDeviceInfo(_ deviceInfo: ProDeviceInfo) {
        dataSource = [
            [ProDeviceMsgInfo(title: "设备SN", value: deviceInfo.deviceSN),
             ProDeviceMsgInfo(title: "设备型号", value: "TXTS-WB-01"),
             ProDeviceMsgInfo(title: "固件版本号", value: deviceInfo.ACUVersion)],
            [ProDeviceMsgInfo(title: "基带MAC", value: deviceInfo.catMAC),
            ProDeviceMsgInfo(title: "基带SN", value: deviceInfo.catSN)]
        ]
        self.tableView.reloadData()
        
        saveDeviceInfoToCache(deviceInfo)
    }
    
    private func saveDeviceInfoToCache(_ deviceInfo: ProDeviceInfo) {
        // 使用UserDefaults缓存设备信息
        let userDefaults = UserDefaults.standard
        userDefaults.set(deviceInfo.deviceSN, forKey: "LastDeviceSN")
        userDefaults.set(deviceInfo.ACUVersion, forKey: "LastACUVersion")
        userDefaults.set(deviceInfo.catMAC, forKey: "LastCatMAC")
        userDefaults.set(deviceInfo.catSN, forKey: "LastCatSN")
        userDefaults.synchronize()
    }
    
    private func loadDeviceInfoFromCache() {
        let userDefaults = UserDefaults.standard
        let deviceSN = userDefaults.string(forKey: "LastDeviceSN") ?? "无缓存数据"
        let acuVersion = userDefaults.string(forKey: "LastACUVersion") ?? "无缓存数据"
        let catMAC = userDefaults.string(forKey: "LastCatMAC") ?? "无缓存数据"
        let catSN = userDefaults.string(forKey: "LastCatSN") ?? "无缓存数据"
        
        dataSource = [
            [ProDeviceMsgInfo(title: "设备SN", value: deviceSN),
             ProDeviceMsgInfo(title: "设备型号", value: "TXTS-WB-01"),
             ProDeviceMsgInfo(title: "固件版本号", value: acuVersion)],
            [ProDeviceMsgInfo(title: "基带MAC", value: catMAC),
            ProDeviceMsgInfo(title: "基带SN", value: catSN)]
        ]
    }
}

extension ProDeviceMsgViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowData = dataSource[section]
        return rowData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceMsgCell") as! ProDeviceMsgCell
        cell.configure(with: dataSource[indexPath.section][indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        let lineLabel = UILabel(frame: CGRect(x: 16, y: 0, width: UIScreen.main.bounds.width-32, height: 1))
        lineLabel.backgroundColor = .systemGray5
        view.addSubview(lineLabel)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 30
        }
        return 0
    }
    
}


class ProDeviceMsgCell: UITableViewCell {
    static let identifier = "ProDeviceMsgCell"
    
    // MARK: - UI Components
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(contentLabel)
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        
        // 设置单元格样式
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    // MARK: - Configuration
    func configure(with settingData: ProDeviceMsgInfo) {
        // cell名称
        nameLabel.text = settingData.title
        
        // cell内容
        contentLabel.text = settingData.value
        
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        contentLabel.text = nil
    }
}
