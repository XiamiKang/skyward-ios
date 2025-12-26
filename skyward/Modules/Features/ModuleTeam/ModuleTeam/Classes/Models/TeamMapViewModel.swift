//
//  TeamMapViewModel.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/3.
//

import Foundation
import TXKit
import SWKit
import SWNetwork
import CoreLocation

typealias MemberListBlock = ([Member]?) -> Void

typealias MemberLoactionBlock = () -> Void

public class TeamMapViewModel: ObservableObject {
    
    @Published var messageList: [Message] = []
    @Published var team: Team?
    
    public var conversation: Conversation
    
    var getMemberListHandler: MemberListBlock?
    var getMemberLocationHandler: MemberLoactionBlock?
    
    lazy var locationManager: LocationManager = {
        let locationManager = LocationManager()
        return locationManager
    }()
    
    public init(conversation: Conversation) {
        self.conversation = conversation
        
        // DB
        if let convId = conversation.id {
            if let result = DBManager.shared.queryFromDb(fromTable: DBTableName.message.rawValue, cls: Message.self) {
                let filteredMessages = result.filter { $0.conversationId == convId }
                let sortedMessages = filteredMessages.sorted { $0.sendTime ?? 0 < $1.sendTime ?? 0}
                DispatchQueue.main.async {
                    self.messageList = sortedMessages
                }
            }
        }
        
        // MQTT
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: [TeamAPI.messagePage_sub, TeamAPI.teamInfo_sub, TeamAPI.memberLoaction_sub])
        
        var params = [String : Any]()
        params["requestId"] = Int(Date().timeIntervalSince1970)
        params["conversationId"] = conversation.id
        params["pageNum"] = 1
        params["pageSize"] = 1000
        
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.messagePage_pub, qos:.qos1)
        }
        
        // 通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveTeamNewMessage(_:)),
            name: .receiveTeamNewMessage,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func disconnect() {
        MQTTManager.shared.removeDelegate(self)
    }
    
    func sendMessage(_ msg: String) {
        if NetworkMonitor.shared.isConnected {
            var params = [String : Any]()
            params["requestId"] = Int(Date().timeIntervalSince1970)
            params["conversationId"] = conversation.id
            params["content"] = msg
            params["sendId"] = UserManager.shared.userId
            params["receiverId"] = conversation.id
            params["sendTime"] = Int(Date().timeIntervalSince1970 * 1000)
            if let jsonStr = params.dataValue?.jsonString {
                MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.sendMessage_pub, qos:.qos1)
            }
        }else {
            if let _ = BluetoothManager.shared.connectedPeripheral {
                guard let convId = conversation.id else {
                    UIWindow.topWindow?.sw_showWarningToast("为获取到会话id")
                    return
                }
                guard let msgData = MessageGenerator.generateImSend(senderId: UserManager.shared.userId,
                                                                    targetId: convId,
                                                                    timestamp: Date().timeIntervalSince1970,
                                                                    message: msg) else {
                    UIWindow.topWindow?.sw_showWarningToast("消息格式错误")
                    return
                }
                SWAlertView.showAlert(title: nil, message: "当前无网络连接，通过Mini设备发消息？") {
                    BluetoothManager.shared.sendAppCustomData(msgData)
                }
                
            } else {
                UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
            }
        }
    }
    
    func locationDetailDesc(data: MarkerData) -> (String, String, String) {
        let coordinate = CLLocationCoordinate2D(latitude: data.coordinate.latitude, longitude: data.coordinate.longitude)
        let longitudeString = convertToDMSString(coordinate.longitude, isLongitude: true)
        let latitudeString = convertToDMSString(coordinate.latitude, isLongitude: false)
        let coordinateDes = longitudeString + "," + latitudeString
        
        if let userInfo = data.userInfo,
           let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
           let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
            var name = message.sender?.nickname ?? ""
            if message.messageType == .safety {
                name = name + "（报平安）"
            } else if message.messageType == .sos {
                name = name + "（SOS 报警）"
            }
            
            guard let time = message.location?.reportTime  else {
                return (name, coordinateDes, "")
            }
            let date = NSDate(timeIntervalSince1970: time / 1000 )
            let str = DateFormatter.fullPretty.string(from: date as Date)
            return (name, coordinateDes, str)
        }
        return ("", "", "")
    }
    
    // MARK: - Markers
    
    /// 从所有消息中获取每个成员的最后一条指定类型消息
    /// - Returns: 筛选后的消息数组（每个成员仅保留最后一条符合条件的消息）
    func getLatestMessagesForEachMember() -> [Message] {
        // 筛选出符合条件的消息类型
        let filteredMessages = messageList.filter { message in
            guard let messageType = message.messageType else { return false }
            return messageType == .safety || messageType == .sos || messageType == .location
        }
        
        // 按发送者ID分组
        var groupedMessages: [String: [Message]] = [:]
        for message in filteredMessages {
            if let senderId = message.sender?.id {
                if groupedMessages[senderId] == nil {
                    groupedMessages[senderId] = []
                }
                groupedMessages[senderId]?.append(message)
            }
        }
        
        // 从每组中获取最后一条消息（按发送时间排序）
        var latestMessages: [Message] = []
        for (_, messages) in groupedMessages {
            // 按sendTime降序排序，取第一条
            if let latestMessage = messages.sorted(by: { m1, m2 in
                guard let time1 = m1.sendTime, let time2 = m2.sendTime else { return false }
                return time1 > time2
            }).first {
                latestMessages.append(latestMessage)
            }
        }
        
        return latestMessages
    }
    
    func makeMarkerData(message: Message) -> MarkerData? {
        guard message.messageType == .safety || message.messageType == .sos || message.messageType == .location else {
            return nil
        }
        guard let longitude = message.location?.longitude,let latitude = message.location?.latitude else {
            return nil
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let msgDict = try? message.asDictionary()
        
        return MarkerData(
            id: message.sender?.id ?? "",
            coordinate: coordinate,
            title: message.sender?.nickname ?? "",
            userInfo: msgDict)
    }
    
    
    // MARK: - Notification
    
    @objc private func receiveTeamNewMessage(_ notification: Notification) {
        guard let message = notification.object as? Message, message.conversationId == conversation.id else {
            return
        }
        
        self.messageList.append(message)
    }
}


