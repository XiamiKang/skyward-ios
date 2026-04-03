//
//  HomeViewModel.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/16.
//

import Foundation
import Combine
import Moya
import SWNetwork
import SWKit
import ModulePersonal // 后面把设备单独抽离出模块来
import CoreBluetooth

public class HomeViewModel: ObservableObject {
    
    @Published var noticeList: [HomeNoticeItem] = []
    @Published var weatherInfo: WeatherInfo?
    @Published var selectedMiniDevice: MiniDevice?
    @Published var selectedProDevice: WiFiDevice?
    
    private var selectedMiniDeviceStatusInfo: StatusInfo?  //选中的设备的状态信息
    private var selectedMiniDeviceSatelliteNum: Int?       //选中的设备的卫星信号
    
    private var latestMessage: HomeNoticeItem?
    
    private var didPublish: Bool = false
    
    private let locationManager = LocationManager()
    
    // 在线心跳定时器
    private var onlinePingTimer: Timer?
    
    // MARK: - Initialization
    public init() {
        // 通知
        setupNotifications()
        
        // MQTT
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: [HomeAPI.noticeNew_sub])
        
        // 启动在线心跳定时器
        startOnlinePingTimer()
        
        // 天气
        getWeatherInfo()
        
        WiFiDeviceManager.shared.connect()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopOnlinePingTimer()
    }
    
    // MARK: - Public Methods
    
    func getMiniDeviceListData() -> [MiniDevice] {
        let baseModel = BaseModel(pageNum: 1, pageSize: 20)
        PersonalViewModel().input.deviceListRequest.send(baseModel)
        
        var savedMiniDevices: [MiniDevice] = []
        let connectedMiniDevice = BluetoothManager.shared.connectedScannedPeripheral
        if let miniDevices = MiniDeviceDBManager.shared.qureyFromMiniDeviceDataAllData() {
            miniDevices.forEach { device in
                let status = selectedMiniDevice?.info.imeiNum == device.imeiNum ? selectedMiniDevice?.status : nil
                let satelliteNum = selectedMiniDevice?.info.imeiNum == device.imeiNum ? selectedMiniDevice?.satelliteNum : nil
                var connected = false
                if  device.imeiNum == connectedMiniDevice?.imeiNum {
                   connected = true
                }
                let miniDevice = MiniDevice(info: device, status: status, satelliteNum: satelliteNum, connected: connected)
                savedMiniDevices.append(miniDevice)
            }
            return savedMiniDevices
        }
        return []
    }
    
    func getProDeviceListData() -> [WiFiDevice] {
        return WiFiDeviceStorageManager.shared.getAllDevices()
    }
    
    func setupDevice() {
        
        if let miniDevice = getMiniDeviceListData().first {
            selectedMiniDevice = miniDevice
            linkOrBreakMiniDevice(miniDevice)
        }
        
        if let proDevice = getProDeviceListData().first {
            selectedProDevice = proDevice
        }

        if BluetoothManager.shared.connectedPeripheral != nil {
            BluetoothManager.shared.requestStatusInfo()
        }
    }
    
    func linkOrBreakMiniDevice(_ device: MiniDevice) {
        if device.connected {
            BluetoothManager.shared.disconnectPeripheral()
        } else {
            let scannedMiniDevices = BluetoothManager.shared.getAllScannedDevices()
            Logger.debug("扫描出来的窄带设备--\(scannedMiniDevices)")
            for miniDevice in scannedMiniDevices {
                if device.info.imeiNum == miniDevice.imei {
                    BluetoothManager.shared.connectToPeripheral(miniDevice.peripheral)
                    return
                }
            }
            
        }
    }
    
    // MARK: - Notice List
    
    func loadPage() {
        loadNoticeList()
        _Concurrency.Task {
            await requestNoticeList()
            loadNoticeList()
        }
    }
    
    func loadNoticeList() {
        self.noticeList = DBManager.shared.queryFromDb(fromTable: DBTableName.homeNotice.rawValue, cls: HomeNoticeItem.self, orderBy: [HomeNoticeItem.Properties.noticeTimeTimestamp.order(.descending)]) ?? []
    }
    
    func cleanMessage() {
        MQTTManager.shared.publish(message: "{}", to: HomeAPI.cleanMessage_pub, qos: .qos1)
    }
    
    private func didReceiveNotice(_ notice: HomeNoticeItem) {
        DBManager.shared.insertToDb(objects: [notice], intoTable: DBTableName.homeNotice.rawValue)
        loadNoticeList()
    }
    
    // MARK: - network

    private func getWeatherInfo() {
        locationManager.getCurrentLocation {[weak self] location, error in
            guard let location = location else {
                return
            }
            
            var districtName = ""
            var weatherInfo: WeatherInfo?
            
            let group = DispatchGroup()
            group.enter()
            LocationManager.reverseGeocode(location: location) { placemark in
                if let district = placemark?.subLocality {
                    districtName = district
                }
                group.leave()
            }
            
            group.enter()
            NetworkProvider<HomeAPI>().request(.weatherInfo(longitude: location.coordinate.longitude, latitude: location.coordinate.latitude)) { result in
                group.leave()
                if case .success(let rsp) = result {
                    do {
                        let networkResponse = try rsp.map(NetworkResponse<WeatherInfo>.self)
                        weatherInfo = networkResponse.data
                    } catch {
                        
                    }
                }
            }
            
            group.notify(queue: .main) {
                weatherInfo?.district = districtName
                if weatherInfo != nil {
                    self?.weatherInfo = weatherInfo
                }
            }
        }
    }
    
    private func requestNoticeList() async {
        do {
            let rsp = try await NetworkProvider<HomeAPI>().request(.noticeList)
            let networkResponse = try JSONDecoder().decode(NetworkResponse<[HomeNoticeItem]>.self, from: rsp.data)
            if let notices = networkResponse.data, notices.count > 0 {
                DBManager.shared.insertToDb(objects: notices, intoTable: DBTableName.homeNotice.rawValue)
            }
        } catch {
            Logger.debug("[通知列表] 请求失败: \(error)")
        }
    }
    
    // MARK: - Notification
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusInfoUpdate(_:)),
            name: .didReceiveStatusInfo,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSatelliteInfo(_:)),
            name: .didReceiveSatelliteInfo,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveOfflineReportState(_:)),
            name: .offlineReportState,
            object: nil
        )
    }
    
    @objc private func handleStatusInfoUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let statusInfo = userInfo["statusInfo"] as? StatusInfo else {
            return
        }
        selectedMiniDeviceStatusInfo = statusInfo
        uploadSelectedMiniDevice()
    }
    
    @objc private func showSatelliteInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let satelliteInfo = userInfo["satelliteInfo"] as? String {
            Logger.debug("Mini设备卫星状态--首页Model--\(satelliteInfo)")
            selectedMiniDeviceSatelliteNum = Int(satelliteInfo)
            uploadSelectedMiniDevice()
        }
    }
    
    private func uploadSelectedMiniDevice() {
        if let deviceInfo = BluetoothManager.shared.connectedScannedPeripheral  {
            selectedMiniDevice = MiniDevice(info: deviceInfo, status: selectedMiniDeviceStatusInfo, satelliteNum: selectedMiniDeviceSatelliteNum, connected: true)
        } else {
            selectedMiniDevice?.connected = false
        }
    }
    
    
    /// 收到离线上报状态的通知（SOS/报平安）
    @objc private func receiveOfflineReportState(_ notification: Notification) {
        Logger.debug("[离线上报] 收到通知: \(notification.object ?? "未知")")

        // 如果 ReportType 是枚举，可能需要用 rawValue 或者从 userInfo 中获取
        guard let type = notification.object as? ReportType else {
            // 如果类型转换失败，尝试其他方式
            Logger.debug("[离线上报] 类型转换失败")
            return
        }

        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        let noticeType: NoticeType
        switch type {
        case .safety:
            noticeType = .safety
        case .openSOS:
            noticeType = .sos
        case .closeSOS:
            noticeType = .disarmSOS
        }
        
        let notice = HomeNoticeItem(noticeId: String(timestamp), noticeType: noticeType, noticeContent: type.reportStateTip, reportId: nil, noticeTimeTimestamp: timestamp)
        
        didReceiveNotice(notice)
    }
    
}

