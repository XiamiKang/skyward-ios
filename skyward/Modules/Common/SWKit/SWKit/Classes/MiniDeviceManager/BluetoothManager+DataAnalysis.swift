//
//  File.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/18.
//

import Foundation
import CoreBluetooth

// MARK: - 数据解析具体实现
extension BluetoothManager {
    
    private func handleDeviceInfoResponse(_ data: Data) {
        guard data.count >= 33 else {
            print("设备信息数据长度错误: \(data.count)")
            return
        }
        
        var offset = 0
        
        // 安全读取协议版本 (2字节)
        let protocolVersion = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        // 读取BLE MAC地址 (6字节)
        let bleMac = data.subdata(in: offset..<offset + 6)
        offset += 6
        
        // 读取绑定状态 (1字节)
        let bond = data[offset]
        offset += 1
        
        // 安全读取蓝牙软件版本 (4字节)
        let bleSoftwareVersion = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取蓝牙硬件版本 (4字节)
        let bleHardwareVersion = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取MCU软件版本 (4字节)
        let mcuSoftwareVersion = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取MCU硬件版本 (4字节)
        let mcuHardwareVersion = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取设备ID (8字节)
        let deviceId = (UInt64(data[offset]) << 56) |
        (UInt64(data[offset + 1]) << 48) |
        (UInt64(data[offset + 2]) << 40) |
        (UInt64(data[offset + 3]) << 32) |
        (UInt64(data[offset + 4]) << 24) |
        (UInt64(data[offset + 5]) << 16) |
        (UInt64(data[offset + 6]) << 8) |
        UInt64(data[offset + 7])
        offset += 8
        
        let deviceInfo = DeviceInfo(
            protocolVersion: protocolVersion,
            bleMac: bleMac,
            bond: bond,
            bleSoftwareVersion: bleSoftwareVersion,
            bleHardwareVersion: bleHardwareVersion,
            mcuSoftwareVersion: mcuSoftwareVersion,
            mcuHardwareVersion: mcuHardwareVersion,
            deviceId: deviceId
        )
        
        print("✅ 收到设备信息:")
        print("  协议版本: 0x\(String(format: "%04X", protocolVersion))")
        print("  BLE MAC: \(bleMac.hexString)")
        print("  绑定状态: \(bond == 1 ? "已绑定" : "未绑定")")
        print("  蓝牙软件版本: \(formatVersion(bleSoftwareVersion))")
        print("  蓝牙硬件版本: \(formatVersion(bleHardwareVersion))")
        print("  MCU软件版本: \(formatVersion(mcuSoftwareVersion))")
        print("  MCU硬件版本: \(formatVersion(mcuHardwareVersion))")
        print("  设备ID: \(deviceId)")
        
        NotificationCenter.default.post(
            name: .didReceiveDeviceInfo,
            object: nil,
            userInfo: ["deviceInfo": deviceInfo]
        )
    }
    
    
    private func handleStatusInfoResponse(_ data: Data) {
        // 重新计算数据长度：run_time(4) + temp(4) + humi(4) + bat(1) + mds(1) + wm(1) + srpf(1) + lat(4) + lathem(1) + lon(4) + lonhem(1) + alt(4) + st(1) + pos_rpt(4) + low_power_t(4) + position_t(4) = 47字节
        guard data.count >= 43 else {
            print("状态信息数据长度错误: \(data.count)，期望至少43字节")
            return
        }
        
        var offset = 0
        
        // 安全读取运行时长 (4字节)
        let runTime = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取温度 (4字节，*100)
        let temperature = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 安全读取湿度 (4字节，*100)
        let humidity = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 读取电池电量 (1字节)
        let battery = data[offset]
        offset += 1
        
        // 读取模组状态 (1字节)
        let moduleStatus = data[offset]
        offset += 1
        
        // 读取工作模式 (1字节)
        let workMode = data[offset]
        offset += 1
        
        // 读取状态上报间隔 (1字节)
        let statusReportFreq = data[offset]
        offset += 1
        
        // 安全读取纬度 (4字节，*10000)
        let latitude = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 读取纬度半球 (1字节)
        let latitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取经度 (4字节，*10000)
        let longitude = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 读取经度半球 (1字节)
        let longitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取海拔 (4字节，*10) - 修正为4字节
        let altitude = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 读取运动状态 (1字节)
        let motionStatus = data[offset]
        offset += 1
        
        // 安全读取定位信息上报间隔 (4字节) - 修正为4字节
        let positionReport = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取低功耗唤醒时间 (4字节)
        let lowPowerTime = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取定位信息存储周期 (4字节)
        let positionStoreTime = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        let statusInfo = StatusInfo(
            runTime: runTime,
            temperature: temperature,
            humidity: humidity,
            battery: battery,
            moduleStatus: moduleStatus,
            workMode: workMode,
            statusReportFreq: statusReportFreq,
            latitude: latitude,
            latitudeHemisphere: latitudeHemisphere,
            longitude: longitude,
            longitudeHemisphere: longitudeHemisphere,
            altitude: altitude,
            motionStatus: motionStatus,
            positionReport: positionReport,
            lowPowerTime: lowPowerTime,
            positionStoreTime: positionStoreTime
        )
        
        print("✅ 收到状态信息:")
        print("  运行时长: \(runTime) 秒 (\(formatTimeInterval(runTime)))")
        print("  温度: \(Float(temperature) / 100.0)°C")
        print("  湿度: \(Float(humidity) / 100.0)%")
        print("  电池电量: \(battery)%")
        print("  模组状态: 0x\(String(format: "%02X", moduleStatus))")
        print("  工作模式: \(getWorkModeDescription(workMode))")
        print("  状态上报间隔: \(statusReportFreq) 秒")
        print("  纬度: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S")")
        print("  经度: \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
        print("  海拔: \(Float(altitude) / 10.0) 米")
        print("  运动状态: \(getMotionStatusDescription(motionStatus))")
        print("  定位上报间隔: \(positionReport) 秒")
        print("  低功耗唤醒时间: \(lowPowerTime) 秒")
        print("  定位存储周期: \(positionStoreTime) 秒")
        
        // 解析模组状态详细位
        let bleStatus = (moduleStatus & 0x01) != 0 ? "异常" : "正常"
        let satelliteStatus = (moduleStatus & 0x02) != 0 ? "异常" : "正常"
        let gnssStatus = (moduleStatus & 0x04) != 0 ? "异常" : "正常"
        print("  模组状态详情 - BLE:\(bleStatus) 卫星:\(satelliteStatus) GNSS:\(gnssStatus)")
        
        NotificationCenter.default.post(
            name: .didReceiveStatusInfo,
            object: nil,
            userInfo: ["statusInfo": statusInfo]
        )
    }
    
    private func handleAlarmReport(_ data: Data) {
        guard data.count >= 29 else {
            print("报警信息数据长度错误: \(data.count)")
            return
        }
        
        var offset = 0
        
        // 安全读取设备ID (8字节)
        let deviceId = (UInt64(data[offset]) << 56) |
        (UInt64(data[offset + 1]) << 48) |
        (UInt64(data[offset + 2]) << 40) |
        (UInt64(data[offset + 3]) << 32) |
        (UInt64(data[offset + 4]) << 24) |
        (UInt64(data[offset + 5]) << 16) |
        (UInt64(data[offset + 6]) << 8) |
        UInt64(data[offset + 7])
        offset += 8
        
        // 安全读取时间戳 (4字节)
        let timestamp = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取纬度 (4字节，*10000)
        let latitude = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 读取纬度半球 (1字节)
        let latitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取经度 (4字节，*10000)
        let longitude = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 读取经度半球 (1字节)
        let longitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取海拔 (4字节，*10) - 修正为4字节
        let altitude = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // 读取运动状态 (1字节)
        let motionStatus = data[offset]
        offset += 1
        
        // 读取告警类型 (1字节)
        let alarmType = data[offset]
        offset += 1
        
        // 读取电池电量 (1字节)
        let battery = data[offset]
        offset += 1
        
        let alarmInfo = AlarmInfo(
            deviceId: deviceId,
            timestamp: timestamp,
            latitude: latitude,
            latitudeHemisphere: latitudeHemisphere,
            longitude: longitude,
            longitudeHemisphere: longitudeHemisphere,
            altitude: altitude,
            motionStatus: motionStatus,
            alarmType: alarmType,
            battery: battery
        )
        
        print("🚨 收到报警信息:")
        print("  设备ID: \(deviceId)")
        print("  时间戳: \(timestamp) (\(Date(timeIntervalSince1970: TimeInterval(timestamp))))")
        print("  纬度: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S")")
        print("  经度: \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
        print("  海拔: \(Float(altitude) / 10.0) 米")
        print("  运动状态: \(getMotionStatusDescription(motionStatus))")
        print("  告警类型: \(getAlarmTypeDescription(alarmType))")
        print("  电池电量: \(battery)%")
        
        NotificationCenter.default.post(
            name: .didReceiveAlarmReport,
            object: nil,
            userInfo: ["alarmInfo": alarmInfo]
        )
    }
    
    private func handlePositionReport(_ data: Data) {
        guard data.count >= 32 else {
            print("定位信息数据长度错误: \(data.count)")
            return
        }
        
        var offset = 0
        
        // 安全读取设备ID (8字节)
        let deviceId = (UInt64(data[offset]) << 56) |
        (UInt64(data[offset + 1]) << 48) |
        (UInt64(data[offset + 2]) << 40) |
        (UInt64(data[offset + 3]) << 32) |
        (UInt64(data[offset + 4]) << 24) |
        (UInt64(data[offset + 5]) << 16) |
        (UInt64(data[offset + 6]) << 8) |
        UInt64(data[offset + 7])
        offset += 8
        
        // 读取定位数据条数 (1字节)
        let numPositions = data[offset]
        offset += 1
        
        // 安全读取定位上报间隔 (2字节)
        let positionReport = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        // 安全读取首条数据时间戳 (4字节)
        let firstTimestamp = (UInt32(data[offset]) << 24) |
        (UInt32(data[offset + 1]) << 16) |
        (UInt32(data[offset + 2]) << 8) |
        UInt32(data[offset + 3])
        offset += 4
        
        var positions: [PositionInfo] = []
        var currentOffset = offset
        
        // 解析多条定位信息
        for i in 0..<Int(numPositions) {
            guard currentOffset + 17 <= data.count else {
                print("定位数据 \(i) 长度不足")
                break
            }
            
            // 安全读取时间戳 (4字节)
            let timestamp = (UInt32(data[currentOffset]) << 24) |
            (UInt32(data[currentOffset + 1]) << 16) |
            (UInt32(data[currentOffset + 2]) << 8) |
            UInt32(data[currentOffset + 3])
            currentOffset += 4
            
            // 安全读取纬度 (4字节，*10000)
            let latitude = (Int32(data[currentOffset]) << 24) |
            (Int32(data[currentOffset + 1]) << 16) |
            (Int32(data[currentOffset + 2]) << 8) |
            Int32(data[currentOffset + 3])
            currentOffset += 4
            
            // 读取纬度半球 (1字节)
            let latitudeHemisphere = data[currentOffset]
            currentOffset += 1
            
            // 安全读取经度 (4字节，*10000)
            let longitude = (Int32(data[currentOffset]) << 24) |
            (Int32(data[currentOffset + 1]) << 16) |
            (Int32(data[currentOffset + 2]) << 8) |
            Int32(data[currentOffset + 3])
            currentOffset += 4
            
            // 读取经度半球 (1字节)
            let longitudeHemisphere = data[currentOffset]
            currentOffset += 1
            
            // 安全读取海拔 (4字节，*10)
            let altitude = (Int32(data[offset]) << 24) |
            (Int32(data[offset + 1]) << 16) |
            (Int32(data[offset + 2]) << 8) |
            Int32(data[offset + 3])
            currentOffset += 4
            
            let positionInfo = PositionInfo(
                timestamp: timestamp,
                latitude: latitude,
                latitudeHemisphere: latitudeHemisphere,
                longitude: longitude,
                longitudeHemisphere: longitudeHemisphere,
                altitude: altitude
            )
            
            positions.append(positionInfo)
            
            print("  定位点 \(i+1):")
            print("    时间: \(Date(timeIntervalSince1970: TimeInterval(timestamp)))")
            print("    坐标: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S"), \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
            print("    海拔: \(Float(altitude) / 10.0) 米")
        }
        
        print("📍 收到定位信息上报:")
        print("  设备ID: \(deviceId)")
        print("  定位数据条数: \(numPositions)")
        print("  上报间隔: \(positionReport) 秒")
        print("  首条时间: \(Date(timeIntervalSince1970: TimeInterval(firstTimestamp)))")
        print("  解析到 \(positions.count) 条定位数据")
        
        NotificationCenter.default.post(
            name: .didReceivePositionReport,
            object: nil,
            userInfo: [
                "deviceId": deviceId,
                "numPositions": numPositions,
                "positionReport": positionReport,
                "firstTimestamp": firstTimestamp,
                "positions": positions
            ]
        )
    }
    
    // MARK: - 辅助方法
    // 坐标格式化辅助方法
    private func formatCoordinate(_ value: Int32, isLatitude: Bool) -> String {
        let decimalValue = Float(value) / 10000.0
        return String(format: "%.6f", decimalValue)
    }
    
    // 时间间隔格式化辅助方法
    private func formatTimeInterval(_ seconds: UInt32) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if days > 0 {
            return "\(days)天\(hours)小时\(minutes)分\(secs)秒"
        } else if hours > 0 {
            return "\(hours)小时\(minutes)分\(secs)秒"
        } else if minutes > 0 {
            return "\(minutes)分\(secs)秒"
        } else {
            return "\(secs)秒"
        }
    }
    
    // 工作模式描述
    private func getWorkModeDescription(_ mode: UInt8) -> String {
        switch mode {
        case 0: return "待机模式"
        case 1: return "正常工作模式"
        default: return "未知(\(mode))"
        }
    }
    
    // 运动状态描述
    private func getMotionStatusDescription(_ status: UInt8) -> String {
        switch status {
        case 0: return "静态"
        case 1: return "运动"
        case 2: return "跌落"
        default: return "未知(\(status))"
        }
    }
    
    // 报警类型描述
    private func getAlarmTypeDescription(_ type: UInt8) -> String {
        switch type {
        case 0: return "SOS报警"
        case 1: return "报平安"
        default: return "未知(\(type))"
        }
    }
    
    private func handlePlatformNotification(_ data: Data) {
        if let notificationText = String(data: data, encoding: .utf8) {
            NotificationCenter.default.post(
                name: .didReceivePlatformNotification,
                object: nil,
                userInfo: ["text": notificationText]
            )
        }
    }
}


// MARK: - 扩展数据类型转换
public extension UInt16 {
    var bigEndianData: Data {
        var value = self.bigEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
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

// MARK: - 数据解析扩展
public extension BluetoothManager {
    
    // 解析通信帧
    private func parseCommunicationFrame(_ data: Data) -> CommunicationFrame? {
        guard data.count >= 14 else {
            print("数据长度不足: \(data.count)")
            return nil
        }
        
        var offset = 0
        
        // 安全读取帧头 (2字节)
        let header = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        guard header == 0xAA55 else {
            print("帧头错误: 0x\(String(format: "%04X", header))")
            return nil
        }
        
        // 安全读取流水码 (4字节)
        let serialNumber = (UInt32(data[offset]) << 24) |
                           (UInt32(data[offset + 1]) << 16) |
                           (UInt32(data[offset + 2]) << 8) |
                           UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取数据长度 (2字节) - 根据文档，这是信息内容的长度
        let dataLength = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        // 修正：数据长度字段只包含信息内容的长度（不包含命令编号）
        // 所以总帧长度应该是：帧头2 + 流水码4 + 数据长度2 + 命令编号2 + 信息内容(dataLength) + 校验码2 + 结束符2
        let messageLength = Int(dataLength) // 信息内容长度
        let expectedTotalLength = 2 + 4 + 2 + 2 + messageLength + 2 + 2
        
        guard data.count == expectedTotalLength else {
            print("数据长度不匹配: 期望\(expectedTotalLength)，实际\(data.count)，数据长度字段: \(dataLength)")
            print("详细计算: 帧头2 + 流水码4 + 数据长度2 + 命令编号2 + 信息内容\(messageLength) + 校验码2 + 结束符2")
            return nil
        }
        
        // 安全读取命令编号 (2字节)
        let commandCodeValue = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        guard let commandCode = CommandCode(rawValue: commandCodeValue) else {
            print("未知命令编号: 0x\(String(format: "%04X", commandCodeValue))")
            return nil
        }
        offset += 2
        
        // 解析信息内容
        guard offset + messageLength <= data.count else {
            print("信息内容长度错误: offset=\(offset), messageLength=\(messageLength), data.count=\(data.count)")
            return nil
        }
        let messageContent = data.subdata(in: offset..<offset + messageLength)
        offset += messageLength
        
        // 安全读取校验码 (2字节)
        let checksum = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        // 安全读取结束符 (2字节)
        let terminator = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        guard terminator == 0x0D0A else {
            print("结束符错误: 0x\(String(format: "%04X", terminator))")
            return nil
        }
        
        // 验证校验码
        let checksumData = data.subdata(in: 0..<(2 + 4 + 2 + 2 + messageLength))
        
        let calculatedChecksum = crcCalculator.calculate(checksumData)
        
        guard checksum == calculatedChecksum else {
            print("校验码错误: 计算值0x\(String(format: "%04X", calculatedChecksum))，接收值0x\(String(format: "%04X", checksum))")
            print("校验数据: \(checksumData.hexString)")
            return nil
        }
        
        print("✅ 通信帧解析成功:")
        print("  帧头: 0x\(String(format: "%04X", header))")
        print("  流水码: \(serialNumber)")
        print("  数据长度字段: \(dataLength)")
        print("  命令编号: 0x\(String(format: "%04X", commandCode.rawValue))")
        print("  信息内容长度: \(messageContent.count)")
        print("  信息内容: \(messageContent.hexString)")
        print("  校验码: 0x\(String(format: "%04X", checksum))")
        print("  结束符: 0x\(String(format: "%04X", terminator))")
        
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
    
    
    
    // 解析BLE广播数据
    func parseAdvertisementData(_ advertisementData: [String: Any]) -> (mac: Data?, advVersion: UInt8?, bond: UInt8?, pid: UInt16?, did: UInt64?)? {
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              manufacturerData.count >= 2 else {
            return nil
        }
        
        // 检查厂商ID（小端）
        let companyId = (UInt16(manufacturerData[1]) << 8) | UInt16(manufacturerData[0])
        guard companyId == 0x1273 else { // 你的公司ID
            return nil
        }
        
        var offset = 2
        guard manufacturerData.count >= offset + 25 else {
            return nil
        }
        
        // 解析MAC地址（小端，6字节）
        let mac = manufacturerData.subdata(in: offset..<offset + 6)
        offset += 6
        
        // 解析广播版本（1字节）
        let advVersion = manufacturerData[offset]
        offset += 1
        
        // 解析绑定状态（1字节）
        let bond = manufacturerData[offset]
        offset += 1
        
        // 解析产品ID（小端，2字节）
        let pid = (UInt16(manufacturerData[offset + 1]) << 8) | UInt16(manufacturerData[offset])
        offset += 2
        
        // 解析设备ID（小端，8字节）
        var didBytes = [UInt8](manufacturerData[offset..<offset + 8])
        didBytes.reverse() // 转换为大端用于显示
        let did = didBytes.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        return (mac: mac, advVersion: advVersion, bond: bond, pid: pid, did: did)
    }
}


// MARK: - 数据接收处理
public extension BluetoothManager {
    
    func handleReceivedData(_ data: Data, from characteristic: CBCharacteristic) {
        if let packet = parsePacketData(data) {
            print("解析到分包数据:")
            print("  帧头: 0x\(String(format: "%04X", packet.header))")
            print("  状态: \(packet.status)")
            print("  编号: \(packet.packetId)")
            print("  长度: \(packet.dataLength)")
            print("  数据: \(packet.data.hexString)")
            
            
            if let completeData = packetAssembler.processPacket(packet) {
                print("✅ 组包完成，完整数据长度: \(completeData.count) 字节")
                processApplicationData(completeData)
            } else if packet.status == .noPacket {
                processApplicationData(packet.data)
            }
        } else {
            if let stringValue = String(data: data, encoding: .utf8) {
                print("收到文本数据: \(stringValue)")
                NotificationCenter.default.post(
                    name: .didReceiveBluetoothData,
                    object: nil,
                    userInfo: ["data": stringValue, "type": "text"]
                )
            } else {
                let hexString = data.hexString
                print("收到二进制数据: \(hexString)")
                NotificationCenter.default.post(
                    name: .didReceiveBluetoothData,
                    object: nil,
                    userInfo: ["data": data, "type": "binary", "hex": hexString]
                )
            }
        }
    }
    
    // 解析分包数据
    private func parsePacketData(_ data: Data) -> PacketData? {
        guard data.count >= 9 else {
            print("数据长度不足")
            return nil
        }
        
        var offset = 0
        
        // 安全读取帧头 (2字节)
        let header = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        guard header == 0xFAF5 else {
            print("帧头错误: 0x\(String(format: "%04X", header))")
            return nil
        }
        
        // 读取分包状态 (1字节)
        let statusValue = data[offset]
        guard let status = PacketStatus(rawValue: statusValue) else {
            print("未知的分包状态: 0x\(String(format: "%02X", statusValue))")
            return nil
        }
        offset += 1
        
        // 安全读取分包数据编号 (4字节)
        let packetId = (UInt32(data[offset]) << 24) |
                       (UInt32(data[offset + 1]) << 16) |
                       (UInt32(data[offset + 2]) << 8) |
                       UInt32(data[offset + 3])
        offset += 4
        
        // 安全读取数据长度 (2字节)
        let dataLength = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        guard offset + Int(dataLength) <= data.count else {
            print("数据长度不匹配: 期望 \(offset + Int(dataLength))，实际 \(data.count)")
            return nil
        }
        
        let packetData = data.subdata(in: offset..<offset + Int(dataLength))
        
        return PacketData(
            header: header,
            status: status,
            packetId: packetId,
            dataLength: dataLength,
            data: packetData
        )
    }
    
    private func processApplicationData(_ data: Data) {
        print("处理应用数据: \(data.hexString)")
        
        if let frame = parseCommunicationFrame(data) {
            print("✅ 解析到通信帧:")
            print("  流水码: \(frame.serialNumber)")
            print("  命令编号: 0x\(String(format: "%04X", frame.commandCode.rawValue))")
            print("  信息内容: \(frame.messageContent.hexString)")
            
            if frame.messageContent.count == 5 {
                // 消息长度==5
                if let responseFrame = parseResponseFrame(data) {
                    handleResponseFrame(responseFrame)
                }
            } else {
                handleCommandFrame(frame)
            }
        } else {
            print("无法解析为通信帧")
            NotificationCenter.default.post(
                name: .didReceiveBluetoothData,
                object: nil,
                userInfo: [
                    "data": data,
                    "type": "raw",
                    "hex": data.hexString
                ]
            )
        }
    }
    
    private func parseResponseFrame(_ data: Data) -> ResponseFrame? {
        guard let frame = parseCommunicationFrame(data) else {
            return nil
        }
        
        guard frame.messageContent.count == 5 else {
            print("应答帧信息内容长度错误: \(frame.messageContent.count)")
            return nil
        }
        
        return ResponseFrame(
            header: frame.header,
            serialNumber: frame.serialNumber,
            dataLength: frame.dataLength,
            commandCode: frame.commandCode,
            messageContent: frame.messageContent,
            checksum: frame.checksum,
            terminator: frame.terminator
        )
    }
    
    private func handleCommandFrame(_ frame: CommunicationFrame) {
        print("处理命令帧: \(frame.commandCode)")
        
        switch frame.commandCode {
        case .deviceInfo:
            handleDeviceInfoResponse(frame.messageContent)
        case .statusInfo:
            handleStatusInfoResponse(frame.messageContent)
        case .alarmReport:
            handleAlarmReport(frame.messageContent)
        case .positionReport:
            handlePositionReport(frame.messageContent)
        case .platformNotification:
            handlePlatformNotification(frame.messageContent)
        case .getPhoneLocation:
            NotificationCenter.default.post(
                name: .deviceRequestPhoneLocation,
                object: nil
            )
        case .platformCustomData:
            NotificationCenter.default.post(
                name: .didReceiveDeviceCustomMsg,
                object: nil,
                userInfo: ["data": frame.messageContent]
            )
        case .getSatelliteRecords:
            guard let recordFrame = parseCommunicationFrame(frame.messageContent) else {
                handlePlatformNotification(frame.messageContent)
                return
            }
            
        default:
            print("未处理的命令: \(frame.commandCode)")
        }
        
        NotificationCenter.default.post(
            name: .didReceiveCommandFrame,
            object: nil,
            userInfo: ["frame": frame]
        )
    }
    
    private func handleResponseFrame(_ frame: ResponseFrame) {
        guard let responseSerial = frame.responseSerial,
              let responseStatus = frame.responseStatus else {
            print("应答帧解析失败")
            return
        }
        
        print("✅ 收到应答帧:")
        print("  对应流水码: \(responseSerial)")
        print("  应答状态: \(responseStatus)")
        
        // 处理固件数据应答
        if frame.commandCode == .startFirmwareUpgrade {
            sendNextFirmwarePacket()
        }
        
        if frame.commandCode == .firmwareData {
            handleFirmwareDataResponse(frame)
        }
        
        if frame.commandCode == .appTriggerAlarm {
            NotificationCenter.default.post(
                name: .didSaveOfSOSResponseMsg,
                object: nil,
                userInfo: [
                    "result": responseStatus
                ]
            )
        }
        
        if frame.commandCode == .setBindStatus {
            NotificationCenter.default.post(
                name: .unBindMiniDeviceResponseMsg,
                object: nil,
                userInfo: [
                    "result": responseStatus
                ]
            )
        }
        
        NotificationCenter.default.post(
            name: .didReceiveResponseFrame,
            object: nil,
            userInfo: [
                "frame": frame,
                "responseSerial": responseSerial,
                "responseStatus": responseStatus
            ]
        )
    }
    
    private func handleFirmwareDataResponse(_ frame: ResponseFrame) {
        guard let responseSerial = frame.responseSerial,
              let responseStatus = frame.responseStatus else {
            return
        }
        
        print("固件数据包应答:")
        print("  状态: \(responseStatus)")
        print("  对应流水码: \(responseSerial)")
        
        switch responseStatus {
        case .success:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.sendNextFirmwarePacket()
            }
        case .inProgress:
            print("设备正在处理固件数据包")
        case .failed, .crcError:
            print("固件数据包发送失败，停止升级")
            firmwareManager.reset()
            NotificationCenter.default.post(
                name: .firmwareUpgradeCompleted,
                object: nil,
                userInfo: ["success": false, "error": "发送失败"]
            )
        }
    }
}

// MARK: - 广播数据解析扩展
public extension BluetoothManager {
    
    /// 解析BLE广播自定义数据
    func parseBLEAdvertisementData(_ advertisementData: [String: Any]) -> BLEAdvertisementData? {
        // 1. 获取制造商数据
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              manufacturerData.count >= 18 else {
            print("制造商数据长度不足: \(advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data())")
            return nil
        }
        
        var offset = 0
        
        // 3. 解析MAC地址 (6字节，小端)
        guard offset + 6 <= manufacturerData.count else { return nil }
        let macData = manufacturerData.subdata(in: offset..<offset + 6)
        let macAddress = formatMACAddress(macData)
        offset += 6
        
        // 4. 解析广播版本 (1字节)
        guard offset + 1 <= manufacturerData.count else { return nil }
        let advVersion = manufacturerData[offset]
        offset += 1
        
        // 5. 解析绑定状态 (1字节)
        guard offset + 1 <= manufacturerData.count else { return nil }
        let bondStatus = manufacturerData[offset]
        offset += 1
        
        // 6. 解析产品ID (2字节，小端)
        guard offset + 2 <= manufacturerData.count else { return nil }
        let productId = (UInt16(manufacturerData[offset + 1]) << 8) | UInt16(manufacturerData[offset])
        offset += 2
        
        // 7. 解析设备ID/IMEI (8字节)
        guard offset + 8 <= manufacturerData.count else { return nil }
        let deviceIdData = manufacturerData.subdata(in: offset..<offset + 8)
        print(" 设备ID(IMEI)的数据: \(deviceIdData.hexString)")
        let deviceId = parseDeviceId(deviceIdData)
        
//        print("✅ 解析到BLE广播数据:")
//        print("  MAC地址: \(macAddress)")
//        print("  广播版本: \(advVersion)")
//        print("  绑定状态: \(bondStatus == 1 ? "已绑定" : "未绑定")")
//        print("  产品ID: 0x\(String(format: "%04X", productId))")
//        print("  设备ID(IMEI): \(deviceId)")
        
        return BLEAdvertisementData(
            macAddress: macAddress,
            advVersion: advVersion,
            bondStatus: bondStatus,
            productId: productId,
            deviceId: deviceId
        )
    }
    
    /// 格式化MAC地址
    private func formatMACAddress(_ data: Data) -> String {
        let bytes = [UInt8](data)
        // MAC地址是小端，需要反转显示
        let reversedBytes = bytes.reversed()
        return reversedBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }
    
    /// 解析设备ID (IMEI)
    private func parseDeviceId(_ data: Data) -> String {
        let hexString = data.hexString
        var result = ""
        
        if let value = UInt64(hexString, radix: 16) {
            result = String(value)
        }
        
        return result
    }
    
    /// 从广播数据中提取IMEI（兼容旧方法）
    func extractIMEIFromAdvertisementData(_ advertisementData: [String: Any]) -> String? {
        if let bleData = parseBLEAdvertisementData(advertisementData) {
            return bleData.deviceId
        }
        return nil
    }
}


// 版本号格式化辅助方法
public func formatVersion(_ version: UInt32) -> String {
    let major = (version >> 24) & 0xFF
    let minor = (version >> 16) & 0xFF
    let patch = (version >> 8) & 0xFF
    let build = version & 0xFF
    return "v\(major).\(minor).\(patch).\(build)"
}

//
//  File.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/18.
//

//import Foundation
//import CoreBluetooth
//
//// MARK: - 数据解析具体实现
//extension BluetoothManager {
//    
//    // 辅助方法：从Data中解析UInt64（大端序）
//    private func parseUInt64(from data: Data, at offset: inout Int) -> UInt64 {
//        var value: UInt64 = 0
//        value |= UInt64(data[offset]) << 56
//        value |= UInt64(data[offset + 1]) << 48
//        value |= UInt64(data[offset + 2]) << 40
//        value |= UInt64(data[offset + 3]) << 32
//        value |= UInt64(data[offset + 4]) << 24
//        value |= UInt64(data[offset + 5]) << 16
//        value |= UInt64(data[offset + 6]) << 8
//        value |= UInt64(data[offset + 7])
//        offset += 8
//        return value
//    }
//    
//    // 辅助方法：从Data中解析UInt32（大端序）
//    private func parseUInt32(from data: Data, at offset: inout Int) -> UInt32 {
//        var value: UInt32 = 0
//        value |= UInt32(data[offset]) << 24
//        value |= UInt32(data[offset + 1]) << 16
//        value |= UInt32(data[offset + 2]) << 8
//        value |= UInt32(data[offset + 3])
//        offset += 4
//        return value
//    }
//    
//    // 辅助方法：从Data中解析Int32（大端序）
//    private func parseInt32(from data: Data, at offset: inout Int) -> Int32 {
//        var value: Int32 = 0
//        value |= Int32(data[offset]) << 24
//        value |= Int32(data[offset + 1]) << 16
//        value |= Int32(data[offset + 2]) << 8
//        value |= Int32(data[offset + 3])
//        offset += 4
//        return value
//    }
//    
//    // 辅助方法：从Data中解析UInt16（大端序）
//    private func parseUInt16(from data: Data, at offset: inout Int) -> UInt16 {
//        let value = UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
//        offset += 2
//        return value
//    }
//    
//    private func handleDeviceInfoResponse(_ data: Data) {
//        guard data.count >= 33 else {
//            print("设备信息数据长度错误: \(data.count)")
//            return
//        }
//        
//        var offset = 0
//        
//        // 安全读取协议版本 (2字节)
//        let protocolVersion = parseUInt16(from: data, at: &offset)
//        
//        // 读取BLE MAC地址 (6字节)
//        let bleMac = data.subdata(in: offset..<offset + 6)
//        offset += 6
//        
//        // 读取绑定状态 (1字节)
//        let bond = data[offset]
//        offset += 1
//        
//        // 安全读取蓝牙软件版本 (4字节)
//        let bleSoftwareVersion = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取蓝牙硬件版本 (4字节)
//        let bleHardwareVersion = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取MCU软件版本 (4字节)
//        let mcuSoftwareVersion = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取MCU硬件版本 (4字节)
//        let mcuHardwareVersion = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取设备ID (8字节)
//        let deviceId = parseUInt64(from: data, at: &offset)
//        
//        let deviceInfo = DeviceInfo(
//            protocolVersion: protocolVersion,
//            bleMac: bleMac,
//            bond: bond,
//            bleSoftwareVersion: bleSoftwareVersion,
//            bleHardwareVersion: bleHardwareVersion,
//            mcuSoftwareVersion: mcuSoftwareVersion,
//            mcuHardwareVersion: mcuHardwareVersion,
//            deviceId: deviceId
//        )
//        
//        print("✅ 收到设备信息:")
//        print("  协议版本: 0x\(String(format: "%04X", protocolVersion))")
//        print("  BLE MAC: \(bleMac.hexString)")
//        print("  绑定状态: \(bond == 1 ? "已绑定" : "未绑定")")
//        print("  蓝牙软件版本: \(formatVersion(bleSoftwareVersion))")
//        print("  蓝牙硬件版本: \(formatVersion(bleHardwareVersion))")
//        print("  MCU软件版本: \(formatVersion(mcuSoftwareVersion))")
//        print("  MCU硬件版本: \(formatVersion(mcuHardwareVersion))")
//        print("  设备ID: \(deviceId)")
//        
//        NotificationCenter.default.post(
//            name: .didReceiveDeviceInfo,
//            object: nil,
//            userInfo: ["deviceInfo": deviceInfo]
//        )
//    }
//    
//    
//    private func handleStatusInfoResponse(_ data: Data) {
//        // 重新计算数据长度：run_time(4) + temp(4) + humi(4) + bat(1) + mds(1) + wm(1) + srpf(1) + lat(4) + lathem(1) + lon(4) + lonhem(1) + alt(4) + st(1) + pos_rpt(4) + low_power_t(4) + position_t(4) = 47字节
//        guard data.count >= 43 else {
//            print("状态信息数据长度错误: \(data.count)，期望至少43字节")
//            return
//        }
//        
//        var offset = 0
//        
//        // 安全读取运行时长 (4字节)
//        let runTime = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取温度 (4字节，*100)
//        let temperature = parseInt32(from: data, at: &offset)
//        
//        // 安全读取湿度 (4字节，*100)
//        let humidity = parseUInt32(from: data, at: &offset)
//        
//        // 读取电池电量 (1字节)
//        let battery = data[offset]
//        offset += 1
//        
//        // 读取模组状态 (1字节)
//        let moduleStatus = data[offset]
//        offset += 1
//        
//        // 读取工作模式 (1字节)
//        let workMode = data[offset]
//        offset += 1
//        
//        // 读取状态上报间隔 (1字节)
//        let statusReportFreq = data[offset]
//        offset += 1
//        
//        // 安全读取纬度 (4字节，*10000)
//        let latitude = parseInt32(from: data, at: &offset)
//        
//        // 读取纬度半球 (1字节)
//        let latitudeHemisphere = data[offset]
//        offset += 1
//        
//        // 安全读取经度 (4字节，*10000)
//        let longitude = parseInt32(from: data, at: &offset)
//        
//        // 读取经度半球 (1字节)
//        let longitudeHemisphere = data[offset]
//        offset += 1
//        
//        // 安全读取海拔 (4字节，*10) - 修正为4字节
//        let altitude = parseInt32(from: data, at: &offset)
//        
//        // 读取运动状态 (1字节)
//        let motionStatus = data[offset]
//        offset += 1
//        
//        // 安全读取定位信息上报间隔 (4字节) - 修正为4字节
//        let positionReport = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取低功耗唤醒时间 (4字节)
//        let lowPowerTime = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取定位信息存储周期 (4字节)
//        let positionStoreTime = parseUInt32(from: data, at: &offset)
//        
//        let statusInfo = StatusInfo(
//            runTime: runTime,
//            temperature: temperature,
//            humidity: humidity,
//            battery: battery,
//            moduleStatus: moduleStatus,
//            workMode: workMode,
//            statusReportFreq: statusReportFreq,
//            latitude: latitude,
//            latitudeHemisphere: latitudeHemisphere,
//            longitude: longitude,
//            longitudeHemisphere: longitudeHemisphere,
//            altitude: altitude,
//            motionStatus: motionStatus,
//            positionReport: positionReport,
//            lowPowerTime: lowPowerTime,
//            positionStoreTime: positionStoreTime
//        )
//        
//        print("✅ 收到状态信息:")
//        print("  运行时长: \(runTime) 秒 (\(formatTimeInterval(runTime)))")
//        print("  温度: \(Float(temperature) / 100.0)°C")
//        print("  湿度: \(Float(humidity) / 100.0)%")
//        print("  电池电量: \(battery)%")
//        print("  模组状态: 0x\(String(format: "%02X", moduleStatus))")
//        print("  工作模式: \(getWorkModeDescription(workMode))")
//        print("  状态上报间隔: \(statusReportFreq) 秒")
//        print("  纬度: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S")")
//        print("  经度: \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
//        print("  海拔: \(Float(altitude) / 10.0) 米")
//        print("  运动状态: \(getMotionStatusDescription(motionStatus))")
//        print("  定位上报间隔: \(positionReport) 秒")
//        print("  低功耗唤醒时间: \(lowPowerTime) 秒")
//        print("  定位存储周期: \(positionStoreTime) 秒")
//        
//        // 解析模组状态详细位
//        let bleStatus = (moduleStatus & 0x01) != 0 ? "异常" : "正常"
//        let satelliteStatus = (moduleStatus & 0x02) != 0 ? "异常" : "正常"
//        let gnssStatus = (moduleStatus & 0x04) != 0 ? "异常" : "正常"
//        print("  模组状态详情 - BLE:\(bleStatus) 卫星:\(satelliteStatus) GNSS:\(gnssStatus)")
//        
//        NotificationCenter.default.post(
//            name: .didReceiveStatusInfo,
//            object: nil,
//            userInfo: ["statusInfo": statusInfo]
//        )
//    }
//    
//    private func handleAlarmReport(_ data: Data) {
//        guard data.count >= 29 else {
//            print("报警信息数据长度错误: \(data.count)")
//            return
//        }
//        
//        var offset = 0
//        
//        // 安全读取设备ID (8字节)
//        let deviceId = parseUInt64(from: data, at: &offset)
//        
//        // 安全读取时间戳 (4字节)
//        let timestamp = parseUInt32(from: data, at: &offset)
//        
//        // 安全读取纬度 (4字节，*10000)
//        let latitude = parseInt32(from: data, at: &offset)
//        
//        // 读取纬度半球 (1字节)
//        let latitudeHemisphere = data[offset]
//        offset += 1
//        
//        // 安全读取经度 (4字节，*10000)
//        let longitude = parseInt32(from: data, at: &offset)
//        
//        // 读取经度半球 (1字节)
//        let longitudeHemisphere = data[offset]
//        offset += 1
//        
//        // 安全读取海拔 (4字节，*10) - 修正为4字节
//        let altitude = parseInt32(from: data, at: &offset)
//        
//        // 读取运动状态 (1字节)
//        let motionStatus = data[offset]
//        offset += 1
//        
//        // 读取告警类型 (1字节)
//        let alarmType = data[offset]
//        offset += 1
//        
//        // 读取电池电量 (1字节)
//        let battery = data[offset]
//        offset += 1
//        
//        let alarmInfo = AlarmInfo(
//            deviceId: deviceId,
//            timestamp: timestamp,
//            latitude: latitude,
//            latitudeHemisphere: latitudeHemisphere,
//            longitude: longitude,
//            longitudeHemisphere: longitudeHemisphere,
//            altitude: altitude,
//            motionStatus: motionStatus,
//            alarmType: alarmType,
//            battery: battery
//        )
//        
//        print("🚨 收到报警信息:")
//        print("  设备ID: \(deviceId)")
//        print("  时间戳: \(timestamp) (\(Date(timeIntervalSince1970: TimeInterval(timestamp))))")
//        print("  纬度: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S")")
//        print("  经度: \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
//        print("  海拔: \(Float(altitude) / 10.0) 米")
//        print("  运动状态: \(getMotionStatusDescription(motionStatus))")
//        print("  告警类型: \(getAlarmTypeDescription(alarmType))")
//        print("  电池电量: \(battery)%")
//        
//        NotificationCenter.default.post(
//            name: .didReceiveAlarmReport,
//            object: nil,
//            userInfo: ["alarmInfo": alarmInfo]
//        )
//    }
//    
//    private func handlePositionReport(_ data: Data) {
//        guard data.count >= 32 else {
//            print("定位信息数据长度错误: \(data.count)")
//            return
//        }
//        
//        var offset = 0
//        
//        // 安全读取设备ID (8字节)
//        let deviceId = parseUInt64(from: data, at: &offset)
//        
//        // 读取定位数据条数 (1字节)
//        let numPositions = data[offset]
//        offset += 1
//        
//        // 安全读取定位上报间隔 (2字节)
//        let positionReport = parseUInt16(from: data, at: &offset)
//        
//        // 安全读取首条数据时间戳 (4字节)
//        let firstTimestamp = parseUInt32(from: data, at: &offset)
//        
//        var positions: [PositionInfo] = []
//        var currentOffset = offset
//        
//        // 解析多条定位信息
//        for i in 0..<Int(numPositions) {
//            guard currentOffset + 17 <= data.count else {
//                print("定位数据 \(i) 长度不足")
//                break
//            }
//            
//            // 安全读取时间戳 (4字节)
//            // 注意：这里需要使用本地的currentOffset，所以不能直接使用parseUInt32方法
//            var tsValue: UInt32 = 0
//            tsValue |= UInt32(data[currentOffset]) << 24
//            tsValue |= UInt32(data[currentOffset + 1]) << 16
//            tsValue |= UInt32(data[currentOffset + 2]) << 8
//            tsValue |= UInt32(data[currentOffset + 3])
//            let timestamp = tsValue
//            currentOffset += 4
//            
//            // 安全读取纬度 (4字节，*10000)
//            var latValue: Int32 = 0
//            latValue |= Int32(data[currentOffset]) << 24
//            latValue |= Int32(data[currentOffset + 1]) << 16
//            latValue |= Int32(data[currentOffset + 2]) << 8
//            latValue |= Int32(data[currentOffset + 3])
//            let latitude = latValue
//            currentOffset += 4
//            
//            // 读取纬度半球 (1字节)
//            let latitudeHemisphere = data[currentOffset]
//            currentOffset += 1
//            
//            // 安全读取经度 (4字节，*10000)
//            let longitude = (Int32(data[currentOffset]) << 24) |
//            (Int32(data[currentOffset + 1]) << 16) |
//            (Int32(data[currentOffset + 2]) << 8) |
//            Int32(data[currentOffset + 3])
//            currentOffset += 4
//            
//            // 读取经度半球 (1字节)
//            let longitudeHemisphere = data[currentOffset]
//            currentOffset += 1
//            
//            // 安全读取海拔 (4字节，*10)
//            let altitude = (Int32(data[offset]) << 24) |
//            (Int32(data[offset + 1]) << 16) |
//            (Int32(data[offset + 2]) << 8) |
//            Int32(data[offset + 3])
//            currentOffset += 4
//            
//            let positionInfo = PositionInfo(
//                timestamp: timestamp,
//                latitude: latitude,
//                latitudeHemisphere: latitudeHemisphere,
//                longitude: longitude,
//                longitudeHemisphere: longitudeHemisphere,
//                altitude: altitude
//            )
//            
//            positions.append(positionInfo)
//            
//            print("  定位点 \(i+1):")
//            print("    时间: \(Date(timeIntervalSince1970: TimeInterval(timestamp)))")
//            print("    坐标: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S"), \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
//            print("    海拔: \(Float(altitude) / 10.0) 米")
//        }
//        
//        print("📍 收到定位信息上报:")
//        print("  设备ID: \(deviceId)")
//        print("  定位数据条数: \(numPositions)")
//        print("  上报间隔: \(positionReport) 秒")
//        print("  首条时间: \(Date(timeIntervalSince1970: TimeInterval(firstTimestamp)))")
//        print("  解析到 \(positions.count) 条定位数据")
//        
//        NotificationCenter.default.post(
//            name: .didReceivePositionReport,
//            object: nil,
//            userInfo: [
//                "deviceId": deviceId,
//                "numPositions": numPositions,
//                "positionReport": positionReport,
//                "firstTimestamp": firstTimestamp,
//                "positions": positions
//            ]
//        )
//    }
//    
//    // MARK: - 辅助方法
//    // 坐标格式化辅助方法
//    private func formatCoordinate(_ value: Int32, isLatitude: Bool) -> String {
//        let decimalValue = Float(value) / 10000.0
//        return String(format: "%.6f", decimalValue)
//    }
//    
//    // 时间间隔格式化辅助方法
//    private func formatTimeInterval(_ seconds: UInt32) -> String {
//        let days = seconds / 86400
//        let hours = (seconds % 86400) / 3600
//        let minutes = (seconds % 3600) / 60
//        let secs = seconds % 60
//        
//        if days > 0 {
//            return "\(days)天\(hours)小时\(minutes)分\(secs)秒"
//        } else if hours > 0 {
//            return "\(hours)小时\(minutes)分\(secs)秒"
//        } else if minutes > 0 {
//            return "\(minutes)分\(secs)秒"
//        } else {
//            return "\(secs)秒"
//        }
//    }
//    
//    // 工作模式描述
//    private func getWorkModeDescription(_ mode: UInt8) -> String {
//        switch mode {
//        case 0: return "待机模式"
//        case 1: return "正常工作模式"
//        default: return "未知(\(mode))"
//        }
//    }
//    
//    // 运动状态描述
//    private func getMotionStatusDescription(_ status: UInt8) -> String {
//        switch status {
//        case 0: return "静态"
//        case 1: return "运动"
//        case 2: return "跌落"
//        default: return "未知(\(status))"
//        }
//    }
//    
//    // 报警类型描述
//    private func getAlarmTypeDescription(_ type: UInt8) -> String {
//        switch type {
//        case 0: return "SOS报警"
//        case 1: return "报平安"
//        default: return "未知(\(type))"
//        }
//    }
//    
//    private func handlePlatformNotification(_ data: Data) {
//        if let notificationText = String(data: data, encoding: .utf8) {
//            NotificationCenter.default.post(
//                name: .didReceivePlatformNotification,
//                object: nil,
//                userInfo: ["text": notificationText]
//            )
//        }
//    }
//}
//
//
//// MARK: - 扩展数据类型转换
//public extension UInt16 {
//    var bigEndianData: Data {
//        var value = self.bigEndian
//        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
//    }
//}
//
//public extension UInt32 {
//    var bigEndianData: Data {
//        var value = self.bigEndian
//        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
//    }
//}
//
//public extension UInt64 {
//    var bigEndianData: Data {
//        var value = self.bigEndian
//        return Data(bytes: &value, count: MemoryLayout<UInt64>.size)
//    }
//}
//
//// 添加有符号整数的扩展
//public extension Int16 {
//    var bigEndianData: Data {
//        var value = self.bigEndian
//        return Data(bytes: &value, count: MemoryLayout<Int16>.size)
//    }
//}
//
//public extension Int32 {
//    var bigEndianData: Data {
//        var value = self.bigEndian
//        return Data(bytes: &value, count: MemoryLayout<Int32>.size)
//    }
//}
//
//public extension Data {
//    var hexString: String {
//        return map { String(format: "%02X", $0) }.joined()
//    }
//}
//
//// MARK: - 数据解析扩展
//public extension BluetoothManager {
//    
//    // 解析通信帧
//    private func parseCommunicationFrame(_ data: Data) -> CommunicationFrame? {
//        guard data.count >= 14 else {
//            print("数据长度不足: \(data.count)")
//            return nil
//        }
//        
//        var offset = 0
//        
//        // 安全读取帧头 (2字节)
//        let header = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        offset += 2
//        
//        guard header == 0xAA55 else {
//            print("帧头错误: 0x\(String(format: "%04X", header))")
//            return nil
//        }
//        
//        // 安全读取流水码 (4字节)
//        let serialNumber = (UInt32(data[offset]) << 24) |
//                           (UInt32(data[offset + 1]) << 16) |
//                           (UInt32(data[offset + 2]) << 8) |
//                           UInt32(data[offset + 3])
//        offset += 4
//        
//        // 安全读取数据长度 (2字节) - 根据文档，这是信息内容的长度
//        let dataLength = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        offset += 2
//        
//        // 修正：数据长度字段只包含信息内容的长度（不包含命令编号）
//        // 所以总帧长度应该是：帧头2 + 流水码4 + 数据长度2 + 命令编号2 + 信息内容(dataLength) + 校验码2 + 结束符2
//        let messageLength = Int(dataLength) // 信息内容长度
//        let expectedTotalLength = 2 + 4 + 2 + 2 + messageLength + 2 + 2
//        
//        guard data.count == expectedTotalLength else {
//            print("数据长度不匹配: 期望\(expectedTotalLength)，实际\(data.count)，数据长度字段: \(dataLength)")
//            print("详细计算: 帧头2 + 流水码4 + 数据长度2 + 命令编号2 + 信息内容\(messageLength) + 校验码2 + 结束符2")
//            return nil
//        }
//        
//        // 安全读取命令编号 (2字节)
//        let commandCodeValue = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        guard let commandCode = CommandCode(rawValue: commandCodeValue) else {
//            print("未知命令编号: 0x\(String(format: "%04X", commandCodeValue))")
//            return nil
//        }
//        offset += 2
//        
//        // 解析信息内容
//        guard offset + messageLength <= data.count else {
//            print("信息内容长度错误: offset=\(offset), messageLength=\(messageLength), data.count=\(data.count)")
//            return nil
//        }
//        let messageContent = data.subdata(in: offset..<offset + messageLength)
//        offset += messageLength
//        
//        // 安全读取校验码 (2字节)
//        let checksum = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        offset += 2
//        
//        // 安全读取结束符 (2字节)
//        let terminator = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        offset += 2
//        
//        guard terminator == 0x0D0A else {
//            print("结束符错误: 0x\(String(format: "%04X", terminator))")
//            return nil
//        }
//        
//        // 验证校验码
//        let checksumData = data.subdata(in: 0..<(2 + 4 + 2 + 2 + messageLength))
//        
//        let calculatedChecksum = crcCalculator.calculate(checksumData)
//        
//        guard checksum == calculatedChecksum else {
//            print("校验码错误: 计算值0x\(String(format: "%04X", calculatedChecksum))，接收值0x\(String(format: "%04X", checksum))")
//            print("校验数据: \(checksumData.hexString)")
//            return nil
//        }
//        
//        print("✅ 通信帧解析成功:")
//        print("  帧头: 0x\(String(format: "%04X", header))")
//        print("  流水码: \(serialNumber)")
//        print("  数据长度字段: \(dataLength)")
//        print("  命令编号: 0x\(String(format: "%04X", commandCode.rawValue))")
//        print("  信息内容长度: \(messageContent.count)")
//        print("  信息内容: \(messageContent.hexString)")
//        print("  校验码: 0x\(String(format: "%04X", checksum))")
//        print("  结束符: 0x\(String(format: "%04X", terminator))")
//        
//        return CommunicationFrame(
//            header: header,
//            serialNumber: serialNumber,
//            dataLength: dataLength,
//            commandCode: commandCode,
//            messageContent: messageContent,
//            checksum: checksum,
//            terminator: terminator
//        )
//    }
//    
//    
//    
//    // 解析BLE广播数据
//    func parseAdvertisementData(_ advertisementData: [String: Any]) -> (mac: Data?, advVersion: UInt8?, bond: UInt8?, pid: UInt16?, did: UInt64?)? {
//        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
//              manufacturerData.count >= 2 else {
//            return nil
//        }
//        
//        // 检查厂商ID（小端）
//        let companyId = (UInt16(manufacturerData[1]) << 8) | UInt16(manufacturerData[0])
//        guard companyId == 0x1273 else { // 你的公司ID
//            return nil
//        }
//        
//        var offset = 2
//        guard manufacturerData.count >= offset + 25 else {
//            return nil
//        }
//        
//        // 解析MAC地址（小端，6字节）
//        let mac = manufacturerData.subdata(in: offset..<offset + 6)
//        offset += 6
//        
//        // 解析广播版本（1字节）
//        let advVersion = manufacturerData[offset]
//        offset += 1
//        
//        // 解析绑定状态（1字节）
//        let bond = manufacturerData[offset]
//        offset += 1
//        
//        // 解析产品ID（小端，2字节）
//        let pid = (UInt16(manufacturerData[offset + 1]) << 8) | UInt16(manufacturerData[offset])
//        offset += 2
//        
//        // 解析设备ID（小端，8字节）
//        var didBytes = [UInt8](manufacturerData[offset..<offset + 8])
//        didBytes.reverse() // 转换为大端用于显示
//        let did = didBytes.withUnsafeBytes { $0.load(as: UInt64.self) }
//        
//        return (mac: mac, advVersion: advVersion, bond: bond, pid: pid, did: did)
//    }
//}
//
//
//// MARK: - 数据接收处理
//public extension BluetoothManager {
//    
//    func handleReceivedData(_ data: Data, from characteristic: CBCharacteristic) {
//        if let packet = parsePacketData(data) {
//            print("解析到分包数据:")
//            print("  帧头: 0x\(String(format: "%04X", packet.header))")
//            print("  状态: \(packet.status)")
//            print("  编号: \(packet.packetId)")
//            print("  长度: \(packet.dataLength)")
//            print("  数据: \(packet.data.hexString)")
//            
//            
//            if let completeData = packetAssembler.processPacket(packet) {
//                print("✅ 组包完成，完整数据长度: \(completeData.count) 字节")
//                processApplicationData(completeData)
//            } else if packet.status == .noPacket {
//                processApplicationData(packet.data)
//            }
//        } else {
//            if let stringValue = String(data: data, encoding: .utf8) {
//                print("收到文本数据: \(stringValue)")
//                NotificationCenter.default.post(
//                    name: .didReceiveBluetoothData,
//                    object: nil,
//                    userInfo: ["data": stringValue, "type": "text"]
//                )
//            } else {
//                let hexString = data.hexString
//                print("收到二进制数据: \(hexString)")
//                NotificationCenter.default.post(
//                    name: .didReceiveBluetoothData,
//                    object: nil,
//                    userInfo: ["data": data, "type": "binary", "hex": hexString]
//                )
//            }
//        }
//    }
//    
//    // 解析分包数据
//    private func parsePacketData(_ data: Data) -> PacketData? {
//        guard data.count >= 9 else {
//            print("数据长度不足")
//            return nil
//        }
//        
//        var offset = 0
//        
//        // 安全读取帧头 (2字节)
//        let header = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        offset += 2
//        
//        guard header == 0xFAF5 else {
//            print("帧头错误: 0x\(String(format: "%04X", header))")
//            return nil
//        }
//        
//        // 读取分包状态 (1字节)
//        let statusValue = data[offset]
//        guard let status = PacketStatus(rawValue: statusValue) else {
//            print("未知的分包状态: 0x\(String(format: "%02X", statusValue))")
//            return nil
//        }
//        offset += 1
//        
//        // 安全读取分包数据编号 (4字节)
//        let packetId = (UInt32(data[offset]) << 24) |
//                       (UInt32(data[offset + 1]) << 16) |
//                       (UInt32(data[offset + 2]) << 8) |
//                       UInt32(data[offset + 3])
//        offset += 4
//        
//        // 安全读取数据长度 (2字节)
//        let dataLength = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
//        offset += 2
//        
//        guard offset + Int(dataLength) <= data.count else {
//            print("数据长度不匹配: 期望 \(offset + Int(dataLength))，实际 \(data.count)")
//            return nil
//        }
//        
//        let packetData = data.subdata(in: offset..<offset + Int(dataLength))
//        
//        return PacketData(
//            header: header,
//            status: status,
//            packetId: packetId,
//            dataLength: dataLength,
//            data: packetData
//        )
//    }
//    
//    private func processApplicationData(_ data: Data) {
//        print("处理应用数据: \(data.hexString)")
//        
//        if let frame = parseCommunicationFrame(data) {
//            print("✅ 解析到通信帧:")
//            print("  流水码: \(frame.serialNumber)")
//            print("  命令编号: 0x\(String(format: "%04X", frame.commandCode.rawValue))")
//            print("  信息内容: \(frame.messageContent.hexString)")
//            
//            if frame.messageContent.count == 5 {
//                // 消息长度==5
//                if let responseFrame = parseResponseFrame(data) {
//                    handleResponseFrame(responseFrame)
//                }
//            } else {
//                handleCommandFrame(frame)
//            }
//        } else {
//            print("无法解析为通信帧")
//            NotificationCenter.default.post(
//                name: .didReceiveBluetoothData,
//                object: nil,
//                userInfo: [
//                    "data": data,
//                    "type": "raw",
//                    "hex": data.hexString
//                ]
//            )
//        }
//    }
//    
//    private func parseResponseFrame(_ data: Data) -> ResponseFrame? {
//        guard let frame = parseCommunicationFrame(data) else {
//            return nil
//        }
//        
//        guard frame.messageContent.count == 5 else {
//            print("应答帧信息内容长度错误: \(frame.messageContent.count)")
//            return nil
//        }
//        
//        return ResponseFrame(
//            header: frame.header,
//            serialNumber: frame.serialNumber,
//            dataLength: frame.dataLength,
//            commandCode: frame.commandCode,
//            messageContent: frame.messageContent,
//            checksum: frame.checksum,
//            terminator: frame.terminator
//        )
//    }
//    
//    private func handleCommandFrame(_ frame: CommunicationFrame) {
//        print("处理命令帧: \(frame.commandCode)")
//        
//        switch frame.commandCode {
//        case .deviceInfo:
//            handleDeviceInfoResponse(frame.messageContent)
//        case .statusInfo:
//            handleStatusInfoResponse(frame.messageContent)
//        case .alarmReport:
//            handleAlarmReport(frame.messageContent)
//        case .positionReport:
//            handlePositionReport(frame.messageContent)
//        case .platformNotification:
//            handlePlatformNotification(frame.messageContent)
//        case .getPhoneLocation:
//            NotificationCenter.default.post(
//                name: .deviceRequestPhoneLocation,
//                object: nil
//            )
//        case .platformCustomData:
//            NotificationCenter.default.post(
//                name: .didReceiveDeviceCustomMsg,
//                object: nil,
//                userInfo: ["data": frame.messageContent]
//            )
//        case .getSatelliteRecords:
//            guard let recordFrame = parseCommunicationFrame(frame.messageContent) else {
//                handlePlatformNotification(frame.messageContent)
//                return
//            }
//            
//        default:
//            print("未处理的命令: \(frame.commandCode)")
//        }
//        
//        NotificationCenter.default.post(
//            name: .didReceiveCommandFrame,
//            object: nil,
//            userInfo: ["frame": frame]
//        )
//    }
//    
//    private func handleResponseFrame(_ frame: ResponseFrame) {
//        guard let responseSerial = frame.responseSerial,
//              let responseStatus = frame.responseStatus else {
//            print("应答帧解析失败")
//            return
//        }
//        
//        print("✅ 收到应答帧:")
//        print("  对应流水码: \(responseSerial)")
//        print("  应答状态: \(responseStatus)")
//        
//        // 处理固件数据应答
//        if frame.commandCode == .startFirmwareUpgrade {
//            sendNextFirmwarePacket()
//        }
//        
//        if frame.commandCode == .firmwareData {
//            handleFirmwareDataResponse(frame)
//        }
//        
//        NotificationCenter.default.post(
//            name: .didReceiveResponseFrame,
//            object: nil,
//            userInfo: [
//                "frame": frame,
//                "responseSerial": responseSerial,
//                "responseStatus": responseStatus
//            ]
//        )
//    }
//    
//    private func handleFirmwareDataResponse(_ frame: ResponseFrame) {
//        guard let responseSerial = frame.responseSerial,
//              let responseStatus = frame.responseStatus else {
//            return
//        }
//        
//        print("固件数据包应答:")
//        print("  状态: \(responseStatus)")
//        print("  对应流水码: \(responseSerial)")
//        
//        switch responseStatus {
//        case .success:
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.sendNextFirmwarePacket()
//            }
//        case .inProgress:
//            print("设备正在处理固件数据包")
//        case .failed, .crcError:
//            print("固件数据包发送失败，停止升级")
//            firmwareManager.reset()
//            NotificationCenter.default.post(
//                name: .firmwareUpgradeCompleted,
//                object: nil,
//                userInfo: ["success": false, "error": "发送失败"]
//            )
//        }
//    }
//}
//
//// MARK: - 广播数据解析扩展
//public extension BluetoothManager {
//    
//    /// 解析BLE广播自定义数据
//    func parseBLEAdvertisementData(_ advertisementData: [String: Any]) -> BLEAdvertisementData? {
//        // 1. 获取制造商数据
//        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
//              manufacturerData.count >= 18 else {
//            print("制造商数据长度不足: \(advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data())")
//            return nil
//        }
//        
//        var offset = 0
//        
//        // 3. 解析MAC地址 (6字节，小端)
//        guard offset + 6 <= manufacturerData.count else { return nil }
//        let macData = manufacturerData.subdata(in: offset..<offset + 6)
//        let macAddress = formatMACAddress(macData)
//        offset += 6
//        
//        // 4. 解析广播版本 (1字节)
//        guard offset + 1 <= manufacturerData.count else { return nil }
//        let advVersion = manufacturerData[offset]
//        offset += 1
//        
//        // 5. 解析绑定状态 (1字节)
//        guard offset + 1 <= manufacturerData.count else { return nil }
//        let bondStatus = manufacturerData[offset]
//        offset += 1
//        
//        // 6. 解析产品ID (2字节，小端)
//        guard offset + 2 <= manufacturerData.count else { return nil }
//        let productId = (UInt16(manufacturerData[offset + 1]) << 8) | UInt16(manufacturerData[offset])
//        offset += 2
//        
//        // 7. 解析设备ID/IMEI (8字节)
//        guard offset + 8 <= manufacturerData.count else { return nil }
//        let deviceIdData = manufacturerData.subdata(in: offset..<offset + 8)
//        print(" 设备ID(IMEI)的数据: \(deviceIdData.hexString)")
//        let deviceId = parseDeviceId(deviceIdData)
//        
////        print("✅ 解析到BLE广播数据:")
////        print("  MAC地址: \(macAddress)")
////        print("  广播版本: \(advVersion)")
////        print("  绑定状态: \(bondStatus == 1 ? "已绑定" : "未绑定")")
////        print("  产品ID: 0x\(String(format: "%04X", productId))")
////        print("  设备ID(IMEI): \(deviceId)")
//        
//        return BLEAdvertisementData(
//            macAddress: macAddress,
//            advVersion: advVersion,
//            bondStatus: bondStatus,
//            productId: productId,
//            deviceId: deviceId
//        )
//    }
//    
//    /// 格式化MAC地址
//    private func formatMACAddress(_ data: Data) -> String {
//        let bytes = [UInt8](data)
//        // MAC地址是小端，需要反转显示
//        let reversedBytes = bytes.reversed()
//        return reversedBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
//    }
//    
//    /// 解析设备ID (IMEI)
//    private func parseDeviceId(_ data: Data) -> String {
//        let hexString = data.hexString
//        var result = ""
//        
//        if let value = UInt64(hexString, radix: 16) {
//            result = String(value)
//        }
//        
//        return result
//    }
//    
//    /// 从广播数据中提取IMEI（兼容旧方法）
//    func extractIMEIFromAdvertisementData(_ advertisementData: [String: Any]) -> String? {
//        if let bleData = parseBLEAdvertisementData(advertisementData) {
//            return bleData.deviceId
//        }
//        return nil
//    }
//}
//
//
//// 版本号格式化辅助方法
//public func formatVersion(_ version: UInt32) -> String {
//    let major = (version >> 24) & 0xFF
//    let minor = (version >> 16) & 0xFF
//    let patch = (version >> 8) & 0xFF
//    let build = version & 0xFF
//    return "v\(major).\(minor).\(patch).\(build)"
//}
