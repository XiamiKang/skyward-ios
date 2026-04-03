//
//  MessageManager.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/1/8.
//

import Foundation
import SWKit


class MessageManager {
    
    static let shared = MessageManager()
    
    func startMonitorMessage() {
        // 监听窄带设备的自定义消息
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveDeviceCustomMessage(_:)),
            name: .didReceiveDeviceCustomMsg,
            object: nil
        )
    }
    
    func stopMonitorMessage() {
        //MQTTManager 统一处理退出登录 remove Delegate 和 remove Subscribe
        NotificationCenter.default.removeObserver(self, name: .didReceiveDeviceCustomMsg, object: nil)
    }
    
    
    // MARK: - 窄带设备自定义消息(用于无网络离线接受消息)

    @objc private func receiveDeviceCustomMessage(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? Data else {
            return
        }
        
        if let message = parseDeviceCustomMessage(data) {
            guard let _ = message.id else {
                return
            }
            DBManager.shared.insertToDb(objects: [message], intoTable: DBTableName.urgentMessage.rawValue)
            
            if let urgentMessageVC = UIWindow.findViewController(ofType: UrgentMessageViewController.self) {
                urgentMessageVC.addMessageToTable(message)
            }
        }
    }
    
    func parseDeviceCustomMessage(_ data: Data) -> UrgentMessage? {
        // 1+1+4+2+n
        guard data.count >= 8 else {
            debugPrint("设备信息数据长度错误: \(data.count)")
            return nil
        }
        
        var offset = 0
        
        // 命令指令(1字节)
        let protocolVersion = data[offset]
        
        guard protocolVersion == 7 else {
            return nil
        }
        offset += 1
        
        // 通知类型(1字节) 1：SOS报警 2：报平安 3：天气 4:紧急通讯 5:紧急通讯消息成功通知
        let noticeType = data[offset]
        offset += 1
        
        // 时间戳 (4字节)
        let timestamp = (Int32(data[offset]) << 24) |
        (Int32(data[offset + 1]) << 16) |
        (Int32(data[offset + 2]) << 8) |
        Int32(data[offset + 3])
        offset += 4
        
        // msgLength (2字节)
        offset += 2
        
        let msg = String(data: data[offset...], encoding: .utf8) ?? ""
        offset += msg.count
        
        debugPrint("✅ 解析出来的数据:")
        debugPrint("  命令指令: 0x\(protocolVersion)")
        debugPrint("  通知类型: \(noticeType)")
        debugPrint("  时间戳: \(timestamp)")
        debugPrint("  消息内容: \(msg)")
        
        let sendTime = Int64(timestamp) * 1000
        let msgId = String(sendTime)
        var nickname: String?
        var userType: Int?
        if [1, 2, 3].contains(noticeType) {
            nickname = "天行探索平台"
            userType = 9
        } else if noticeType == 4 {
            nickname = (UserManager.shared.emergencyContact?.first?.name ?? UserManager.shared.emergencyContact?.first?.phone) ?? "紧急联系人"
            userType = 2
        } else if noticeType == 5 {
            nickname = "紧急通讯消息成功通知"
        }
        
        let sender = UrgentUser(id: msgId,
                                nickname: nickname,
                                imUserType: userType)
        
        return UrgentMessage(id: msgId,
                             sendId: "1",
                             receiverId: UserManager.shared.userId,
                             content: msg,
                             sendTime: DateFormatter.fullPretty.string(from: Date(timeIntervalSince1970: Double(timestamp))),
                             type: Int(noticeType),
                             sendUserBaseInfoVO: sender,
                             receiveUserBaseInfoVO: nil)
    }
    
}
