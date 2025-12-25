//
//  MQTTManager.swift
//  SWNetwork
//
//  Created by 赵波 on 2025/11/19.
//

/**
 *该MQTT客户端封装具有以下核心功能：
 *连接管理‌：提供完整的连接状态监控、连接/断开控制，以及连接失败的错误处理机制
 *自动重连‌：实现基于指数退避算法的智能重连策略，避免频繁重连对服务器造成压力
 *消息处理‌：支持消息发布、订阅管理，并自动恢复重连后的订阅状态
 *配置灵活‌：支持自定义KeepAlive时间、会话保持、认证信息等参数配置
 *状态维护‌：维护连接状态、已订阅主题列表，确保业务连续性
 */

import Foundation
import CocoaMQTT

// MQTT连接状态枚举
public enum MQTTConnectState {
    case connecting
    case connected
    case disconnected
    case reconnecting
}

// MQTT消息接收协议
public protocol MQTTManagerDelegate: AnyObject {
    func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectState)
    func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String)
    func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String)
    func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: Error?)
}

public extension MQTTManagerDelegate {
    func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectState){}
    func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String){}
    func mqttManager(_ manager: MQTTManager, didPublishMessage message: String, toTopic topic: String){}
    func mqttManager(_ manager: MQTTManager, connectionDidFailWithError error: Error?){}
}

// MQTT配置结构体
public struct MQTTConfiguration {
    let host: String
    let port: UInt16
    let clientID: String
    let username: String?
    let password: String?
    let keepAlive: UInt16
    let cleanSession: Bool
    let autoReconnect: Bool
    let reconnectInterval: TimeInterval
    let maxReconnectInterval: TimeInterval
    
    public init(host: String, port: UInt16 = 1883, clientID: String? = nil, username: String? = nil, password: String? = nil, keepAlive: UInt16 = 60, cleanSession: Bool = false, autoReconnect: Bool = true, reconnectInterval: TimeInterval = 1.0, maxReconnectInterval: TimeInterval = 60.0) {
        self.host = host
        self.port = port
        self.clientID = clientID ?? "iOS_Client_\(UUID().uuidString)"
        self.username = username
        self.password = password
        self.keepAlive = keepAlive
        self.cleanSession = cleanSession
        self.autoReconnect = autoReconnect
        self.reconnectInterval = reconnectInterval
        self.maxReconnectInterval = maxReconnectInterval
    }

    public static let defaultConfig: MQTTConfiguration = {
        // 测试
        let config = MQTTConfiguration(host: "39.102.202.212",
                                       port: 1883,
                                       clientID: "ios-app-\(UUID().uuidString)",
                                       username: "txts_client",
                                       password: "txts123456")
        // 生产
//        let config = MQTTConfiguration(host: "39.102.203.24",
//                                       port: 1883,
//                                       clientID: "ios-app-\(UUID().uuidString)",
//                                       username: "txts-ios",
//                                       password: "ios@txtsqaz.")
        return config
    }()
}

// 主要的MQTT管理类
public final class MQTTManager {
    // MARK: - 属性
    public static let shared = MQTTManager()
    
    private var mqtt: CocoaMQTT5?
    private var configuration: MQTTConfiguration
    private var reconnectTimer: Timer?
    private var currentReconnectInterval: TimeInterval = 0
    private var subscribedTopics: Set<String> = []
    
    /// 使用代理数组支持多个代理
    private var delegates: [WeakMQTTDelegate] = []
    
    /// 添加代理
    /// - Parameter delegate: 要添加的代理
    public func addDelegate(_ delegate: MQTTManagerDelegate) {
        delegates.append(WeakMQTTDelegate(delegate: delegate))
        // 立即通知新代理当前连接状态
        delegate.mqttManager(self, didChangeState: connectionState)
    }
    
    /// 移除代理
    /// - Parameter delegate: 要移除的代理
    public func removeDelegate(_ delegate: MQTTManagerDelegate) {
        delegates.removeAll { $0.delegate === delegate }
    }
    
