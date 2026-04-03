//
//  BluetoothManager+SendAndReceive.swift
//  SWKit
//
//  Created by yifan kang on 2026/3/11.
//

import Foundation
import CoreBluetooth

// MARK: -- 蓝牙的收发方法
extension BluetoothManager {
    
    // MARK: - 蓝牙发送方法
    func sendCommand(_ command: Command, messageContent: Data = Data()) {
        let frameData: Data
        
        switch deviceType {
        case .TXTS:
            let frame = createTXTSFrame(commandCode: command.chengduCode, messageContent: messageContent)
            frameData = frame.frameData
            sendRawData(frameData)
        case .K01:
            let frame = createK01Frame(commandCode: command.k01Code, messageContent: messageContent)
            frameData = frame.frameData
            sendDataWithFAF5Packet(frameData, packetStatus: .noPacket)
        }
        
//        print("发送命令帧:")
//        print("  命令编号: 0x\(String(format: "%04X", commandCode.rawValue))")
//        print("  流水码: \(frame.serialNumber)")
//        print("  数据长度: \(frame.dataLength)")
//        print("  信息内容: \(messageContent.hexString)")
//        print("  校验码: 0x\(String(format: "%04X", frame.checksum))")
//        print("  完整帧: \(frameData.hexString)")
    }
    
    // MARK: - 帧创建方法
    public func createTXTSFrame(commandCode: UInt16?, messageContent: Data) -> CommunicationFrame {
        let header: UInt16 = 0xAA55
        let code = commandCode ?? 0
        let serialNumber = generateTXTSerialNumber()
        let dataLength = UInt16(messageContent.count)
        
        // 计算校验码
        var checksumData = Data()
        checksumData.append(header.bigEndianData)
        checksumData.append(serialNumber.bigEndianData)  // 4字节流水码
        checksumData.append(dataLength.bigEndianData)
        checksumData.append(code.bigEndianData)
        checksumData.append(messageContent)
        let checksum = crcCalculator.calculate(checksumData)
        let terminator: UInt16 = 0x0D0A
        
        return CommunicationFrame(
            header: header,
            serialNumber: serialNumber,      // UInt32 (4字节)
            dataLength: dataLength,
            commandCode: code,
            messageContent: messageContent,
            checksum: checksum,
            terminator: terminator
        )
    }
    private func createK01Frame(commandCode: UInt8?, messageContent: Data) -> K01CommunicationFrame {
        let header: UInt16 = 0xAA55
        let code = commandCode ?? 0
        let serialNumber = generateK01SerialNumber()  // UInt8 (1字节)
        let dataLength = UInt16(messageContent.count)
        
        // 计算校验码
        var checksumData = Data()
        checksumData.append(header.bigEndianData)
        checksumData.append(serialNumber)  // 1字节流水码
        checksumData.append(dataLength.bigEndianData)
        checksumData.append(code)
        checksumData.append(messageContent)
        let checksum = crcCalculator.calculate(checksumData)
        let terminator: UInt16 = 0x0D0A
        
        return K01CommunicationFrame(
            header: header,
            serialNumber: serialNumber,     // UInt8 (1字节)
            dataLength: dataLength,
            commandCode: code,
            messageContent: messageContent,
            checksum: checksum,
            terminator: terminator
        )
    }
    
    // MARK: - 流水码生成
    private func generateTXTSerialNumber() -> UInt32 {
        currentTXTSerialNumber += 1
        if currentTXTSerialNumber > UInt32.max {
            currentTXTSerialNumber = 0
        }
        return currentTXTSerialNumber
    }
    
    private func generateK01SerialNumber() -> UInt8 {
        currentK01SerialNumber = currentK01SerialNumber &+ 1  // 自动溢出
        return currentK01SerialNumber
    }
    
    // MARK: - 数据发送
    func sendRawData(_ data: Data) {
        guard let peripheral = connectedPeripheral else {
            print("设备未连接")
            return
        }
//        print("准备发送数据，长度: \(data.count) 字节")
//        print("数据内容: \(data.hexString)")
        
        // 优先使用有响应写入
        if let characteristic = writeCharacteristic {
//            print("使用有响应写入特征: \(characteristic.uuid)")
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            return
        }
        
        // 其次使用无响应写入
        if let characteristic = writeWithoutResponseCharacteristic {
//            print("使用无响应写入特征: \(characteristic.uuid)")
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            return
        }
        
        // 最后尝试查找特征
        if let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }),
           let characteristics = service.characteristics {
            
            for characteristic in characteristics {
                if characteristic.properties.contains(.write) {
//                    print("动态找到有响应写入特征: \(characteristic.uuid)")
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                    return
                }
                if characteristic.properties.contains(.writeWithoutResponse) {
//                    print("动态找到无响应写入特征: \(characteristic.uuid)")
                    peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
                    return
                }
            }
        }
        
        print("错误: 没有找到支持写入的特征")
    }
}

extension BluetoothManager {
    
