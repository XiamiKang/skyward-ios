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

class DeviceListView: UITableView, UITableViewDataSource, UITableViewDelegate, SWPopupContentView {
    
    var deviceList: [MiniDevice] = []
    
    var popupDismissBlock: (() -> Void)?
    
    var clickRightButtonBlock: ((MiniDevice) -> Void)?
    
    // 自定义初始化方法，允许设置deviceList
    init(frame: CGRect, deviceList: [MiniDevice] = []) {
        self.deviceList = deviceList
        super.init(frame: frame, style: .plain)
        commonInit()
    }
    
    // 无参数初始化方法
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        self.deviceList = []
        super.init(coder: coder)
        commonInit()
    }
    
    // 通用初始化设置
    private func commonInit() {
        // 可以在这里设置一些通用的初始化配置
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: DeviceCell.self)
        
        let devide = deviceList[indexPath.row]
        
        cell.deviceInfoView.deviceName = devide.info.displayName
        cell.deviceInfoView.batteryLevel = devide.status?.battery
        if devide.connected {
            cell.iconImageView.image = HomeModule.image(named: "device_mini_linked")
            
            cell.deviceInfoView.nameLabel.textColor = ThemeManager.current.titleColor
            cell.deviceInfoView.connectionIcon = HomeModule.image(named: "device_bluetooth_linked")
            cell.deviceInfoView.satelliteIcon = HomeModule.image(named: "device_satellite_linked")
            
            cell.rightButton.backgroundColor = ThemeManager.current.mediumGrayBGColor
            cell.rightButton.setTitle("断开", for: .normal)
            cell.rightButton.setTitleColor(ThemeManager.current.mainColor, for: .normal)
            cell.rightButton.setImage(HomeModule.image(named: "device_bluetooth_break"), for: .normal)
        } else {
            cell.iconImageView.image = HomeModule.image(named: "device_mini_unlink")
            
            cell.deviceInfoView.nameLabel.textColor = ThemeManager.current.textColor
            
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