    /// 移除所有代理
    public func removeAllDelegates() {
        delegates.removeAll()
    }
    
    /// 弱引用包装类，用于存储代理
    private class WeakMQTTDelegate {
        weak var delegate: MQTTManagerDelegate?
        
        init(delegate: MQTTManagerDelegate) {
            self.delegate = delegate
        }
    }
    public private(set) var connectionState: MQTTConnectState = .disconnected {
        didSet {
            // 通知所有代理连接状态变化
            delegates.forEach { $0.delegate?.mqttManager(self, didChangeState: connectionState) }
        }
    }
    
    // MARK: - 初始化
    
    public init(configuration: MQTTConfiguration = MQTTConfiguration.defaultConfig) {
        self.configuration = configuration
        setupMQTTClient()
    }
    
    deinit {
        disconnect()
        reconnectTimer?.invalidate()
    }
    
    // MARK: - 配置设置
    
    private func setupMQTTClient() {
        mqtt = CocoaMQTT5(clientID: configuration.clientID,
                          host: configuration.host,
                          port: configuration.port)
        mqtt?.username = configuration.username
        mqtt?.password = configuration.password
        mqtt?.keepAlive = configuration.keepAlive
        mqtt?.cleanSession = configuration.cleanSession
        mqtt?.delegate = self
        mqtt?.autoReconnect = false // 使用自定义重连逻辑
//        mqtt?.enableSSL = false // 根据实际情况设置是否启用SSL
//        mqtt?.allowUntrustCACertificate = true // 允许不信任的CA证书
//        print("[MQTT] 客户端配置：host=\(configuration.host), port=\(configuration.port), clientID=\(configuration.clientID), username=\(configuration.username ?? "nil"), keepAlive=\(configuration.keepAlive), cleanSession=\(configuration.cleanSession), autoReconnect=\(configuration.autoReconnect)")
    }
    
    // MARK: - 连接管理
    
    /// 连接到MQTT代理
    public func connect() {
        guard let mqtt = mqtt else { return }
        
        connectionState = .connecting
        // CocoaMQTT5的connect()方法不抛出异常，移除try关键字
        let result = mqtt.connect()
        print("[MQTT] 连接请求发送结果: \(result)")
    }
    
    /// 断开MQTT连接
    public func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        mqtt?.disconnect()
        connectionState = .disconnected
    }
    
    /// 重新连接
    public func reconnect() {
        guard configuration.autoReconnect else { return }
        disconnect()
        setupMQTTClient()
        connect()
    }
    
    // MARK: - 消息发布
    
    /// 发布消息到指定主题
    /// - Parameters:
    ///   - message: 消息内容
    ///   - topic: 主题名称
    ///   - qos: 服务质量级别
    /// - Returns: 是否发布成功
    @discardableResult
    public func publish(message: String, to topic: String, qos: CocoaMQTTQoS = .qos1) -> Bool {
        guard let mqtt = mqtt, connectionState == .connected else {
            return false
        }
        let publishProperties = MqttPublishProperties()
        publishProperties.contentType = "JSON"
        mqtt.publish(topic, withString: message, qos: qos, properties: publishProperties)
        // 通知所有代理消息已发布
        delegates.forEach { $0.delegate?.mqttManager(self, didPublishMessage: message, toTopic: topic) }
        return true
    }
    
    // MARK: - 主题订阅
    
    /// 订阅主题
    /// - Parameters:
    ///   - topic: 主题名称
    ///   - qos: 服务质量级别
    public func subscribe(to topic: String, qos: CocoaMQTTQoS = .qos1) {
        // 无论是否连接，都先记录需要订阅的主题
        subscribedTopics.insert(topic)
        
        // 如果已经连接，立即订阅
        if let mqtt = mqtt, connectionState == .connected {
            mqtt.subscribe(topic, qos: qos)
        }
    }
    
    /// 取消订阅主题
    /// - Parameter topic: 主题名称
    public func unsubscribe(from topic: String) {
        // 无论是否连接，都先从订阅列表中移除
        subscribedTopics.remove(topic)
        
        // 如果已经连接，立即取消订阅
        if let mqtt = mqtt, connectionState == .connected {
            mqtt.unsubscribe(topic)
        }
    }
    
    /// 重新订阅之前的所有主题（用于重连后恢复订阅）
    private func resubscribeToTopics() {
        guard let mqtt = mqtt, connectionState == .connected else { return }
        
        for topic in subscribedTopics {
            mqtt.subscribe(topic)
        }
    }
    
    // MARK: - 自动重连逻辑
    
    private func scheduleReconnect() {
        guard configuration.autoReconnect else { return }
        
        reconnectTimer?.invalidate()
        
        // 使用指数退避算法计算重连间隔
        currentReconnectInterval = min(
            currentReconnectInterval * 2,
            configuration.maxReconnectInterval
        )
        
        if currentReconnectInterval == 0 {
            currentReconnectInterval = configuration.reconnectInterval
        }
        
        reconnectTimer = Timer.scheduledTimer(
            timeInterval: currentReconnectInterval,
            target: self,
            selector: #selector(performReconnect),
            userInfo: nil,
            repeats: false
        )
    }
    
    @objc private func performReconnect() {
        reconnect()
    }
    
    private func handleConnectionError(_ error: Error) {
        // 通知所有代理连接失败
        delegates.forEach { $0.delegate?.mqttManager(self, connectionDidFailWithError: error) }
        connectionState = .disconnected
        
        if configuration.autoReconnect {
            scheduleReconnect()
        }
    }
}

