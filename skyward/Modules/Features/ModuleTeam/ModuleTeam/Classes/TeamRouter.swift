//
//  TeamRouter.swift
//  Alamofire
//
//  Created by zhaobo on 2025/12/4.
//

import TXKit
import TXRouterKit
import SWKit
import SWNetwork

class TeamRouter: RoutableActionType {
    // 用于持有自身引用，防止被提前释放
    private var selfReference: TeamRouter?
    
    static func handle(_ url: any URLConvertible, _ callback: ((Any?) -> Void)?) -> Bool {
        if let conversations = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self), conversations.count > 0 {
            UIWindow.topViewController()?.navigationController?.pushViewController(TeamListViewController(conversations: conversations), animated: true)
        } else {
            let router = TeamRouter()
            router.selfReference = router
            MQTTManager.shared.addDelegate(router)
            MQTTManager.shared.subscribe(to: TeamAPI.convList_sub, qos: .qos1)
            MQTTManager.shared.publish(message: "{}", to: TeamAPI.convList_pub, qos:.qos1)
        }
        return true
    }
    
    static var patterns: [String] {
        return ["\(RouteTable.teamPageUrl)[^\\s]*"]
    }
    
    deinit {
        MQTTManager.shared.removeDelegate(self)
    }
}


extension TeamRouter: MQTTManagerDelegate {

    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == TeamAPI.convList_sub else {
            return
        }
        do {
            guard let jsonData = message.data(using: .utf8) else {
                cleanup()
                return
            }
            let rsp = try JSONDecoder().decode(MQTTResponse<[Conversation]>.self, from: jsonData)
            
            if let conversations = rsp.data, conversations.count > 0 {
                DBManager.shared.insertToDb(objects: conversations, intoTable: DBTableName.conversation.rawValue)
                DispatchQueue.main.async {
                    UIWindow.topViewController()?.navigationController?.pushViewController(TeamListViewController(conversations: conversations), animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    UIWindow.topViewController()?.navigationController?.pushViewController(TeamCreateViewController(), animated: true)
                }
            }
            cleanup()
        } catch {
            cleanup()
        }
    }
    
    public func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: (any Error)?) {
        // 连接失败时清理资源
        self.cleanup()
    }
    
    // 清理资源的方法
    private func cleanup() {
        // 释放自身引用，让实例可以被销毁
        selfReference = nil
    }
}
