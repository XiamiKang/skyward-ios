//
//  Pro.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit
import SWKit

class ProDeviceSettingCell: UITableViewCell {

    let itemWidth = (UIScreen.main.bounds.width - 64)/4
    
    var selectedCallback: ((Int) -> Void)?
    
    var warningNum: Int = 0
    
    private let bgView = UIView()
    private let settingTitle = UILabel()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth*5/7)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(ProDeviceSettingManageCell.self, forCellWithReuseIdentifier: "ProDeviceSettingManageCell")
        return collectionView
    }()
    
    private let dataSource: [ProDeviceSettingManageData] = [
        ProDeviceSettingManageData(imageStr: "device_pro_deviceWarning", title: "设备警告"),
        ProDeviceSettingManageData(imageStr: "device_pro_restart", title: "复位重启"),
        ProDeviceSettingManageData(imageStr: "device_pro_msg", title: "设备信息"),
        ProDeviceSettingManageData(imageStr: "device_pro_update", title: "固件信息"),
        ProDeviceSettingManageData(imageStr: "device_pro_louter", title: "路由器设置"),
        ProDeviceSettingManageData(imageStr: "device_pro_satellite", title: "卫星参数"),
    ]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupNotifications()
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
        
        settingTitle.text = "设备管理"
        settingTitle.textColor = UIColor(str: "#070808")
        settingTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        bgView.addSubview(settingTitle)
        
        bgView.addSubview(collectionView)
        
        setConstraint()
    }
    
    private func setConstraint() {
        bgView.translatesAutoresizingMaskIntoConstraints = false
        settingTitle.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            settingTitle.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 16),
            settingTitle.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            
            collectionView.topAnchor.constraint(equalTo: settingTitle.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: -5),
            
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dealDeviceWarningData(_:)),
            name: .proDeviceWarningData,
            object: nil
        )
    }
    
    @objc private func dealDeviceWarningData(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let result = userInfo["warning"] as? FaultCodes else {
            return
        }
        warningNum = 0
        if result.imu == 1 {
            warningNum += 1
        }
        if result.beidou == 1 {
            warningNum += 1
        }
        if result.beacon == 1 {
            warningNum += 1
        }
        if result.lnb == 1 {
            warningNum += 1
        }
        if result.buc == 1 {
            warningNum += 1
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
        
    }
}

extension ProDeviceSettingCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProDeviceSettingManageCell", for: indexPath) as! ProDeviceSettingManageCell
        cell.confign(with: dataSource[indexPath.row])
        if indexPath.row == 0 {
            cell.tipLabe.isHidden = warningNum == 0
            cell.tipLabe.text = String(warningNum)
        } else if indexPath.row == 3 {
            
        } else {
            cell.tipLabe.isHidden = true
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCallback?(indexPath.row)
    }
    
}
