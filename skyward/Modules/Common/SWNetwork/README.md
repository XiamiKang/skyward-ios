# SWNetwork

[![CI Status](https://img.shields.io/travis/赵波/SWNetwork.svg?style=flat)](https://travis-ci.org/赵波/SWNetwork)
[![Version](https://img.shields.io/cocoapods/v/SWNetwork.svg?style=flat)](https://cocoapods.org/pods/SWNetwork)
[![License](https://img.shields.io/cocoapods/l/SWNetwork.svg?style=flat)](https://cocoapods.org/pods/SWNetwork)
[![Platform](https://img.shields.io/cocoapods/p/SWNetwork.svg?style=flat)](https://cocoapods.org/pods/SWNetwork)

SWNetwork 是一个功能强大的网络库，提供了基于 Moya 的 HTTP 网络请求封装和基于 CocoaMQTT 的 MQTT 消息通信封装。

## 功能特性

### 🌐 HTTP 网络请求 (基于 Moya)
- 统一的网络请求接口
- 自动错误处理
- 请求缓存支持
- 网络状态监控
- 插件化架构支持

### 📡 MQTT 消息通信 (基于 CocoaMQTT)
- **连接管理**: 自动连接、断开、重连
- **消息发布**: 支持不同 QoS 级别的消息发布
- **主题订阅**: 支持通配符订阅和批量操作
- **状态监控**: 实时连接状态监控和回调
- **自动重连**: 智能重连机制，支持指数退避
- **单例模式**: 全局共享实例，方便使用
- **消息模型**: 结构化的消息处理
- **错误处理**: 完善的错误处理机制

## 快速开始

### HTTP 网络请求

```swift
import SWNetwork

// 使用 NetworkProvider 进行网络请求
let provider = NetworkProvider<NetworkAPI>()
provider.request(.getUserInfo(userId: "123")) { result in
    switch result {
    case .success(let response):
        // 处理成功响应
        let user = try? response.map(User.self)
    case .failure(let error):
        // 处理错误
        print("请求失败: \(error)")
    }
}
```

### MQTT 消息通信

```swift
import SWNetwork

// 创建MQTT配置
let configuration = MQTTConfiguration(
    host: "broker.hivemq.com",
    port: 1883,
    clientID: "iOS_Client_Demo"
)

// 创建MQTT管理器
let mqttManager = MQTTManager(configuration: configuration)
mqttManager.delegate = self

// 连接并订阅
mqttManager.connect()
mqttManager.subscribe(to: "test/topic")

// 发布消息
mqttManager.publish(message: "Hello MQTT", to: "test/topic")
```

### 使用MQTT单例模式

```swift
// 配置共享实例
MQTTManager.configureSharedInstance(host: "broker.hivemq.com", port: 1883)

// 获取共享实例
let mqttManager = MQTTManager.shared
mqttManager.delegate = self
mqttManager.connect()
```

## MQTT 功能详解

### 连接状态管理
```swift
extension YourViewController: MQTTManagerDelegate {
    func mqttManager(_ manager: MQTTManager, didChangeState state: MQTTConnectionState) {
        switch state {
        case .connecting:
            print("正在连接...")
        case .connected:
            print("已连接")
        case .disconnected:
            print("已断开")
        case .reconnecting:
            print("正在重连...")
        }
    }
}
```

### 消息处理
```swift
func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
    print("收到消息: \(message) from topic: \(topic)")
    // 根据主题处理不同的消息
}
```

### 通配符订阅
```swift
// 订阅所有设备状态
mqttManager.subscribeWithWildcard(to: "devices/+/status")

// 订阅所有传感器数据
mqttManager.subscribeWithWildcard(to: "sensors/#")
```

### 批量操作
```swift
// 批量订阅
let topics = ["topic1", "topic2", "topic3"]
mqttManager.subscribe(to: topics)

// 批量取消订阅
mqttManager.unsubscribe(from: topics)
```

## 使用场景

### 💬 聊天应用
```swift
// 聊天室消息处理
let chatTopic = "chat/room123/messages"
mqttManager.subscribe(to: chatTopic)

// 发送聊天消息
let message = "Hello, everyone!"
mqttManager.publish(message: message, to: chatTopic, qos: .qos1)
```

### 🏠 IoT设备控制
```swift
// 设备状态监控
let deviceTopics = [
    "devices/device001/status",
    "devices/device001/telemetry"
]
mqttManager.subscribe(to: deviceTopics)

// 发送控制命令
let command = "{\"action\":\"turn_on\"}"
mqttManager.publish(message: command, to: "devices/device001/command")
```

### 📊 实时数据推送
```swift
// 使用通配符订阅所有传感器数据
mqttManager.subscribeWithWildcard(to: "sensors/+/data")

// 发布传感器数据
mqttManager.publish(message: "25.5", to: "sensors/temperature/data")
```

## 安装

### CocoaPods

在你的 `Podfile` 中添加：

```ruby
# 本地模块路径
pod 'SWNetwork', :path => './skyward/Modules/Common/SWNetwork'
pod 'CocoaMQTT'  # MQTT支持
```

然后运行：
```bash
pod install
```

## 项目结构

```
SWNetwork/
├── Classes/
│   ├── MQTTManager.swift          # MQTT核心管理器
│   ├── MQTTUsageExample.swift     # 使用示例
│   ├── NetworkAPI.swift           # HTTP网络API定义
│   ├── NetworkProvider.swift      # 网络请求提供者
│   ├── NetworkConfig.swift        # 网络配置
│   ├── NetworkError.swift         # 网络错误定义
│   ├── NetworkExtension.swift     # 网络扩展功能
│   ├── NetworkPlugin.swift        # 网络插件
│   └── NetworkCacher.swift        # 网络缓存
└── README.md
```

## 最佳实践

### MQTT 使用建议

1. **连接管理**：
   - 在应用启动时建立连接
   - 监听应用生命周期事件，适时断开连接
   - 使用自动重连功能处理网络异常

2. **主题设计**：
   - 使用清晰的层级结构：`app/module/specific`
   - 合理使用通配符，避免过度订阅
   - 为不同功能模块设计独立的主题空间

3. **消息处理**：
   - 在UI更新时确保回到主线程
   - 实现消息去重机制
   - 对重要消息使用高QoS级别

4. **性能优化**：
   - 合理设置keep-alive间隔
   - 批量处理消息，减少频繁操作
   - 及时清理不再需要的订阅

5. **错误处理**：
   - 实现完善的错误处理机制
   - 给用户清晰的错误提示
   - 记录详细的错误日志

## 依赖

### HTTP 网络请求
- Moya: 网络抽象层框架
- Alamofire: 底层网络库

### MQTT 消息通信
- CocoaMQTT: MQTT 协议实现
- Foundation: 基础框架

## 版本历史

### 1.0.0
- 基础HTTP网络封装（基于Moya）
- 基础MQTT消息通信封装（基于CocoaMQTT）
- 自动重连功能
- 主题管理和消息模型支持
- 完善的错误处理机制

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件

## 作者

赵波 (zbo900801@gmail.com)

## 支持

如有问题或建议，请提交 Issue 或 Pull Request。
