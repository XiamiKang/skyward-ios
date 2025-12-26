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
    
    private var writeCharacteristic: CBCharacteristic?
    private var writeWithoutResponseCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?
    
    private var scannedDevices: [String: ScannedDevice] = [:] // key: IMEI
    private var deviceIMEIMap: [UUID: String] = [:] // Peripheral identifier 到 IMEI 的映射
    
    // UUID配置
    let serviceUUID = CBUUID(string: "1273FFF0-580E-0287-4B44-35BA9C22894B")
    let characteristicUUID1 = CBUUID(string: "1273FFF1-580E-0287-4B44-35BA9C22894B")
    let characteristicUUID2 = CBUUID(string: "1273FFF2-580E-0287-4B44-35BA9C22894B")
    
    
    // 协议相关
    var currentSerialNumber: UInt32 = 0
    var packetAssembler = PacketAssembler()
    var firmwareManager = FirmwareUpgradeManager()
    var crcCalculator = CRC16.ibm
    public var MTU = 244
    
    // 筛选关键词
    var filterKeyword: String = "TXTS"
    
    // MARK: - 初始化
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    public var isConnected: Bool {
        return connectedPeripheral != nil && connectedPeripheral?.state == .connected
    }
    
    // MARK: - 蓝牙基础操作
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
    
    public func startScanningForFilteredDevices(keyword: String = "TXTS") {
        self.filterKeyword = keyword
        scanForPeripherals()
    }
    
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
    
    func searchPeripherals(byName name: String) -> [CBPeripheral] {
        return discoveredPeripherals.filter { peripheral in
            if let peripheralName = peripheral.name {
                return peripheralName.uppercased().contains(name.uppercased())
            }
            return false
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    
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
    
    // 添加获取当前状态的方法
    public func getCurrentBluetoothState() -> CBManagerState {
        return centralManager.state
    }
    
    // 添加一个方法来快速判断是否是目标设备
    private func isTargetDevice(_ peripheral: CBPeripheral) -> Bool {
        guard let name = peripheral.name else { return false }
        return name.uppercased().contains(filterKeyword.uppercased())
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let isTarget = isTargetDevice(peripheral)
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            
            if isTarget {
                print("保存目标设备---")
                processTargetDevice(peripheral, advertisementData: advertisementData, rssi: RSSI)
            }
        }
    }
    
    private func processTargetDevice(_ peripheral: CBPeripheral, advertisementData: [String : Any], rssi: NSNumber) {
        if let bleData = parseBLEAdvertisementData(advertisementData) {
            print("✅ 扫描到目标设备 - IMEI: \(bleData.deviceId), RSSI: \(rssi), 名称: \(peripheral.name ?? "未知")")
            filteredPeripherals.append(peripheral)
            saveDeviceWithAdvertisementData(
                peripheral: peripheral,
                rssi: rssi,
                advertisementData: advertisementData
            )
            delegate?.didDiscoverPeripheral(peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        connectedPeripheral = peripheral
        
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        
        print("连接成功: \(peripheral.name ?? "未知设备")")
        // 保存设备信息到本地
        saveConnectedDeviceInfo(peripheral)
        // 代理
        delegate?.didConnectPeripheral(peripheral)
        // 延时等待特征发现
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            print("连接稳定，请求设备状态信息")
            self.requestStatusInfo()
            self.requestDeviceInfo()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("连接失败: \(peripheral.name ?? "未知设备") - \(error?.localizedDescription ?? "未知错误")")
        delegate?.didFailToConnectPeripheral(peripheral, error: error)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("设备断开: \(peripheral.name ?? "未知设备")")
        connectedPeripheral = nil
        delegate?.didDisconnectPeripheral(peripheral)
    }
    
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
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
        print("当前 MTU: \(mtu)")
        MTU = mtu
        
        if data.count > mtu {
            // 数据包超过 MTU，需要分包
            sendDataInChunks(data, mtu: mtu)
        }
        
        handleReceivedData(data, from: characteristic)
    }
    
    private func sendDataInChunks(_ data: Data, mtu: Int) {
        var offset = 0
        while offset < data.count {
            let chunkSize = min(mtu, data.count - offset)
            offset += chunkSize
            // 添加延迟，避免发送过快
            Thread.sleep(forTimeInterval: 0.01)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入数据错误: \(error.localizedDescription)")
        } else {
            print("数据写入成功: \(characteristic.uuid)")
        }
    }
    
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
    /// 保存扫描到的设备信息（包含完整的广播数据）
    private func saveDeviceWithAdvertisementData(peripheral: CBPeripheral,
                                                 rssi: NSNumber,
                                                 advertisementData: [String: Any]) {
        
        // 只处理目标设备
        guard isTargetDevice(peripheral) else {
            return
        }
        
        // 解析广播数据
        guard let bleData = parseBLEAdvertisementData(advertisementData) else {
            print("无法解析广播数据")
            return
        }
        
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
        
        // 发送通知
        NotificationCenter.default.post(
            name: .didScanDeviceWithIMEI,
            object: nil,
            userInfo: ["device": device]
        )
        
        // 发送更新通知
        NotificationCenter.default.post(
            name: .didUpdateScannedDevices,
            object: nil
        )
        
//        print("💾 保存设备信息: \(deviceName)")
//        print("  MAC: \(bleData.macAddress)")
//        print("  IMEI: \(bleData.deviceId)")
//        print("  绑定状态: \(bleData.bondStatus == 1 ? "已绑定" : "未绑定")")
//        print("  产品ID: 0x\(String(format: "%04X", bleData.productId))")
    }
}

// MARK: - 操作发送指令
public extension BluetoothManager {
    
    func sendCommand(_ commandCode: CommandCode, messageContent: Data = Data()) {
        let frame = createFrame(commandCode: commandCode, messageContent: messageContent)
        let frameData = frame.frameData
        
//        print("发送命令帧:")
//        print("  命令编号: 0x\(String(format: "%04X", commandCode.rawValue))")
//        print("  流水码: \(frame.serialNumber)")
//        print("  数据长度: \(frame.dataLength)")
//        print("  信息内容: \(messageContent.hexString)")
//        print("  校验码: 0x\(String(format: "%04X", frame.checksum))")
//        print("  完整帧: \(frameData.hexString)")
        
        sendRawData(frameData)
    }
    
    // 生成一个完整的通信帧
    private func createFrame(commandCode: CommandCode, messageContent: Data = Data()) -> CommunicationFrame {
        let header: UInt16 = 0xAA55
        let serialNumber = nextSerialNumber()
        let dataLength = UInt16(messageContent.count)
        // 计算校验码的数据范围
        var checksumData = Data()
        checksumData.append(header.bigEndianData)
        checksumData.append(serialNumber.bigEndianData)
        checksumData.append(dataLength.bigEndianData)
        checksumData.append(commandCode.rawValue.bigEndianData)
        checksumData.append(messageContent)
        let checksum = crcCalculator.calculate(checksumData)
        let terminator: UInt16 = 0x0D0A
        
        return CommunicationFrame(
            header: header,
            serialNumber: serialNumber,
            dataLength: dataLength,
            commandCode: commandCode,
            messageContent: messageContent,
            checksum: checksum,
            terminator: terminator
        )
    }
    // 生成4字节的流水码
    private func nextSerialNumber() -> UInt32 {
        currentSerialNumber += 1
        if currentSerialNumber > UInt32.max {
            currentSerialNumber = 0
        }
        return currentSerialNumber
    }
    
    // MARK: - 数据发送
    public func sendRawData(_ data: Data) {
        guard let peripheral = connectedPeripheral else {
            print("设备未连接")
            return
        }
        print("准备发送数据，长度: \(data.count) 字节")
        print("数据内容: \(data.hexString)")
        
        // 优先使用有响应写入
        if let characteristic = writeCharacteristic {
            print("使用有响应写入特征: \(characteristic.uuid)")
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            return
        }
        
        // 其次使用无响应写入
        if let characteristic = writeWithoutResponseCharacteristic {
            print("使用无响应写入特征: \(characteristic.uuid)")
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            return
        }
        
        // 最后尝试查找特征
        if let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
           let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                if characteristic.properties.contains(.write) {
                    print("动态找到有响应写入特征: \(characteristic.uuid)")
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                    return
                }
                if characteristic.properties.contains(.writeWithoutResponse) {
                    print("动态找到无响应写入特征: \(characteristic.uuid)")
                    peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
                    return
                }
            }
        }
        
        print("错误: 没有找到支持写入的特征")
    }
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


