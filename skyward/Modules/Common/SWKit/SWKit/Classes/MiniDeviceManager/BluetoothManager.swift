//
//  BluetoothManagerDelegate.swift
//  test11
//
//  Created by yifan kang on 2025/11/13.
//


import Foundation
import CoreBluetooth
import SWNetwork

public protocol BluetoothManagerDelegate: AnyObject {
    func didUpdateBluetoothState(_ state: CBManagerState)
    func didDiscoverPeripheral(_ peripheral: CBPeripheral)
    func didConnectPeripheral(_ peripheral: CBPeripheral)
    func didDisconnectPeripheral(_ peripheral: CBPeripheral)
    func didFailToConnectPeripheral(_ peripheral: CBPeripheral, error: Error?)
}

public class BluetoothManager: NSObject {
    
    public static let shared = BluetoothManager()
    
    public weak var delegate: BluetoothManagerDelegate?
    
    // MARK: - 属性
    private var centralManager: CBCentralManager!
    private(set) var discoveredPeripherals: [CBPeripheral] = []
    public private(set) var filteredPeripherals: [CBPeripheral] = []
    public var connectedPeripheral: CBPeripheral?
    
    public var writeCharacteristic: CBCharacteristic?
    public var writeWithoutResponseCharacteristic: CBCharacteristic?
    public var notifyCharacteristic: CBCharacteristic?
    
    private var scannedDevices: [String: ScannedDevice] = [:] // key: IMEI
    private var deviceIMEIMap: [UUID: String] = [:] // Peripheral identifier 到 IMEI 的映射
    
    // UUID配置
    let serviceUUID = CBUUID(string: "1273FFF0-580E-0287-4B44-35BA9C22894B")
    let characteristicUUID1 = CBUUID(string: "1273FFF1-580E-0287-4B44-35BA9C22894B")
    let characteristicUUID2 = CBUUID(string: "1273FFF2-580E-0287-4B44-35BA9C22894B")
    
    
    // 协议相关
    public var currentTXTSerialNumber: UInt32 = 0
    public var currentK01SerialNumber: UInt8 = 0
    public var deviceType: BluetoothDeviceType = .TXTS
    public var packetAssembler = PacketAssembler()
    public var firmwareManager = FirmwareUpgradeManager()
    public var crcCalculator = CRC16.ibm
    public var MTU = 244
    public var isShowingSOSAlert = false
    
    // 筛选关键词
    var filterKeyword: String = "TXTS"
    
    public var isConnected: Bool {
        return connectedPeripheral != nil && connectedPeripheral?.state == .connected
    }
    
    // 连接的外设对应的保存在本地的设备信息
    public var connectedScannedPeripheral: MiniDeviceData? {
        if connectedPeripheral != nil && connectedPeripheral?.state == .connected {
            for scannedDevice in scannedDevices.values {
                if scannedDevice.peripheral == connectedPeripheral {
                    if let miniDeviceData = MiniDeviceDBManager.shared.qureyFromMiniDeviceWithIMEI(scannedDevice.imei)?.first {
                        return miniDeviceData
                    }
                }
            }
        }
        return nil
    }
    
    // MARK: - 初始化
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // MARK: - 蓝牙基础操作
    // MARK: - 开启蓝牙扫描
    public func startScanningForFilteredDevices(keyword: String = "TXTS") {
        self.filterKeyword = keyword
        scanForPeripherals()
    }
    
    func scanForPeripherals(withServiceUUIDs serviceUUIDs: [CBUUID]? = nil, options: [String: Any]? = nil) {
        guard centralManager.state == .poweredOn else {
            print("蓝牙未开启，无法扫描")
            return
        }
        
        discoveredPeripherals.removeAll()
        filteredPeripherals.removeAll()
        
        if let serviceUUIDs = serviceUUIDs {
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: options)
        }
        
