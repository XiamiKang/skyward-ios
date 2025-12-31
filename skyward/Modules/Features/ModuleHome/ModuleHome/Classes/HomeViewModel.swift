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
    
    var savedMiniDevices: [MiniDevice] {
        get {
            var savedMiniDevices: [MiniDevice] = []
            let peripheral = BluetoothManager.shared.connectedPeripheral
            BluetoothManager.shared.getAllSavedDevices().forEach { info in
                let status = selectedMiniDevice?.info.uuid == info.uuid ? selectedMiniDevice?.status : nil
                let miniDevice = MiniDevice(info: info, status: status, connected: info.uuid == peripheral?.identifier.uuidString)
                savedMiniDevices.append(miniDevice)
            }
            return savedMiniDevices
        }
    }
    var latestMessage: HomeNewMessageModel?
    var noticeReponse: HomeNoticeModel = HomeNoticeModel(totalCount: 0, safeCount: 0, sosCount: 0, weatherCount: 0, safeList: [], sosList: [], weatherList: [])
    
    private var homeCache: SWCache?
    
    @Published var noticeTypeItems: [NoticeTypeItem] = [NoticeTypeItem(noticeType: .all, selected: true, count: 0),
                                                        NoticeTypeItem(noticeType: .sos, selected: false, count: 0),
                                                        NoticeTypeItem(noticeType: .safety, selected: false, count: 0),
                                                        NoticeTypeItem(noticeType: .weather, selected: false, count: 0),
                                                        NoticeTypeItem(noticeType: .service, selected: false, count: 0)]
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
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopOnlinePingTimer()
    }
    
    // MARK: - Public Methods
    
    func setupZhaidaiDevice() {
        
        if let miniDevice = self.savedMiniDevices.first {
            selectedMiniDevice = miniDevice
            linkOrBreakMiniDevice(miniDevice)
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
            let scannedDevices = BluetoothManager.shared.getAllScannedDevices()
            print("保存后的扫描设备--\(scannedDevices)")
            for scannedDevice in scannedDevices {
                if device.info.uuid == scannedDevice.peripheral.identifier.uuidString {
                    BluetoothManager.shared.connectToPeripheral(scannedDevice.peripheral)
                    return
                }
            }
        }
    }
    
    public func cleanMessage() {
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

    func getWeatherInfo() {
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
            print("❌ SWCache 创建失败: \(error)")
            print("错误详情: \(error.localizedDescription)")
        }
    }
    
    private func loadCacheData() {
        // 加载最新消息缓存
        loadCacheValue(forKey: latestMessage_sub) { [weak self] (data: Data?) in
            guard let self = self, let data = data else { return }
            self.latestMessage = try? JSONDecoder().decode(HomeNewMessageModel.self, from: data)
            self.updateNoticeTypeItems()
            self.updateNoticeList()
        }
        
        // 加载通知列表缓存
        loadCacheValue(forKey: noticeList_sub) { [weak self] (data: Data?) in
            guard let self = self, let data = data else { return }
            if let reponse = try? JSONDecoder().decode(HomeNoticeModel.self, from: data) {
                self.noticeReponse = reponse
            }

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
                    print("没有缓存数据 for key: \(key)")
                    completion(nil)
                }
            case .failure(let error):
                print("❌ 加载缓存失败 for key: \(key): \(error)")
                completion(nil)
            }
        }
    }
    
    private func saveCacheValue(data: Data, forKey key: String) {
        guard let cache = homeCache else { return }
        
        cache.setValue(data, forKey: key, toDisk: true) { result in
            switch result.memoryCacheResult {
            case .success:
                print("✅ 内存存储成功 for key: \(key)")
            case .failure(let error):
                print("❌ 内存存储失败 for key: \(key): \(error)")
            }
            
            switch result.diskCacheResult {
            case .success:
                print("✅ 磁盘存储成功 for key: \(key)")
            case .failure(let error):
                print("❌ 磁盘存储失败 for key: \(key): \(error)")
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
    }
    
    @objc private func handleStatusInfoUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let statusInfo = userInfo["statusInfo"] as? StatusInfo else {
            return
        }
        
        if let peripheral = BluetoothManager.shared.connectedPeripheral,
           let deviceInfo = BluetoothManager.shared.getAllSavedDevices().first(where: {$0.uuid == peripheral.identifier.uuidString})  {
            selectedMiniDevice = MiniDevice(info: deviceInfo, status: statusInfo, connected: true)
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
        
        // 确保在主线程更新UI
        _Concurrency.Task { @MainActor in
            do {
                // 将消息字符串转换为Data
                guard let jsonData = message.data(using: .utf8) else {
                    print("[JSON解析] 消息转换为Data失败")
                    return
                }
                
                // 使用JSONDecoder直接解析数据
                let decoder = JSONDecoder()

                if topic == noticeListSubscribeTopic {
                    self.noticeReponse = try decoder.decode(HomeNoticeModel.self, from: jsonData)
                    saveCacheValue(data: jsonData, forKey: noticeListSubscribeTopic)
                } else if topic == latestMessageSubscribeTopic {
                    self.latestMessage = try decoder.decode(HomeNewMessageModel.self, from: jsonData)
                    saveCacheValue(data: jsonData, forKey: latestMessageSubscribeTopic)
                }
                
                // 更新通知类型计数
                updateNoticeTypeItems()
                
                // 根据当前选中的通知类型更新列表
                updateNoticeList()
                
                print("[JSON解析] 成功解析通知: 总数\(self.noticeReponse.totalCount), SOS\(self.noticeReponse.sosCount)")
            } catch {
                print("[JSON解析] 解析失败: \(error)")
            }
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
    
    public func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: (any Error)?) {
        
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
        print("✅ 发送在线心跳到: \(onlinePing_pub)")
    }
}

