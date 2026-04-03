//
//  File.swift
//  test11
//
//  Created by yifan kang on 2025/11/13.
//

import Foundation
import CoreBluetooth
import WCDBSwift

// MARK: - 枚举和结构体定义
public enum BluetoothDeviceType: UInt16 {
    case TXTS = 0x0100
    case K01 = 0x0200
    
    public var description: String {
        switch self {
        case .TXTS: return "成都设备"
        case .K01: return "中北设备"
        }
    }
}

// MARK: - 命令模型
public struct Command {
    public let name: String
    public let chengduCode: UInt16?
    public let k01Code: UInt8?
    
    private init(name: String, chengduCode: UInt16?, k01Code: UInt8?) {
        self.name = name
        self.chengduCode = chengduCode
        self.k01Code = k01Code
    }
    
    // 预定义命令
    public static let deviceInfo = Command(name: "获取设备信息",
                                           chengduCode: 0x0000,
                                           k01Code: 0x00)
    
    public static let setBindStatus = Command(name: "设备绑定状态设置",
                                               chengduCode: 0x0001,
                                               k01Code: 0x01)
    
    public static let statusInfo = Command(name: "状态信息上报",
                                           chengduCode: 0x0002,
                                           k01Code: 0x02)
    
    public static let setWorkMode = Command(name: "设置工作模式",
                                             chengduCode: 0x0003,
                                             k01Code: 0x03)
    
    public static let setStatusReportTime = Command(name: "设置设备状态上报时间",
                                                     chengduCode: 0x0004,
                                                     k01Code: 0x04)
    
    public static let platformCustomData = Command(name: "平台自定义内容信息下发",
                                                    chengduCode: 0x0005,
                                                    k01Code: 0x05)
    
    public static let appCustomData = Command(name: "APP自定义内容信息上报",
                                               chengduCode: 0x0006,
                                               k01Code: 0x06)
    
    public static let alarmReport = Command(name: "报警/报平安",
                                            chengduCode: 0x0007,
                                            k01Code: 0x07)
    
    public static let appTriggerAlarm = Command(name: "APP触发报警/报平安",
                                                 chengduCode: 0x0008,
                                                 k01Code: 0x08)
    
    public static let setPositionReport = Command(name: "设置设备定位信息上报后台时间间隔",
                                                   chengduCode: 0x0009,
                                                   k01Code: 0x09)
    
    public static let positionReport = Command(name: "设备定位信息上报后台",
                                                chengduCode: 0x000A,
                                                k01Code: 0x0A)
    
    public static let getPhoneLocation = Command(name: "获取手机定位及时间信息",
                                                  chengduCode: 0x000B,
                                                  k01Code: 0x0B)
    
    public static let platformNotification = Command(name: "平台下发提示信息",
                                                      chengduCode: 0x000C,
                                                      k01Code: 0x0C)
    
    public static let setLowPowerWakeTime = Command(name: "低功耗唤醒时间设置",
                                                     chengduCode: 0x000D,
                                                     k01Code: 0x0D)
    
    public static let setPositionStoreInterval = Command(name: "定位信息存储时间间隔设置",
                                                          chengduCode: 0x000E,
                                                          k01Code: 0x0E)
    
    public static let readStoredPositions = Command(name: "APP读取存储的定位信息",
                                                     chengduCode: 0x000F,
                                                     k01Code: 0x0F)
    
    public static let startFirmwareUpgrade = Command(name: "开始固件升级",
                                                      chengduCode: 0x0010,
                                                      k01Code: 0x10)
    
    public static let firmwareData = Command(name: "发送固件数据",
                                              chengduCode: 0x0011,
                                              k01Code: 0x11)
    
    public static let endFirmwareUpgrade = Command(name: "固件升级结束",
                                                    chengduCode: 0x0012,
                                                    k01Code: 0x12)
    
    public static let getSatelliteSignal = Command(name: "获取卫星信号质量",
                                                    chengduCode: 0x0014,
                                                    k01Code: 0x14)
    
    public static let getSatelliteRecords = Command(name: "获取卫星收发记录",
                                                     chengduCode: 0x0015,
                                                     k01Code: 0x15)
    
    public static let resetDevice = Command(name: "复位设备",
                                             chengduCode: 0x0016,
                                             k01Code: 0x16)
    
    public static let getSatelliteSendResult = Command(name: "获取卫星收发结果",
                                             chengduCode: 0x0017,
                                             k01Code: 0x17)
    
    public static let closeSOS = Command(name: "关闭SOS",
                                             chengduCode: 0x0018,
                                             k01Code: 0x18)
}

