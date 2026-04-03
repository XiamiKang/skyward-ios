//
//  ConvViewModel.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/3/30.
//

import Foundation
import WCDBSwift
import SWKit
import SWNetwork

class ConvViewModel: ObservableObject {
    @Published var messageList: [Message] = []
    @Published var didLoadPage: Bool = false
    @Published var didSendMessage: Bool = false
    @Published var didReceiveMessage: Bool = false

    var conversation: Conversation

    // page
    private(set) var hasMoreData = true
    private(set) var lastMessageId: String?
    
    private lazy var sender: User = {
        let sender = User(id: UserManager.shared.userId,
                          nickname: UserManager.shared.userInfo?.nickname,
                          avatar: UserManager.shared.userInfo?.avatar,
                          phone: UserManager.shared.userInfo?.phone,
                          role: 0)
        return sender
    }()
    
    init(conversation: Conversation) {
        self.conversation = conversation
        
        // 通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveNewMessage(_:)),
            name: .receiveNewMessage,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func sendMessage(_ message: Message, completion: (() ->Void)? = nil) {
        // 文本消息：内容不能为空、空字符串或纯空格
        if message.messageType == .chat {
            guard let content = message.content,
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
        }
        
        // 定位消息：坐标必须有效
        if message.messageType == .location {
            guard let lon = message.location?.longitude,
                  let lat = message.location?.latitude,
                  lon != 0 && lat != 0  // 排除 (0, 0)
            else {
                return
            }
        }
        
        var updatedMessage = message
        
        if NetworkMonitor.shared.isConnected {
            updatedMessage.status = .sending
            self.addMessageToTable(updatedMessage)
            sendMessage(msg: updatedMessage) { [weak self] serverMessage in
                if let serverMessage = serverMessage {
                    updatedMessage = serverMessage
                    updatedMessage.status = .sent
                } else {
                    updatedMessage.status = .failed
                }
                self?.syncSendMessageWithServer(updatedMessage)
            }
        } else {
            if let _ = BluetoothManager.shared.connectedPeripheral {
                guard let conversationId = updatedMessage.conversationId, let timestamp = updatedMessage.sendTimeTimestamp else {
                    return
                }
                
                let msgData: Data?
                if updatedMessage.messageType == .location {
                    guard let lon = updatedMessage.location?.longitude,
                          let lat = updatedMessage.location?.latitude,
                          lon != 0 && lat != 0  // 排除 (0, 0)
                    else {
                        return
                    }
                    msgData = MessageGenerator.generateLocationMessage(senderId: UserManager.shared.userId,
                                                                       targetId: conversationId,
                                                                       timestamp: Double(timestamp / 1000),
                                                                       lon: lon,
                                                                       lat: lat)
                } else {
                    guard let content = updatedMessage.content else {
                        return
                    }
                    msgData = MessageGenerator.generateTxtMessage(senderId: UserManager.shared.userId,
                                                                  targetId: conversationId,
                                                                  timestamp: Double(timestamp / 1000),
                                                                  message: content)
                }
                guard let msgData = msgData else {
                    return
                }
                SWAlertView.showAlert(message: "当前无网络连接，通过Mini设备发消息？") {
                    BluetoothManager.shared.sendAppCustomData(msgData)
                    updatedMessage.offline = true
                    self.addMessageToTable(updatedMessage)
                }
                
            } else {
                UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
            }
        }
    }
    
    func addMessageToTable(_ message: Message) {
        if let msgId = message.id {
            // 如果消息已存在，则更新消息状态，否则添加新消息
            if let index = messageList.firstIndex(where: { $0.id == msgId }) {
                messageList[index] = message
            } else {
                messageList.append(message)
            }
        } else {
            messageList.append(message)
        }

        DBManager.shared.insertToDb(objects: [message], intoTable: DBTableName.message.rawValue)
        
        self.didSendMessage = true
    }
    
    private func syncSendMessageWithServer(_ message: Message) {
        guard let conversationId = message.conversationId, let senderId = message.sender?.id, let timestamp = message.sendTimeTimestamp else {
            return
        }
        
        // 文本消息
        if message.messageType == .chat {
            // 根据 content、sendTimeTimestamp、sender.id 三个条件匹配
            guard let content = message.content else { return }
            
            // 更新数据库 - 不能用id来匹配，因为是拿服务端消息更新本地消息
            let result = DBManager.shared.updateToDb(table: DBTableName.message.rawValue,
                                                     on: Message.Properties.all,
                                                     with: message,
                                                     where: Message.Properties.content == content && Message.Properties.sendTimeTimestamp == timestamp && Message.Properties.conversationId == conversationId)
            
            // 更新列表
            if result {
                if let index = messageList.firstIndex(where: { existing in
                    existing.content == content &&
                    existing.sendTimeTimestamp == timestamp &&
                    existing.sender?.id == senderId
                }) {
                    messageList[index] = message
                }
            }
        }
        
        // 定位消息
        if message.messageType == .location {
            // 更新数据库
            let result = DBManager.shared.updateToDb(table: DBTableName.message.rawValue,
                                                     on: Message.Properties.all,
                                                     with: message,
                                                     where: Message.Properties.sendTimeTimestamp == timestamp && Message.Properties.conversationId == conversationId)
            // 更新列表
            if result {
                if let index = messageList.firstIndex(where: { existing in
                    existing.sendTimeTimestamp == timestamp &&
                    existing.sender?.id == senderId
                }) {
                    messageList[index] = message
                }
            }
        }
    }
    
    @discardableResult
    func syncOfflineMessagesWithServer(_ messages: [Message]) -> Bool {
        // 获取本地离线发送的消息
        let offlineMessages = queryNotSyncOfflineMessages()
        guard offlineMessages.count > 0 else {
            return false
        }
        
        var hasUpdated = false

        // 匹配离线消息和服务器返回的已发送消息
        for offlineMsg in offlineMessages {
            guard let offlineConvId = offlineMsg.conversationId,
                  let offlineTimestamp = offlineMsg.sendTimeTimestamp else {
                continue
            }

            // 查找匹配的服务器消息
            if let matchedMsg = messages.first(where: { serverMsg in
                return serverMsg.conversationId == offlineConvId && serverMsg.sendTimeTimestamp == offlineTimestamp
            }) {
                // 匹配成功，更新本地离线消息
                var updatedMsg = matchedMsg
                updatedMsg.status = .sent

                // 更新数据库
                DBManager.shared.updateToDb(table: DBTableName.message.rawValue,
                                            on: Message.Properties.all,
                                            with: updatedMsg,
                                            where: Message.Properties.conversationId == offlineConvId && Message.Properties.sendTimeTimestamp == offlineTimestamp)
                hasUpdated = true
                
                Logger.debug("同步了离线消息：\(matchedMsg.id ?? "未知id") 内容：\(matchedMsg.content ?? "未知内容")")
            }
        }
        
        return hasUpdated
    }
    
    func sendMessageForbidden() -> Bool {
        guard let enable = conversation.enable  else { return false }
        return enable == false
    }
    
    // messageList有更新则会同步lastMessageId
    func updateLastMessageId() {
        lastMessageId = messageList.first(where: { $0.id != nil })?.id
    }
    
    //MARK: Message List
    
    /// 查询数据库所有消息
    func queryMessages() -> [Message] {
        guard let convId = conversation.id else {
            return []
        }
        
        return DBManager.shared.queryFromDb(fromTable: DBTableName.message.rawValue,
                                            cls: Message.self,
                                            where: Message.Properties.conversationId == convId,
                                            orderBy: [Message.Properties.sendTimeTimestamp.order(.ascending)]) ?? []
    }
    
    /// 查询未同步服务端的离线消息
    func queryNotSyncOfflineMessages() -> [Message] {
        guard let convId = conversation.id else {
            return []
        }
        
        let condition = Message.Properties.conversationId == convId && Message.Properties.offline == true
        
        guard let result = DBManager.shared.queryFromDb(fromTable: DBTableName.message.rawValue,
                                                        cls: Message.self,
                                                        where: condition,
                                                        orderBy: [Message.Properties.sendTimeTimestamp.order(.ascending)]) else {
            return []
        }
        
        return result.filter { message in
            guard let id = message.id else { return false }
            return id.hasPrefix("-")
        }
    }
    
    private func queryLatestMessageId() -> String? {
        guard let convId = conversation.id else {
            return nil
        }
        
        guard let result = DBManager.shared.queryFromDb(fromTable: DBTableName.message.rawValue,
                                                        cls: Message.self,
                                                        where: Message.Properties.conversationId == convId,
                                                        orderBy: [Message.Properties.sendTimeTimestamp.order(.descending)]) else {
            return nil
        }
        
        return result.first(where: {$0.id?.hasPrefix("-") == false})?.id
    }
    
    /// 加载初始页面
    func loadPage() {
        let messageList = queryMessages()

        if messageList.count > 0 {
            self.messageList = messageList
            self.didLoadPage = true
            if NetworkMonitor.shared.isConnected {
                _Concurrency.Task {
                    if queryNotSyncOfflineMessages().count > 0 {
                        await loadHistoryForSyncOfflineMessages()
                    } else {
                        await loadUnread()
                    }
                }
            }
        } else {
            if NetworkMonitor.shared.isConnected {
                _Concurrency.Task {
                    await loadHistory()
                    self.didLoadPage = true
                }
            }
        }
    }

    /// 加载历史消息
    func loadHistory() async {
        guard hasMoreData else {
            return
        }

        guard let convId = conversation.id else {
            return
        }
        
        let pageSize = Constants.pageSize
        
        var params: [String: Any] = [
            "conversationId": convId,
            "pageSize": pageSize
        ]
        if let lastMessageId = lastMessageId {
            params["lastMessageId"] = lastMessageId
        }
        guard let messageList = await requestMessages(params: params) else {
            return
        }

        if messageList.count > 0 {
            DBManager.shared.insertToDb(objects: messageList, intoTable: DBTableName.message.rawValue)
            self.messageList = queryMessages()
        }
        
        self.hasMoreData = messageList.count >= pageSize
    }
    
    func loadHistoryForSyncOfflineMessages() async {
        guard queryNotSyncOfflineMessages().count > 0 else {
            return
        }
        
        guard let convId = conversation.id else {
            return
        }
        
        let params: [String: Any] = [
            "conversationId": convId,
            "pageSize": -1
        ]
        
        guard let messageList = await requestMessages(params: params), messageList.count > 0 else {
            return
        }

        if syncOfflineMessagesWithServer(messageList) {
            self.messageList = queryMessages()
        }
    }

    ///  加载未读消息 （加载本地最后一条消息后面的最新消息）
    func loadUnread() async {
        guard let convId = conversation.id else {
            return
        }
        
        var params: [String: Any] = [
            "conversationId": convId,
            "pageSize": -1,
            "isBefore": false
        ]
        
        if let lastMessageId = queryLatestMessageId() {
            params["lastMessageId"] = lastMessageId
        }
        
        guard let messageList = await requestMessages(params: params), messageList.count > 0 else {
            return
        }
        
        DBManager.shared.insertToDb(objects: messageList, intoTable: DBTableName.message.rawValue)
        self.messageList = queryMessages()
    }
    
    //MARK: - Private
    
    func generateTxtMessage(content: String) -> Message? {
        guard let convId = conversation.id else {
            return nil
        }
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        let message = Message(id: String(-timestamp),
                              conversationId: convId,
                              sender: self.sender,
                              content: content,
                              sendTimeTimestamp: timestamp,
                              messageType: .chat,
                              location: nil,)
        return message
    }

    func generateLocationMessage(address: AroundPOIData) -> Message? {
        guard let convId = conversation.id else {
            return nil
        }
        
        let lon = address.longitude
        let lat = address.latitude
        
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        let location = IMLocation(longitude: lon,
                                  latitude: lat,
                                  address: address.address,
                                  addressName: address.name)
        
        let message = Message(id: String(-timestamp),
                              conversationId: convId,
                              sender: sender,
                              content: nil,
                              sendTimeTimestamp: timestamp,
                              messageType: .location,
                              location: location)
        return message
    }
    
    
    // MARK: - network
    
    func requestMessages(params: [String : Any]) async -> [Message]? {
        do {
            let rsp = try await NetworkProvider<MessageAPI>().request(.messageList(params: params))
            let networkResponse = try JSONDecoder().decode(NetworkResponse<MessageList>.self, from: rsp.data)
            return networkResponse.data?.list
        } catch {
            await UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
            return nil
        }
    }
    
    func sendMessage(msg: Message, completion: @escaping (Message?) ->Void) {
        guard let convId = conversation.id else {
            return
        }
        
        var params: [String: Any] = [
            "conversationId": convId
        ]
        if let msgType = msg.messageType {
            params["messageType"] = msgType.rawValue
        }
        
        if let sendTime = msg.sendTimeTimestamp {
            params["sendTime"] = sendTime
        }
        
        if let content = msg.content {
            params["content"] = content
        }
        
        if let lon = msg.location?.longitude, let lat = msg.location?.latitude {
            params["location"] = ["longitude" : lon, "latitude" : lat, "address": msg.location?.address ?? "", "addressName" : msg.location?.addressName ?? ""]
        }
        NetworkProvider<MessageAPI>().request(.sendMessage(params: params)) { result in
            if case .success(let rsp) = result {
                do {
                    let networkResponse = try JSONDecoder().decode(NetworkResponse<Message>.self, from: rsp.data)
                    completion(networkResponse.data)
                } catch {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    
    // MARK: - Notification
    
    @objc private func receiveNewMessage(_ notification: Notification) {
        guard let message = notification.object as? Message, message.conversationId == conversation.id else {
            return
        }
        self.messageList.append(message)
        self.didReceiveMessage = true
    }
    
    // MARK: - Tool
    
    func covertToAroundPOIData(_ location: IMLocation?) -> AroundPOIData? {
        guard let location = location, let lon = location.longitude, let lat = location.latitude else {
            return nil
        }
        
        return AroundPOIData(longitude: lon, latitude: lat, name: location.addressName, address: location.address)
    }
}
