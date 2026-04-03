//
//  HomeViewController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme
import SnapKit
import TangramMap
import ModuleMap
import SWNetwork

public class HomeViewController: BaseViewController, MapViewDelegate, SOSButtonDelegate {

    var viewModel = HomeViewModel()
    private let mapManager = MapManager()
    
    // MARK: - UI Components
    private let miniDeviceCardView: DeviceCardView = {
        let deviceCard = DeviceCardView()
        deviceCard.deviceName = "添加行者mini"
        return deviceCard
    }()
    
    private let proDeviceCardView: DeviceCardView = {
        let deviceCard = DeviceCardView()
        deviceCard.deviceName = "添加行者Pro"
        return deviceCard
    }()
    
    // 添加信号预警视图
    private let weakSignalAlertView: WeakSignalAlertView = {
        let alertView = WeakSignalAlertView()
        alertView.isHidden = true
        return alertView
    }()
    
    // 添加高度约束的引用
    private var weakSignalAlertViewHeightConstraint: Constraint?
    
    private let mapContianerView = HomeMapView()
    private var mapView = TGMapView()
    private let mapHeight = (ScreenUtil.screenWidth-32)/343*150
    private let centerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "服务中心消息"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = ThemeManager.current.titleColor
        return label
    }()
    
    private let clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(HomeModule.image(named: "home_clean_icon"), for: .normal)
        button.setTitle("清除", for: .normal)
        button.setTitleColor(ThemeManager.current.textColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        return button
    }()
    
    private let reportSafetyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("报平安", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = ThemeManager.current.successColor
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        return button
    }()
    
    private lazy var sosButton: SOSButton = {
        let button = SOSButton()
        // 长按开始时的回调
        button.startLongPanAction = { [weak self] isInSOS in
            guard let self = self else { return }
            // 显示圆弧进度视图并设置类型
            self.arcProgressView.show(animated: true)
            self.arcProgressView.type = isInSOS ? .close : .open
        }
        
        // 同步进度
        button.progressUpdateHandler = { [weak self] progress in
            guard let self = self else { return }
            self.arcProgressView.updateProgressFromExternal(progress)
            
            // 进度完成后延迟隐藏
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.arcProgressView.hideAndReset()
                }
            }
        }
        
        // 长按取消时的回调（松手时触发）
        button.longPressCancelHandler = { [weak self] in
            guard let self = self else { return }
            // 立即隐藏圆弧进度视图
            self.arcProgressView.hideAndReset(animated: true)
        }
        return button
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.estimatedItemSize = CGSize(width: 55, height: 24)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(HomeMessageCell.self, forCellReuseIdentifier: "HomeMessageCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    private lazy var emptyView: SWBlankView = {
        let view = SWBlankView(title: "暂无消息")
        view.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        return view
    }()

    private let arcProgressView = ArcProgressView()
    
    // MARK: - Override
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.current.backgroundColor
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HomeMessageTabCell.self, forCellWithReuseIdentifier: "MessageTabCell")
        
        // 设置 mapView 代理
        mapContianerView.delegate = self
        mapContianerView.weatherInfoView.isHidden = true
        
        // 设置tableView的代理和数据源
        tableView.delegate = self
        tableView.dataSource = self
        
        sosButton.delegate = self
        
        setupActions()
        
        setupNotifications()
        
        bindEmergency()
        
        // 检查SOS状态
        if SOSManager.shared.checkUserSOSState() {
            SOSManager.shared.showSOSIndicator()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                SOSAlertView().showInWindow()
            }
        }
        
        // 创建圆弧进度条
        arcProgressView.frame = CGRect(x: 0, y: 0, width: 136, height: 136)
        arcProgressView.center = view.center
        view.addSubview(arcProgressView)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapManager.loadMapWithCurrentTileSource()
        DangerZoneMonitor.shared.startMonitoring(threshold: 20.0)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DangerZoneMonitor.shared.stopMonitoring()
    }
    
    override public func setupViews() {
        super.setupViews()
        
        view.addSubview(miniDeviceCardView)
        view.addSubview(proDeviceCardView)
        view.addSubview(weakSignalAlertView) // 添加信号预警视图
        view.addSubview(mapContianerView)
        view.addSubview(centerTitleLabel)
        view.addSubview(clearButton)
        view.addSubview(tableView)
        view.addSubview(reportSafetyButton)
        view.addSubview(sosButton)
        
        mapView = mapManager.createMapView(in: mapContianerView, frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        mapContianerView.addSubview(mapView)
        mapContianerView.sendSubviewToBack(mapView)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        miniDeviceCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenUtil.statusBarHeight + 10)
            make.leading.equalToSuperview().inset(Layout.hMargin)
            make.trailing.equalToSuperview().dividedBy(2).offset(-6)
            make.height.equalTo(44)
        }
        
        proDeviceCardView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(ScreenUtil.statusBarHeight + 10)
            make.leading.equalTo(view.snp.centerX).offset(6)
            make.trailing.equalToSuperview().inset(Layout.hMargin)
            make.height.equalTo(44)
        }
        
        weakSignalAlertView.snp.makeConstraints { make in
            make.top.equalTo(miniDeviceCardView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            weakSignalAlertViewHeightConstraint = make.height.equalTo(0).constraint
        }
        
        mapContianerView.snp.makeConstraints { make in
            make.top.equalTo(weakSignalAlertView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(mapHeight)
        }
        
        centerTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(mapContianerView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        clearButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(30))
            make.centerY.equalTo(centerTitleLabel)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(reportSafetyButton.snp.top).offset(-12)
        }
        
        reportSafetyButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().dividedBy(2).offset(-6)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(54)
        }
        
        sosButton.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.centerX).offset(6)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(54)
        }
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
        //通知分类
        bindPublisher(viewModel.$noticeTypeItems.eraseToAnyPublisher()) { [weak self] _ in
            self?.collectionView.reloadData()
        }
        //通知列表
        bindPublisher(viewModel.$noticeList.eraseToAnyPublisher()) { [weak self] noticeList in
            self?.emptyView.isHidden = noticeList.count > 0
            self?.tableView.reloadData()
        }
        // 天气
        bindPublisher(viewModel.$weatherInfo.eraseToAnyPublisher()) { [weak self] weatherInfo in
            if let weatherInfo = weatherInfo {
                self?.mapContianerView.weatherInfoView.isHidden = false
                
                if let icon = weatherInfo.icon {
                    self?.mapContianerView.setWeatherIcon(SWKitModule.image(named: icon))
                }
                
                let district = weatherInfo.district ?? "--"
                let text = weatherInfo.text ?? "--"
                let temp = weatherInfo.temp ?? "--"
                self?.mapContianerView.setWeatherText(district + " " + text + " " + temp + "℃")
            } else {
                self?.mapContianerView.weatherInfoView.isHidden = true
            }
        }
        // 窄带卡片信息
        bindPublisher(viewModel.$selectedMiniDevice.eraseToAnyPublisher()) { [weak self] selectedMiniDevice in
            self?.miniDeviceCardView.hasDevice = true
            self?.miniDeviceCardView.deviceName = selectedMiniDevice?.info.name ?? "行者mini"
            
            if let connected = selectedMiniDevice?.connected, connected == true {
                self?.miniDeviceCardView.isConnected = true
                self?.miniDeviceCardView.connectionIcon = HomeModule.image(named: "device_bluetooth_linked")
                self?.miniDeviceCardView.satelliteIcon = HomeModule.image(named: "device_mini_line_satellite0")
            } else {
                self?.miniDeviceCardView.isConnected = false
                self?.miniDeviceCardView.connectionIcon = HomeModule.image(named: "device_bluetooth_unlink")
                self?.miniDeviceCardView.satelliteIcon = HomeModule.image(named: "device_mini_line_satellite0")
            }
        }
        // 宽带卡片信息
        bindPublisher(viewModel.$selectedProDevice.eraseToAnyPublisher()) { [weak self] selectedProDevice in
            self?.proDeviceCardView.hasDevice = true
            self?.proDeviceCardView.deviceName = selectedProDevice?.nickname ?? "行者pro"
            
            if let connected = selectedProDevice?.isConnected, connected == true {
                self?.proDeviceCardView.isConnected = true
                self?.proDeviceCardView.connectionIcon = HomeModule.image(named: "device_wifi_linked")
                self?.proDeviceCardView.satelliteIcon = HomeModule.image(named: "device_satellite_linked")
            } else {
                self?.proDeviceCardView.isConnected = false
                self?.proDeviceCardView.connectionIcon = nil
                self?.proDeviceCardView.satelliteIcon = nil
            }
        }
        
        viewModel.setupDevice()
    }
    
    // MARK: - Actions
    private func setupActions() {
        miniDeviceCardView.onTap = { [weak self] in
            self?.selectMiniDevice()
        }
        
        proDeviceCardView.onTap = { [weak self] in
            self?.selectProDevice()
        }
        
        reportSafetyButton.addAction(UIAction { [weak self] _ in
            if SOSManager.shared.checkUserSOSState() {
                self?.view.sw_showWarningToast("当前处于SOS不可以报平安")
            }else {
                ReportManager.report(.safety)
            }
        }, for: .touchUpInside)
        
        clearButton.addAction(UIAction { [weak self] _ in
            guard self?.viewModel.noticeList.isEmpty == false else {
                self?.view.sw_showWarningToast("当前无可清除消息")
                return
            }
            SWAlertView.showAlert(title: "确定清除所有消息吗？", message: nil) {
                self?.viewModel.cleanMessage()
            }
        }, for: .touchUpInside)
        
        // 设置信号预警视图的关闭回调
        weakSignalAlertView.onClose = { [weak self] in
            self?.hideWeakSignalAlert()
        }
    }
    
    // MARK: - 通知设置
    private func setupNotifications() {
        // 获取报平安和SOS的应答
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(switchSceneMapSuccess(_:)),
            name: .didSaveOfSOSResponseMsg,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(miniDeviceDisconnected),
            name: .bluetoothDeviceDisconnected,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSatelliteInfo(_:)),
            name: .didReceiveSatelliteInfo,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(proDeviceConnectInfo(_:)),
            name: .proDeviceConnectStatus,
            object: nil
        )
        
        // 监听危险区域通知 - 用于显示信号预警
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDangerAlert(_:)),
            name: .dangerZoneAlert,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWarningAlert(_:)),
            name: .dangerZoneWarning,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideWeakSignalAlert),
            name: .dangerZoneSafe,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSOSButtonTextToOpen),
            name: .SOSStateDidClose,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(changeSOSButtonTextToClose),
            name: .SOSStateDidOpen,
            object: nil
        )
    }
    
    // MARK: - 信号预警显示/隐藏控制
    private func showWeakSignalAlert() {
        guard weakSignalAlertViewHeightConstraint?.layoutConstraints.first?.constant != 40 else { return }
        
        weakSignalAlertView.isHidden = false
        weakSignalAlertViewHeightConstraint?.update(offset: 40)
        animateLayoutChange()
        
    }
    
    @objc private func hideWeakSignalAlert() {
        guard weakSignalAlertViewHeightConstraint?.layoutConstraints.first?.constant != 0 else { return }
        
        weakSignalAlertViewHeightConstraint?.update(offset: 0)
        animateLayoutChange()
        weakSignalAlertView.isHidden = true
    }
    
    private func animateLayoutChange() {
        UIView.animate(withDuration: 0.25, 
                      delay: 0,
                      options: [.curveEaseInOut, .beginFromCurrentState],
                      animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - 信号预警处理
    @objc private func handleDangerAlert(_ notification: Notification) {
        guard let _ = notification.userInfo else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 设置信号预警视图为danger状态
            self.weakSignalAlertView.state = .danger
            self.weakSignalAlertView.message = "信号告警：已进入卫星信号弱区域"
            
            // 显示预警视图
            self.showWeakSignalAlert()
        }
    }
    
    @objc private func handleWarningAlert(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 从通知中提取信息
            let direction = userInfo["direction"] as? String ?? "未知"
            let distance = userInfo["distance"] as? Double ?? 0
            
            // 格式化距离
            let distanceStr = self.formatDistance(distance)
            
            // 设置信号预警视图为warn状态
            self.weakSignalAlertView.state = .warn
            self.weakSignalAlertView.message = "信号预警：\(direction)方向\(distanceStr)后进入卫星信号弱区域"
            
            // 显示预警视图
            self.showWeakSignalAlert()
        }
    }
    
    // 格式化距离显示
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1 {
            return String(format: "%.0f米", distance * 1000)
        } else if distance < 10 {
            return String(format: "%.1f公里", distance)
        } else {
            return String(format: "%.0f公里", distance)
        }
    }
    
    // MARK: - 原有通知处理方法
    @objc private func switchSceneMapSuccess(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let result = userInfo["result"] as? ResponseStatus else {
            return
        }
        if result == .success {
            view.sw_showSuccessToast("发送成功")
        }
        if result == .failed {
            view.sw_showSuccessToast("发送失败")
        }
    }
    
    @objc private func miniDeviceDisconnected() {
        self.miniDeviceCardView.isConnected = false
    }
    
    @objc private func showSatelliteInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let satelliteInfo = userInfo["satelliteInfo"] as? String, let level = Int(satelliteInfo) {
            print("Mini设备卫星状态--首页--\(satelliteInfo)")
            self.miniDeviceCardView.satelliteIcon = HomeModule.image(named: "device_mini_line_satellite\(level))")
        }
    }
    
    @objc private func proDeviceConnectInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let satelliteInfo = userInfo["status"] as? Bool {
            print("宽带设备连接状态--首页--\(satelliteInfo)")
        }
    }
    
    @objc private func changeSOSButtonTextToOpen() {
        DispatchQueue.main.async { [weak self] in
            self?.sosButton.setTitle("长按开启SOS报警", for: .normal)
        }
    }
    
    @objc private func changeSOSButtonTextToClose() {
        DispatchQueue.main.async { [weak self] in
            self?.sosButton.setTitle("长按关闭SOS报警", for: .normal)
        }
    }
    
    // MARK: - 原有方法
    func selectMiniDevice() {
        let savedMiniDevices = viewModel.getMiniDeviceListData()
        guard savedMiniDevices.count > 0 else {
            SWPopupView.currentPopup?.dismiss(animated: false)
            SWRouter.handle(RouteTable.bindDevicePageUrl)
            return
        }
        
        if proDeviceCardView.isSelected {
            SWPopupView.currentPopup?.dismiss(animated: false)
        }
        
        if miniDeviceCardView.isSelected == false {
            SWPopupView.currentPopup?.dismiss()
            return
        }
        
        let contentView = MiniDeviceListView()
        contentView.deviceList = savedMiniDevices
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: ScreenUtil.screenWidth),
            contentView.heightAnchor.constraint(equalToConstant: Double(min(3, contentView.deviceList.count)) * swAdaptedValue(68))
        ])
        let top = CGRectGetMaxY(miniDeviceCardView.frame)
        let superView = UIView(frame: CGRectMake(0, top, ScreenUtil.screenWidth, ScreenUtil.screenHeight - top))
        ScreenUtil.getKeyWindow()?.addSubview(superView)
        let popup = SWPopupView.showFromTop(contentView: contentView, in: superView, configuration: SWPopupConfiguration(springAnimation: false))
        contentView.popupDismissBlock = {
            superView.removeFromSuperview()
            self.miniDeviceCardView.isSelected = false
        }
        
        contentView.clickRightButtonBlock = { device in
            popup.dismiss()
            self.viewModel.linkOrBreakMiniDevice(device)
        }
    }
    
    func selectProDevice() {
        let savedProDevices = viewModel.getProDeviceListData()
        guard savedProDevices.count > 0 else {
            SWPopupView.currentPopup?.dismiss(animated: false)
            SWRouter.handle(RouteTable.bindDevicePageUrl)
            return
        }
        
        if miniDeviceCardView.isSelected {
            SWPopupView.currentPopup?.dismiss(animated: false)
        }
        
        if proDeviceCardView.isSelected == false {
            SWPopupView.currentPopup?.dismiss()
            return
        }
        
        let contentView = ProDeviceListView()
        contentView.deviceList = savedProDevices
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: ScreenUtil.screenWidth),
            contentView.heightAnchor.constraint(equalToConstant: Double(min(3, contentView.deviceList.count)) * swAdaptedValue(68))
        ])
        let top = CGRectGetMaxY(proDeviceCardView.frame)
        let superView = UIView(frame: CGRectMake(0, top, ScreenUtil.screenWidth, ScreenUtil.screenHeight - top))
        ScreenUtil.getKeyWindow()?.addSubview(superView)
        let popup = SWPopupView.showFromTop(contentView: contentView, in: superView, configuration: SWPopupConfiguration(springAnimation: false))
        contentView.popupDismissBlock = {
            superView.removeFromSuperview()
            self.proDeviceCardView.isSelected = false
        }
        
        contentView.clickRightButtonBlock = { device in
            popup.dismiss()
            SWRouter.handle(RouteTable.proDevicePageUrl)
        }
    }
    
    private func bindEmergency() {
         if let emergencyName = UserDefaults.standard.string(forKey: "EmergencyName"),
            let emergencyPhone = UserDefaults.standard.string(forKey: "EmergencyPhone") {
             NetworkProvider<UserAPI>().request(.bindEmergencyContact(name: emergencyName, phone: emergencyPhone)) { result in
                 switch result {
                 case .success(let rsp):
                     do {
                         let networkResponse = try rsp.map(NetworkResponse<Bool>.self)
                         if networkResponse.isSuccess {
                             UserDefaults.standard.removeObject(forKey: "EmergencyName")
                             UserDefaults.standard.removeObject(forKey: "EmergencyPhone")
                             UserManager.shared.requestEmergencyContactList { result in
                                 
                             }
                         }
                     } catch {
                         
                     }
                 case .failure(let error):
                     print(error)
                 }
             }
         }
    }
    
    // MARK: - MapViewDelegate
    func mapViewDidTapLocationButton(_ mapView: HomeMapView) {
        mapManager.moveToUserLocation()
    }
    
    func mapViewDidTapZoomButton(_ mapView: HomeMapView) {
        if let navigationController = UIWindow.currentNavigationController(),
           let tabBarController = navigationController.viewControllers.first as? UITabBarController {
            tabBarController.selectedIndex = 1
        }
    }
    
    // MARK: - SOSButtonDelegate
    public func sosButtonDidCompleteLongPress(_ button: SOSButton) {
        let isInSOS = SOSManager.shared.checkUserSOSState()
        ReportManager.report(isInSOS ? .closeSOS : .openSOS)
    }
    
}