        print("开始扫描蓝牙设备...")
    }
    // MARK: - 停止蓝牙扫描
    public func stopScanning() {
        centralManager.stopScan()
        print("停止扫描")
    }
    
    public func connectToPeripheral(_ peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }
    
    public func disconnectPeripheral() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func getFilteredPeripherals() -> [CBPeripheral] {
        return filteredPeripherals
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    // MARK: - 蓝牙状态
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.didUpdateBluetoothState(central.state)
        // 蓝牙状态改变
        switch central.state {
        case .poweredOn:
            print("蓝牙已开启")
            startScanningForFilteredDevices()
        case .poweredOff:
            print("蓝牙未开启")
        case .unauthorized:
            print("蓝牙权限未授权")
        case .unsupported:
            print("设备不支持蓝牙")
        case .resetting:
            print("蓝牙重置中")
        case .unknown:
            print("蓝牙状态未知")
        @unknown default:
            print("未知状态")
        }
    }
    // MARK: - 蓝牙扫描
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            let isTarget = isTargetDevice(with: peripheral, advertisementData: advertisementData)
            if isTarget {
                print("保存目标设备---")
                processTargetDevice(peripheral, advertisementData: advertisementData, rssi: RSSI)
            }
        }
    }
    
    // MARK: - 蓝牙连接
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        connectedPeripheral = peripheral
        
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        
        print("连接成功: \(peripheral.name ?? "未知设备")")
        // 保存设备信息到本地
        for scannedDevice in scannedDevices.values {
            if scannedDevice.peripheral == peripheral {
                let lastFourDigits = String(scannedDevice.imei.suffix(5))
                let name = "行者mini_\(lastFourDigits)"
                let deviceData = MiniDeviceData(name: name, serialNum: scannedDevice.imei, imeiNum: scannedDevice.imei, forthGenCardNum: "", typeCode: "NARROW_BAND", state: 0, macAddress: scannedDevice.macAddress, model: "TXTS-NB-01")
                // 保存设备信息到本地
                MiniDeviceDBManager.shared.insertFromMiniDeviceList([deviceData])
                // 保存设备信息到后台
                UserManager.shared.bindDevice(serialNum: scannedDevice.imei, macAddress: scannedDevice.macAddress)
                // 修改协议类型
                deviceType = BluetoothDeviceType(rawValue: scannedDevice.productId) ?? .TXTS
            }
            
        }
        
        // 代理
        delegate?.didConnectPeripheral(peripheral)
        // 延时等待特征发现
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            print("连接稳定，请求设备状态信息")
            self.requestDeviceInfo()
            self.requestStatusInfo()
            self.getSatelliteSignal()
            // 无网绑定设备到该用户
            let hasNetwork = NetworkMonitor.shared.isConnected
            if !hasNetwork {
                if let data = MessageGenerator.generateDeviceBind(userId: UserManager.shared.userId) {
                    self.sendAppCustomData(data)
                }
            }
        }
    }
    
    // MARK: - 蓝牙连接失败
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败: \(peripheral.name ?? "未知设备") - \(error?.localizedDescription ?? "未知错误")")
        delegate?.didFailToConnectPeripheral(peripheral, error: error)
    }
    
    // MARK: - 蓝牙断开连接
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("设备断开: \(peripheral.name ?? "未知设备")")
        connectedPeripheral = nil
        delegate?.didDisconnectPeripheral(peripheral)
        NotificationCenter.default.post(name: .bluetoothDeviceDisconnected, object: nil)
    }
    
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    // MARK: - 发现蓝牙服务
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("发现服务错误: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        print("发现 \(services.count) 个服务")
        
        for service in services {
            print("服务 UUID: \(service.uuid)")
            peripheral.discoverCharacteristics([characteristicUUID1, characteristicUUID2], for: service)
        }
    }
    // MARK: - 发现蓝牙特征
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("发现特征错误: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        print("发现 \(characteristics.count) 个特征")
        
        // 重置缓存
        writeCharacteristic = nil
        writeWithoutResponseCharacteristic = nil
        notifyCharacteristic = nil
        
        for characteristic in characteristics {
            print("特征 UUID: \(characteristic.uuid)")
            print("特征属性: \(characteristic.properties.rawValue)")
            
            let properties = characteristic.properties
            // 缓存特征
            if properties.contains(.write) {
                writeCharacteristic = characteristic
                print("✅ 缓存有响应写入特征")
            }
            if properties.contains(.writeWithoutResponse) {
                writeWithoutResponseCharacteristic = characteristic
                print("✅ 缓存无响应写入特征")
            }
            if properties.contains(.notify) {
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                print("✅ 已开启通知并缓存通知特征")
            }
            if properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
        
        // 打印最终找到的特征
        print("特征发现完成:")
        print("  有响应写入特征: \(writeCharacteristic?.uuid.uuidString ?? "无")")
        print("  无响应写入特征: \(writeWithoutResponseCharacteristic?.uuid.uuidString ?? "无")")
        print("  通知特征: \(notifyCharacteristic?.uuid.uuidString ?? "无")")
    }
    // MARK: - 蓝牙特征发生变化（收到蓝牙的数据）
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("读取数据错误: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            print("没有数据")
            return
        }
        
        // 检查 MTU 大小
        let mtu = peripheral.maximumWriteValueLength(for: .withoutResponse)
//        print("当前 MTU: \(mtu)")
        MTU = mtu
        
        handleReceivedData(data, from: characteristic)
    }
    // MARK: - 给蓝牙写入数据
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入数据错误: \(error.localizedDescription)")
        } else {
            print("数据写入成功: \(characteristic.uuid)")
        }
    }
    // MARK: - 蓝牙通知状态更新
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("通知状态更新错误: \(error.localizedDescription)")
            return
        }
        
        if characteristic.isNotifying {
            print("通知已开启: \(characteristic.uuid)")
        } else {
            print("通知已关闭: \(characteristic.uuid)")
        }
    }
}

