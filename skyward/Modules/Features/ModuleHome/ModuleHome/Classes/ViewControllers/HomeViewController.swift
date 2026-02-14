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

    private var viewModel = HomeViewModel()
    private let mapManager = MapManager()
    
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
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mapManager.reloadMapWithCurrentTileSource()
    }
    
    override public func setupViews() {
        super.setupViews()
        
        view.addSubview(miniDeviceCardView)
        view.addSubview(proDeviceCardView)
        view.addSubview(mapContianerView)
        view.addSubview(centerTitleLabel)
        view.addSubview(clearButton)
        view.addSubview(collectionView)
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
        
        mapContianerView.snp.makeConstraints { make in
            make.top.equalTo(miniDeviceCardView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(200)
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
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(12)
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
        bindPublisher(viewModel.$weatherInfo.eraseToAnyPublisher()) { [weak self] _ in
            if let text = self?.viewModel.weatherInfo?.text,
               let temp = self?.viewModel.weatherInfo?.temp,
               let icon = self?.viewModel.weatherInfo?.icon {
                self?.mapContianerView.weatherInfoView.isHidden = false
                self?.mapContianerView.setWeatherText(text + temp + "℃")
                self?.mapContianerView.setWeatherIcon(SWKitModule.image(named: icon))
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
        
        reportSafetyButton.addAction(UIAction { _ in
            ReportManager.report(.safety)
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
    }
    
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
    
    private let mapContianerView = HomeMapView()
    private var mapView = TGMapView()
    
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
        button.titleLabel?.font = ThemeManager.bold16Font
        button.backgroundColor = ThemeManager.current.successColor
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        return button
    }()
    
    private let sosButton: SOSButton = {
        let button = SOSButton()
        return button
    }()
    
    // 添加 UICollectionView 定义
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
        ReportManager.report(.sos)
    }
    
    // MARK: -  通知
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
    }
    
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
        if let satelliteInfo = userInfo["satelliteInfo"] as? String {
            print("Mini设备卫星状态--首页--\(satelliteInfo)")
            self.miniDeviceCardView.satelliteIcon = HomeModule.image(named: "device_mini_line_satellite\(Int(satelliteInfo))")
        }
    }
    
    @objc private func proDeviceConnectInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let satelliteInfo = userInfo["status"] as? Bool {
            print("宽带设备连接状态--首页--\(satelliteInfo)")
            
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
                             UserManager.shared.requestEmergencyContact { result in
                                 
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
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {
    // MARK: - UICollectionView DataSource & Delegate Methods
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
    
    // MARK: - UITableView DataSource & Delegate Methods
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.noticeList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomeMessageCell", for: indexPath) as! HomeMessageCell
        let notice = viewModel.noticeList[indexPath.row]
        cell.configure(with: notice)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 36
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
