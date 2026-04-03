//
//  File.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/18.
//

import Foundation
import CoreBluetooth
import CoreLocation

// MARK: - 数据解析具体实现
extension BluetoothManager {

    func handleDeviceInfoResponse(_ data: Data) {
        guard data.count >= 33 else {
            print("设备信息数据长度错误: \(data.count)")
            return
        }
        
        var offset = 0
        
        // 安全读取协议版本 (2字节)
        let protocolVersion = parseUInt16(from: data, at: &offset)
        
        // 读取BLE MAC地址 (6字节)
        let bleMac = data.subdata(in: offset..<offset + 6)
        offset += 6
        
        // 读取绑定状态 (1字节)
        let bond = data[offset]
        offset += 1
        
        // 安全读取蓝牙软件版本 (4字节)
        let bleSoftwareVersion = parseUInt32(from: data, at: &offset)
        
        // 安全读取蓝牙硬件版本 (4字节)
        let bleHardwareVersion = parseUInt32(from: data, at: &offset)
        
        // 安全读取MCU软件版本 (4字节)
        let mcuSoftwareVersion = parseUInt32(from: data, at: &offset)
        
        // 安全读取MCU硬件版本 (4字节)
        let mcuHardwareVersion = parseUInt32(from: data, at: &offset)
        
        // 安全读取设备ID (8字节)
        let deviceId = parseUInt64(from: data, at: &offset)
        
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
        
//        print("✅ 收到设备信息:")
//        print("  协议版本: \(formatVersion(protocolVersion))")
//        print("  BLE MAC: \(bleMac.hexString)")
//        print("  绑定状态: \(bond == 1 ? "已绑定" : "未绑定")")
//        print("  蓝牙软件版本: \(formatVersion(bleSoftwareVersion))")
//        print("  蓝牙硬件版本: \(formatVersion(bleHardwareVersion))")
//        print("  MCU软件版本: \(formatVersion(mcuSoftwareVersion))")
//        print("  MCU硬件版本: \(formatVersion(mcuHardwareVersion))")
//        print("  设备ID: \(deviceId)")
        
        NotificationCenter.default.post(
            name: .didReceiveDeviceInfo,
            object: nil,
            userInfo: ["deviceInfo": deviceInfo]
        )
    }
    
    func handleStatusInfoResponse(_ data: Data) {
        // 重新计算数据长度：run_time(4) + temp(4) + humi(4) + bat(1) + mds(1) + wm(1) + srpf(1) + lat(4) + lathem(1) + lon(4) + lonhem(1) + alt(4) + st(1) + pos_rpt(4) + low_power_t(4) + position_t(4) = 47字节
        
        guard data.count >= 43 else {
            print("状态信息数据长度错误: \(data.count)，期望至少43字节")
            return
        }
        
        var offset = 0
        
        // 安全读取运行时长 (4字节)
        let runTime = parseUInt32(from: data, at: &offset)
        
        // 安全读取温度 (4字节，*100)
        let temperature = parseInt32(from: data, at: &offset)
        
        // 安全读取湿度 (4字节，*100)
        let humidity = parseUInt32(from: data, at: &offset)
        
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
        let latitude = parseInt32(from: data, at: &offset)
        
        // 读取纬度半球 (1字节)
        let latitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取经度 (4字节，*10000)
        let longitude = parseInt32(from: data, at: &offset)
        
        // 读取经度半球 (1字节)
        let longitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取海拔 (4字节，*10) - 修正为4字节
        let altitude = parseInt32(from: data, at: &offset)
        
        // 读取运动状态 (1字节)
        let motionStatus = data[offset]
        offset += 1
        
        // 安全读取定位信息上报间隔 (4字节) - 修正为4字节
        let positionReport = parseUInt32(from: data, at: &offset)
        
        // 安全读取低功耗唤醒时间 (4字节)
        let lowPowerTime = parseUInt32(from: data, at: &offset)
        
        // 安全读取定位信息存储周期 (4字节)
        let positionStoreTime = parseUInt32(from: data, at: &offset)
        
        // 读取SOS状态 (1字节)
        let sosStatus = data[offset]
        offset += 1
        
        // 读取铱星质量状态 (1字节)
        let iridium = data[offset]
        offset += 1
        
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
            positionStoreTime: positionStoreTime,
            sosStatus: sosStatus,
            iridium: iridium
        )
        
//        print("✅ 收到状态信息:\(data)")
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
//        print("  sos状态: \(sosStatus != 1 ? "开启" : "关闭")")
//        print("  铱星信号质量: \(String(format: "%02X", iridium))")
        