// 应答状态
public enum ResponseStatus: UInt8 {
    case success = 0      // 设置成功
    case inProgress = 1   // 设置中
    case failed = 2       // 设置失败
    case crcError = 3     // CRC校验失败
    case bufferEmpty = 4  // 缓冲区空
    
    public var description: String {
        switch self {
        case .success: return "成功"
        case .inProgress: return "进行中"
        case .failed: return "失败"
        case .crcError: return "CRC错误"
        case .bufferEmpty: return "缓冲区空"
        }
    }
}

// 分包状态枚举
public enum PacketStatus: UInt8 {
    case noPacket = 0x00      // 不分包
    case packetStart = 0x01   // 分包开始
    case packetMiddle = 0x02  // 分包中
    case packetEnd = 0x03     // 分包结束
    
    public var description: String {
        switch self {
        case .noPacket: return "不分包"
        case .packetStart: return "分包开始"
        case .packetMiddle: return "分包中"
        case .packetEnd: return "分包结束"
        }
    }
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
    public let bleMac: Data               // 设备蓝牙MAC地址 (6字节)
    public let bond: UInt8                // 绑定标识
    public let bleSoftwareVersion: UInt32 // 蓝牙模组软件版本号
    public let bleHardwareVersion: UInt32 // 蓝牙模组硬件版本号
    public let mcuSoftwareVersion: UInt32 // MCU软件版本号
    public let mcuHardwareVersion: UInt32 // MCU硬件版本号
    public let deviceId: UInt64           // 设备ID
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
    public let sosStatus: UInt8          // SOS状态 (1字节)  00是开启，01是关闭
    public let iridium: UInt8            // 铱星信号质量 (1字节)
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
    public let header: UInt16           // 帧头 0xAA55
    public let serialNumber: UInt32     // 流水码
    public let dataLength: UInt16       // 数据长度
    public let commandCode: UInt16      // 命令编号
    public let messageContent: Data     // 信息内容
    public let checksum: UInt16         // 校验码
    public let terminator: UInt16       // 结束符 0x0D0A
    
    // 完整的帧数据
    public var frameData: Data {
        var data = Data()
        data.append(header.bigEndianData)
        data.append(serialNumber.bigEndianData)
        data.append(dataLength.bigEndianData)
        data.append(commandCode.bigEndianData)
        data.append(messageContent)
        data.append(checksum.bigEndianData)
        data.append(terminator.bigEndianData)
        return data
    }
}

public struct K01CommunicationFrame {
    public let header: UInt16                 // 帧头 0xAA55
    public let serialNumber: UInt8            // 流水码
    public let dataLength: UInt16             // 数据长度
    public let commandCode: UInt8             // 命令编号
    public let messageContent: Data           // 信息内容
    public let checksum: UInt16               // 校验码
    public let terminator: UInt16             // 结束符 0x0D0A
    
    // 完整的帧数据
    public var frameData: Data {
        var data = Data()
        data.append(header.bigEndianData)
        data.append(serialNumber)
        data.append(dataLength.bigEndianData)
        data.append(commandCode)
        data.append(messageContent)
        data.append(checksum.bigEndianData)
        data.append(terminator.bigEndianData)
        return data
    }
}

// 应答帧结构
public struct ResponseFrame {
    public let header: UInt16           // 帧头 0xAA55
    public let serialNumber: UInt32      // 流水码
    public let dataLength: UInt16        // 数据长度
    public let commandCode: UInt16      // 命令编号
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

public struct K01ResponseFrame {
    public let header: UInt16           // 帧头 0xAA55
    public let serialNumber: UInt8      // 流水码
    public let dataLength: UInt8        // 数据长度
    public let commandCode: UInt8       // 命令编号
    public let messageContent: Data     // 信息内容 (1字节)
    public let checksum: UInt16         // 校验码
    public let terminator: UInt16       // 结束符 0x0D0A
    
    // 解析信息内容
    var responseSerial: UInt8? {
        guard messageContent.count >= 2 else { return nil }
        return messageContent[0]
    }
    
