//
//  ConvViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import CoreLocation
import TXKit
import SnapKit
import SWTheme
import SWKit

class ConvViewController: BaseViewController {
    var onCurrentConversationLatestMessageDidChangedHandler: (() -> Void)?
    
    private var viewModel: ConvViewModel!
    private var isLoadingMore = false
    // 用于保存inputBottomView的底部约束，以便动态调整
    private var inputBottomConstraint: Constraint?
    // 保存messageTextView的高度约束，以便动态调整
    private var textViewHeightConstraint: Constraint?
    // 保存templateView的顶部约束，以便动态调整
    private var templateViewHeightConstraint: Constraint?

    // 保存原始的底部内边距
    private let originalBottomInset = ScreenUtil.safeAreaBottom

    // TextView 高度限制
    private let minTextViewHeight: CGFloat = swAdaptedValue(20)
    private let maxTextViewHeight: CGFloat = swAdaptedValue(100)

    // templateView 是否显示
    private var isTemplateViewVisible = false

    // 保存上次的滚动位置，用于判断滚动方向
    private var lastScrollOffsetY: CGFloat = 0
    private var isScrollingUp = false
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = ThemeManager.current.mediumGrayBGColor
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInset = UIEdgeInsets(top: Layout.vMargin, left: 0, bottom: 0, right: 0)
        tableView.register(cellType: TxtMessageCell.self)
        tableView.register(cellType: LocationMessageCell.self)
        return tableView
    }()
    
    private let bottomView: UIView = {
        let bottomView = UIView()
        bottomView.backgroundColor = .white
        return bottomView
    }()
    
    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeManager.current.mediumGrayBGColor
        view.cornerRadius = CornerRadius.medium.rawValue
        return view
    }()

    private let messageTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.textColor = ThemeManager.current.titleColor
        textView.font = .pingFangFontRegular(ofSize: 14)
        textView.contentInset = .zero
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.tintColor = ThemeManager.current.mainColor
        return textView
    }()

    private let templateButton: UIButton = {
        let button = UIButton()
        button.setImage(MessageModule.image(named: "message_template_icon"), for: .normal)
        return button
    }()

    private let sendButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.mainColor
        button.setTitle("发送", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.pingFangFontMedium(ofSize: 14)
        button.cornerRadius = CornerRadius.medium.rawValue
        return button
    }()

    private let locationButton: UIButton = {
        let button = UIButton()
        button.setImage(MessageModule.image(named: "message_location"), for: .normal)
        return button
    }()

    private let placeHolderLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 14)
        label.text = "请输入/选择模版（70字符）"
        label.textColor = ThemeManager.current.placeholderColor
        return label
    }()

    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.setTitle(viewModel.conversation.name)
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    private lazy var templateView: TemplateView = {
        let templates = ["车辆抛锚，请求救援。急需饮水、食物、医疗包。",
                         "灾害致人受伤，急需医疗急救、饮用水、食物。情况危急，请求速援！",
                         "人员被困，车辆受损。急需医疗救助、饮水食物、车辆拖拽。"]
        let templateView = TemplateView(templates: templates)
        templateView.backgroundColor = ThemeManager.current.mediumGrayBGColor
        templateView.onSelectedHandler = { [weak self] template in
            self?.messageTextView.text = template
            self?.textViewValueDidChanged()
        }
        return templateView
    }()
    
    private lazy var disableLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "SOS报警状态已关闭，不能继续发消息"
        label.textColor = ThemeManager.current.placeholderColor
        label.font = .pingFangFontRegular(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Life Cycle
    init(conversation: Conversation) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = ConvViewModel(conversation: conversation)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.loadPage()
        if viewModel.sendMessageForbidden() {
            switchDisableSendMessageState()
        } else {
            // 注册键盘通知
            registerKeyboardNotifications()
            setupTapGestureToDismissKeyboard()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let rightImgIcon = BluetoothManager.shared.connectedPeripheral == nil ? "device_mini_unlink" : "device_mini_linked"
        navigationBar.setRightButtons(images: [MessageModule.image(named: rightImgIcon)]) { [weak self] index in
            self?.view.endEditing(true)
            SWRouter.handle(RouteTable.bindDevicePageUrl, parameters:["selectedIndex" : "0"])
        }
    }
    
    // MARK: - Override
    
    override var hasNavBar: Bool {
        return false
    }
    
    override func setupViews() {
        // - Main Views
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        view.addSubview(templateView)
        view.addSubview(bottomView)
        view.addSubview(disableLabel)

        // - Bottom View Subviews
        bottomView.addSubview(locationButton)
        bottomView.addSubview(sendButton)
        bottomView.addSubview(inputContainerView)

        // - Input Container Subviews
        inputContainerView.addSubview(messageTextView)
        inputContainerView.addSubview(templateButton)
        inputContainerView.addSubview(placeHolderLabel)

        // - Delegates & Actions
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        messageTextView.delegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = ThemeManager.current.mainColor
        refreshControl.addTarget(self, action: #selector(loadHistory), for: .valueChanged)
        tableView.refreshControl = refreshControl

        templateButton.addTarget(self, action: #selector(templateButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        
        if viewModel.sendMessageForbidden() {
            switchDisableSendMessageState()
        }
    }
    
    override func setupConstraints() {
        // - Main Views Constraints

        // Navigation Bar
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }

        // Table View
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }

        // Template View
        templateView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            templateViewHeightConstraint = make.height.equalTo(0).constraint
        }

        // Bottom View
        bottomView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            inputBottomConstraint = make.bottom.equalToSuperview().inset(originalBottomInset).constraint
        }
        
        disableLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(56))
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().inset(originalBottomInset)
        }

        // - Bottom View Subviews Constraints

        // Location Button
        locationButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: swAdaptedValue(24), height: swAdaptedValue(24)))
            make.centerY.equalTo(inputContainerView)
            make.leading.equalToSuperview().inset(Layout.hMargin)
        }

        // Send Button
        sendButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: swAdaptedValue(52), height: swAdaptedValue(40)))
            make.centerY.equalTo(inputContainerView)
            make.trailing.equalToSuperview().inset(Layout.hMargin)
        }

        // Input Container View
        inputContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.hSpacing)
            make.leading.equalTo(locationButton.snp.trailing).offset(Layout.hSpacing)
            make.trailing.equalTo(sendButton.snp.leading).offset(-Layout.hSpacing)
        }

        // - Input Container Subviews Constraints

        // Message Text View
        messageTextView.snp.makeConstraints { make in
            textViewHeightConstraint = make.height.equalTo(minTextViewHeight).constraint
            make.top.bottom.equalToSuperview().inset(swAdaptedValue(10))
            make.leading.equalToSuperview().offset(Layout.hInset)
            make.trailing.equalTo(templateButton.snp.leading)
        }

        // Template Button
        templateButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: swAdaptedValue(36), height: swAdaptedValue(36)))
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }

        // Placeholder Label
        placeHolderLabel.snp.makeConstraints { make in
            make.left.centerY.equalTo(messageTextView)
        }
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
        //会话列表
        bindPublisher(viewModel.$messageList.eraseToAnyPublisher()) { [weak self] _ in
            self?.tableView.reloadData()
        }
        //加载完数据
        bindPublisher(viewModel.$didLoadPage.eraseToAnyPublisher()) { [weak self] res in
            if res {
                self?.scrollToBottom(animated: false)
                /**
                 服务中心首次加载，需要同步会话列表latestMessage
                 服务中心本地创建的，不是会话列表接口返回的, 所以会话列表的服务中心最开始没有latestMessage，这里主动去补全
                 */
                if self?.viewModel.conversation.id == MessageManager.serviceConversationId {
                    self?.onCurrentConversationLatestMessageDidChangedHandler?()
                }
            }
        }
        //发送完消息
        bindPublisher(viewModel.$didSendMessage.eraseToAnyPublisher()) { [weak self] res in
            self?.messageTextView.text = nil
            self?.textViewValueDidChanged()
            if res {
                self?.scrollToBottom(animated: true)
            }
            self?.onCurrentConversationLatestMessageDidChangedHandler?()
        }
        //接收到消息
        bindPublisher(viewModel.$didReceiveMessage.eraseToAnyPublisher()) { [weak self] _ in
            // 延迟执行，等待 tableView 完成布局
            DispatchQueue.main.async {
                // 只有在底部时才滚动
                if self?.isTableViewAtBottom() == true {
                    self?.scrollToBottom(animated: true)
                }
            }
        }
    }
    
    // MARK: - Actions

    @objc private func loadHistory() {
        if isLoadingMore {
            tableView.refreshControl?.endRefreshing()
            return
        }
        
        isLoadingMore = true
        
        _Concurrency.Task {
            await viewModel.loadHistory()
            isLoadingMore = false
            
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
                if self.viewModel.hasMoreData == false {
                    self.tableView.refreshControl = nil
                }
            }
        }
    }

    @objc private func templateButtonTapped() {
        if isTemplateViewVisible {
            hideTemplateView()
        } else {
            // 如果键盘弹起，先收起键盘
            if messageTextView.isFirstResponder {
                messageTextView.resignFirstResponder()
                DispatchQueue.mp_asyncAfter(0.2) {
                    self.showTemplateView()
                }
            } else {
                showTemplateView()
            }
        }
    }

    /// 显示 templateView
    private func showTemplateView() {
        guard !isTemplateViewVisible else { return }
        isTemplateViewVisible = true

        // 更新约束，显示 templateView
        templateViewHeightConstraint?.update(offset: swAdaptedValue(160) + originalBottomInset)
        inputBottomConstraint?.update(inset: swAdaptedValue(160) + originalBottomInset)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: true)
        }
    }

    /// 隐藏 templateView
    private func hideTemplateView() {
        guard isTemplateViewVisible else { return }
        isTemplateViewVisible = false

        // 更新约束，隐藏 templateView
        templateViewHeightConstraint?.update(offset: 0)
        inputBottomConstraint?.update(inset: originalBottomInset)

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func sendButtonTapped() {
        let content = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard content.count <= 70 else {
            view.sw_showWarningToast("消息长度不能超过70个字符")
            return
        }
        guard let message = MessageManager.generateTxtMessage(convId: viewModel.conversation.id, content: content) else {
            return
        }
        sendMessage(message)
    }
    
    @objc private func locationButtonTapped() {
        let vc = ChoosePOIAddressViewController()
        vc.onSelectedAddressHandler = { address in
            guard let message = MessageManager.generateLocationMessage(convId: self.viewModel.conversation.id, address: address) else {
                return
            }
            self.sendMessage(message)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func scrollToBottom(animated: Bool) {
        DispatchQueue.main.async {
            let rows = self.tableView.numberOfRows(inSection: 0)
            guard rows > 0 else { return }
            
            let lastIndexPath = IndexPath(row: rows - 1, section: 0)
            self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
        }
    }
    
    //MARK: - Message
    
    func sendMessage(_ message: Message) {
        if viewModel.sendMessageForbidden() {
            switchDisableSendMessageState()
            return
        }

        viewModel.sendMessage(message)
    }
    
    private func switchDisableSendMessageState() {
        bottomView.isHidden = true
        disableLabel.isHidden = false
    }
    
    // MARK: - Helper Methods

    /// 判断 tableView 是否滚动到底部
    private func isTableViewAtBottom() -> Bool {
        let contentHeight = tableView.contentSize.height
        let height = tableView.bounds.height
        let offset = tableView.contentOffset.y

        // contentInset.top 不影响最大 offset，只影响起始位置
        // 最大 offset = contentHeight - height + contentInset.bottom
        let maxOffset = contentHeight - height + tableView.contentInset.bottom

        // 允许 150pt 的误差
        let threshold: CGFloat = 150
        return offset >= (maxOffset - threshold)
    }
}

// MARK: - UITableViewDelegate

extension ConvViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var message = viewModel.messageList[indexPath.row]
        let previousTimestamp = indexPath.row > 0 ? viewModel.messageList[indexPath.row - 1].sendTimeTimestamp : nil
        message.previousMessageTimestamp = previousTimestamp

        // 根据消息类型选择cell
        let cell: MessageCell
        if message.messageType == .location {
            cell = tableView.dequeueReusableCell(for: indexPath, cellType: LocationMessageCell.self)
            
            let locCell = cell as! LocationMessageCell
            locCell.onLocationTapHandler = { [weak self] in
                if let data = self?.viewModel.covertToAroundPOIData(message.location) {
                    self?.navigationController?.pushViewController(ShowPOIAddressViewController(aroundPOIData: data), animated: true)
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(for: indexPath, cellType: TxtMessageCell.self)
        }
        cell.configure(message: message)

        // 设置重发回调
        cell.onReSendHandler = { [weak self] in
            SWAlertView.showAlert(message: "消息发送失败，是否继续发送？") {
                message.sendTimeTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
                self?.sendMessage(message)
            }
        }
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 判断是否向上滚动
        let currentOffsetY = tableView.contentOffset.y
        isScrollingUp = currentOffsetY < lastScrollOffsetY
        lastScrollOffsetY = currentOffsetY
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension ConvViewController: UITableViewDataSourcePrefetching {

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard isScrollingUp else {
            return
        }

        // 判断 indexPaths 是否包含 lastMessageId 对应的消息
        guard let lastMessageId = viewModel.lastMessageId,
              let lastMessageIndex = viewModel.messageList.firstIndex(where: { $0.id == lastMessageId }),
              indexPaths.contains(where: { $0.row == lastMessageIndex }) else {
            return
        }

        // 满足条件：向上滚动且预加载包含 lastMessageId 的消息
        if viewModel.queryNotSyncOfflineMessages().count > 0 || viewModel.hasSyncLatestServerMessage == false {
            loadHistory()
        }
    }
}

extension ConvViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textViewValueDidChanged()
    }
    
    private func textViewValueDidChanged() {
        placeHolderLabel.isHidden = !messageTextView.text.isEmpty
        adjustTextViewHeight()
    }

    /// 调整 TextView 高度
    private func adjustTextViewHeight() {
        // 计算内容高度
        let contentSize = messageTextView.sizeThatFits(CGSize(width: messageTextView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        let targetHeight = contentSize.height

        // 限制在最小和最大高度之间
        let newHeight = max(minTextViewHeight, min(maxTextViewHeight, targetHeight))

        // 更新高度约束
        textViewHeightConstraint?.update(offset: newHeight)

        // 平滑动画更新布局
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }

        // 更新 TextView 的滚动能力
        messageTextView.isScrollEnabled = newHeight >= maxTextViewHeight
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


// MARK: - Keyboard Handling

extension ConvViewController: UIGestureRecognizerDelegate {
    
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

        // 如果 templateView 显示中，先隐藏
        if isTemplateViewVisible {
            hideTemplateView()
        }

        // 计算键盘高度
        let keyboardHeight = keyboardFrame.height
        
        // 调整inputBottomView的底部约束
        self.inputBottomConstraint?.update(inset: keyboardHeight)
        
        // 使用与键盘相同的动画参数更新约束
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve)) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: true)
        }
    }
    
    /// 键盘将要隐藏的处理方法
    @objc private func keyboardWillHide(notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        
        // 恢复inputBottomView的原始底部约束
        self.inputBottomConstraint?.update(inset: self.originalBottomInset)
        
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
        // 收起键盘并隐藏 templateView
        view.endEditing(true)
        hideTemplateView()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 如果点击的是按钮、ScrollView 或 templateView，不触发收起键盘的手势
        return !(touch.view is UIButton || touch.view is UIScrollView || touch.view?.isDescendant(of: templateView) == true)
    }
}

