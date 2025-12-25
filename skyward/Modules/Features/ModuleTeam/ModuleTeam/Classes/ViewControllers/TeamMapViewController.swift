//
//  TeamMapViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import UIKit
import SnapKit
import TangramMap
import TXKit
import SWTheme
import SWKit
import ModuleMap
import ModulePersonal

class TeamMapViewController: BaseViewController {
    
    // MARK: - Properties
    private var conversation: Conversation
    private var viewModel: TeamMapViewModel!
    private let mapManager = MapManager()
    private let bottomDefaultHeight = swAdaptedValue(112)
    private let messageTextView = UITextView()
    private let sendButton = UIButton()
    
    // 用于保存inputBottomView的底部约束，以便动态调整
    private var inputBottomConstraint: Constraint?
    
    // 保存原始的底部内边距
    private let originalBottomInset = ScreenUtil.safeAreaBottom
    
    // MARK: - Initialization
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 指定初始化器，通过conversation构造实例
    public init(conversation: Conversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
        
        // 使用conversation初始化viewModel
        self.viewModel = TeamMapViewModel(conversation: conversation)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 注册键盘通知
        registerKeyboardNotifications()
        setupTapGestureToDismissKeyboard()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            viewModel.disconnect()
            mapManager.reset()
        }
    }
    
    deinit {
        // 移除键盘通知
        removeKeyboardNotifications()
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        view.backgroundColor = ThemeManager.current.backgroundColor
        setupMap()
        view.addSubview(navigationBar)
        view.addSubview(inputBottomView)
        view.addSubview(rightBottomView)
        view.addSubview(tableView)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        inputBottomView.snp.makeConstraints { make in
            make.height.equalTo(bottomDefaultHeight)
            make.left.right.equalToSuperview()
            // 使用变量保存底部约束，以便后续调整
            inputBottomConstraint = make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom).constraint
        }
        
        rightBottomView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(168))
            make.width.equalTo(swAdaptedValue(48))
            make.bottom.equalTo(inputBottomView.snp.top).offset(-24)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        tableView.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(279))
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.bottom.equalTo(inputBottomView.snp.top).offset(-24)
            make.height.equalTo(0)
        }
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
        bindPublisher(viewModel.$messageList.eraseToAnyPublisher()) { [weak self] messages in
            let isReceiveMessage = self?.tableView.numberOfRows(inSection: 0) ?? 0 > 0

            self?.tableView.reloadData()
            
            // 更新表格高度
            self?.updateTableViewHeight(for: messages)
            let lastIndex = messages.count - 1
            if lastIndex > 0 {
                self?.tableView.scrollToRow(at: IndexPath(row: lastIndex, section: 0), at: .bottom, animated: isReceiveMessage)
            }
            // marker
            if isReceiveMessage {
                if let lastMessage = messages.last {
                    self?.addMarkerIfNeed(message: lastMessage)
                }
            } else {
                self?.loadMarkers()
            }
        }
        
        bindPublisher(viewModel.$team.eraseToAnyPublisher()) { [weak self] team in
            let teamName = team?.name ?? ""
            let teamSize = team?.members?.count ?? 0
            self?.navigationBar.setTitle("\(teamName)(\(teamSize))")
        }
    }
    
    // MARK: - UI Components
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        let rightImgIcon = BluetoothManager.shared.connectedPeripheral == nil ? "team_device_unlink" : "team_device_linked"
        let teamName = conversation.name ?? ""
        let teamSize = conversation.teamSize ?? 0
        bar.setTitle("\(teamName)(\(teamSize))")
        
        bar.setLeftBackButton { [weak self] in
            if let vc = self?.navigationController?.viewControllers.first(where: { $0 is MapViewController }) {
                self?.navigationController?.popToViewController(vc, animated: true)
            }else {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        bar.setRightButtons(images: [TeamModule.image(named: rightImgIcon), TeamModule.image(named: "team_map_set")]) { [weak self] index in
            self?.view.endEditing(true)
            if index == 0 {
                if let peripheral = BluetoothManager.shared.connectedPeripheral {
                    let detailVC = MiniDeviceDetailViewController()
                    if let device = MiniDeviceStorageManager.shared.findDeviceByUUID(peripheral.identifier.uuidString) {
                        detailVC.deviceInfo = device
                        self?.navigationController?.pushViewController(detailVC, animated: true)
                    }
                    
                }else {
                    let devicelistVC = DeviceListViewController()
                    self?.navigationController?.pushViewController(devicelistVC, animated: true)
                }
            }
            if index == 1 {
                guard let teamId = self?.conversation.teamId else {
                    return
                }
                let vc = TeamSettingViewController(teamId: teamId)
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        return bar
    }()

    
    private lazy var inputBottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        let getLoactionButton = UIButton()
        getLoactionButton.layer.borderWidth = 1.0
        getLoactionButton.layer.borderColor = ThemeManager.current.separatorColor.cgColor
        getLoactionButton.setTitle("获取位置", for: .normal)
        getLoactionButton.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        getLoactionButton.titleLabel?.font = UIFont.pingFangFontRegular(ofSize: 14)
        getLoactionButton.setImage(TeamModule.image(named: "team_user_location"), for: .normal)
        getLoactionButton.addTarget(self, action: #selector(getLocationButtonTapped), for: .touchUpInside)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Layout.hInset, bottom: 0, trailing: Layout.hInset)
            configuration.background.cornerRadius = swAdaptedValue(16)
            getLoactionButton.configuration = configuration
        } else {
            getLoactionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.hInset, bottom: 0, right: Layout.hInset)
            getLoactionButton.layer.cornerRadius = swAdaptedValue(16)
        }
        view.addSubview(getLoactionButton)
        getLoactionButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(32))
            make.top.equalToSuperview().inset(Layout.hSpacing)
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        // 消息输入视图
        messageTextView.font = .pingFangFontRegular(ofSize: 14)
        messageTextView.backgroundColor = ThemeManager.current.mediumGrayBGColor
        messageTextView.layer.cornerRadius = CornerRadius.medium.rawValue
        messageTextView.textContainerInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        messageTextView.isScrollEnabled = true
        messageTextView.keyboardDismissMode = .onDrag
        messageTextView.delegate = self
        messageTextView.textColor = ThemeManager.current.titleColor
        messageTextView.tintColor = ThemeManager.current.mainColor
        view.addSubview(messageTextView)
        messageTextView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(Layout.hMargin)
            $0.top.equalToSuperview().offset(swAdaptedValue(52))
            $0.bottom.equalToSuperview().offset(-Layout.vInset)
            $0.right.equalToSuperview().offset(-80)
            $0.height.equalTo(48)
        }
        
        // 发送按钮
        sendButton.cornerRadius = CornerRadius.medium.rawValue
        sendButton.isEnabled = false
        sendButton.backgroundColor = UIColor(str: "#FFE0B9")
        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = UIFont.pingFangFontBold(ofSize: 14)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(Layout.hMargin)
            $0.bottom.equalToSuperview().inset(Layout.vInset)
            $0.width.equalTo(swAdaptedValue(52))
            $0.height.equalTo(swAdaptedValue(48))
        }
        return view
    }()
    
    private lazy var rightBottomView: TeamMapRightBottomView = {
        let view = TeamMapRightBottomView()
        view.locationButton.addAction(UIAction {[weak self] _ in
            self?.mapManager.moveToUserLocation()
        }, for: .touchUpInside)
        view.safeButton.addAction(UIAction {[weak self] _ in
            self?.dismissKeyboard()
            ReportManager.report(.safety)
        }, for: .touchUpInside)
        view.sosButton.addAction(UIAction {[weak self] _ in
            self?.dismissKeyboard()
            ReportManager.report(.sos)
        }, for: .touchUpInside)
        return view
    }()
    
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(cellType: TeamMessageCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    private func setupMap() {
        let top = ScreenUtil.statusBarHeight + 44
        let height = ScreenUtil.screenHeight - top - bottomDefaultHeight
        let mapView = mapManager.createMapView(in: self.view, frame: CGRectMake(0, top, ScreenUtil.screenWidth, height))
        view.addSubview(mapView)
        
        // 设置回调
        mapManager.onSceneLoaded = { _ in
            
        }
        
        mapManager.onUserLocationUpdated = { (coordinate, _) in
            print("用户位置更新: \(coordinate.latitude), \(coordinate.longitude)")
        }
        
        mapManager.onMarkerSelected = { [weak self] markerId, data, layerId in
            if let (title, coordinateDes, timeDesc) = self?.viewModel.locationDetailDesc(data: data) {
                self?.showLocationDetailView(title: title, coordinate: coordinateDes, time: timeDesc)
            }
        }
        
        registeMarkerLayers()
    }
    
    // MARK: - Private Methods
    
    /// 更新tableview高度
    private func updateTableViewHeight(for messages: [Message]) {
        let maxHeight = swAdaptedValue(202)
        
        if CGRectGetHeight(tableView.bounds) >= maxHeight {
            return
        }
        
        if messages.isEmpty {
            tableView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        } else {
            // 强制布局以确保所有单元格都被正确计算
            tableView.layoutIfNeeded()
            
            // 计算内容高度
            let contentHeight = tableView.contentSize.height
            let actualHeight = min(contentHeight, maxHeight)
            
            // 更新高度约束
            tableView.snp.updateConstraints { make in
                make.height.equalTo(actualHeight)
            }
        }
        
        // 动画更新约束
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Markers
    func registeMarkerLayers() {
        _ = mapManager.markerLayerManager?.createLayer(id: "sos", name: "sos", isVisible: true)
        _ = mapManager.markerLayerManager?.createLayer(id: "safe", name: "safe", isVisible: true)
        _ = mapManager.markerLayerManager?.createLayer(id: "memberLocation", name: "memberLocation", isVisible: true)
    }
    
    func loadMarkers() {
        // 获取每个成员的最后一条指定类型消息
        let latestMessages = viewModel.getLatestMessagesForEachMember()
        
        // 为每条消息创建并添加标记
        latestMessages.forEach {[weak self] message in
            self?.addMarkerIfNeed(message: message)
        }
    }
    
    func addMarkerIfNeed(message: Message) {
        guard let markerData = viewModel.makeMarkerData(message: message) else {
            return
        }
        // 如果该消息的发送者已经在地图中有marker了（通过markerData.id判断） 则需要更新，即先removeMarker 然后重新addMarkerWithPresetStyle
        if let existingMarker = mapManager.markerLayerManager?.findMarker(for: markerData.id), let layerId = mapManager.markerLayerManager?.findLayerId(for: existingMarker) {
            mapManager.markerLayerManager?.removeMarker(markerData.id, from: layerId)
        }
        if message.messageType == .safety {
            mapManager.markerLayerManager?.addMarkerWithPresetStyle(to: "safe", data: markerData, styleType: .safe)
        } else if message.messageType == .sos {
            mapManager.markerLayerManager?.addMarkerWithPresetStyle(to: "sos", data: markerData, styleType: .sos)
        } else if message.messageType == .location {
            mapManager.markerLayerManager?.addMarkerWithPresetStyle(to: "memberLocation", data: markerData, styleType: .memberLocation)
        }
    }
    
    // MARK: - Actions
    
    @objc private func getLocationButtonTapped() {
        dismissKeyboard()
        view.sw_showLoading()
        viewModel.getMemberList {[weak self] members in
            self?.view.sw_hideLoading()
            guard let members = members else {
                return
            }
            let filterMembers = members.filter({$0.userId != UserManager.shared.userInfo?.id})
            // 创建获取位置视图
            let getLocationView = TeamMemberGetLocationView()
            getLocationView.configure(with: filterMembers)
            
            // 设置关闭回调
            getLocationView.closeHandler = { _ in
                SWPopupView.currentPopup?.dismiss()
            }
            
            getLocationView.getUserLocationHandler = { userId, shortId in
                self?.viewModel.getMemberLocation(userId: userId, shortId: shortId) {
                    
                }
            }
            
            // 设置弹窗视图大小
            getLocationView.snp.makeConstraints {
                $0.width.equalTo(ScreenUtil.screenWidth)
                $0.height.equalTo(ScreenUtil.screenHeight * 0.6)
            }
            
            // 创建并显示弹窗
            SWPopupView.showFromBottom(contentView: getLocationView)
        }
    }
    
    @objc private func sendButtonTapped() {
        guard let message = messageTextView.text, !message.isEmpty else {
            return
        }
        messageTextView.text = nil
        messageTextView.resignFirstResponder()
        // 重置输入框高度
        adjustTextViewHeight()
        // 实现发送消息功能
        viewModel.sendMessage(message)
    }
    
    func showLocationDetailView(title: String, coordinate: String, time: String) {
        let detailView = TeamMemberLocationDetailView()
        detailView.configure(titleDesc: title, coordinateDesc: coordinate, timeDesc: time)
        detailView.snp.makeConstraints {
            $0.width.equalTo(ScreenUtil.screenWidth)
            $0.height.equalTo(3 * swAdaptedValue(56) + ScreenUtil.safeAreaBottom)
        }
        SWPopupView.showFromBottom(contentView: detailView)
    }
    
    private func adjustTextViewHeight() {
        // 计算文本高度
        let fixedWidth = messageTextView.frame.size.width
        let newSize = messageTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        var newFrame = messageTextView.frame
        
        // 限制最大高度为100
        let maxHeight: CGFloat = 100
        newFrame.size = CGSize(width: max(fixedWidth, newSize.width), height: min(maxHeight, newSize.height))
        
        // 更新输入框高度
        messageTextView.snp.updateConstraints {
            $0.height.equalTo(newFrame.size.height)
        }
        
        // 自动滚动到底部
        messageTextView.scrollRangeToVisible(NSRange(location: messageTextView.text.count - 1, length: 0))
    }
}


// MARK: - UITextViewDelegate

extension TeamMapViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if let message = textView.text, !message.isEmpty {
            sendButton.isEnabled = true
            sendButton.backgroundColor = ThemeManager.current.mainColor
        } else {
            sendButton.isEnabled = false
            sendButton.backgroundColor = UIColor(str: "#FFE0B9")
        }
        // 当文本变化时调整高度
        adjustTextViewHeight()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 处理回车键发送消息
        if text == "\n" {
            sendButtonTapped()
            return false
        }
        return true
    }
}


extension TeamMapViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messageList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TeamMessageCell.self)
        let message = viewModel.messageList[indexPath.row]
        cell.configure(with: message)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

// MARK: - Keyboard Handling

extension TeamMapViewController: UIGestureRecognizerDelegate {
    
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
