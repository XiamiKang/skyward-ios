//
//  File.swift
//  test11
//
//  Created by yifan kang on 2025/11/13.
//

import Foundation
import CoreBluetooth

// MARK: - 枚举和结构体定义

// 命令编号定义
public enum CommandCode: UInt16 {
    case deviceInfo = 0x0000              // 获取设备信息
    case setBindStatus = 0x0001           // 设备绑定状态设置
    case statusInfo = 0x0002              // 状态信息上报
    case setWorkMode = 0x0003             // 设置工作模式
    case setStatusReportTime = 0x0004     // 设置设备状态上报时间
    case platformCustomData = 0x0005      // 平台自定义内容信息下发
    case appCustomData = 0x0006           // APP自定义内容信息上报
    case alarmReport = 0x0007             // (Mini设备到平台)报警/报平安
    case appTriggerAlarm = 0x0008         // APP触发报警/报平安
    case setPositionReport = 0x0009       // 设置设备定位信息上报后台时间间隔
    case positionReport = 0x000A          // 设备定位信息上报后台
    case getPhoneLocation = 0x000B        // 获取手机定位及时间信息
    case platformNotification = 0x000C    // 平台下发提示信息
    case setLowPowerWakeTime = 0x000D     // 低功耗唤醒时间设置
    case setPositionStoreInterval = 0x000E // 定位信息存储时间间隔设置
    case readStoredPositions = 0x000F     // APP读取存储的定位信息
    case startFirmwareUpgrade = 0x0010    // 开始固件升级
    case firmwareData = 0x0011            // 发送固件数据
    case endFirmwareUpgrade = 0x0012      // 固件升级结束
    case getSatelliteSignal = 0x0014      // 获取卫星信号质量
    case getSatelliteRecords = 0x0015     // 获取卫星收发记录
    case resetDevice = 0x0016             // 复位设备
}

// 应答状态
public enum ResponseStatus: UInt8 {
    case success = 0      // 设置成功
    case inProgress = 1   // 设置中
    case failed = 2       // 设置失败
    case crcError = 3     // CRC校验失败
}

// 分包状态枚举
public enum PacketStatus: UInt8 {
    case noPacket = 0x00      // 不分包
    case packetStart = 0x01   // 分包开始
    case packetMiddle = 0x02  // 分包中
    case packetEnd = 0x03     // 分包结束
}

// MARK: - BLE广播数据模型
public struct BLEAdvertisementData {
    public let macAddress: String
    public let advVersion: UInt8
    public let bondStatus: UInt8
    public let productId: UInt16
    public let deviceId: String // IMEI
}

// 连接到设备信息结构
public struct DeviceInfo {
    public let protocolVersion: UInt16    // 协议版本号
    public let bleMac: Data              // 设备蓝牙MAC地址 (6字节)
    public let bond: UInt8               // 绑定标识
    public let bleSoftwareVersion: UInt32 // 蓝牙模组软件版本号
    public let bleHardwareVersion: UInt32 // 蓝牙模组硬件版本号
    public let mcuSoftwareVersion: UInt32 // MCU软件版本号
    public let mcuHardwareVersion: UInt32 // MCU硬件版本号
    public let deviceId: UInt64          // 设备ID
}

// 状态信息结构体 - 修正数据类型
public struct StatusInfo {
    public let runTime: UInt32           // 设备运行时长 (4字节)
    public let temperature: Int32        // 温度数据 * 100 (4字节)
    public let humidity: UInt32          // 湿度数据 * 100 (4字节)
    public let battery: UInt8            // 电池电量百分比 (1字节)
    public let moduleStatus: UInt8       // 模组状态 (1字节)
    public let workMode: UInt8           // 工作模式 (1字节)
    public let statusReportFreq: UInt8   // 设备状态上报间隔 (1字节)
    public let latitude: Int32           // 纬度数据 * 10000 (4字节)
    public let latitudeHemisphere: UInt8 // 纬度半球 (1字节)
    public let longitude: Int32          // 经度数据 * 10000 (4字节)
    public let longitudeHemisphere: UInt8 // 经度半球 (1字节)
    public let altitude: Int32           // 海拔数据 * 10 (4字节)
    public let motionStatus: UInt8       // 运动状态 (1字节)
    public let positionReport: UInt32    // 定位信息上报间隔 (4字节)
    public let lowPowerTime: UInt32      // 低功耗唤醒时间周期 (4字节)
    public let positionStoreTime: UInt32 // 定位信息存储周期 (4字节)
}

// 定位信息结构
public struct PositionInfo {
    public let timestamp: UInt32         // 时间戳
    public let latitude: Int32           // 纬度数据 * 10000
    public let latitudeHemisphere: UInt8 // 纬度半球
    public let longitude: Int32          // 经度数据 * 10000
    public let longitudeHemisphere: UInt8 // 经度半球
    public let altitude: Int32           // 海拔数据 * 10
}

// 报警信息结构
public struct AlarmInfo {
    public let deviceId: UInt64          // 设备ID
    public let timestamp: UInt32         // 时间戳
    public let latitude: Int32           // 纬度数据 * 10000
    public let latitudeHemisphere: UInt8 // 纬度半球
    public let longitude: Int32          // 经度数据 * 10000
    public let longitudeHemisphere: UInt8 // 经度半球
    public let altitude: Int32           // 海拔数据 * 10
    public let motionStatus: UInt8       // 运动状态
    public let alarmType: UInt8          // 告警类型
    public let battery: UInt8            // 电池电量
}