        // 解析模组状态详细位
        let bleStatus = (moduleStatus & 0x01) != 0 ? "异常" : "正常"
        let satelliteStatus = (moduleStatus & 0x02) != 0 ? "异常" : "正常"
        let gnssStatus = (moduleStatus & 0x04) != 0 ? "异常" : "正常"
        print("  模组状态详情 - BLE:\(bleStatus) 卫星:\(satelliteStatus) GNSS:\(gnssStatus)")
        
        checkSOSStatusChange(sosStatus: sosStatus)
        
        
        NotificationCenter.default.post(
            name: .didReceiveStatusInfo,
            object: nil,
            userInfo: ["statusInfo": statusInfo]
        )
    }
    
    /// 检查SOS状态变化
    private func checkSOSStatusChange(sosStatus: UInt8) {
        // 获取APP端的SOS状态
        let isSOSStateOpen = SOSManager.shared.checkUserSOSState()
        
        // 设备端SOS状态: sosStatus != 1 表示开启, sosStatus == 1 表示关闭
        let isDeviceSOSOpen = sosStatus != 1
        
        // 如果状态不一致，且没有正在显示的弹窗，则弹窗询问用户
        if isSOSStateOpen != isDeviceSOSOpen && !isShowingSOSAlert {
            print("SOS状态不一致 - APP端: \(isSOSStateOpen ? "开启" : "关闭"), 设备端: \(isDeviceSOSOpen ? "开启" : "关闭")")
            
            isShowingSOSAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                let alertView = SOSAlertView()
                alertView.showInWindow()
                
                // 假设弹窗会在关闭时调用回调，这里简单延迟5秒后重置标志
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.isShowingSOSAlert = false
                }
            }
        }
    }
    
    public func handleAlarmReport(_ data: Data) {
        guard data.count >= 29 else {
            print("报警信息数据长度错误: \(data.count)")
            return
        }
        
        var offset = 0
        
        // 安全读取设备ID (8字节)
        let deviceId = parseUInt64(from: data, at: &offset)
        
        // 安全读取时间戳 (4字节)
        let timestamp = parseUInt32(from: data, at: &offset)
        
        // 安全读取纬度 (4字节，*10000)
        let latitude = parseInt32(from: data, at: &offset)
        
        // 读取纬度半球 (1字节)
        let latitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取经度 (4字节，*10000)
        let longitude = parseInt32(from: data, at: &offset)
        
        // 读取经度半球 (1字节)
        let longitudeHemisphere = data[offset]
        offset += 1
        
        // 安全读取海拔 (4字节，*10) - 修正为4字节
        let altitude = parseInt32(from: data, at: &offset)
        
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
        
//        print("🚨 收到报警信息:")
//        print("  设备ID: \(deviceId)")
//        print("  时间戳: \(timestamp) (\(Date(timeIntervalSince1970: TimeInterval(timestamp))))")
//        print("  纬度: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S")")
//        print("  经度: \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
//        print("  海拔: \(Float(altitude) / 10.0) 米")
//        print("  运动状态: \(getMotionStatusDescription(motionStatus))")
//        print("  告警类型: \(getAlarmTypeDescription(alarmType))")
//        print("  电池电量: \(battery)%")
        
        NotificationCenter.default.post(
            name: .didReceiveAlarmReport,
            object: nil,
            userInfo: ["alarmInfo": alarmInfo]
        )
    }
    
    func handlePositionReport(_ data: Data) {
        guard data.count >= 32 else {
            print("定位信息数据长度错误: \(data.count)")
            return
        }
        
        var offset = 0
        
        // 安全读取设备ID (8字节)
        let deviceId = parseUInt64(from: data, at: &offset)
        
        // 读取定位数据条数 (1字节)
        let numPositions = data[offset]
        offset += 1
        
        // 安全读取定位上报间隔 (2字节)
        let positionReport = parseUInt16(from: data, at: &offset)
        
        // 安全读取首条数据时间戳 (4字节)
        let firstTimestamp = parseUInt32(from: data, at: &offset)
        
        var positions: [PositionInfo] = []
        var currentOffset = offset
        
        // 解析多条定位信息
        for i in 0..<Int(numPositions) {
            guard currentOffset + 17 <= data.count else {
                print("定位数据 \(i) 长度不足")
                break
            }
            
            // 安全读取时间戳 (4字节)
            // 注意：这里需要使用本地的currentOffset，所以不能直接使用parseUInt32方法
            var tsValue: UInt32 = 0
            tsValue |= UInt32(data[currentOffset]) << 24
            tsValue |= UInt32(data[currentOffset + 1]) << 16
            tsValue |= UInt32(data[currentOffset + 2]) << 8
            tsValue |= UInt32(data[currentOffset + 3])
            let timestamp = tsValue
            currentOffset += 4
            
            // 安全读取纬度 (4字节，*10000)
            var latValue: Int32 = 0
            latValue |= Int32(data[currentOffset]) << 24
            latValue |= Int32(data[currentOffset + 1]) << 16
            latValue |= Int32(data[currentOffset + 2]) << 8
            latValue |= Int32(data[currentOffset + 3])
            let latitude = latValue
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
            
//            print("  定位点 \(i+1):")
//            print("    时间: \(Date(timeIntervalSince1970: TimeInterval(timestamp)))")
//            print("    坐标: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S"), \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
//            print("    海拔: \(Float(altitude) / 10.0) 米")
        }
        
//        print("📍 收到定位信息上报:")
//        print("  设备ID: \(deviceId)")
//        print("  定位数据条数: \(numPositions)")
//        print("  上报间隔: \(positionReport) 秒")
//        print("  首条时间: \(Date(timeIntervalSince1970: TimeInterval(firstTimestamp)))")
//        print("  解析到 \(positions.count) 条定位数据")
        
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
    
    func handlePlatformNotification(_ data: Data) {
        if let notificationText = String(data: data, encoding: .utf8) {
            NotificationCenter.default.post(
                name: .didReceivePlatformNotification,
                object: nil,
                userInfo: ["text": notificationText]
            )
        }
    }
    
    func handleSatelliteInfoNotification(_ data: Data) {
        let satelliteInfo = data.hexString
        print("Mini设备卫星状态--字符串--\(satelliteInfo)")
        NotificationCenter.default.post(
            name: .didReceiveSatelliteInfo,
            object: nil,
            userInfo: ["satelliteInfo": satelliteInfo]
        )
    }
    
    func handleDeviceBufferInfoNotification(_ data: Data) {
        NotificationCenter.default.post(
            name: .didDeviceBufferInfo,
            object: nil,
            userInfo: ["deviceBufferInfo": data]
        )
    }
    
    func handleK01DeviceBufferInfoNotification(_ data: Data) {
        NotificationCenter.default.post(
            name: .didDeviceBufferInfo,
            object: nil,
            userInfo: ["deviceBufferInfo": data]
        )
    }
    
    func handlePhoneLocation() {
        print("📱 收到获取手机定位的请求")
        
        // 1. 获取当前时间戳（UNIX时间戳）
        let timestamp = UInt32(Date().timeIntervalSince1970)
        
        // 2. 检查定位服务是否可用
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if CLLocationManager.locationServicesEnabled() {
                // 2.1 检查授权状态
                let authorizationStatus = CLLocationManager().authorizationStatus
                switch authorizationStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    // 有定位权限，获取最新位置
                    if let location = CLLocationManager().location {
                        let coordinate = location.coordinate
                        let altitude = location.altitude
                        
                        // 纬度计算（乘以10000）
                        let latitude = Int32(coordinate.latitude * 10000 * 100)
                        // 纬度半球：北半球为1，南半球为2
                        let latitudeHemisphere: UInt8 = coordinate.latitude >= 0 ? 1 : 2
                        
                        // 经度计算（乘以10000）
                        let longitude = Int32(coordinate.longitude * 10000 * 100)
                        // 经度半球：东经为1，西经为2
                        let longitudeHemisphere: UInt8 = coordinate.longitude >= 0 ? 1 : 2
                        
                        // 海拔计算（乘以10）
                        let altitudeValue = Int32(altitude * 10)
                        
                        // 构建位置信息
                        let positionInfo = PositionInfo(
                            timestamp: timestamp,
                            latitude: latitude,
                            latitudeHemisphere: latitudeHemisphere,
                            longitude: longitude,
                            longitudeHemisphere: longitudeHemisphere,
                            altitude: altitudeValue
                        )
                        
//                        print("✅ 获取到手机定位信息:")
//                        print("  时间戳: \(timestamp) (\(Date(timeIntervalSince1970: TimeInterval(timestamp))))")
//                        print("  纬度: \(formatCoordinate(latitude, isLatitude: true))°\(latitudeHemisphere == 1 ? "N" : "S")")
//                        print("  经度: \(formatCoordinate(longitude, isLatitude: false))°\(longitudeHemisphere == 1 ? "E" : "W")")
//                        print("  海拔: \(Float(altitudeValue) / 10.0) 米")
                        
                        sendPhoneLocation(positionInfo)
                    } else {
                        // 没有获取到位置数据
                        print("没有获取到位置数据")
                    }
                    
                case .denied, .restricted:
                    // 用户拒绝或限制定位权限
                    print("定位权限被拒绝")
                    
                    
                case .notDetermined:
                    // 尚未请求权限
                    print("定位权限未确定")
                    
                @unknown default:
                    print("未知的定位状态")
                }
            } else {
                // 定位服务未开启
                print("定位服务未开启")
            }
        }
    }
    
    func handleCustomMsg(_ data: Data) {
        NotificationCenter.default.post(
            name: .didReceiveDeviceCustomMsg,
            object: nil,
            userInfo: ["data": data]
        )
    }
    
    func handleSatelliteSendResultNotification(_ data: Data) {
        
        guard let connectedScannedPeripheral = connectedScannedPeripheral, let imeiNum = connectedScannedPeripheral.imeiNum else {return}
        
        guard data.count >= 2 else {
            print("卫星收发信息数据长度错误: \(data.count)")
            return
        }
        
        let commandByte = data[0]
        let resultByte = data[1]
        
        // 使用枚举初始化
        let command = SatelliteCommand(rawValue: commandByte) ?? .unknown
        let result = SatelliteSendResult(rawValue: resultByte) ?? .unknown
        
        let miniDeviceSendResultData = MiniDeviceSendResultData(
                imeiNum: imeiNum,
                command: command,
                result: result,
                time: Date()
            )
        MiniDeviceSendResultDBManager.shared.insertFromMiniDeviceSendResultList([miniDeviceSendResultData])
        
        NotificationCenter.default.post(
            name: .didReceiveSatelliteSendResult,
            object: nil,
            userInfo: nil
        )
    }
    
    // MARK: - 辅助方法
    // 辅助方法：从Data中解析UInt64（大端序）
    private func parseUInt64(from data: Data, at offset: inout Int) -> UInt64 {
        var value: UInt64 = 0
        value |= UInt64(data[offset]) << 56
        value |= UInt64(data[offset + 1]) << 48
        value |= UInt64(data[offset + 2]) << 40
        value |= UInt64(data[offset + 3]) << 32
        value |= UInt64(data[offset + 4]) << 24
        value |= UInt64(data[offset + 5]) << 16
        value |= UInt64(data[offset + 6]) << 8
        value |= UInt64(data[offset + 7])
        offset += 8
        return value
    }
    
    // 辅助方法：从Data中解析UInt32（大端序）
    private func parseUInt32(from data: Data, at offset: inout Int) -> UInt32 {
        var value: UInt32 = 0
        value |= UInt32(data[offset]) << 24
        value |= UInt32(data[offset + 1]) << 16
        value |= UInt32(data[offset + 2]) << 8
        value |= UInt32(data[offset + 3])
        offset += 4
        return value
    }
    
    // 辅助方法：从Data中解析Int32（大端序）
    private func parseInt32(from data: Data, at offset: inout Int) -> Int32 {
        var value: Int32 = 0
        value |= Int32(data[offset]) << 24
        value |= Int32(data[offset + 1]) << 16
        value |= Int32(data[offset + 2]) << 8
        value |= Int32(data[offset + 3])
        offset += 4
        return value
    }
    
    // 辅助方法：从Data中解析UInt16（大端序）
    private func parseUInt16(from data: Data, at offset: inout Int) -> UInt16 {
        let value = UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
        offset += 2
        return value
    }
    
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
        let deviceId = parseDeviceId(deviceIdData)
        
        print("✅ 解析到BLE广播数据:")
        print("  MAC地址: \(macAddress)")
        print("  广播版本: \(advVersion)")
        print("  绑定状态: \(bondStatus == 1 ? "已绑定" : "未绑定")")
        print("  产品ID: 0x\(String(format: "%04X", productId))")
        print("  设备ID(IMEI): \(deviceId)")
        
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

public func formatHardware(_ version: UInt32) -> String {
    let major = (version >> 24) & 0xFF
    let minor = (version >> 16) & 0xFF
    let patch = (version >> 8) & 0xFF
    let build = version & 0xFF
    return "\(major).\(minor).\(patch).\(build)"
}

public func formatVersion(_ version: UInt16) -> String {
    let major = (version >> 8) & 0xFF
    let build = version & 0xFF
    return "v\(major).\(build)"
}

public func uint64ToAsciiString(_ value: UInt64) -> String {
    // 将UInt64转换为字节数组（大端序）
    var bigEndianValue = value.bigEndian
    let data = withUnsafeBytes(of: &bigEndianValue) { Data($0) }
    
    // 过滤掉空字节（\0）并转换为ASCII字符串
    let asciiString = data.compactMap { byte -> String? in
        // 只转换可打印ASCII字符（32-126）或特定需要的字符
        guard byte != 0 else { return nil }  // 忽略空字节
        return String(UnicodeScalar(byte))
    }.joined()
    
    return asciiString
}

