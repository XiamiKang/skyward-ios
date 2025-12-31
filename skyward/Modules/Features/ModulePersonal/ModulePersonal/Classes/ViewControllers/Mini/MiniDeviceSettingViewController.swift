//
//  DeviceSettingViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/19.
//

import UIKit
import CoreBluetooth
import SWKit
import Combine
import SWTheme

struct SettingData {
    let titleStr: String
    let contentStr: String
    let canChange: Bool
}

class MiniDeviceSettingViewController: PersonalBaseViewController {
    
    var deviceInfo: BluetoothDeviceInfo?
    var statusInfo: StatusInfo?
    var dataSource: [SettingData] = []
    private let viewModel = PersonalViewModel()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(DevieceSettingCell.self, forCellReuseIdentifier: "DevieceSettingCell")
        return tableView
    }()
    
    private lazy var unBindButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("解除绑定", for: .normal)
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
        setupNotifications()
        loadDeviceData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "设置"
        
        view.addSubview(tableView)
        view.addSubview(unBindButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            unBindButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            unBindButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            unBindButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            unBindButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusInfoUpdate(_:)),
            name: .didReceiveStatusInfo,
            object: nil
        )
        // 获取解除绑定的应答
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(switchSceneMapSuccess(_:)),
            name: .unBindMiniDeviceResponseMsg,
            object: nil
        )
    }
    
    private func loadDeviceData() {
        
        var titles = ["设备名称", "设备模式", "设备上报平台频率", "定位信息存储时间间隔", "低功耗唤醒时间"]
        
        guard let statusInfo = statusInfo else {
            dataSource = [
                SettingData(
                    titleStr: titles[0],
                    contentStr: deviceInfo?.displayName ?? "未知设备",
                    canChange: false
                ),
                SettingData(
                    titleStr: titles[1],
                    contentStr: WorkModeHelper.modeString(from: 0),
                    canChange: false
                ),
                SettingData(
                    titleStr: titles[2],
                    contentStr: PositionReportHelper.reportString(from: 0),
                    canChange: false
                ),
                SettingData(
                    titleStr: titles[3],
                    contentStr: TimeHelper.secondsToMinutesString(6000),
                    canChange: false  // 不可改动
                ),
                SettingData(
                    titleStr: titles[4],
                    contentStr: TimeHelper.secondsToMinutesString(10),
                    canChange: false  // 不可改动
                )
            ]
            
            tableView.reloadData()
            return
        }
        
        if statusInfo.workMode == 0 {
            titles = ["设备名称", "设备模式", "设备上报平台频率", "定位信息存储时间间隔", "低功耗唤醒时间"]
            // 创建数据源
            dataSource = [
                SettingData(
                    titleStr: titles[0],
                    contentStr: deviceInfo?.displayName ?? "未知设备",
                    canChange: false
                ),
                SettingData(
                    titleStr: titles[1],
                    contentStr: WorkModeHelper.modeString(from: statusInfo.workMode),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[2],
                    contentStr: PositionReportHelper.reportString(from: statusInfo.positionReport),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[3],
                    contentStr: TimeHelper.secondsToMinutesString(statusInfo.positionStoreTime),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[4],
                    contentStr: TimeHelper.secondsToMinutesString(statusInfo.lowPowerTime),
                    canChange: false  // 不可改动
                )
            ]
        }else {
            titles = ["设备名称", "设备模式", "设备参数更新频率", "设备上报平台频率", "定位信息存储时间间隔", "低功耗唤醒时间"]
            // 创建数据源
            dataSource = [
                SettingData(
                    titleStr: titles[0],
                    contentStr: deviceInfo?.displayName ?? "未知设备",
                    canChange: false
                ),
                SettingData(
                    titleStr: titles[1],
                    contentStr: WorkModeHelper.modeString(from: statusInfo.workMode),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[2],
                    contentStr: StatusReportFreqHelper.freqString(from: statusInfo.statusReportFreq),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[3],
                    contentStr: PositionReportHelper.reportString(from: statusInfo.positionReport),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[4],
                    contentStr: TimeHelper.secondsToMinutesString(statusInfo.positionStoreTime),
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[5],
                    contentStr: TimeHelper.secondsToMinutesString(statusInfo.lowPowerTime),
                    canChange: false  // 不可改动
                )
                
            ]
        }
        
        tableView.reloadData()
    }
    
    @objc private func handleStatusInfoUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let statusInfo = userInfo["statusInfo"] as? StatusInfo else {
            return
        }
        
        DispatchQueue.main.async {
            self.statusInfo = statusInfo
            self.loadDeviceData()
        }
    }
    
    @objc private func unBindClick() {
        var bindData = Data()
        bindData.append(0x00) // 解除绑定
        BluetoothManager.shared.sendCommand(.setBindStatus, messageContent: bindData)
        
        let userId = Int(UserManager.shared.userId) ?? 0
        if let imei = deviceInfo?.imei, let macAddress = deviceInfo?.macAddress {
            let unbindModel = UnBindModel(userId: userId, serialNum: imei, macAddress: macAddress)
            viewModel.unBingMiniDevice(model: unbindModel)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    
                } receiveValue: { [weak self] data in
                    if data {
                        self?.unBindMiniDeviceSuccess()
                    }else {
                        self?.view.sw_showSuccessToast("解除设备失败")
                    }
                }
                .store(in: &viewModel.cancellables)
        }
    }
    
   
    
    @objc private func switchSceneMapSuccess(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let result = userInfo["result"] as? ResponseStatus else {
            return
        }
        if result == .success {
            unBindMiniDeviceSuccess()
        }
        if result == .failed {
            view.sw_showSuccessToast("解除绑定失败")
        }
    }
    
    private func unBindMiniDeviceSuccess() {
        MiniDeviceStorageManager.shared.removeDevice(self.deviceInfo?.uuid ?? "")
        BluetoothManager.shared.disconnectPeripheral()
        NotificationCenter.default.post(name: .deviceListNeedToUpdate, object: nil)
        self.view.sw_showSuccessToast("解除设备成功")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let vc = self.navigationController?.viewControllers.first(where: { $0 is DeviceListViewController }) {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
}

extension MiniDeviceSettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DevieceSettingCell") as! DevieceSettingCell
        
        let settingData = dataSource[indexPath.row]
        // 这里假设你的 DevieceSettingCell 有配置方法
        // 如果没有，你需要根据实际的 cell 实现来设置数据
        cell.configure(with: settingData)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // 或者你想要的合适高度
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let settingData = dataSource[indexPath.row]
        
        // 如果该项可以修改，处理点击事件
        if settingData.canChange {
            handleSettingSelection(at: indexPath, settingData: settingData)
        }
    }
}

