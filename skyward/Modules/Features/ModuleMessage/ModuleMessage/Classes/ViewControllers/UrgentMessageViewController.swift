//
//  UrgentMessageViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/12/22.
//

import TXKit
import SnapKit
import SWTheme
import SWKit
import SWNetwork

class UrgentMessageViewController: BaseViewController {
    
    private var messages: [UrgentMessage] = []
    private let tableView = UITableView()
    private let inputContainerView = UIView()
    private let messageTextView = UITextView()
    private let sendButton = UIButton()
    
    
    // 用于保存inputBottomView的底部约束，以便动态调整
    private var inputBottomConstraint: Constraint?
    
    // 保存原始的底部内边距
    private let originalBottomInset = ScreenUtil.safeAreaBottom

    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("服务中心")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messages = DBManager.shared.queryFromDb(fromTable: DBTableName.urgentMessage.rawValue, cls: UrgentMessage.self) ?? []
        
        // 注册键盘通知
        registerKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
        
        // MQTT
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: receiveUrgentMessage_sub, qos: .qos1)
        // 获取消息列表
        _Concurrency.Task {
            await requestUrgentMessages()
        }
        
        // 监听窄带设备的自定义消息
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveDeviceCustomMessage(_:)),
            name: .didReceiveDeviceCustomMsg,
            object: nil
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 在布局完成后滚动到底部，确保tableView已经完成渲染
        scrollToBottom(animated: false)
    }
    
    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let lastIndexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
    }
    
    // MARK: - Override
    
    override var hasNavBar: Bool {
        return false
    }
    
    override func setupViews(){
        view.addSubview(navigationBar)
        
        // 初始化 tableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.register(cellType: MessageCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag // 滑动隐藏键盘
        view.addSubview(tableView)
        
        // 设置输入容器
        view.addSubview(inputContainerView)
        
        // 设置输入框
        messageTextView.font = .pingFangFontRegular(ofSize: 14)
        messageTextView.backgroundColor = ThemeManager.current.mediumGrayBGColor
        messageTextView.layer.cornerRadius = CornerRadius.medium.rawValue
        messageTextView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        messageTextView.isScrollEnabled = true
        messageTextView.keyboardDismissMode = .onDrag
        messageTextView.delegate = self
        messageTextView.textColor = ThemeManager.current.titleColor
        messageTextView.tintColor = ThemeManager.current.mainColor
        inputContainerView.addSubview(messageTextView)
        
        // 设置发送按钮
        sendButton.cornerRadius = CornerRadius.medium.rawValue
        sendButton.isEnabled = false
        sendButton.backgroundColor = ThemeManager.current.mainColor
        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = UIFont.pingFangFontBold(ofSize: 14)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)
        
    }
    
    override func setupConstraints() {
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top)
        }
        
        inputContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(swAdaptedValue(64))
            // 使用变量保存底部约束，以便后续调整
            inputBottomConstraint = make.bottom.equalToSuperview().inset(originalBottomInset).constraint
        }
        
        messageTextView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
        }
        
        sendButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.trailing.equalToSuperview().offset(-8)
            make.width.equalTo(60)
        }
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        let content = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        // 清空输入框
        messageTextView.text = ""
        
        sendMessage(content)
    }
    
    func sendMessage(_ msg: String) {
        guard msg.count <= 70 else {
            view.sw_showWarningToast("消息长度不能超过70个字符")
            return
        }
        let timestamp = Date().timeIntervalSince1970
        let sendTime = UInt64(timestamp * 1000)
        let senderId = UserManager.shared.userId
        
        let message = UrgentMessage(id: String(sendTime),
                                    sendId: senderId,
                                    receiverId: "1",
                                    content: msg,
                                    sendTime: DateFormatter.fullPretty.string(from: Date()),
                                    type: 0,
                                    sendUserBaseInfoVO: nil,
                                    receiveUserBaseInfoVO: nil)
        
        if NetworkMonitor.shared.isConnected {
            sendMessage(msg: msg) { success in
                self.addMessageToTable(message)
            }
        }else {
            if let _ = BluetoothManager.shared.connectedPeripheral {
                guard let msgData = MessageGenerator.generateEmergencyNotifySend(senderId: senderId,
                                                                                 timestamp: timestamp,
                                                                                 message: msg) else {
                    return
                }
                view.endEditing(true)
                SWAlertView.showAlert(title: nil, message: "当前无网络连接，通过Mini设备发消息？") {
                    BluetoothManager.shared.sendAppCustomData(msgData)
                    self.addMessageToTable(message)
                }
                
            } else {
                UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
            }
        }
    }
    
    func addMessageToTable(_ message: UrgentMessage) {
        messages.append(message)
        DBManager.shared.insertToDb(objects: [message], intoTable: DBTableName.urgentMessage.rawValue)
        DispatchQueue.main.async {[weak self] in
            self?.tableView.reloadData()
            self?.scrollToBottom(animated: false)
        }
    }
    
    // MARK: - network
    func requestUrgentMessages() async {
        do {
            let rsp = try await NetworkProvider<MessageAPI>().request(.urgentMessages(page: 1, size: 1000))
            let networkResponse = try JSONDecoder().decode(NetworkResponse<UrgentMessageList>.self, from: rsp.data)
            if let messages = networkResponse.data?.list, !messages.isEmpty {
                self.messages = messages.reversed()
                DBManager.shared.insertToDb(objects: self.messages, intoTable: DBTableName.urgentMessage.rawValue)

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: false)
                }
            } else {
                UIWindow.topWindow?.sw_showWarningToast(networkResponse.msg ?? "")
            }
        } catch {
            UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
            print("+++\(error.localizedDescription)")
        }
    }
    
    func sendMessage(msg: String, completion: @escaping (Bool) ->Void) {
        NetworkProvider<MessageAPI>().request(.sendUrgentMessage(msg: msg)) { result in
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<Bool>.self)
                    if networkResponse.isSuccess {
                        completion(true)
                    } else {
                        UIWindow.topWindow?.sw_showWarningToast(networkResponse.msg ?? "")
                        completion(false)
                    }
                } catch {
                    UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                    completion(false)
                }
                
            case .failure(let error):
                UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                completion(false)
            }
        }
    }
}

