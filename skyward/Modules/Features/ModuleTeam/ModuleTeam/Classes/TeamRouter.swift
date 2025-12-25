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

        let convs = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self)
        if let conversations = convs, !conversations.isEmpty {
            let vc = TeamListViewController(conversations: conversations)
            UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
        } else {
            let router = TeamRouter()
            router.selfReference = router
            MQTTManager.shared.addDelegate(router)
            var params = [String : Any]()
            params["requestId"] = Int(Date().timeIntervalSince1970)
            if let jsonStr = params.dataValue?.jsonString {
                MQTTManager.shared.subscribe(to: TeamAPI.convList_sub, qos: .qos1)
                MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.convList_pub, qos:.qos1)
            }
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
        
        DispatchQueue.main.async {[weak self] in
            do {
                guard let jsonData = message.data(using: .utf8) else {
                    debugPrint("[JSON解析] 消息转换为Data失败")
                    self?.cleanup()
                    return
                }
        
                let decoder = JSONDecoder()
                let rsp = try decoder.decode(MQTTResponse<[Conversation]>.self, from: jsonData)
                
                guard rsp.isSuccess else {
                    debugPrint("[MQTT] 响应失败: \(String(describing: rsp.msg))")
                    self?.cleanup()
                    return
                }
                
                // 直接使用rsp.data，不需要额外的类型转换
                if let conversations = rsp.data, !conversations.isEmpty {
                    DBManager.shared.insertToDb(objects: conversations, intoTable: DBTableName.conversation.rawValue)
                    let vc = TeamListViewController(conversations: conversations)
                    UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    // 如果没有会话列表，进入创建队伍页面
                    let vc = TeamCreateViewController()
                    UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                }
                self?.cleanup()
                
            } catch {
                self?.cleanup()
                debugPrint("[JSON解析] 解析失败: \(error)")
            }
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