public extension BluetoothManager {
    
    // MARK: - 设备信息保存
    private func saveConnectedDeviceInfo(_ peripheral: CBPeripheral) {
        
        guard let scannedDevice = findScannedDevice(for: peripheral) else {
            print("❌ 无法找到设备的扫描信息，无法保存")
            return
        }
        
        let deviceInfo = BluetoothDeviceInfo(
            uuid: peripheral.identifier.uuidString,
            imei: scannedDevice.imei,
            name: peripheral.name,
            macAddress: scannedDevice.macAddress,
            productId: scannedDevice.productId,
            connectionDate: Date(),
            lastConnectedDate: Date()
        )
        MiniDeviceStorageManager.shared.saveConnectedDevice(deviceInfo)
        
        if NetworkMonitor.shared.isConnected {
            UserManager.shared.bindMiniDevice(serialNum: scannedDevice.imei, macAddress: scannedDevice.macAddress) { result in
                
            }
        }else {
            SWAlertView.showAlert(title: nil, message: "当前无网络连接，通过Mini设备绑定设备？") {
                if let data = MessageGenerator.generateDeviceBind(userId: UserManager.shared.userId) {
                    BluetoothManager.shared.sendAppCustomData(data)
                }
            }
            return
        }
    }
    
    // MARK: - 获取保存的设备信息
    func getSavedDeviceInfo(for peripheral: CBPeripheral) -> BluetoothDeviceInfo? {
        return MiniDeviceStorageManager.shared.findDeviceByUUID(peripheral.identifier.uuidString)
    }
    