// MARK: - 设备扫描功能扩展
extension BluetoothManager {
    
    // MARK: - 添加获取当前状态的方法
    public func getCurrentBluetoothState() -> CBManagerState {
        return centralManager.state
    }
    
    // MARK: - 判断是否是目标设备
    private func isTargetDevice(with peripheral: CBPeripheral, advertisementData: [String: Any]) -> Bool {
        // 检查 peripheral.name
        if let name = peripheral.name, name.uppercased().contains(filterKeyword.uppercased()) {
            return true
        }
        
        // 检查广播数据中的本地名称
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
           localName.uppercased().contains(filterKeyword.uppercased()) {
            return true
        }
        
        return false
    }
    
    // MARK: - 解析广播数据并存储目标设备
    private func processTargetDevice(_ peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        if let bleData = parseBLEAdvertisementData(advertisementData) {
            print("✅ 扫描到目标设备 - IMEI: \(bleData.deviceId), RSSI: \(rssi), 名称: \(peripheral.name ?? "未知")")
            filteredPeripherals.append(peripheral)
            saveDeviceWithAdvertisementData(
                peripheral: peripheral,
                rssi: rssi,
                bleData: bleData
            )
            delegate?.didDiscoverPeripheral(peripheral)
        }
    }
    
    // MARK: - 保存扫描到的设备信息
    private func saveDeviceWithAdvertisementData(peripheral: CBPeripheral,
                                                 rssi: NSNumber,
                                                 bleData: BLEAdvertisementData) {
        
        
        let deviceName = peripheral.name ?? "未知设备"
        
        let device = ScannedDevice(
            peripheral: peripheral,
            imei: bleData.deviceId,
            rssi: rssi.intValue,
            macAddress: bleData.macAddress,
            bondStatus: bleData.bondStatus,
            deviceName: deviceName,
            productId: bleData.productId,
            advVersion: bleData.advVersion,
            timestamp: Date()
        )
        
        // 使用IMEI作为唯一标识存储
        scannedDevices[bleData.deviceId] = device
        deviceIMEIMap[peripheral.identifier] = bleData.deviceId
        
//        print("💾 保存设备信息: \(deviceName)")
//        print("  MAC: \(bleData.macAddress)")
//        print("  IMEI: \(bleData.deviceId)")
//        print("  绑定状态: \(bleData.bondStatus == 1 ? "已绑定" : "未绑定")")
//        print("  产品ID: 0x\(String(format: "%04X", bleData.productId))")
        
    }
}

// MARK: - 操作发送指令
public extension BluetoothManager {
    
    
}

// MARK: - 设备查找方法
public extension BluetoothManager {
    
    /// 根据IMEI查找扫描到的设备
    func findDeviceByIMEI(_ imei: String) -> ScannedDevice? {
        return scannedDevices[imei]
    }
    