extension MiniDeviceSettingViewController {
    private func handleSettingSelection(at indexPath: IndexPath, settingData: SettingData) {
        switch indexPath.row {
        case 1:
            showWorkModeSelection()
        case 2:
            showStatusReportFreqSelection()
        case 3:
            showPositionReportSelection()
        case 4:
            showSavePointTimeSelection()
        case 0, 5:
            // 不可改动的项目，不处理点击
            break
        default:
            break
        }
    }
    
    private func showWorkModeSelection() {
        guard let statusInfo = statusInfo else { return }
        
        let workModeView = WorkModeSelectionView()
        workModeView.delegate = self
        workModeView.show(in: view, currentMode: statusInfo.workMode)
    }
    
    private func showStatusReportFreqSelection() {
        guard let statusInfo = statusInfo else { return }
        
        let freqView = StatusReportFreqSelectionView()
        freqView.delegate = self
        freqView.show(in: view, currentFreq: statusInfo.statusReportFreq)
    }
    
    private func showPositionReportSelection() {
//        guard let statusInfo = statusInfo else { return }
//        
//        let reportView = PositionReportSelectionView() // 需要创建类似的视图
//        reportView.delegate = self
//        reportView.show(in: view, currentReport: statusInfo.positionReport)
        let customView = TeamModifyNameView()
        SWAlertView.showCustomAlert(title: "修改参数（分钟）", customView: customView, confirmTitle: "保存", cancelTitle: "取消", confirmHandler: {
            let num = customView.textField.text
            var positionData = Data()

            if let numString = num, let intervalValue = UInt32(numString) {
                let interval = intervalValue * 60
                // 使用 bigEndian 属性
                let bigEndianInterval = interval.bigEndian
                positionData.append(contentsOf: withUnsafeBytes(of: bigEndianInterval) { Data($0) })
            }
            BluetoothManager.shared.sendCommand(.setPositionReport, messageContent: positionData)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                BluetoothManager.shared.requestStatusInfo()
            }
        })
    }
    
    private func showSavePointTimeSelection() {
//        guard let statusInfo = statusInfo else { return }
//        
//        let reportView = SavePointTimeSelectionView() // 需要创建类似的视图
//        reportView.delegate = self
//        reportView.show(in: view, currentReport: statusInfo.positionStoreTime)
        
        let customView = TeamModifyNameView()
        SWAlertView.showCustomAlert(title: "修改参数（分钟）", customView: customView, confirmTitle: "保存", cancelTitle: "取消", confirmHandler: {
            let num = customView.textField.text
            var positionData = Data()

            if let numString = num, let intervalValue = UInt32(numString) {
                let interval = intervalValue * 60
                // 使用 bigEndian 属性
                let bigEndianInterval = interval.bigEndian
                positionData.append(contentsOf: withUnsafeBytes(of: bigEndianInterval) { Data($0) })
            }
            BluetoothManager.shared.sendCommand(.setPositionStoreInterval, messageContent: positionData)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                BluetoothManager.shared.requestStatusInfo()
            }
        })
    }
    
}