extension UrgentMessageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MessageCell.self)
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

extension UrgentMessageViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "请输入消息..." {
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "请输入消息..."
            textView.textColor = UIColor.placeholderText
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let hasContent = !(textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        sendButton.isEnabled = hasContent
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            // 回车即发送
            sendButtonTapped()
            return false
        }
        return true
    }
}

extension UrgentMessageViewController: MQTTManagerDelegate {
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == receiveUrgentMessage_sub else {
            return
        }
        do {
            guard let jsonData = message.data(using: .utf8) else {
                return
            }
            // 后端返回的是直接的UrgentMessage对象，不是MQTTResponse包装
            let urgentMessage = try JSONDecoder().decode(UrgentMessage.self, from: jsonData)
            addMessageToTable(urgentMessage)
        } catch {
            debugPrint("[JSON解析] 解析失败: \(error)")
        }
    }
}


// MARK: - Keyboard Handling

extension UrgentMessageViewController: UIGestureRecognizerDelegate {
    
    /// 注册键盘通知
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    /// 移除键盘通知
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillShowNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIResponder.keyboardWillHideNotification,
                                                  object: nil)
    }
    
    /// 键盘将要显示的处理方法
    @objc private func keyboardWillShow(notification: Notification) {
        guard messageTextView.isFirstResponder else {
            return
        }
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        // 计算键盘高度
        let keyboardHeight = keyboardFrame.height
        
        // 调整inputBottomView的底部约束
        inputBottomConstraint?.update(inset: keyboardHeight)
        
        // 使用与键盘相同的动画参数更新约束
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve)) {
            self.view.layoutIfNeeded()
        }
    }
    
    /// 键盘将要隐藏的处理方法
    @objc private func keyboardWillHide(notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        // 恢复inputBottomView的原始底部约束
        inputBottomConstraint?.update(inset: originalBottomInset)
        
        // 使用与键盘相同的动画参数更新约束
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve)) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupTapGestureToDismissKeyboard() {
        // 创建点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // 设置点击手势的委托，以便在某些情况下不触发（比如点击了按钮）
        tapGesture.delegate = self
        // 添加手势到视图
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        // 收起键盘
        view.endEditing(true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 如果点击的是按钮或其他需要交互的控件，不触发收起键盘的手势
        return !(touch.view is UIButton || touch.view is UIScrollView)
    }
}

extension UrgentMessageViewController {
    
    // MARK: - 窄带设备自定义消息

    @objc private func receiveDeviceCustomMessage(_ notification: Notification) {
        guard let data = notification.userInfo?["data"] as? Data else {
            return
        }
        
        if let deviceMessage = parseDeviceCustomMessage(data) {
            addMessageToTable(deviceMessage)
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
            nickname = (UserManager.shared.emergencyContact?.name ?? UserManager.shared.emergencyContact?.phone) ?? "紧急联系人"
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