extension TeamMapViewModel: MQTTManagerDelegate {
    
    public func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectState) {

    }
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        DispatchQueue.main.async {[weak self] in
            do {
                guard let jsonData = message.data(using: .utf8) else {
                        return
                    }
            
                    let decoder = JSONDecoder()

                if topic == TeamAPI.messagePage_sub {
                    let rsp = try decoder.decode(MQTTResponse<MessagePage>.self, from: jsonData)
                    if let messages = rsp.data?.records, !messages.isEmpty {
                        self?.messageList = messages.sorted(by: { $0.sendTime ?? 0 < $1.sendTime ?? 0})
                        DBManager.shared.insertToDb(objects: messages, intoTable: DBTableName.message.rawValue)
                    }
                    manager.unsubscribe(from: topic)
                } else if topic == TeamAPI.teamInfo_sub {
                    let rsp = try decoder.decode(MQTTResponse<Team>.self, from: jsonData)
                    if let team = rsp.data {
                        self?.team = team
                        self?.getMemberListHandler?(team.members)
                        self?.getMemberListHandler = nil
                    }
                } else if topic == TeamAPI.memberLoaction_sub {
                    let rsp = try decoder.decode(MQTTResponse<UserLocation>.self, from: jsonData)
                    if let location = rsp.data,let mode = location.mode  {
                        if mode == 0 {
                            self?.sendMemberLocation()
                        } else {
                            // 展示气泡
                        }
                    }
                }
                
            } catch {
                print("[JSON解析] 解析失败: \(error)")
            }
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String) {
        if topic == TeamAPI.memberLoaction_pub {
            ScreenUtil.getKeyWindow()?.sw_showSuccessToast("获取位置已发送，请等待对方位置回执")
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: (any Error)?) {
        
    }
}

// MARK: - 获取好友位置相关
extension TeamMapViewModel {
    
    func getMemberList(_ completed: @escaping MemberListBlock) {
        getMemberListHandler = completed
        
        var params = [String : Any]()
        params["requestId"] = Int(Date().timeIntervalSince1970)
        params["id"] = conversation.teamId
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.teamInfo_pub, qos:.qos1)
        }
    }
    
    
    func getMemberLocation(userId: String, shortId: Int?, _ completed: @escaping MemberLoactionBlock) {
        guard let convId = conversation.id else {
            return
        }
        guard NetworkMonitor.shared.isConnected else {
            if let _ = BluetoothManager.shared.connectedPeripheral, let shortId = shortId {
                SWAlertView.showAlert(title: nil, message: "当前无网络连接，通过Mini设备获取成员定位？") {
                    if let data = MessageGenerator.generateRequestFriendLocation(friendId: shortId, conversationId: convId, timestamp: Date().timeIntervalSince1970) {
                        BluetoothManager.shared.sendAppCustomData(data)
                    }
                }
                
            } else {
                UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
            }
            return
        }
        getMemberLocationHandler = completed
        
        var params = [String : Any]()
        params["requestId"] = Int(Date().timeIntervalSince1970)
        params["userId"] = userId
        params["mode"] = "0"
        params["conversationId"] = convId
        params["reportTime"] = params["requestId"]
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.memberLoaction_pub, qos:.qos1)
        }
    }
    
    func sendMemberLocation() {
        let convId = conversation.id
        locationManager.getCurrentLocation { location, error in
            var params = [String : Any]()
            params["requestId"] = Int(Date().timeIntervalSince1970)
            params["userId"] = UserManager.shared.userId
            params["mode"] = "1"
            params["conversationId"] = convId
            params["reportTime"] = params["requestId"]
            params["coordinate"] = ["longitude": location?.coordinate.longitude ?? 0.0, "latitude": location?.coordinate.latitude ?? 0.0]
            if let jsonStr = params.dataValue?.jsonString {
                MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.memberLoaction_pub, qos:.qos1)
            }
        }
    }
}


extension TeamMapViewModel {
    
    // 返回格式化经纬度字符串
    func convertToDMSString(_ coordinate: Double, isLongitude: Bool) -> String {
        let absCoordinate = abs(coordinate)
        let degrees = Int(absCoordinate)
        let minutesDecimal = (absCoordinate - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let secondsDecimal = (minutesDecimal - Double(minutes)) * 60
        let seconds = Int(secondsDecimal)
        
        // 根据经纬度类型和正负添加方向标识
        let direction: String
        if isLongitude {
            direction = coordinate >= 0 ? "E" : "W"
        } else {
            direction = coordinate >= 0 ? "N" : "S"
        }
        
        return String(format: "%d°%d′%d″%@", degrees, minutes, seconds, direction)
    }
}
