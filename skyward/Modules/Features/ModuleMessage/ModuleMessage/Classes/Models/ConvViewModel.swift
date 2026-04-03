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
    
    private(set) var hasSyncLatestServerMessage: Bool = false
    
    init(conversation: Conversation) {
        self.conversation = conversation
        Logger.debug("====当前conversation的lastMessageId：\(conversation.latestMessage?.id ?? "没ID") content: \(conversation.latestMessage?.displayText() ?? "没内容")")
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

    func sendMessage(_ message: Message) {
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
                // 更新数据库
                self?.updateMessageIfExistWithServer(updatedMessage)
                // 更新列表
                if let index = self?.messageList.firstIndex(where: {$0.id == message.id}) {
                    self?.messageList[index] = updatedMessage
                }
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
    
    private enum MessageUpdateResult {
        case updated      // 已更新
        case skipped      // 跳过（已存在的在线消息, 但不符合更新条件）
        case notFound     // 没找到，需要插入
    }
    
    @discardableResult
    private func updateMessageIfExistWithServer(_ message: Message, onlyOffline: Bool = false) -> MessageUpdateResult {
        guard let conversationId = message.conversationId,
              let senderId = message.sender?.id,
              let timestamp = message.sendTimeTimestamp,
              let content = message.displayText() else {
            return .notFound
        }

        if let index = messageList.firstIndex(where: { existing in
            existing.displayText() == content &&
            existing.sendTimeTimestamp == timestamp &&
            existing.sender?.id == senderId
        }) {
            // 取出匹配的消息
            let existingMessage = messageList[index]

            // 如果指定 onlyOffline，只更新离线消息
            if onlyOffline && existingMessage.offline != true {
                // 已存在的在线消息，跳过
                return .skipped
            }

            // 构建更新条件
            var condition = Message.Properties.conversationId == conversationId && Message.Properties.sendTimeTimestamp == timestamp
            // 文本消息需要额外匹配内容
            if message.messageType == .chat {
                condition = condition && Message.Properties.content == content
            }

            DBManager.shared.updateToDb(table: DBTableName.message.rawValue,
                                        on: Message.Properties.all,
                                        with: message,
                                        where: condition)
            return .updated
        }
        // 本地不存在
        return .notFound
    }

    private func insertOrUpdateMessagesWithServer(_ messages: [Message]) {
        var messagesToInsert: [Message] = []

        for message in messages {
            let result = updateMessageIfExistWithServer(message, onlyOffline: true)
            if result == .notFound {
                messagesToInsert.append(message)
            }
        }

        // 批量插入新消息
        if !messagesToInsert.isEmpty {
            DBManager.shared.insertToDb(objects: messagesToInsert, intoTable: DBTableName.message.rawValue)
        }

        Logger.debug("====更新了或跳过了 \(messages.count - messagesToInsert.count) 条已存在的消息，插入了 \(messagesToInsert.count) 条新消息")
    }
    
    func sendMessageForbidden() -> Bool {
        guard let enable = conversation.enable  else { return false }
        return enable == false
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
        return messageList.filter { message in
            guard let id = message.id else { return false }
            return id.hasPrefix("-")
        }
    }
    
    /// 加载初始页面
    func loadPage() {
        let messageList = queryMessages()

        if messageList.count > 0 {
            self.messageList = messageList
            self.didLoadPage = true
        }
        
        if queryNotSyncOfflineMessages().count > 0 || hasSyncLatestServerMessage == false {
            _Concurrency.Task {
                await loadHistory()
                self.didLoadPage = true
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
        
        guard let messageList = await requestMessages(params: params), messageList.count > 0 else {
            return
        }
        // 标记本次请求返回的最后第一条消息ID，因为是降序的
        lastMessageId = messageList.last?.id
        Logger.debug("====接口返回的lastMessageId：\(lastMessageId ?? "没ID") content: \(messageList.last?.displayText() ?? "没内容")")
        // 获取列表最后一条消息ID
        let latestValidMessageId = latestValidMessageId()
        // 本次结果包含列表的消息，说明已经同步了服务端最新消息
        if messageList.contains(where: {$0.id == latestValidMessageId}) {
            Logger.debug("====已经同步了服务端最新消息了")
            hasSyncLatestServerMessage = true
        }

        insertOrUpdateMessagesWithServer(messageList)
        self.messageList = queryMessages()
        
        self.hasMoreData = messageList.count >= pageSize
    }
    
    private func latestValidMessageId() -> String? {
        return self.messageList.reversed().first(where: {$0.id?.hasPrefix("-") == false})?.id
    }
    
    // MARK: - network
    
    func requestMessages(params: [String : Any]) async -> [Message]? {
        guard NetworkMonitor.shared.isConnected else {
            return nil
        }
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