extension HomeViewModel: MQTTManagerDelegate {
    public func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectState) {
        if state == .connected, !didPublish {
            sendOnlinePing()
            didPublish = true
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == HomeAPI.noticeNew_sub else {
            return
        }
        
        guard let jsonData = message.data(using: .utf8) else {
            return
        }
        
        do {
            let notice  = try JSONDecoder().decode(HomeNoticeItem.self, from: jsonData)
            didReceiveNotice(notice)
        } catch {
            Logger.debug("[JSON解析] 解析失败: \(error)")
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String) {
        if topic == HomeAPI.cleanMessage_pub {
            DBManager.shared.deleteFromDb(fromTable: DBTableName.homeNotice.rawValue)
            noticeList.removeAll()
        }
    }
}

// MARK: - MQTT online
extension HomeViewModel {
    /// 启动在线心跳定时器
    private func startOnlinePingTimer() {
        // 每60秒发送一次
        onlinePingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.sendOnlinePing()
        }
        
        // 将定时器添加到RunLoop，确保在主线程运行
        if let timer = onlinePingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// 停止在线心跳定时器
    private func stopOnlinePingTimer() {
        onlinePingTimer?.invalidate()
        onlinePingTimer = nil
    }
    
    /// 发送在线心跳
    private func sendOnlinePing() {
        MQTTManager.shared.publish(message: "{}", to: HomeAPI.onlinePing_pub, qos: .qos1)
        Logger.debug("✅ 发送在线心跳到: \(HomeAPI.onlinePing_pub)")
    }
}