// MARK: - 委托方法
extension MiniDeviceSettingViewController: WorkModeSelectionViewDelegate {
    func didSelectWorkMode(_ mode: UInt8) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            BluetoothManager.shared.requestStatusInfo()
        }
    }
}

extension MiniDeviceSettingViewController: StatusReportFreqSelectionViewDelegate {
    func didSelectStatusReportFreq(_ freq: UInt8) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            BluetoothManager.shared.requestStatusInfo()
        }
    }
}

extension MiniDeviceSettingViewController: PositionReportSelectionViewDelegate {
    func didSelectPositionReport(_ report: UInt32) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            BluetoothManager.shared.requestStatusInfo()
        }
    }
}

extension MiniDeviceSettingViewController: SavePointTimeSelectionViewDelegate {
    func didSelectSavePointTime(_ report: UInt32) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            BluetoothManager.shared.requestStatusInfo()
        }
    }
}


extension Notification.Name {
    static let deviceListNeedToUpdate = Notification.Name("deviceListNeedToUpdate")
}


class TeamModifyNameView: UIView, SWAlertCustomView {
    
    lazy var textField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.font = .pingFangFontMedium(ofSize: 14)
        textField.textColor = ThemeManager.current.titleColor
        textField.tintColor = ThemeManager.current.mainColor
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "请输入分钟数"
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.layer.cornerRadius = CornerRadius.medium.rawValue
        textField.layer.masksToBounds = true
        textField.layer.borderColor = ThemeManager.current.errorColor.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Layout.hMargin, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.keyboardType = .numberPad
        return textField
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.errorColor
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.left.right.equalToSuperview()
        }
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(17))
            make.top.equalTo(textField.snp.bottom).offset(swAdaptedValue(8))
            make.bottom.equalToSuperview().inset(swAdaptedValue(8))
            make.leading.equalTo(textField.snp.leading)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func shouldClickConfirmButton() -> Bool {
        if let text = textField.text, text.count > 20 {
            errorLabel.text = "已达昵称长度上限"
            textField.layer.borderWidth = 1
            return false
        } else {
            errorLabel.text = ""
            textField.layer.borderWidth = 0
            return true
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, text.count > 20 {
            errorLabel.text = "已达昵称长度上限"
            textField.layer.borderWidth = 1
        } else {
            errorLabel.text = ""
            textField.layer.borderWidth = 0
        }
    }
    
    func alertDidShow() {
        textField.becomeFirstResponder()
    }
}