    // MARK: - 收到蓝牙数据
    func handleReceivedData(_ data: Data, from characteristic: CBCharacteristic) {
        if let packet = parsePacketData(data) {
//            print("解析到分包数据:")
//            print("  帧头: 0x\(String(format: "%04X", packet.header))")
//            print("  状态: \(packet.status)")
//            print("  编号: \(packet.packetId)")
//            print("  长度: \(packet.dataLength)")
//            print("  数据: \(packet.data.hexString)")
            
            
            if let completeData = packetAssembler.processPacket(packet) {
//                print("✅ 组包完成，完整数据长度: \(completeData.count) 字节")
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
        
        switch deviceType {
        case .TXTS:
            print("成都")
            if let frame = parseResponseFrame(data) {
//                print("✅ 解析到通信帧:")
//                print("  流水码: \(frame.serialNumber)")
//                print("  命令编号: 0x\(String(format: "%04X", frame.commandCode))")
//                print("  信息内容: \(frame.messageContent.hexString)")
                handleTXTSCommandFrame(frame)
            }else {
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
        case .K01:
            print("中北")
            if let frame = parseK01ResponseFrameData(data) {
//                print("✅ 解析到通信帧:")
//                print("  流水码: \(frame.serialNumber)")
//                print("  命令编号: 0x\(String(format: "%04X", frame.commandCode))")
//                print("  信息内容: \(frame.messageContent.hexString)")
                handleK01CommandFrame(frame)
            }else {
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
        
        
    }
    
    // MARK: - TXTS设备命令处理
        private func handleTXTSCommandFrame(_ frame: ResponseFrame) {
            print("处理成都设备命令帧: \(String(format: "0x%04X", frame.commandCode))")
            
            switch frame.commandCode {
            case Command.deviceInfo.chengduCode:
                handleDeviceInfoResponse(frame.messageContent)
            case Command.statusInfo.chengduCode:
                handleStatusInfoResponse(frame.messageContent)
            case Command.alarmReport.chengduCode:
                handleAlarmReport(frame.messageContent)
            case Command.positionReport.chengduCode:
                handlePositionReport(frame.messageContent)
            case Command.platformNotification.chengduCode:
                handlePlatformNotification(frame.messageContent)
            case Command.getPhoneLocation.chengduCode:
                handlePhoneLocation()
            case Command.platformCustomData.chengduCode:
                handleCustomMsg(frame.messageContent)
            case Command.getSatelliteRecords.chengduCode:
                handleDeviceBufferInfoNotification(frame.messageContent)
            case Command.getSatelliteSignal.chengduCode:
                handleSatelliteInfoNotification(frame.messageContent)
            case Command.getSatelliteSendResult.chengduCode:
                handleSatelliteSendResultNotification(frame.messageContent)
            default:
                handleResponseFrame(frame)
                print("未处理的成都设备命令: \(String(format: "0x%04X", frame.commandCode))")
            }
        }
        
    // MARK: - K01设备命令处理
        private func handleK01CommandFrame(_ frame: K01ResponseFrame) {
            print("处理中北设备命令帧: \(String(format: "0x%02X", frame.commandCode))")
            
            switch frame.commandCode {
            case Command.deviceInfo.k01Code:
                handleDeviceInfoResponse(frame.messageContent)
            case Command.statusInfo.k01Code:
                handleStatusInfoResponse(frame.messageContent)
            case Command.alarmReport.k01Code:
                handleAlarmReport(frame.messageContent)
            case Command.positionReport.k01Code:
                handlePositionReport(frame.messageContent)
            case Command.platformNotification.k01Code:
                handlePlatformNotification(frame.messageContent)
            case Command.getPhoneLocation.k01Code:
                handlePhoneLocation()
            case Command.platformCustomData.k01Code:
                handleCustomMsg(frame.messageContent)
            case Command.getSatelliteRecords.k01Code:
                handleK01DeviceBufferInfoNotification(frame.messageContent)
            case Command.getSatelliteSignal.k01Code:
                handleSatelliteInfoNotification(frame.messageContent)
            default:
                handleK01ResponseFrame(frame)
                print("未处理的中北设备命令: \(String(format: "0x%02X", frame.commandCode))")
            }
        }
    
    private func handleResponseFrame(_ frame: ResponseFrame) {
        guard let responseSerial = frame.responseSerial,
              let responseStatus = frame.responseStatus else {
            print("应答帧解析失败")
            return
        }
        
//        print("✅ 收到应答帧:")
//        print("  对应流水码: \(responseSerial)")
//        print("  应答状态: \(responseStatus)")
        
        // 处理固件数据应答
        if frame.commandCode == Command.appTriggerAlarm.chengduCode {
            NotificationCenter.default.post(
                name: .didSaveOfSOSResponseMsg,
                object: nil,
                userInfo: [
                    "result": responseStatus
                ]
            )
        }
        
        if frame.commandCode == Command.setBindStatus.chengduCode {
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
    
    private func handleK01ResponseFrame(_ frame: K01ResponseFrame) {
        guard let responseSerial = frame.responseSerial,
              let responseStatus = frame.responseStatus else {
            print("应答帧解析失败")
            return
        }
        
//        print("✅ 收到应答帧:")
//        print("  对应流水码: \(responseSerial)")
//        print("  应答状态: \(responseStatus)")
        
        // 处理固件数据应答
        if frame.commandCode == Command.appTriggerAlarm.k01Code {
            NotificationCenter.default.post(
                name: .didSaveOfSOSResponseMsg,
                object: nil,
                userInfo: [
                    "result": responseStatus
                ]
            )
        }
        
        if frame.commandCode == Command.setBindStatus.k01Code {
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
}

// MARK: - 数据解析扩展
public extension BluetoothManager {
    
    // 解析应答帧
    func parseResponseFrame(_ data: Data) -> ResponseFrame? {
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
        
        print("✅ 应答帧解析成功:")
//        print("  帧头: 0x\(String(format: "%04X", header))")
//        print("  流水码: \(serialNumber)")
//        print("  数据长度字段: \(dataLength)")
//        print("  命令编号: 0x\(String(format: "%04X", commandCodeValue))")
//        print("  信息内容长度: \(messageContent.count)")
        print("  信息内容: \(messageContent.hexString)")
//        print("  校验码: 0x\(String(format: "%04X", checksum))")
//        print("  结束符: 0x\(String(format: "%04X", terminator))")
        
        return ResponseFrame(
            header: header,
            serialNumber: serialNumber,
            dataLength: dataLength,
            commandCode: commandCodeValue,
            messageContent: messageContent,
            checksum: checksum,
            terminator: terminator
        )
    }
    
    func parseK01ResponseFrameData(_ data: Data) -> K01ResponseFrame? {
        guard data.count >= 10 else {
            print("应答帧数据长度不足: \(data.count)")
            return nil
        }
        
        var offset = 0
        
        // 安全读取帧头 (2字节)
        let header = (UInt16(data[offset]) << 8) | UInt16(data[offset + 1])
        offset += 2
        
        guard header == 0xAA55 else {
            print("应答帧帧头错误: 0x\(String(format: "%04X", header))")
            return nil
        }
        
        // 安全读取流水码 (1字节)
        let serialNumber = data[offset]
        offset += 1
        
        // 安全读取数据长度 (1字节)
        let dataLength = data[offset]
        offset += 1
        
        // 修正：数据长度字段只包含信息内容的长度（不包含命令编号）
        // 所以总帧长度应该是：帧头2 + 流水码1 + 数据长度1 + 命令编号1 + 信息内容(dataLength) + 校验码2 + 结束符2
        let messageLength = Int(dataLength) // 信息内容长度
        let expectedTotalLength = 2 + 1 + 1 + 1 + messageLength + 2 + 2
        
        guard data.count == expectedTotalLength else {
            print("应答帧数据长度不匹配: 期望\(expectedTotalLength)，实际\(data.count)，数据长度字段: \(dataLength)")
            print("应答帧详细计算: 帧头2 + 流水码1 + 数据长度1 + 命令编号1 + 信息内容\(messageLength) + 校验码2 + 结束符2")
            return nil
        }
        
        // 安全读取命令编号 (1字节)
        let commandCode = data[offset]
        offset += 1
        
        // 解析信息内容
        guard offset + messageLength <= data.count else {
            print("应答帧信息内容长度错误: offset=\(offset), messageLength=\(messageLength), data.count=\(data.count)")
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
            print("应答帧结束符错误: 0x\(String(format: "%04X", terminator))")
            return nil
        }
        
//        // 验证校验码
//        var checksumData = Data()
//        // 添加帧头 (2字节)
//        checksumData.append(data[0..<2])
//        // 跳过流水码（不添加）
//        // 添加数据长度 (1字节) - 位置在索引3
//        checksumData.append(data[3..<4])
//        // 添加命令编号 (1字节) - 位置在索引4
//        checksumData.append(data[4..<5])
//        // 添加信息内容 (messageLength字节) - 从索引5开始
//        checksumData.append(data[5..<5+messageLength])
//
//        let calculatedChecksum = crcCalculator.modbusCRC16(checksumData)
//
//        guard checksum == calculatedChecksum else {
//            sendLogMessage("应答帧校验码错误: 计算值0x\(String(format: "%04X", calculatedChecksum))，接收值0x\(String(format: "%04X", checksum))")
//            sendLogMessage("校验数据: \(checksumData.hexString)")
//            return nil
//        }
        
        print("✅ K01应答帧解析成功:")
//        print("  帧头: 0x\(String(format: "%04X", header))")
//        print("  流水码: \(serialNumber)")
//        print("  数据长度字段: \(dataLength)")
//        print("  命令编号: 0x\(String(format: "%02X", commandCode))")
        print("  K01信息内容长度: \(messageContent.count)")
//        print("  信息内容: \(messageContent.hexString)")
//        print("  校验码: 0x\(String(format: "%04X", checksum))")
//        print("  结束符: 0x\(String(format: "%04X", terminator))")
        
        return K01ResponseFrame(
            header: header,
            serialNumber: serialNumber,
            dataLength: dataLength,
            commandCode: commandCode,
            messageContent: messageContent,
            checksum: checksum,
            terminator: terminator
        )
    }
}