// MARK: - CocoaMQTT5Delegate

extension MQTTManager: CocoaMQTT5Delegate {
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData: MqttDecodeConnAck?) {
        switch ack {
        case .success:
            connectionState = .connected
            currentReconnectInterval = 0 // 重置重连间隔
            resubscribeToTopics() // 恢复订阅
        default:
            handleConnectionError(NSError(domain: "MQTT", code: Int(ack.rawValue), userInfo: [NSLocalizedDescriptionKey: "连接被拒绝"]))
        }
    }
    public func mqtt5(_ mqtt5: CocoaMQTT5, didStateChangeTo state: CocoaMQTTConnState) {
        print("mqtt5_didStateChangeTo : \(state.description)")
        switch state {
        case .connected:
            connectionState = .connected
        case .connecting:
            connectionState = .connecting
        case .disconnected:
            connectionState = .disconnected
        }
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id: UInt16) {
        let payload = message.string ?? ""
        // 通知所有代理消息已发布
        delegates.forEach { $0.delegate?.mqttManager(self, didPublishMessage: payload, toTopic: message.topic) }
        print("mqtt5_didPublishMessage: topic:\(message.topic) \n message: \(payload)")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didPublishAck id: UInt16, pubAckData: MqttDecodePubAck?) {
        print("mqtt5_didPublishAck: \(String(describing: pubAckData!.reasonCode))")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didPublishRec id: UInt16, pubRecData: MqttDecodePubRec?) {
        print("mqtt5_didPublishRec: \(String(describing: pubRecData!.reasonCode))")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didPublishComplete id: UInt16,  pubCompData: MqttDecodePubComp?){
        print("mqtt5_didPublishComplete: \(String(describing: pubCompData!.reasonCode))")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id: UInt16, publishData: MqttDecodePublish?) {
        let payload = message.string ?? ""
        // 通知所有代理接收到消息
        delegates.forEach { $0.delegate?.mqttManager(self, didReceiveMessage: payload, fromTopic: message.topic) }
        print("mqtt5_didReceiveMessage: topic:\(message.topic) \n  message: \(payload) ")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData: MqttDecodeSubAck?) {
        print("mqtt5_didSubscribeTopics: success:\(success) failed:\(failed) ")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData: MqttDecodeUnsubAck?) {
        print("mqtt5_didUnsubscribeTopics: \(topics)")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        print("mqtt5_didReceiveDisconnectReasonCode: \(reasonCode)")
    }
    
    public func mqtt5(_ mqtt5: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        print("mqtt5_didReceiveAuthReasonCode: \(reasonCode)")
    }
    
    public func mqtt5DidPing(_ mqtt5: CocoaMQTT5) {
        print("mqtt5_DidPing")
    }
    
    public func mqtt5DidReceivePong(_ mqtt5: CocoaMQTT5) {
        print("mqtt5_DidReceivePong")
    }
    
    public func mqtt5DidDisconnect(_ mqtt5: CocoaMQTT5, withError err: (any Error)?) {
        print("mqtt5_mqtt5DidDisconnect: \(String(describing: err?.localizedDescription))")
        connectionState = .disconnected
        if configuration.autoReconnect {
            // 无论是否有错误，都尝试重连
            scheduleReconnect()
        } else if let error = err {
            handleConnectionError(error)
        }
    }
}