    /// 根据Peripheral查找对应的扫描设备信息
    func findScannedDevice(for peripheral: CBPeripheral) -> ScannedDevice? {
        // 先通过IMEI映射查找
        if let imei = deviceIMEIMap[peripheral.identifier] {
            return scannedDevices[imei]
        }
        
        // 如果没有找到映射，遍历所有设备查找
        for device in scannedDevices.values {
            if device.peripheral.identifier == peripheral.identifier {
                return device
            }
        }
        
        return nil
    }
    
    /// 获取所有扫描到的设备（按信号强度排序）
    func getAllScannedDevices() -> [ScannedDevice] {
        return scannedDevices.values.sorted { $0.rssi > $1.rssi }
    }
    
    /// 根据产品ID过滤设备
    func getDevicesByProductId(_ productId: UInt16) -> [ScannedDevice] {
        return scannedDevices.values.filter { $0.productId == productId }
            .sorted { $0.rssi > $1.rssi }
    }
    
    /// 根据绑定状态过滤设备
    func getDevicesByBondStatus(_ bonded: Bool) -> [ScannedDevice] {
        let targetStatus: UInt8 = bonded ? 1 : 0
        return scannedDevices.values.filter { $0.bondStatus == targetStatus }
            .sorted { $0.rssi > $1.rssi }
    }
    
    /// 查找未绑定的设备
    func getUnbondedDevices() -> [ScannedDevice] {
        return getDevicesByBondStatus(false)
    }
    
    /// 查找已绑定的设备
    func getBondedDevices() -> [ScannedDevice] {
        return getDevicesByBondStatus(true)
    }
    
    /// 清空扫描到的设备列表
    func clearScannedDevices() {
        scannedDevices.removeAll()
        deviceIMEIMap.removeAll()
        print("已清空扫描设备缓存")
    }
    
    /// 移除特定的扫描设备
    func removeScannedDevice(by imei: String) {
        if let device = scannedDevices.removeValue(forKey: imei) {
            deviceIMEIMap.removeValue(forKey: device.peripheral.identifier)
            print("已移除设备: \(device.deviceName) - IMEI: \(imei)")
        }
    }
}

// MARK: - 通知名称
public extension Notification.Name {
    static let didReceiveBluetoothData = Notification.Name("didReceiveBluetoothData")                      //蓝牙应答数据通知
    static let didReceiveResponseFrame = Notification.Name("didReceiveResponseFrame")                      //蓝牙应答通知
    static let didReceiveDeviceInfo = Notification.Name("didReceiveDeviceInfo")                            //蓝牙设备信息通知
    static let didReceiveStatusInfo = Notification.Name("didReceiveStatusInfo")                            //蓝牙状态信息通知
    static let didReceiveAlarmReport = Notification.Name("didReceiveAlarmReport")                          //蓝牙终端上报平台安全通知
    static let didReceivePlatformNotification = Notification.Name("didReceivePlatformNotification")        //平台下发提示信息
    static let deviceRequestPhoneLocation = Notification.Name("deviceRequestPhoneLocation")                //获取手机定位
    static let didReceivePositionReport = Notification.Name("didReceivePositionReport")                    //蓝牙设备定位信息上报后台
    static let didScanDeviceWithIMEI = Notification.Name("didScanDeviceWithIMEI")                          //蓝牙终端上报平台安全通知
    static let didReceiveDeviceCustomMsg = Notification.Name("didReceiveDeviceCustomMsg")                  //蓝牙自定义消息
    static let didSaveOfSOSResponseMsg = Notification.Name("didSaveOfSOSResponseMsg")                      //上报平安和SOS的通知
    static let unBindMiniDeviceResponseMsg = Notification.Name("unBindMiniDeviceResponseMsg")              //解绑蓝牙设备通知
    static let bluetoothDeviceDisconnected = Notification.Name("bluetoothDeviceDisconnected")              //设备断联通知
    static let didReceiveSatelliteInfo = Notification.Name("didReceiveSatelliteInfo")                      //获取卫星信号通知
    static let didDeviceBufferInfo = Notification.Name("didDeviceBufferInfo")                              //获取缓冲区内容
    static let didFirmwareUpdateOver = Notification.Name("didFirmwareUpdateOver")                          //固件升级结束
    static let didReceiveSatelliteSendResult = Notification.Name("didReceiveSatelliteSendResult")          //获取卫星发送结果
}


