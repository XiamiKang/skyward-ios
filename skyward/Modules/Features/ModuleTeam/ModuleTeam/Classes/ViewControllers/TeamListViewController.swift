//
//  TeamListViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/3.
//

import SnapKit
import TXKit
import SWKit
import SWTheme
import SWNetwork

class TeamListViewController: BaseViewController {
    
    // MARK: - Properties
    
    public var conversations: [Conversation] = []
    private var currentConversation: Conversation?
    
    // MARK: - Initialization
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(conversations: [Conversation]) {
        super.init(nibName: nil, bundle: nil)
        self.conversations = conversations.sorted { $0.latestMessage?.messageTime ?? 0 > $1.latestMessage?.messageTime ?? 0 }
    }
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MQTT
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: [TeamAPI.convList_sub])
        var params = [String : Any]()
        params["requestId"] = Int(Date().timeIntervalSince1970)
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.convList_pub, qos:.qos1)
        }
        
        // 通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveTeamNewMessage(_:)),
            name: .receiveTeamNewMessage,
            object: nil
        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            MQTTManager.shared.removeDelegate(self)
            MQTTManager.shared.unsubscribe(from: [TeamAPI.convList_sub])
        }
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
    }
    
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("队伍")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        bar.setRightButtons(images: [TeamModule.image(named: "team_navi_add")]) { [weak self] index in
            let vc = TeamCreateViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        }
        return bar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(cellType: TeamListCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    // MARK: - Notification
    
    @objc private func receiveTeamNewMessage(_ notification: Notification) {
        guard notification.object is Message else {
            return
        }
        conversations = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self) ?? []
        // 如果当前在会话页，要过滤掉当前会话的unreadCount
        if let conv = currentConversation,  let index = conversations.firstIndex(where: { $0.id == conv.id}) {
            self.conversations[index].unreadCount = 0
        }
        
        Task {
            await MainActor.run {
                self.tableView.reloadData()
            }
        }
    }
    
}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension TeamListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TeamListCell.self)
        let conversation = conversations[indexPath.row]
        cell.configure(with: conversation)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(88)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 更新数组中的原始对象，而不是副本
        var conversation = conversations[indexPath.row]
        if let unreadCount = conversation.unreadCount, unreadCount > 0 {
            conversation.unreadCount = 0
            conversations[indexPath.row] = conversation
            tableView.reloadRows(at: [indexPath], with: .none)
            // 用户进入会话视图，重置未读消息数为0 同步数据库
            DBManager.shared.insertToDb(objects: [conversation], intoTable: DBTableName.conversation.rawValue)
        }
        currentConversation = conversation
        let vc = TeamMapViewController(conversation: conversation)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - MQTTManagerDelegate

extension TeamListViewController: MQTTManagerDelegate {
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == TeamAPI.convList_sub else { return }
        do {
            guard let jsonData = message.data(using: .utf8) else {
                return
            }
            let rsp = try JSONDecoder().decode(MQTTResponse<[Conversation]>.self, from: jsonData)
            
            if let conversations = rsp.data, !conversations.isEmpty {
                // 同步未读消息数到新的会话列表
                let updatedConversations = conversations.map { newConversation -> Conversation in
                    var updatedConversation = newConversation
                    // 在旧会话列表中查找相同id的会话
                    if let oldConversation = self.conversations.first(where: { $0.id == newConversation.id }) {
                        // 同步未读消息数
                        updatedConversation.unreadCount = oldConversation.unreadCount
                    }
                    return updatedConversation
                }
                
                DBManager.shared.insertToDb(objects: updatedConversations, intoTable: DBTableName.conversation.rawValue)
                self.conversations = updatedConversations
                DispatchQueue.main.async {[weak self] in
                    self?.tableView.reloadData()
                }
            }
        } catch {
            print("[JSON解析] 解析失败: \(error)")
        }
    }
}