// MARK: - 便捷方法扩展
extension MQTTManager {
    
    /// 便捷初始化方法
    /// - Parameters:
    ///   - host: 服务器地址
    ///   - port: 端口号
    ///   - clientID: 客户端ID
    public convenience init(host: String, port: UInt16 = 1883, clientID: String? = nil) {
        let configuration = MQTTConfiguration(
            host: host,
            port: port,
            clientID: clientID
        )
        self.init(configuration: configuration)
    }
    
    /// 检查是否已连接到指定主题
    /// - Parameter topic: 主题名称
    /// - Returns: 是否已订阅
    public func isSubscribed(to topic: String) -> Bool {
        return subscribedTopics.contains(topic)
    }
    
    /// 获取当前已订阅的所有主题
    /// - Returns: 主题名称数组
    public func getAllSubscribedTopics() -> [String] {
        return Array(subscribedTopics)
    }
    
    /// 批量订阅主题
    /// - Parameters:
    ///   - topics: 主题名称数组
    ///   - qos: 服务质量级别
    public func subscribe(to topics: [String], qos: CocoaMQTTQoS = .qos1) {
        for topic in topics {
            subscribe(to: topic, qos: qos)
        }
    }
    
    /// 批量取消订阅主题
    /// - Parameter topics: 主题名称数组
    public func unsubscribe(from topics: [String]) {
        for topic in topics {
            unsubscribe(from: topic)
        }
    }
}

// MARK: - 连接状态检查
extension MQTTManager {
    
    /// 检查当前连接状态
    /// - Returns: 是否已连接
    public var isConnected: Bool {
        return connectionState == .connected
    }
    
    /// 检查是否正在连接中
    /// - Returns: 是否正在连接
    public var isConnecting: Bool {
        return connectionState == .connecting
    }
    
    /// 检查是否正在重连中
    /// - Returns: 是否正在重连
    public var isReconnecting: Bool {
        return connectionState == .reconnecting
    }
    
    // 打印MQTT状态
    public func printConnectionStatus() {
        print("=== MQTT 连接状态 ===")
        print("连接状态: \(connectionState)")
        print("是否已连接: \(isConnected)")
        print("MQTT实例: \(mqtt != nil ? "存在" : "nil")")
        print("已订阅主题: \(subscribedTopics)")
        print("配置信息:")
        print("  Host: \(configuration.host)")
        print("  Port: \(configuration.port)")
        print("  ClientID: \(configuration.clientID)")
        print("  Username: \(configuration.username ?? "nil")")
        print("===================")
    }
}

// MARK: - 配置管理
extension MQTTManager {
    
    /// 更新MQTT配置
    /// - Parameter newConfiguration: 新的配置
    public func updateConfiguration(_ newConfiguration: MQTTConfiguration) {
        let wasConnected = isConnected
        
        disconnect()
        configuration = newConfiguration
        setupMQTTClient()
        
        if wasConnected {
            connect()
        }
    }
    
    /// 获取当前配置的副本
    /// - Returns: 当前配置
    public func getCurrentConfiguration() -> MQTTConfiguration {
        return configuration
    }
}