// 通信帧结构
public struct CommunicationFrame {
    let header: UInt16           // 帧头 0xAA55
    let serialNumber: UInt32     // 流水码
    let dataLength: UInt16       // 数据长度
    let commandCode: CommandCode // 命令编号
    let messageContent: Data     // 信息内容
    let checksum: UInt16         // 校验码
    let terminator: UInt16       // 结束符 0x0D0A
    
    // 完整的帧数据
    var frameData: Data {
        var data = Data()
        data.append(header.bigEndianData)
        data.append(serialNumber.bigEndianData)
        data.append(dataLength.bigEndianData)
        data.append(commandCode.rawValue.bigEndianData)
        data.append(messageContent)
        data.append(checksum.bigEndianData)
        data.append(terminator.bigEndianData)
        return data
    }
}

// 应答帧结构
public struct ResponseFrame {
    public let header: UInt16           // 帧头 0xAA55
    public let serialNumber: UInt32     // 流水码
    public let dataLength: UInt16       // 数据长度
    public let commandCode: CommandCode // 命令编号
    public let messageContent: Data     // 信息内容 (5字节)
    public let checksum: UInt16         // 校验码
    public let terminator: UInt16       // 结束符 0x0D0A
    
    // 解析信息内容
    var responseSerial: UInt32? {
        guard messageContent.count >= 4 else { return nil }
        return messageContent.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self).bigEndian }
    }
    
    var responseStatus: ResponseStatus? {
        guard messageContent.count >= 5 else { return nil }
        return ResponseStatus(rawValue: messageContent[4])
    }
}

// 分包数据结构
public struct PacketData {
    public let header: UInt16        // 帧头
    public let status: PacketStatus  // 分包状态
    public let packetId: UInt32      // 分包数据编号
    public let dataLength: UInt16    // 数据长度
    public let data: Data           // 数据内容
}

// 固件数据包结构
public struct FirmwarePacket {
    public let index: UInt32        // 固件数据包索引 (4字节)
    public let length: UInt16       // 当前固件包数据长度 (2字节)
    public let data: Data          // 固件数据内容 (可变长度)
    
    var packetData: Data {
        var data = Data()
        data.append(index.bigEndianData)
        data.append(length.bigEndianData)
        data.append(self.data)
        return data
    }
}

// MARK: - 工具类

// CRC16校验 (IBM格式)
class CRC16 {
    static let ibm: CRC16 = CRC16(polynomial: 0xA001)
    
    private let polynomial: UInt16
    private var table: [UInt16] = []
    
    init(polynomial: UInt16) {
        self.polynomial = polynomial
        generateTable()
    }
    
    private func generateTable() {
        table = Array(repeating: 0, count: 256)
        for i in 0..<256 {
            var crc: UInt16 = UInt16(i)  // ✅ 从当前字节开始
            for _ in 0..<8 {
                if (crc & 0x0001) != 0 {  // ✅ 检查最低位
                    crc = (crc >> 1) ^ polynomial
                } else {
                    crc = crc >> 1
                }
            }
            table[i] = crc
        }
    }
    
    func calculate(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0  // ✅ IBM初始值为0
        for byte in data {
            let index = Int((crc ^ UInt16(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc
    }
    
    // 为了方便使用，添加一个接受字节数组的方法
    func calculate(_ bytes: [UInt8]) -> UInt16 {
        return calculate(Data(bytes))
    }
}

// MARK: - 扫描到的设备模型
public class ScannedDevice {
    public let peripheral: CBPeripheral
    public let imei: String
    public let rssi: Int
    public let macAddress: String
    public let bondStatus: UInt8
    public let deviceName: String
    public let productId: UInt16
    public let advVersion: UInt8
    public let timestamp: Date
    
    init(peripheral: CBPeripheral,
         imei: String,
         rssi: Int,
         macAddress: String,
         bondStatus: UInt8,
         deviceName: String,
         productId: UInt16,
         advVersion: UInt8,
         timestamp: Date) {
        self.peripheral = peripheral
        self.imei = imei
        self.rssi = rssi
        self.macAddress = macAddress
        self.bondStatus = bondStatus
        self.deviceName = deviceName
        self.productId = productId
        self.advVersion = advVersion
        self.timestamp = timestamp
    }
    
    /// 绑定状态描述
    var bondStatusDescription: String {
        return bondStatus == 1 ? "已绑定" : "未绑定"
    }
    
    /// 产品类型描述
    var productDescription: String {
        switch productId {
        case 0x0001:
            return "窄带mini"
        case 0x0002:
            return "窄带标准版"
        // 添加更多产品类型...
        default:
            return "未知产品(0x\(String(format: "%04X", productId)))"
        }
    }
    
    /// 格式化显示信息
    var displayInfo: String {
        return "\(deviceName)\nIMEI: \(imei)\nMAC: \(macAddress)\n状态: \(bondStatusDescription)"
    }
}

// MARK: - 保存到本地的设备信息
public struct BluetoothDeviceInfo: Codable {
    public let uuid: String
    public let imei: String
    public let name: String?
    public let macAddress: String?
    public let productId: UInt16?
    public let connectionDate: Date
    public var lastConnectedDate: Date
    
    // 为了方便使用，添加一些计算属性
    public var displayName: String {
        let originalName = "行者mini"
        
        // 如果 IMEI 长度足够，取后5位
        let imeiSuffix = imei.count >= 5 ? String(imei.suffix(5)) : imei
        
        return "\(originalName)_\(imeiSuffix)"
    }
    
    public var deviceIdentifier: String {
        return "\(imei)-\(uuid)"
    }
}

