//
//  ConvListViewModel.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/3/25.
//

import Foundation
import SWKit
import SWNetwork
import WCDBSwift

class ConvListViewModel: ObservableObject, MQTTManagerDelegate {
    @Published var convList: [Conversation] = []
    
    private var currentConversationId: String?
    
    // MARK: - Initialization
    
    init() {

        // 处理服务中心消息
        if let latestServiceMessage = queryLatestMessage(convId: MessageManager.serviceConversationId) {
            DispatchQueue.main.async {
                self.syncHomeLatestServiceMessage(latestServiceMessage)
            }
        } else {
            let serviceConversation = Conversation.serviceConversation()
            DBManager.shared.insertToDb(objects: [serviceConversation], intoTable: DBTableName.conversation.rawValue)
        }
        
        refreshConversationList()
        
        _Concurrency.Task {
            if await requestConversationList() {
                refreshConversationList()
            }
        }

        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: MessageAPI.convList_sub)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveNewMessage(_:)),
            name: .receiveNewMessage,
            object: nil
        )
    }
    
    deinit {
        MQTTManager.shared.removeDelegate(self)
        MQTTManager.shared.unsubscribe(from: MessageAPI.convList_sub)
    }

    // MARK: - Public Methods

    @discardableResult
    func requestConversationList() async -> Bool {
        guard NetworkMonitor.shared.isConnected else {
            return false
        }
        
        do {
            let rsp = try await NetworkProvider<MessageAPI>().request(.conversationList())
            let networkResponse = try JSONDecoder().decode(NetworkResponse<[Conversation]>.self, from: rsp.data)
            
            if let conversations = networkResponse.data, conversations.count > 0 {
                // 不实用服务端的unreadCount，避免和本地不一致导致的红点问题， 如果conversations里包含本地conversation，则用本地conversation的unreadCount
                let conversationsToInsert = conversations.map { conv -> Conversation in
                    var mutableConv = conv
                    if let convId = conv.id, let localConv = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue,
                                                                    cls: Conversation.self,
                                                                    where: Conversation.Properties.id == convId)?.first {
                        mutableConv.unreadCount = localConv.unreadCount
                        mutableConv.latestMessage = localConv.latestMessage
                    }
                    return mutableConv  
                }
                DBManager.shared.insertToDb(objects: conversationsToInsert, intoTable: DBTableName.conversation.rawValue)
                return true
            }
            return false
        } catch {
            Logger.debug("[会话列表] 请求失败: \(error)")
            return false
        }
    }
    
    func didSelectRowAt(row: Int) -> Conversation? {
        guard convList.count > row else {
            return nil
        }
        
        var conv = convList[row]
        
        guard let convId = conv.id else {
            return nil
        }
        
        // 清除红点
        if conv.unreadCount ?? 0 > 0 {
            conv.unreadCount = 0
            if DBManager.shared.updateToDb(table: DBTableName.conversation.rawValue,
                                           on: [Conversation.Properties.unreadCount],
                                           with: conv,
                                           where: Conversation.Properties.id == convId) {
                convList[row] = conv
            }
        }
        
        currentConversationId = convId
        
        refreshTabBadgeValue()
        
        return conv
    }
    
    func popFromCurrentConversation() {
        currentConversationId = nil
    }
    
    /// 当前会话消息列表发生变化，需更新排序和最新消息后刷新会话列表
    func currentConversationLatestMessageDidChanged() {
        guard let currentConvId = currentConversationId else {
            return
        }
        
        guard var conv = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self, where: Conversation.Properties.id == currentConvId)?.first else {
            return
        }
        
        guard let latestMessage = queryLatestMessage(convId: currentConvId) else {
            return
        }
        
        conv.latestMessage = latestMessage
        DBManager.shared.updateToDb(table: DBTableName.conversation.rawValue,
                                       on: [Conversation.Properties.latestMessage],
                                       with: conv,
                                       where: Conversation.Properties.id == currentConvId)
        
        refreshConversationList()
        
        // 如果是服务中心会话，同步首页
        if currentConvId == MessageManager.serviceConversationId {
            syncHomeLatestServiceMessage(latestMessage)
        }
    }
    
    // MARK: - Notification
    
    @objc private func receiveNewMessage(_ notification: Notification) {
        guard let message = notification.object as? Message else {
            return
        }
        
        guard let receivedConvId = message.conversationId else {
            return
        }
        
        // 如果收到的消息是当前会话的，则该会话未读数设置为0
        if let currentConvId = currentConversationId, currentConvId == receivedConvId {
            guard var conv = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self, where: Conversation.Properties.id == receivedConvId)?.first else {
                return
            }
            conv.unreadCount = 0
            DBManager.shared.updateToDb(table: DBTableName.conversation.rawValue,
                                           on: [Conversation.Properties.unreadCount],
                                           with: conv,
                                           where: Conversation.Properties.id == receivedConvId)
        }

        refreshConversationList()
        
        // 如果是服务中心会话，同步首页
        if receivedConvId == MessageManager.serviceConversationId {
            syncHomeLatestServiceMessage(message)
        }
    }
    
    // MARK: - Private Methods

    ///  刷新会话列表
    private func refreshConversationList() {
        guard let conversations = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self) else {
            return
        }
        
        // 过滤掉可能已存在的 serviceConversation
        let filteredConversations = conversations.filter { $0.id != MessageManager.serviceConversationId }

        // 剩余会话按时间戳排序
        let sortedConversations = filteredConversations.sorted { conv1, conv2 in
            let timestamp1 = conv1.latestMessage?.sendTimeTimestamp ?? 0
            let timestamp2 = conv2.latestMessage?.sendTimeTimestamp ?? 0
            return timestamp1 > timestamp2 // 降序：时间戳大的在前面
        }
        
        if let serviceConversation = conversations.first(where: {$0.id == MessageManager.serviceConversationId}) {
            /// 根据最新消息时间戳对会话列表排序（降序），serviceConversation 固定在顶部
            convList = [serviceConversation] + sortedConversations
        } else {
            convList = sortedConversations
        }
        
        refreshTabBadgeValue()
    }
    
    private func refreshTabBadgeValue() {
        let unreadCount = convList.reduce(0) { $0 + ($1.unreadCount ?? 0) }
        
        DispatchQueue.main.async {
            let vc = UIWindow.findViewController(ofType: ConvListViewController.self)
            if unreadCount > 0 {
                vc?.tabBarItem.badgeValue = unreadCount > 99 ? "99+" : String(unreadCount)
            } else {
                vc?.tabBarItem.badgeValue = nil
            }
            
            if #available(iOS 16.0, *) {
                UNUserNotificationCenter.current().setBadgeCount(unreadCount)
            } else {
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
            }
        }
    }
    
    private func syncHomeLatestServiceMessage(_ latestMessage: Message) {

        guard let content = latestMessage.displayText(), !content.isEmpty else {
            return
        }
        
        let timestamp = "\(latestMessage.sendTimeTimestamp ?? 0)"
        
        SWRouter.handle(RouteTable.homeLatestServiceMessageUrl, parameters: ["content": content, "timestamp": timestamp])
    }
    
    private func queryLatestMessage(convId: String) -> Message? {
        return DBManager.shared.queryFromDb(fromTable: DBTableName.message.rawValue,
                                            cls: Message.self,
                                            where: Message.Properties.conversationId == convId,
                                            orderBy: [Message.Properties.sendTimeTimestamp.order(.descending)])?.first
    }
    
    // MARK: - MQTTManagerDelegate
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == MessageAPI.convList_sub else { return }
        do {
            guard let jsonData = message.data(using: .utf8) else {
                return
            }
            let networkResponse = try JSONDecoder().decode(NetworkResponse<[Conversation]>.self, from: jsonData)

            if let conversations = networkResponse.data, conversations.count > 0 {
                DBManager.shared.insertToDb(objects: conversations, intoTable: DBTableName.conversation.rawValue)
                refreshConversationList()
            }
        } catch {
            Logger.debug("[JSON解析] 解析失败: \(error)")
        }
    }
}