    var responseStatus: ResponseStatus? {
        guard messageContent.count >= 2 else { return nil }
        return ResponseStatus(rawValue: messageContent[1])
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
public class CRC16 {
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
    
    public func calculate(_ data: Data) -> UInt16 {
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
    // 基础属性（不变）
    public let peripheral: CBPeripheral
    public let imei: String
    public let rssi: Int
    public let macAddress: String
    public let bondStatus: UInt8
    public let deviceName: String
    public let productId: UInt16
    public let advVersion: UInt8
    public let timestamp: Date
      
    // MARK: - 初始化
    public init(peripheral: CBPeripheral,
                imei: String,
                rssi: Int,
                macAddress: String,
                bondStatus: UInt8,
                deviceName: String,
                productId: UInt16,
                advVersion: UInt8,
                timestamp: Date = Date()) {
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
    
    public var name: String {
        // 确保 imei 至少有 4 位
        guard imei.count >= 5 else { return "行者mini_未知" }
        
        // 获取 imei 的最后 4 位
        let lastFourDigits = String(imei.suffix(5))
        return "行者mini_\(lastFourDigits)"
    }
}

public struct MiniDeviceData: TableCodable {
    
    public let name: String?                      // 设备名称
    public let serialNum: String?                 // 设备序列号
    public let imeiNum: String?                   // 设备IMEI
    public let forthGenCardNum: String?           // 设备4G卡号
    public let typeCode: String?                  // 窄带：NARROW_BAND, 宽带：BROAD_BAND
    public var state: Int?                        //  0 有效 1删除
    public let macAddress: String?                // 设备MAC地址
    public let model: String?                     // 设备型号   窄带：TXTS-NB-01
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = MiniDeviceData
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case name
        case serialNum
        case imeiNum
        case forthGenCardNum
        case typeCode
        case state
        case macAddress
        case model
        
        static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .imeiNum: ColumnConstraintConfig(imeiNum, isPrimary: true, defaultTo: "")
            ]
        }
    }
}

// MARK: - 卫星命令枚举
public enum SatelliteCommand: UInt8, Codable {
    case customMessage = 0x06
    case alertOrSafety = 0x07
    case locationInfo = 0x0A
    case unknown = 0xFF
    
    var description: String {
        switch self {
        case .customMessage: return "自定义消息"
        case .alertOrSafety: return "报警/报平安"
        case .locationInfo: return "定位信息"
        case .unknown: return "未知"
        }
    }
}

// MARK: - 卫星发送结果枚举
public enum SatelliteSendResult: UInt8, Codable {
    case success = 0x01
    case failure = 0x02
    case timeout = 0x03
    case noResponse = 0x04
    case unknown = 0xFF
    
    var description: String {
        switch self {
        case .success: return "成功(铱星返回成功)"
        case .failure: return "失败(铱星返回失败)"
        case .timeout: return "超时(铱星发送超时)"
        case .noResponse: return "失败(铱星模块未响应)"
        case .unknown: return "未知"
        }
    }
}

public struct MiniDeviceSendResultData: TableCodable {
    
    public let imeiNum: String                    // 设备
    public let command: UInt8                      // 指令（存储枚举的rawValue）
    public let result: UInt8                       // 结果（存储枚举的rawValue）
    public let time: Date                          // 时间
    
    // 计算属性 - 方便获取枚举
    public var commandEnum: SatelliteCommand {
        return SatelliteCommand(rawValue: command) ?? .unknown
    }
    
    public var resultEnum: SatelliteSendResult {
        return SatelliteSendResult(rawValue: result) ?? .unknown
    }
    
    // 显示用的字符串
    public var commandStr: String {
        return commandEnum.description
    }
    
    public var resultStr: String {
        return resultEnum.description
    }
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = MiniDeviceSendResultData
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        case imeiNum
        case command
        case result
        case time
        
        static var columnConstraintBindings: [CodingKeys: BindColumnConstraint]? {
            return [
                .imeiNum: ColumnConstraintConfig(imeiNum, isPrimary: true, defaultTo: "")
            ]
        }
    }
    
    // 使用枚举的初始化方法
    public init(imeiNum: String, command: SatelliteCommand, result: SatelliteSendResult, time: Date) {
        self.imeiNum = imeiNum
        self.command = command.rawValue
        self.result = result.rawValue
        self.time = time
    }
}


// MARK: - 扩展数据类型转换
public extension UInt16 {
    var bigEndianData: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
    
    var hexString: String {
        return String(format: "0x%04X", self)
    }
}

public extension UInt32 {
    var bigEndianData: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}

public extension UInt64 {
    var bigEndianData: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<UInt64>.size)
    }
}

// 添加有符号整数的扩展
public extension Int16 {
    var bigEndianData: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<Int16>.size)
    }
}

public extension Int32 {
    var bigEndianData: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<Int32>.size)
    }
}

public extension Data {
    var hexString: String {
        return map { String(format: "%02X", $0) }.joined()
    }
}
