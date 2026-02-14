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
    @Published var noticeTypeItems: [NoticeTypeItem] = [NoticeTypeItem(noticeType: .all, selected: true, count: 0),
                                                        NoticeTypeItem(noticeType: .sos, selected: false, count: 0),
                                                        NoticeTypeItem(noticeType: .safety, selected: false, count: 0),
                                                        NoticeTypeItem(noticeType: .weather, selected: false, count: 0),
                                                        NoticeTypeItem(noticeType: .service, selected: false, count: 0)]
    
    private var selectedMiniDeviceStatusInfo: StatusInfo?  //选中的设备的状态信息
    private var selectedMiniDeviceSatelliteNum: Int?       //选中的设备的卫星信号
    
    private var latestMessage: HomeNewMessageModel?
    private var noticeReponse: HomeNoticeModel = HomeNoticeModel(totalCount: 0, safeCount: 0, sosCount: 0, weatherCount: 0, safeList: [], sosList: [], weatherList: [])
    
    private var homeCache: SWCache?
    
    private var didPublish: Bool = false
    
    private let locationManager = LocationManager()
    
    // 在线心跳定时器
    private var onlinePingTimer: Timer?
    
    // MARK: - Initialization
    public init() {
        // 通知
        setupNotifications()
        
        // 初始化缓存
        setupCaches()
        
        // 初始加载缓存数据
        loadCacheData()
        
        // MQTT
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: [noticeList_sub,latestMessage_sub])
        
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
    
    func selectNoticeTypeItem(_ noticeTypeItem: NoticeTypeItem) {
        // 如果点击的已经是选中项，则不需要操作
        guard !noticeTypeItem.selected else {
            return
        }
        
        // 根据传入item的noticeType，重新创建noticeTypeItems数组，设置正确的selected状态
        noticeTypeItems = noticeTypeItems.map { item in
            var mutableItem = item
            // 匹配的项设为选中，非匹配项设为未选中
            mutableItem.selected = (item.noticeType == noticeTypeItem.noticeType)
            return mutableItem
        }
        
        // 根据选中的类型更新通知列表
        updateNoticeList()
    }
    
    func linkOrBreakMiniDevice(_ device: MiniDevice) {
        if device.connected {
            BluetoothManager.shared.disconnectPeripheral()
        } else {
            let scannedMiniDevices = BluetoothManager.shared.getAllScannedDevices()
            print("扫描出来的窄带设备--\(scannedMiniDevices)")
            for miniDevice in scannedMiniDevices {
                if device.info.imeiNum == miniDevice.imei {
                    BluetoothManager.shared.connectToPeripheral(miniDevice.peripheral)
                    return
                }
            }
            
        }
    }
    
    func cleanMessage() {
        MQTTManager.shared.publish(message: "{}", to: cleanMessage_pub, qos: .qos1)
    }
    
    // MARK: - Private
    
    /// 更新通知类型计数
    private func updateNoticeTypeItems() {
        noticeTypeItems = noticeTypeItems.map { item in
            var mutableItem = item
            switch item.noticeType {
            case .all:
                if latestMessage == nil {
                    mutableItem.count = noticeReponse.totalCount
                } else {
                    mutableItem.count = noticeReponse.totalCount + 1
                }
            case .sos:
                mutableItem.count = noticeReponse.sosCount
            case .safety:
                mutableItem.count = noticeReponse.safeCount
            case .weather:
                mutableItem.count = noticeReponse.weatherCount
            case .service:
                if latestMessage == nil {
                    mutableItem.count = 0
                } else {
                    mutableItem.count = 1
                }
            }
            return mutableItem
        }
    }
    
    private func updateNoticeList() {
        // 找到选中的通知类型项
        guard let selectedItem = noticeTypeItems.first(where: { $0.selected }) else {
            return
        }
        
        // 根据选中类型获取对应的通知列表
        var filteredNotices: [HomeNoticeItem]
        
        // 处理最新消息，声明为可选类型
        var latestNotice: HomeNoticeItem?
        if let latestMessage = latestMessage {
            latestNotice = HomeNoticeItem(noticeId: nil,
                                         noticeType: .service,
                                         noticeContent: latestMessage.message,
                                         reportId: latestMessage.sendId,
                                         noticeTime: nil)
        }
        
        switch selectedItem.noticeType {
        case .all:
            filteredNotices = noticeReponse.allNotices
        case .sos:
            filteredNotices = noticeReponse.sosList
        case .safety:
            filteredNotices = noticeReponse.safeList
        case .weather:
            filteredNotices = noticeReponse.weatherList
        case .service:
            filteredNotices = latestNotice != nil ? [latestNotice!] : []
        }
        
        // 按noticeTime降序排序
        filteredNotices.sort { item1, item2 in
            guard let time1 = item1.noticeTime else { return false }  // 没有时间的排在后面
            guard let time2 = item2.noticeTime else { return true }   // 有时间的排在前面
            return time1 > time2  // 降序排序（时间大的排前面）
        }
        
        if selectedItem.noticeType == .all {
            // 如果是所有，有最新通知，将其插入到列表最前面
            if let latestNotice = latestNotice {
                filteredNotices.insert(latestNotice, at: 0)
            }
        }
        
        // 在主线程更新UI
        DispatchQueue.main.async {
            self.noticeList = filteredNotices
        }
    }

    private func getWeatherInfo() {
        locationManager.getCurrentLocation {[weak self] location, error in
            guard let location = location else {
                return
            }
            NetworkProvider<HomeAPI>().request(.weatherInfo(longitude: location.coordinate.longitude, latitude: location.coordinate.latitude)) { result in
                if case .success(let rsp) = result {
                    do {
                        let networkResponse = try rsp.map(NetworkResponse<WeatherInfo>.self)
                        if let weatherInfo = networkResponse.data {
                            self?.weatherInfo = weatherInfo
                        }
                    } catch {
                        
                    }
                }
            }
        }
    }
    
    // MARK: - Cache
    
    private func setupCaches() {
        do {
            homeCache = try SWCache(dirName: CacheModuleName.home.module)
        } catch {
            debugPrint("❌ SWCache 创建失败: \(error.localizedDescription)")
        }
    }
    
    private func loadCacheData() {
        let dispatchGroup = DispatchGroup()

        // 加载最新消息缓存
        dispatchGroup.enter()
        loadCacheValue(forKey: latestMessage_sub) { [weak self] (data: Data?) in
            guard let self = self, let data = data else {
                dispatchGroup.leave()
                return
            }
            if let reponse = try? JSONDecoder().decode(HomeNewMessageModel.self, from: data) {
                self.latestMessage = reponse
            }
            dispatchGroup.leave()
        }

        // 加载通知列表缓存
        dispatchGroup.enter()
        loadCacheValue(forKey: noticeList_sub) { [weak self] (data: Data?) in
            guard let self = self, let data = data else {
                dispatchGroup.leave()
                return
            }
            if let reponse = try? JSONDecoder().decode(HomeNoticeModel.self, from: data) {
                self.noticeReponse = reponse
            }
            dispatchGroup.leave()
        }

        // 两个缓存都加载完成后执行
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.updateNoticeTypeItems()
            self.updateNoticeList()
        }
    }
    
    private func loadCacheValue(forKey key: String,completion: @escaping (Data?) -> Void) {
        guard let cache = homeCache else {
            completion(nil)
            return
        }
        
        cache.value(forKey: key) { result in
            switch result {
            case .success(let cacheResult):
                switch cacheResult {
                case .memory(let data), .disk(let data):
                    completion(data)
                case .none:
                    debugPrint("没有缓存数据 for key: \(key)")
                    completion(nil)
                }
            case .failure(let error):
                debugPrint("❌ 加载缓存失败 for key: \(key): \(error)")
                completion(nil)
            }
        }
    }
    
    private func saveCacheValue(data: Data, forKey key: String) {
        guard let cache = homeCache else { return }
        
        cache.setValue(data, forKey: key, toDisk: true) { result in
            switch result.memoryCacheResult {
            case .success:
                debugPrint("✅ 内存存储成功 for key: \(key)")
            case .failure(let error):
                debugPrint("❌ 内存存储失败 for key: \(key): \(error)")
            }
            
            switch result.diskCacheResult {
            case .success:
                debugPrint("✅ 磁盘存储成功 for key: \(key)")
            case .failure(let error):
                debugPrint("❌ 磁盘存储失败 for key: \(key): \(error)")
            }
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
            debugPrint("Mini设备卫星状态--首页Model--\(satelliteInfo)")
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
    
}

extension HomeViewModel: MQTTManagerDelegate {
    public func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectState) {
        if state == .connected, !didPublish {
            sendOnlinePing()
            //通知列表
            manager.publish(message: "{}", to: noticeList_pub, qos:.qos1)
            //最新消息
            manager.publish(message: "{}", to: latestMessage_pub, qos:.qos1)
            didPublish = true
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        let noticeListSubscribeTopic = noticeList_sub
        let latestMessageSubscribeTopic = latestMessage_sub
        guard topic == noticeListSubscribeTopic || topic == latestMessageSubscribeTopic else {
            return
        }
        
        guard let jsonData = message.data(using: .utf8) else {
            return
        }
        
        do {
            if topic == noticeListSubscribeTopic {
                self.noticeReponse = try JSONDecoder().decode(HomeNoticeModel.self, from: jsonData)
                saveCacheValue(data: jsonData, forKey: noticeListSubscribeTopic)
            } else if topic == latestMessageSubscribeTopic {
                self.latestMessage = try JSONDecoder().decode(HomeNewMessageModel.self, from: jsonData)
                saveCacheValue(data: jsonData, forKey: latestMessageSubscribeTopic)
            }
            updateNoticeTypeItems()
            updateNoticeList()
        } catch {
            debugPrint("[JSON解析] 解析失败: \(error)")
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String) {
        if topic == cleanMessage_pub {
            guard let cache = homeCache else { return }
            cache.cleanMemoryAndDiskCache(forKey: noticeList_sub)
            cache.cleanMemoryAndDiskCache(forKey: latestMessage_sub)
            noticeReponse = HomeNoticeModel(totalCount: 0, safeCount: 0, sosCount: 0, weatherCount: 0, safeList: [], sosList: [], weatherList: [])
            latestMessage = nil
            updateNoticeTypeItems()
            updateNoticeList()
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
        MQTTManager.shared.publish(message: "{}", to: onlinePing_pub, qos: .qos1)
        debugPrint("✅ 发送在线心跳到: \(onlinePing_pub)")
    }
}