// MARK: - UICollectionView & UITableView Delegate/DataSource
extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.noticeTypeItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageTabCell", for: indexPath) as! HomeMessageTabCell
        let noticeTypeItem = viewModel.noticeTypeItems[indexPath.item]
        cell.configure(with: noticeTypeItem)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let noticeTypeItem = viewModel.noticeTypeItems[indexPath.item]
        viewModel.selectNoticeTypeItem(noticeTypeItem)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noticeTypeItem = viewModel.noticeTypeItems[indexPath.item]
        let label = UILabel()
        label.text = noticeTypeItem.desc
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.sizeToFit()
        return CGSize(width: label.frame.width + 2*Layout.hInset, height: 24)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.noticeList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeMessageCell", for: indexPath) as! HomeMessageCell
        let notice = viewModel.noticeList[indexPath.row]
        cell.configure(with: notice)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SWRouter.handle(RouteTable.urgentMessagePageUrl)
    }
}

// MARK: - TGRecognizerDelegate
extension HomeViewController: TGRecognizerDelegate {
    
    public func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, shouldRecognizePanGesture displacement: CGPoint) -> Bool {
        return true
    }
    
    public func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, shouldRecognizePinchGesture location: CGPoint) -> Bool {
        return true
    }
    
    public func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, shouldRecognizeShoveGesture displacement: CGPoint) -> Bool {
        return true
    }
    
    public func mapView(_ view: TGMapView!, recognizer: UIGestureRecognizer!, shouldRecognizeRotationGesture location: CGPoint) -> Bool {
        return true
    }
}
