//
//  ConvViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import SnapKit
import SWTheme
import SWKit

class ConvViewController: BaseViewController {
    var tableView: UITableView!
    
//    private var messages: [Message] = []
    private var messages: [NoticeItem] = []
    
    private let inputContainerView = UIView()
    private let messageInputTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    
    private var userId: String = UserManager.shared.userId
    private var homeCache: SWCache?
    
    var latestMessage: NewMessageModel?
    
    var noticeReponse: NoticeModel = NoticeModel(totalCount: 0, safeCount: 0, sosCount: 0, weatherCount: 0, safeList: [], sosList: [], weatherList: [])
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        title = otherUser.name
        view.backgroundColor = ThemeManager.current.backgroundColor
        setupTableView()
        setupCaches()
        loadCacheData()
    }
    
    private func setupTableView() {
        // 初始化 tableView
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        tableView.register(cellType: MessageCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.keyboardDismissMode = .onDrag // 滑动隐藏键盘
        view.addSubview(tableView)
        
        // 设置输入容器
        inputContainerView.backgroundColor = UIColor.systemGray6
        inputContainerView.layer.cornerRadius = 16
        inputContainerView.clipsToBounds = true
        view.addSubview(inputContainerView)
        
        // 设置输入框
        messageInputTextView.font = UIFont.systemFont(ofSize: 16)
        messageInputTextView.text = "请输入消息..."
        messageInputTextView.textColor = UIColor.placeholderText
        messageInputTextView.layer.cornerRadius = 12
        messageInputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        messageInputTextView.isScrollEnabled = false
        messageInputTextView.delegate = self
        inputContainerView.addSubview(messageInputTextView)
        
        // 设置发送按钮
        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.backgroundColor = UIColor.systemBlue
        sendButton.layer.cornerRadius = 12
        sendButton.isEnabled = false // 初始禁用
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        inputContainerView.addSubview(sendButton)
        
        // 布局
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top).offset(-8)
        }
        
        inputContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
            make.height.equalTo(50)
        }
        
        messageInputTextView.snp.makeConstraints { make in
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardHeight = keyboardFrame.height
        tableView.contentInset.bottom = keyboardHeight + 64 // 64 = inputContainer高度 + 间距
        tableView.scrollIndicatorInsets.bottom = keyboardHeight + 64
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset.bottom = 0
        tableView.scrollIndicatorInsets.bottom = 0
    }
    
    @objc private func sendButtonTapped() {
            let content = messageInputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty, content != "请输入消息..." else { return }
            
            // 创建新消息
//            let newMessage = Message(id: "6", content: content, sender: currentUser, timestamp: Date())
        
//            messages.append(newMessage)
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: true)
            
            // 清空输入框
            messageInputTextView.text = ""
            messageInputTextView.textColor = UIColor.placeholderText
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        }
    
}

extension ConvViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MessageCell.self)
//        cell.configure(with: messages[indexPath.row])
        return cell
    }
}

extension ConvViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "请输入消息..." {
            textView.text = ""
            textView.textColor = .label
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
        sendButton.backgroundColor = hasContent ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.5)
        
        // 自动调整高度（可选，本例固定高度）
        // 如果需要动态高度，可监听 contentSize 并更新约束
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


extension ConvViewController {
    
    // MARK: - Cache
    
    private func setupCaches() {
        do {
            homeCache = try SWCache(dirName: CacheModuleName.home.module)
        } catch {
            print("❌ SWCache 创建失败: \(error)")
            print("错误详情: \(error.localizedDescription)")
        }
    }
    
    @MainActor private func loadCacheData() {
        // 加载最新消息缓存
        loadCacheValue(forKey: getLatestMessageSubscribeTopic()) { [weak self] (data: Data?) in
            guard let self = self, let data = data else { return }
            self.latestMessage = try? JSONDecoder().decode(NewMessageModel.self, from: data)
            self.updateNoticeList()
        }
        
        // 加载通知列表缓存
        loadCacheValue(forKey: getNoticeListSubscribeTopic()) { [weak self] (data: Data?) in
            guard let self = self, let data = data else { return }
            if let reponse = try? JSONDecoder().decode(NoticeModel.self, from: data) {
                self.noticeReponse = reponse
            }
            self.updateNoticeList()
        }
    }
    
