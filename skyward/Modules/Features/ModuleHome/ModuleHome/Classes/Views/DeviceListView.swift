//
//  DeviceListView.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/21.
//

import TXKit
import SWKit
import SWTheme
import ModulePersonal

class MiniDeviceListView: UITableView, UITableViewDataSource, UITableViewDelegate, SWPopupContentView {
    
    var deviceList: [MiniDevice] = []
    
    var popupDismissBlock: (() -> Void)?
    
    var clickRightButtonBlock: ((MiniDevice) -> Void)?
    
    init() {
        super.init(frame: CGRectZero, style: .plain)
        self.dataSource = self
        self.delegate = self
        self.bounces = false
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.register(cellType: DeviceCell.self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: DeviceCell.self)
        
        let devide = deviceList[indexPath.row]
        
        cell.deviceInfoView.deviceName = devide.info.name ?? "行者mini"
        
        if devide.connected {
            cell.iconImageView.image = HomeModule.image(named: "device_mini_linked")
            
            cell.deviceInfoView.nameLabel.textColor = ThemeManager.current.titleColor
            cell.deviceInfoView.connectionIcon = HomeModule.image(named: "device_bluetooth_linked")
            cell.deviceInfoView.satelliteIcon = HomeModule.image(named: "device_satellite_linked")
            cell.deviceInfoView.batteryLevel = devide.status?.battery
            cell.deviceInfoView.satelliteLevel = devide.satelliteNum ?? 0
            
            cell.rightButton.backgroundColor = ThemeManager.current.mediumGrayBGColor
            cell.rightButton.setTitle("断开", for: .normal)
            cell.rightButton.setTitleColor(ThemeManager.current.mainColor, for: .normal)
            cell.rightButton.setImage(HomeModule.image(named: "device_bluetooth_break"), for: .normal)
        } else {
            cell.iconImageView.image = HomeModule.image(named: "device_mini_unlink")
            
            cell.deviceInfoView.nameLabel.textColor = ThemeManager.current.textColor
            cell.deviceInfoView.batteryLevel = nil
            cell.deviceInfoView.satelliteLevel = nil
            
            cell.rightButton.backgroundColor = ThemeManager.current.mainColor
            cell.rightButton.setTitle("连接", for: .normal)
            cell.rightButton.setTitleColor(.white, for: .normal)
            cell.rightButton.setImage(HomeModule.image(named: "device_bluetooth_white"), for: .normal)
            
        }

        cell.rightButton.addAction(UIAction {[weak self] _  in
            self?.clickRightButtonBlock?(devide)
        }, for: .touchUpInside)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(68)
    }
    
    func popupDidDismiss() {
        popupDismissBlock?()
    }
}

// 宽带设备列表
class ProDeviceListView: UITableView, UITableViewDataSource, UITableViewDelegate, SWPopupContentView {
    
    var deviceList: [WiFiDevice] = []
    
    var popupDismissBlock: (() -> Void)?
    
    var clickRightButtonBlock: ((WiFiDevice) -> Void)?
    
    init() {
        super.init(frame: CGRectZero, style: .plain)
        self.dataSource = self
        self.delegate = self
        self.bounces = false
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.register(cellType: DeviceCell.self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: DeviceCell.self)
        
        let device = deviceList[indexPath.row]
        
        cell.deviceInfoView.deviceName = device.nickname
        
        cell.rightButton.backgroundColor = ThemeManager.current.mainColor
        cell.rightButton.setTitle("详情", for: .normal)
        cell.rightButton.setTitleColor(.white, for: .normal)
        
        if device.isConnected {
            cell.iconImageView.image = HomeModule.image(named: "device_pro_linked")
            
            cell.deviceInfoView.nameLabel.textColor = ThemeManager.current.titleColor
            cell.deviceInfoView.connectionIcon = HomeModule.image(named: "device_wifi_linked")
            cell.deviceInfoView.satelliteIcon = HomeModule.image(named: "device_satellite_linked")
        } else {
            cell.iconImageView.image = HomeModule.image(named: "device_pro_unlink")
            
            cell.deviceInfoView.nameLabel.textColor = ThemeManager.current.textColor
            cell.deviceInfoView.connectionIcon = nil
            cell.deviceInfoView.satelliteIcon = nil
        }

        cell.rightButton.addAction(UIAction {[weak self] _  in
            self?.clickRightButtonBlock?(device)
        }, for: .touchUpInside)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(68)
    }
    
    func popupDidDismiss() {
        popupDismissBlock?()
    }
}