    func getSavedDeviceInfo(byIMEI imei: String) -> BluetoothDeviceInfo? {
        return MiniDeviceStorageManager.shared.findDeviceByIMEI(imei)
    }
    
    // MARK: - 获取所有保存的设备
    func getAllSavedDevices() -> [BluetoothDeviceInfo] {
        return MiniDeviceStorageManager.shared.getAllSavedDevices()
    }
    
    // MARK: - 删除保存的设备
    func removeSavedDevice(_ peripheral: CBPeripheral) {
        MiniDeviceStorageManager.shared.removeDevice(peripheral.identifier.uuidString)
    }
    
    func removeSavedDevice(byIMEI imei: String) {
        if let device = MiniDeviceStorageManager.shared.findDeviceByIMEI(imei) {
            MiniDeviceStorageManager.shared.removeDevice(device.uuid)
        }
    }
    
    // MARK: - 自动重连上次连接的设备
    func autoReconnectLastDevice() {
        guard let lastDevice = MiniDeviceStorageManager.shared.getLastConnectedDevice() else {
            print("没有找到上次连接的设备")
            return
        }
        
        print("尝试自动重连上次连接的设备: \(lastDevice.displayName)")
        
        // 在已发现的设备中查找
        if let peripheral = discoveredPeripherals.first(where: {
            $0.identifier.uuidString == lastDevice.uuid
        }) {
            connectToPeripheral(peripheral)
        } else {
            print("设备未在扫描范围内，开始扫描...")
            // 可以在这里触发扫描，然后尝试连接
            scanForPeripherals()
        }
    }
}


// MARK: - 通知名称
public extension Notification.Name {
    static let didReceiveBluetoothData = Notification.Name("didReceiveBluetoothData")                      //蓝牙应答数据通知
    static let didReceiveCommandFrame = Notification.Name("didReceiveCommandFrame")                        //蓝牙应答命令通知
    static let didReceiveResponseFrame = Notification.Name("didReceiveResponseFrame")                      //蓝牙应答通知
    static let didReceiveDeviceInfo = Notification.Name("didReceiveDeviceInfo")                            //蓝牙设备信息通知
    static let didReceiveStatusInfo = Notification.Name("didReceiveStatusInfo")                            //蓝牙状态信息通知
    static let didReceiveAlarmReport = Notification.Name("didReceiveAlarmReport")                          //蓝牙终端上报平台安全通知
    static let didReceivePlatformNotification = Notification.Name("didReceivePlatformNotification")
    static let deviceRequestPhoneLocation = Notification.Name("deviceRequestPhoneLocation")
    static let firmwareUpgradeProgress = Notification.Name("firmwareUpgradeProgress")
    static let firmwareUpgradeCompleted = Notification.Name("firmwareUpgradeCompleted")
    static let didReceivePositionReport = Notification.Name("didReceivePositionReport")
    static let didScanDeviceWithIMEI = Notification.Name("didScanDeviceWithIMEI")
    static let didUpdateScannedDevices = Notification.Name("didUpdateScannedDevices")
    static let didReceiveDeviceCustomMsg = Notification.Name("didReceiveDeviceCustomMsg")
    static let didSaveOfSOSResponseMsg = Notification.Name("didSaveOfSOSResponseMsg")
    static let unBindMiniDeviceResponseMsg = Notification.Name("unBindMiniDeviceResponseMsg")
    static let bluetoothDeviceDisconnected = Notification.Name("bluetoothDeviceDisconnected")
    
}

// MARK: - 枚举描述扩展
extension PacketStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noPacket: return "不分包"
        case .packetStart: return "分包开始"
        case .packetMiddle: return "分包中"
        case .packetEnd: return "分包结束"
        }
    }
}

extension ResponseStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success: return "成功"
        case .inProgress: return "进行中"
        case .failed: return "失败"
        case .crcError: return "CRC错误"
        }
    }
}