    private func loadCacheValue(forKey key: String,completion: @escaping (Data?) -> Void) {
        guard let cache = homeCache else {
            completion(nil)
            return
        }
        
        cache.value(forKey: key) { result in
            switch result {
            case .success(let cacheResult):
                switch cacheResult {
                case .memory(let data), .disk(let data):
                    completion(data)
                case .none:
                    print("没有缓存数据 for key: \(key)")
                    completion(nil)
                }
            case .failure(let error):
                print("❌ 加载缓存失败 for key: \(key): \(error)")
                completion(nil)
            }
        }
    }
    
    private func updateNoticeList() {

        // 根据选中类型获取对应的通知列表
        var filteredNotices = noticeReponse.allNotices
        
        // 处理最新消息，声明为可选类型
        var latestNotice: NoticeItem?
        if let latestMessage = latestMessage {
            latestNotice = NoticeItem(noticeId: nil,
                                         noticeType: 4,
                                         noticeContent: latestMessage.message,
                                         reportId: latestMessage.sendId,
                                         noticeTime: latestMessage.sendTime)
        }
        
        
        
        // 按noticeTime降序排序
        filteredNotices.sort { item1, item2 in
            guard let time1 = item1.noticeTime else { return false }  // 没有时间的排在后面
            guard let time2 = item2.noticeTime else { return true }   // 有时间的排在前面
            return time1 < time2  // 降序排序（时间大的排前面）
        }
        
        if let latestNotice = latestNotice {
            filteredNotices.append(latestNotice)
        }
        
        messages = filteredNotices
        
        // 在主线程更新UI
        DispatchQueue.main.async {
            self.tableView.reloadData()
            
            DispatchQueue.mp_asyncAfter(0.1) {
                let count = self.tableView(self.tableView, numberOfRowsInSection: 0)
                guard count > 0 else {
                    return
                }
                self.tableView.scrollToRow(at: IndexPath(row: count - 1, section: 0), at: .bottom, animated: false)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getNoticeListSubscribeTopic() -> String {
        return "txts/home/servertoapp/notice/list/" + userId
    }

    private func getLatestMessageSubscribeTopic() -> String {
        return "txts/home/servertoapp/urgentMessage/latest/" + userId
    }
}


struct NoticeItem: Codable {
    public let noticeId: String?
    public let noticeType: Int
    public let noticeContent: String?
    public let reportId: String?
    public let noticeTime: Int64?
    
    public init(
        noticeId: String?,
        noticeType: Int,
        noticeContent: String?,
        reportId: String?,
        noticeTime: Int64?
    ) {
        self.noticeId = noticeId
        self.noticeType = noticeType
        self.noticeContent = noticeContent
        self.reportId = reportId
        self.noticeTime = noticeTime
    }
}

struct NewMessageModel: Codable {
    public let message: String?
    public let sendTime: Int64?
    public let sendId: String?
}

 struct NoticeModel: Codable {
    public let totalCount: Int
    public let safeCount: Int
    public let sosCount: Int
    public let weatherCount: Int
    public let safeList: [NoticeItem]
    public let sosList: [NoticeItem]
    public let weatherList: [NoticeItem]
    
    public init(
        totalCount: Int,
        safeCount: Int,
        sosCount: Int,
        weatherCount: Int,
        safeList: [NoticeItem],
        sosList: [NoticeItem],
        weatherList: [NoticeItem]
    ) {
        self.totalCount = totalCount
        self.safeCount = safeCount
        self.sosCount = sosCount
        self.weatherCount = weatherCount
        self.safeList = safeList
        self.sosList = sosList
        self.weatherList = weatherList
    }
    
    // 获取所有通知列表
    public var allNotices: [NoticeItem] {
        return sosList + safeList + weatherList
    }
}
