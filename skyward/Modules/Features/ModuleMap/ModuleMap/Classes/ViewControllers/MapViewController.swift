//
//  MapViewController.swift
//  yifan_test
//
//  Created by TXTS on 2025/11/24.
//

import UIKit
import TangramMap
import CoreLocation
import TXKit
import SWKit
import SnapKit
import SWTheme
import SWNetwork
import Combine

public class MapViewController: UIViewController {
    
    // MARK: - ViewModel
    private let viewModel = MapViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private var searchView: UIView!
    private var searchTextField: UITextField!
    private var rightButtonStack: UIStackView!
    private var bottomButtonStack: UIStackView!
    
    // 下边弹出框
    private var bottomSheet: BottomSheetView!
    
    // 右侧功能按钮
    private var measureButton: UIButton!
    private var layerButton: UIButton!
    private var poiButton: UIButton!
    private var teamButton: UIButton!
    private var locationButton: UIButton!
    private var compassButton: UIButton!
    private var trajectoryButton: UIButton!
    private var safeButton: UIButton!
    private var sosButton: UIButton!
    
    // MARK: - Properties
    private let mapManager = MapManager()
    private var isMeasuring = false {
        didSet {
            measureBottomView.isHidden = !isMeasuring
            if isMeasuring == false {
                distanceManager.clear()
            }
        }
    }
    private var isAddPOIing = false
    private var isAddRoute  = false {
        didSet {
            routeBottomView.isHidden = !isAddRoute
            if isAddRoute == false {
                distanceManager.clear()
                routeManager.closeRecord()
            }
        }
    }
    
    // 弹窗控制器
    private var layerPopupController: LayerPopupController?
    private var popupView: PopupMenuView?
    private var heightLevels: [CGFloat] = [0.35, 0.5]
    
    // 数据
    private var publicPoiDatas: [PublicPOIData]?
    private var customPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var customPointView = CustomPointView()
    private var addPointData: MapSearchPointMsgData?
    
    // MARK: - SOS Properties
    private var sosLongPressTimer: Timer?
    private var sosPressStartTime: Date?
    private let sosLongPressDuration: TimeInterval = 3.0 // 长按3秒
    private var isSOSActive = false
    
    // 闪烁红光图层
    private var alarmLayer: CALayer!
    // 报警强度配置
    private let alarmIntensitie: (alpha: CGFloat, duration: TimeInterval) = (0.6, 0.5)
    
    // manager
    private lazy var distanceManager: DistanceMeasurementManager = {
        guard let mapView = mapManager.mapView else {
            let mapView = mapManager.createMapView(in: self.view, frame: self.view.frame)
            let distanceManager = DistanceMeasurementManager(mapView: mapView)
            return distanceManager
        }
        let distanceManager = DistanceMeasurementManager(mapView: mapView)
        return distanceManager
    }()
    
    private lazy var trackManager: TrackManager = {
        let mgr = TrackManager()
        return mgr
    }()
    
    private lazy var routeManager: RouteManager = {
        let mgr = RouteManager()
        return mgr
    }()
    
    // 添加遮罩层用于点击其他地方关闭弹窗
    private lazy var tapMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hidePopupView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    // MARK: - Lazy Views
    private lazy var measureBottomView: MeasureBottomView = {
        let view = MeasureBottomView()
        view.revocationButton.addAction(UIAction {[weak self] _ in
            self?.distanceManager.revocation()
        }, for: .touchUpInside)
        view.deleteButton.addAction(UIAction {[weak self] _ in
            self?.distanceManager.clear()
        }, for: .touchUpInside)
        view.exitButton.addAction(UIAction {[weak self] _ in
            self?.isMeasuring = false
        }, for: .touchUpInside)
        
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(216))
            make.height.equalTo(swAdaptedValue(40))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(swAdaptedValue(36))
        }
        
        return view
    }()
    
    private lazy var routeBottomView: RouteBottomView = {
       let view = RouteBottomView()
        view.revocationButton.addAction(UIAction {[weak self] _ in
            self?.distanceManager.revocation()
        }, for: .touchUpInside)
        view.confirmButton.addAction(UIAction {[weak self] _ in
            self?.presentAddRouteVC()
        }, for: .touchUpInside)
        view.exitButton.addAction(UIAction {[weak self] _ in
            self?.isAddRoute = false
        }, for: .touchUpInside)
        
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(216))
            make.height.equalTo(swAdaptedValue(40))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(swAdaptedValue(36))
        }
        return view
    }()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupUI()
        setupConstraints()
        bindViewModel()
        setupMarkerLayer()
        loadInitialData()
        setupNotifications()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tapMaskView.frame = view.bounds
    }
}

// MARK: - Setup
extension MapViewController {
    
    private func setupMap() {
        
        let mapView = mapManager.createMapView(in: self.view, frame: self.view.frame)
        view.addSubview(mapView)
        
        // 设置回调
        mapManager.onSceneLoaded = { _ in
            
        }
        
        mapManager.onUserLocationUpdated = { (coordinate, _) in
            print("用户位置更新: \(coordinate.latitude), \(coordinate.longitude)")
        }
        
        mapManager.onMarkerSelected = { [weak self] markerId, data, layerId in
            print("\(markerId)----点--被点击")
            if markerId.contains("custom") {
                print("点击的----------------\(data.id)")
                let pointId = String(markerId.dropFirst(7))
                self?.getUserPointData(pointId: pointId)
            }else if markerId.contains("campsite") || markerId.contains("scenicSpots") || markerId.contains("gasStation") {
                let coordinate = CLLocationCoordinate2D(latitude: data.coordinate.latitude, longitude: data.coordinate.longitude)
                self?.showWeatherDetail(with: data.title, address: data.subtitle ?? "", coordinate: coordinate)
            }
        }
        mapManager.onMapSingleTapHandler = {[weak self] coordinate in
            if self?.isMeasuring == true {
                self?.distanceManager.handleMapTap(at: coordinate)
            }
            if self?.isAddRoute == true {
                self?.distanceManager.addRouteLine(at: coordinate)
                self?.routeManager.writePoint(coordinate)
            }
        }
        
        mapManager.onAddCustomMarker = { [weak self] (coordinate, point) in
            guard let self = self else { return }
            let location = "\(coordinate.longitude),\(coordinate.latitude)"
            viewModel.input.customPointRequest.send(location)
            customPoint = point
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGray6
        setupSearchView()
        setupRightButtons()
        setupMaskView()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeMapSource(_:)), name: .updateMapSource, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSelectPoi(_:)), name: .updatePOILayers, object: nil)
    }
    
    private func setupSearchView() {
        // 搜索视图
        searchView = UIView()
        searchView.backgroundColor = .white
        searchView.layer.cornerRadius = 12
        searchView.layer.shadowColor = UIColor.black.cgColor
        searchView.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchView.layer.shadowOpacity = 0.1
        searchView.layer.shadowRadius = 4
        searchView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchView)
        
        // 搜索图标
        let searchIcon = UIImageView(image: MapModule.image(named: "map_search"))
        searchIcon.tintColor = .black
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchView.addSubview(searchIcon)
        
        // 搜索文本框
        searchTextField = UITextField()
        searchTextField.placeholder = "请输入地点/经纬度"
        searchTextField.borderStyle = .none
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchView.addSubview(searchTextField)
        
        NSLayoutConstraint.activate([
            searchIcon.trailingAnchor.constraint(equalTo: searchView.trailingAnchor, constant: -12),
            searchIcon.centerYAnchor.constraint(equalTo: searchView.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchView.leadingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: searchIcon.leadingAnchor, constant: -12),
            searchTextField.topAnchor.constraint(equalTo: searchView.topAnchor, constant: 8),
            searchTextField.bottomAnchor.constraint(equalTo: searchView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupRightButtons() {
        // 描绘功能项
        measureButton = createIconButton(
            imageName: "map_distance",
            title: "测距",
            action: #selector(onMeasure)
        )
        
        // 图层功能项
        layerButton = createIconButton(
            imageName: "map_layers",
            title: "图层",
            action: #selector(onBasemapPopup)
        )
        
        // 兴趣点功能项
        poiButton = createIconButton(
            imageName: "map_addPoint",
            title: "兴趣点",
            action: #selector(onAddPoi)
        )
        
        // 组队功能项
        teamButton = createIconButton(
            imageName: "map_team",
            title: "队伍",
            action: #selector(onTeam)
        )
        
        // 右侧按钮堆栈
        let functionStack = UIStackView(arrangedSubviews: [measureButton, layerButton, poiButton, teamButton])
        functionStack.axis = .vertical
        functionStack.spacing = 12
        functionStack.distribution = .fillEqually
        functionStack.backgroundColor = .white
        functionStack.layer.cornerRadius = 12
        functionStack.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        functionStack.isLayoutMarginsRelativeArrangement = true
        
        // 定位按钮
        locationButton = createCircleButton(
            imageName: "map_myLocation",
            action: #selector(onStartLocation)
        )
        
        // 指北按钮
        compassButton = createCircleButton(
            imageName: "map_compass",
            action: #selector(onCompass)
        )
        
        // 轨迹按钮
        trajectoryButton = createCircleButton(
            imageName: "map_trajectory",
            action: #selector(onStartRecordTrajectory)
        )
        
        // 报平安按钮
        safeButton = createCircleButton(
            imageName: "map_safe",
            isRadius: true,
            action: #selector(onSafeReport)
        )
        
        // SOS按钮
        sosButton = createCircleButton(
            imageName: "map_sos",
            isRadius: true,
            action: #selector(onSOS)
        )
        
        // 底部按钮堆栈
        bottomButtonStack = UIStackView(arrangedSubviews: [locationButton, compassButton, trajectoryButton, safeButton, sosButton])
        bottomButtonStack.axis = .vertical
        bottomButtonStack.spacing = 12
        
        // 主右侧堆栈
        rightButtonStack = UIStackView(arrangedSubviews: [functionStack, bottomButtonStack])
        rightButtonStack.axis = .vertical
        rightButtonStack.spacing = 12
        rightButtonStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(rightButtonStack)
    }
    
    private func setupMaskView() {
        tapMaskView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tapMaskView)
        
        NSLayoutConstraint.activate([
            tapMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            tapMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tapMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            // 搜索视图
            searchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchView.heightAnchor.constraint(equalToConstant: 50),
            
            // 右侧按钮堆栈
            rightButtonStack.topAnchor.constraint(equalTo: searchView.bottomAnchor, constant: 24),
            rightButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    private func createIconButton(imageName: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建垂直堆栈
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 图标
        let icon = UIImageView(image: MapModule.image(named: imageName))
        icon.tintColor = .black
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        // 标题
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#070808")
        label.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(label)
        
        button.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            
            label.heightAnchor.constraint(equalToConstant: 17),
            
            // 堆栈视图居中
            stackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            // 按钮固定大小 - 移除冲突的约束
            button.widthAnchor.constraint(equalToConstant: 41), // 增加宽度避免冲突
            button.heightAnchor.constraint(equalToConstant: 41)
        ])
        
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createCircleButton(imageName: String, isRadius: Bool = false, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = isRadius ? 25 : 12
        
        if imageName == "map_sos" {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSOSLongPress(_:)))
            longPressGesture.minimumPressDuration = 0.1 // 降低阈值以便立即开始检测
            button.addGestureRecognizer(longPressGesture)
        } else {
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        
        let icon = UIImageView(image: MapModule.image(named: imageName))
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        button.addSubview(icon)
        
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: isRadius ? 50 : 24),
            icon.heightAnchor.constraint(equalToConstant: isRadius ? 50 : 24),
            
            button.widthAnchor.constraint(equalToConstant: 50),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return button
    }
}

// MARK: - ViewModel Binding
extension MapViewController {
    private func bindViewModel() {
        
        viewModel.$userPoiListData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if let data = data {
                    self.addUserMarkers(with: data)
                }
            }
            .store(in: &viewModel.cancellables)
        
        viewModel.$customPointData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if let customPointData = data?.first {
                    self.addPointData = customPointData
                    self.addCustomMarkers(with: customPointData)
                }
            }
            .store(in: &viewModel.cancellables)
        
        // 监听错误
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { error in
                guard let _ = error else { return }
            }
            .store(in: &viewModel.cancellables)
        
        // 监听加载状态
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    private func showLoading() {
        // 显示加载指示器
        print("正在加载...")
    }
    
    private func hideLoading() {
        // 隐藏加载指示器
        print("加载完成")
    }
    
    // 在 viewDidLoad 中调用数据请求
    private func loadInitialData() {
        
        // 请求路线列表数据
        let routeModel = RouteListModel(type: "0", pageNum: "1", pageSize: "20")
        viewModel.input.routeListRequest.send(routeModel)
        
        // 请求POI数据
        let poiModel = PublicPOIListModel(
            pageNum: 1,
            pageSize: 100
        )
        viewModel.input.userPoiListRequest.send(poiModel)
    }
    
    private func setupBottomSheet(data: [MapSearchPointMsgData], isNetwork: Bool) {
        // 创建配置
        if data.count == 0  || !isNetwork {
            heightLevels = [0.35]
        }else {
            heightLevels = [0.35, 0.5]
        }
        let config = BottomSheetConfig(
            heightPercentages: heightLevels,
            cornerRadius: 16,
            handleBarHeight: 5,
            backgroundColor: .white,
            dimColor: .black,
            dimAlpha: 0.6,
            animationDuration: 0.25,
            showIndicator: true
        )
        
        bottomSheet = BottomSheetView(config: config)
        bottomSheet.delegate = self
        
        // 创建示例内容视图
        let contentView = SearchResultView()
        contentView.configWithSearchData(searchData: data, isNetwork: isNetwork)
        contentView.closeAction = { [weak self] in
            self?.bottomSheet.hide()
        }
        contentView.choosePointAction = { [weak self] coordinate in
            self?.bottomSheet.hide()
//            self?.mapManager.createPointLocationMarker(with: coordinate)
            LocationManager().getCurrentLocation { [weak self] location, error in
                guard let self = self else { return }
                let startLat = location?.coordinate.latitude ?? 0.0
                let startLon = location?.coordinate.latitude ?? 0.0
                let endLat = coordinate.latitude
                let endLon = coordinate.longitude
                viewModel.openAmapNavigation(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon, destinationName: "yifan")
            }
        }
        // 设置内容视图（这很重要！）
        bottomSheet.setContentView(contentView)
        DispatchQueue.main.async { [weak self] in
            self?.bottomSheet.show()
        }
    }
}

// MARK: - 按钮点击事件
extension MapViewController {
    @objc private func onMeasure() {
        offMeasure()
        isMeasuring = true
    }
    
    func offMeasure() {
        isMeasuring = false
    }
    
    @objc private func onBasemapPopup() {
        offMeasure()
        showLayerPopup()
    }
    
    @objc private func onAddPoi() {
        if popupView != nil {
            hidePopupView()
        } else {
            // 创建菜单项
            let items = [
                PopupMenuItem(
                    title: "添加兴趣点",
                    iconName: "map_addPoint_1",
                    action: { [weak self] in
                        print("添加兴趣点")
                        self?.offMeasure()
                        self?.addPointOfInterest()
                        self?.hidePopupView()
                    }
                ),
                PopupMenuItem(
                    title: "添加路线",
                    iconName: "map_addPoint_2",
                    action: { [weak self] in
                        self?.offMeasure()
                        self?.hidePopupView()
                        self?.isAddRoute = true
                    }
                )
            ]
            showMenuPopover(items: items, type: .poi)
        }
    }

    // 队伍
    @objc private func onTeam() {

        SWRouter.handle(RouteTable.teamPageUrl)
    }
    
    // 定位
    @objc private func onStartLocation() {
        mapManager.moveToUserLocation()
    }
    
    @objc private func onCompass() {
        mapManager.mapView?.bearing = 0
    }
    
    @objc private func onStartRecordTrajectory() {
        let recording = trackManager.recording
        let items = [
            PopupMenuItem(
                title: "开始记录轨迹",
                iconName: recording ? "map_track_on" : "map_track_off",
                action: { [weak self] in
                    if recording {
                        self?.trackManager.stopRecord()
                        var popupContainer: SWPopupView?
                        let customView = AddTrackPopupView()
                        customView.nameTextField.text = self?.trackManager.currentRecord?.name
                        customView.closeHandler = {
                            self?.distanceManager.clear()
                            self?.trackManager.deleteRecords()
                            popupContainer?.dismiss()
                        }
                        customView.confirmHandler = { recordName in
                            self?.distanceManager.clear()
                            self?.trackManager.uploadRecords(recordName: recordName)
                            popupContainer?.dismiss()
                        }
                        var cfg = SWPopupConfiguration()
                        cfg.dismissOnMaskTap = false
                        popupContainer = SWPopupView.showFromBottom(contentView: customView, configuration: cfg)
                    } else {
                        self?.trackManager.startRecord()
                        self?.trackManager.locationUpdateCompletion = { [weak self] coordinate, error in
                            if let coordinate = coordinate {
                                self?.distanceManager.trackLine(coordinate: coordinate)
                            }
                        }
                        
                    }
                    self?.hidePopupView()
                }
            ),
            PopupMenuItem(
                title: "我的历史轨迹",
                iconName: "map_arrow_white",
                action: { [weak self] in
                    self?.hidePopupView()
                    self?.prsentTrackRecordVC()
                }
            )
        ]
        showMenuPopover(items: items, type: .track)
    }
    
    @objc private func onSafeReport() {
        ReportManager.report(.safety)
    }
    
    @objc private func onSOS() {
        ReportManager.report(.sos)
    }
    
    // MARK: - SOS长按手势处理
    @objc private func handleSOSLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // 开始长按
            sosPressStartTime = Date()
            startSOSLongPressTimer()
            startRedFogAnimation()
            updateSOSButtonUI(isPressed: true)
            
        case .changed:
            // 长按中
            updateSOSProgress()
            
        case .ended, .cancelled, .failed:
            // 结束长按
            cancelSOSLongPress()
            stopRedFlashAnimation()
            updateSOSButtonUI(isPressed: false)
            
        default:
            break
        }
    }
    
    private func startSOSLongPressTimer() {
        // 清除之前的计时器
        sosLongPressTimer?.invalidate()
        
        // 创建新的计时器
        sosLongPressTimer = Timer.scheduledTimer(withTimeInterval: sosLongPressDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.triggerSOS()
        }
    }

    private func updateSOSProgress() {
        guard let startTime = sosPressStartTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        let progress = min(elapsedTime / sosLongPressDuration, 1.0)
        
        // 可以在这里添加进度条或按钮状态更新
        // 例如：更新按钮的透明度或添加进度环
        sosButton.alpha = 0.5 + (progress * 0.5) // 从半透明到不透明
    }

    private func cancelSOSLongPress() {
        sosLongPressTimer?.invalidate()
        sosLongPressTimer = nil
        sosPressStartTime = nil
        sosButton.alpha = 1.0
    }

    private func triggerSOS() {
        isSOSActive = true
        
        // 停止闪烁动画
        stopRedFlashAnimation()
        
        // 执行SOS操作
        performSOSAction()
        
        // 更新按钮状态
        updateSOSButtonUI(isPressed: false)
        
        // 重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isSOSActive = false
        }
    }

    private func performSOSAction() {
        print("SOS已触发！")
        let hasNetwork = NetworkMonitor.shared.isConnected
        if hasNetwork {
            ReportManager.report(.sos)
            // 显示成功提示
            SWAlertView.showConfirmAlert(title: "SOS报警", message: "SOS报警信息已经发送成功，请您保持自身安全，等待救援")
        }else {
            if let _ = BluetoothManager.shared.connectedPeripheral {
                var alarmData = Data()
                alarmData.append(0x00) // SOS报警
                BluetoothManager.shared.sendCommand(.appTriggerAlarm, messageContent: alarmData)
                
                // 显示成功提示
                SWAlertView.showConfirmAlert(title: "SOS报警", message: "SOS报警信息已经发送成功，请您保持自身安全，等待救援")
            }else {
                self.view.sw_showWarningToast("请先连接Mini设备")
            }
        }
    }

    private func updateSOSButtonUI(isPressed: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.sosButton.transform = isPressed ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
            self.sosButton.backgroundColor = isPressed ? UIColor.systemRed.withAlphaComponent(0.8) : .white
        }
    }
    
    // MARK: - 红色闪烁动画
    // MARK: - 雾状边缘红光闪烁（最终优化版）
    private func startRedFogAnimation() {
        setupAlarmLayer()
        startIntenseFlashing()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func setupAlarmLayer() {
        alarmLayer = CALayer()
        alarmLayer.frame = view.bounds
        alarmLayer.backgroundColor = UIColor.red.cgColor
        alarmLayer.opacity = 0
        view.layer.addSublayer(alarmLayer)
    }
    
    private func startIntenseFlashing() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = alarmIntensitie.alpha
        animation.duration = alarmIntensitie.duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        alarmLayer.add(animation, forKey: "flash")
    }

    private func stopRedFlashAnimation() {
        alarmLayer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.3) {
            self.alarmLayer.opacity = 0
        }
    }
}

// MARK: - 功能实现
extension MapViewController {

    private func startDistanceMeasurement() {
        isMeasuring = true
        
        showToast(message: "测距模式已开启，长按地图开始测量")
        updateButtonAppearance(measureButton, isActive: true)
        
        measureBottomView.isHidden = false
        if measureBottomView.superview == nil {
            view.addSubview(measureBottomView)
            measureBottomView.snp.makeConstraints { make in
                make.width.equalTo(swAdaptedValue(216))
                make.height.equalTo(swAdaptedValue(40))
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(swAdaptedValue(36))
            }
        }
    }
    
    private func updateButtonAppearance(_ button: UIButton, isActive: Bool) {
        UIView.animate(withDuration: 0.3) {
            button.backgroundColor = isActive ? .systemBlue : .white
            button.tintColor = isActive ? .white : .systemBlue
        }
    }
    
    private func createCoordinateArrayFromScreenBounds() -> (Double, Double, Double, Double) {
        // 使用 MapManager 的方法获取坐标
        let corners = mapManager.createCoordinateArrayForPOIRequest()
        let minLat = corners.bottomRight.latitude
        let maxLat = corners.topLeft.latitude
        let minLon = corners.topLeft.longitude
        let maxLon = corners.bottomRight.longitude
       
        return (minLat, maxLat, minLon, maxLon)
    }
}

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let searchText = textField.text, !searchText.isEmpty {
            searchLocation(searchText)
        }
        
        return true
    }
    
    private func searchLocation(_ query: String) {
        showToast(message: "搜索: \(query)")
        if viewModel.determineSearchType(query) == .coordinate {
            print("---------这是坐标---------")
            if let coordinate = parseCoordinate(from: query) {
                mapManager.createPointLocationMarker(with: coordinate)
            }
        }else {
            print("---------这是文字---------")
            if NetworkMonitor.shared.isConnected {
                viewModel.mapSearchData(address: query)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        
                    } receiveValue: { [weak self] data in
                        guard let self = self else { return }
                        self.setupBottomSheet(data: data, isNetwork: true)
                    }
                    .store(in: &viewModel.cancellables)
            }else {
                self.setupBottomSheet(data: [], isNetwork: false)
            }
        }
        
    }
    
    func parseCoordinate(from string: String) -> CLLocationCoordinate2D? {
        let components = string.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        guard components.count == 2,
              let longitude = Double(components[0]),
              let latitude = Double(components[1]) else {
            return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - 弹窗功能
extension MapViewController {
    
    private func showLayerPopup() {
        layerPopupController = LayerPopupController()
        if let sheet = layerPopupController?.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(layerPopupController!, animated: true)
    }
    
    private func showMenuPopover(items: [PopupMenuItem], type: MenuType) {
        self.hidePopupView()
        
        // 创建弹窗
        let popupView = PopupMenuView(items: items, type: type)
        self.popupView = popupView
        
        // 计算显示位置（在兴趣点按钮的下方中间）
        var poiButtonFrame = poiButton.convert(poiButton.bounds, to: view)
        if type == .track {
            poiButtonFrame = trajectoryButton.convert(trajectoryButton.bounds, to: view)
        }
        
        // 弹窗显示在按钮下方，水平居中
        let point = CGPoint(
            x: poiButtonFrame.midX + 10,
            y: poiButtonFrame.maxY + 4
        )
        
        // 显示遮罩层
        tapMaskView.isHidden = false
        view.bringSubviewToFront(tapMaskView)
        
        // 显示弹窗
        popupView.show(from: view, at: point)
        view.bringSubviewToFront(popupView)
        
        // 设置弹窗关闭回调
        popupView.onDismiss = { [weak self] in
            self?.hidePopupView()
        }
    }
    
    @objc private func hidePopupView() {
        if let popupView = popupView {
            popupView.hide()
            self.popupView = nil
        }
        tapMaskView.isHidden = true
    }
    
    private func addPointOfInterest() {
        print("执行添加兴趣点操作")
        mapManager.isAddPOIStatus = true
    }
    
    private func presentAddPOIVC(latitude: Double, longitude: Double) {
        let coordinate = POICoordinate(latitude: latitude, longitude: longitude)
        
        // 创建添加页面
        let addPOIVC = AddPOIViewController(coordinate: coordinate)
        addPOIVC.deleteCustomMarker = { [weak self] in
            guard let self = self else { return }
            if let pointData = self.addPointData {
                self.closeCustomPointView(with: pointData)
            }
        }
        // 创建并设置自定义的过渡代理
        let customTransitioningDelegate = CustomTransitioningDelegate(heightPercentage: 0.8)
        addPOIVC.customTransitioningDelegate = customTransitioningDelegate // 保持引用
        addPOIVC.transitioningDelegate = customTransitioningDelegate
        addPOIVC.modalPresentationStyle = .custom
        
        // 展示页面
        present(addPOIVC, animated: true)
    }
    
    private func presentAddRouteVC() {
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView()
        customView.closeHandler = { [weak self] in
            self?.isAddRoute = false
            popupContainer?.dismiss()
        }
        customView.confirmHandler = {[weak self] name, desc in
            self?.isAddRoute = false
            self?.routeManager.saveRoute(name: name, desc: desc)
            popupContainer?.dismiss()
        }
        var cfg = SWPopupConfiguration()
        cfg.dismissOnMaskTap = false
        popupContainer = SWPopupView.showFromBottom(contentView: customView, configuration: cfg)
    }
    
    private func prsentTrackRecordVC() {
        let trackRecordVC = TrackRecordViewController()
        trackRecordVC.records = trackManager.getTrackRecords()
        trackRecordVC.onClickCloseHandler = {[weak self] in
            self?.distanceManager.clear()
        }
        trackRecordVC.onClickLookHandler = {[weak self] coordinates in
            self?.distanceManager.trackLines(coordinates: coordinates)
        }
        trackRecordVC.onClickUnLookHandler = {[weak self] in
            self?.distanceManager.clear()
        }
        trackRecordVC.onClickDeleteHandler = {[weak self] _ in
            self?.distanceManager.clear()
        }
        
        // 创建并设置自定义的过渡代理
        let customTransitioningDelegate = CustomTransitioningDelegate(heightPercentage: 0.35)
        trackRecordVC.customTransitioningDelegate = customTransitioningDelegate // 保持引用
        trackRecordVC.transitioningDelegate = customTransitioningDelegate
        trackRecordVC.modalPresentationStyle = .custom
        
        // 展示页面
        present(trackRecordVC, animated: true)
    }
    
    private func showToast(message: String) {
        print("Toast: \(message)")
    }
    
    private func showAlert(title: String, message: String, confirmText: String = "确定") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmText, style: .default))
        present(alert, animated: true)
    }
}

extension MapViewController {
    
//    private func showPOIMsgView(location: CGPoint, point: CLLocationCoordinate2D) {
//        let locationStr = "\(point.longitude),\(point.latitude)"
//        viewModel.mapPointData(locationStr)
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                if case .failure(let error) = completion {
//                    print("点位的信息获取失败--\(error)")
//                }
//            } receiveValue: { [weak self] data in
//                guard let self = self else { return }
//                print("点位的信息--\(data)")
//            }
//            .store(in: &viewModel.cancellables)
//    }
    
    // 当用户点击兴趣点时显示天气详情
    func showWeatherDetail(with title: String, address: String, coordinate: CLLocationCoordinate2D) {
        let weatherVC = POIWeatherDetailViewController(title: title, address: address, coordinate: coordinate)
        if let sheet = weatherVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheet.delegate = weatherVC
        }
        present(weatherVC, animated: true)
    }
    
    func showUserPointDetail(with poiData: UserPOIData) {
        let userPoiVC = UserPOIDetailViewController(poiData: poiData)
        if let sheet = userPoiVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheet.delegate = userPoiVC
        }
        present(userPoiVC, animated: true)
    }
    
    func getUserPointData(pointId: String) {
        viewModel.fetchUserPoiData(id: pointId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(_) = completion {
                    self?.view.sw_showWarningToast("获取自定义兴趣点信息失败")
                }
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                self.showUserPointDetail(with: data)
            }
            .store(in: &cancellables)
    }
    
}
// LayerPopup中的通知方法
extension MapViewController {
    
    @objc private func changeMapSource(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let sceneUrl = userInfo["sceneUrl"] as? String {
            mapManager.switchTileSource(to: sceneUrl)
        }
            
    }
    
    @objc private func showSelectPoi(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let (minLat, maxLat, minLon, maxLon) = createCoordinateArrayFromScreenBounds()
        POIDatabaseManager.shared.fetchPOIsInRegion(minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon) { [weak self] publicPOIList in
            guard let self = self else { return }
            self.publicPoiDatas = publicPOIList
            self.addPublicMarkers()
        }
        
        if let poiLayers = userInfo["poiLayers"] as? [String: Bool] {
            print("选择的兴趣点---\(poiLayers)")
            
            // 安全地访问 markerLayerManager
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            
            // 设置图层可见性
            if let campsite = poiLayers["露营地"] {
                markerLayerManager.setLayerVisible(campsite, layerId: "campsite")
            }
            if let scenicSpots = poiLayers["风景名胜"] {
                markerLayerManager.setLayerVisible(scenicSpots, layerId: "scenicSpots")
            }
            if let gasStation = poiLayers["加油站"] {
                markerLayerManager.setLayerVisible(gasStation, layerId: "gasStation")
            }
            if let custom = poiLayers["我的兴趣点"] {
                markerLayerManager.setLayerVisible(custom, layerId: "custom")
                markerLayerManager.setLayerVisible(custom, layerId: "newCustom")
            }
            if let route = poiLayers["我的路线"] {
                if route {
                    if let routes = self.routeManager.getAllRoutes() {
                        for route in routes {
                            if let routeId = route.routeId, let points = self.routeManager.getPointsInRoute(routeId: routeId), points.count > 1 {
                                let coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude ?? 0, longitude: $0.longitude ?? 0) }
                                self.distanceManager.showRoute(coordinates: coordinates)
                            }
                        }
                    }
                } else {
                    self.distanceManager.clear()
                }
            }
        }
    }
    
    public func setupMarkerLayer() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        _ = markerLayerManager.createLayer(id: "campsite", name: "露营地", isVisible: false)
        _ = markerLayerManager.createLayer(id: "scenicSpots", name: "风景名胜", isVisible: false)
        _ = markerLayerManager.createLayer(id: "gasStation", name: "加油站", isVisible: false)
        _ = markerLayerManager.createLayer(id: "custom", name: "自定义标注", isVisible: false)
        _ = markerLayerManager.createLayer(id: "newCustom", name: "添加自定义标注", isVisible: true)
    }
    
    /// 添加公共兴趣点
    public func addPublicMarkers() {
        // 安全地访问 markerLayerManager
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        
        guard let markersData = self.publicPoiDatas else { return }
        print("兴趣点消息------\(markersData)")
        
        // 添加露营地
        let campsitesData = markersData.filter { $0.type?.contains("露营地") == true }
        print("露营地消息------\(campsitesData)")
        for (index, publicPoi) in campsitesData.enumerated() {
            if let lat = publicPoi.wgsLat, let lon = publicPoi.wgsLon {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let data = MarkerData(
                    id: "campsite_\(index)",
                    coordinate: coordinate,
                    title: publicPoi.name ?? "",
                    subtitle: publicPoi.address ?? ""
                )
                markerLayerManager.addMarkerWithPresetStyle(to: "campsite", data: data, styleType: .campsite)
            }
        }
        
        // 添加风景名胜
        let scenicSpotsData = markersData.filter { $0.type?.contains("风景名胜") == true }
        print("风景名胜消息------\(scenicSpotsData)")
        for (index, publicPoi) in scenicSpotsData.enumerated() {
            if let lat = publicPoi.wgsLat, let lon = publicPoi.wgsLon {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let data = MarkerData(
                    id: "scenicSpots_\(index)",
                    coordinate: coordinate,
                    title: publicPoi.name ?? "",
                    subtitle: publicPoi.address ?? ""
                )
                markerLayerManager.addMarkerWithPresetStyle(to: "scenicSpots", data: data, styleType: .scenicSpots)
            }
        }
        
        // 添加加油站
        let gasStationData = markersData.filter { $0.type?.contains("加油站") == true }
        for (index, publicPoi) in gasStationData.enumerated() {
            if let lat = publicPoi.wgsLat, let lon = publicPoi.wgsLon {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let data = MarkerData(
                    id: "gasStation_\(index)",
                    coordinate: coordinate,
                    title: publicPoi.name ?? "",
                    subtitle: publicPoi.address ?? ""
                )
                markerLayerManager.addMarkerWithPresetStyle(to: "gasStation", data: data, styleType: .gasStation)
            }
        }
        
    }
    // 添加服务器中我的兴趣点数据
    public func addUserMarkers(with pointData: [UserPOIData]) {
        // 安全地访问 markerLayerManager
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        
        for (_, userPoi) in pointData.enumerated() {
            if let lat = userPoi.lat, let lon = userPoi.lon, let code = userPoi.poiId {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let data = MarkerData(
                    id: "custom_\(code)",
                    coordinate: coordinate,
                    title: userPoi.name ?? "",
                    subtitle: userPoi.description ?? ""
                )
                markerLayerManager.addMarkerWithPresetStyle(to: "custom", data: data, styleType: .user)
            }
        }
    }
    // 执行添加我的兴趣点操作
    public func addCustomMarkers(with pointData: MapSearchPointMsgData) {
        // 安全地访问 markerLayerManager
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        
        if let lat = pointData.latitude, let lon = pointData.longitude, let code = pointData.regionCode {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let data = MarkerData(
                id: "newCustom_\(code)",
                coordinate: coordinate,
                title: pointData.name ?? "",
                subtitle: pointData.address ?? ""
            )
            markerLayerManager.addMarkerWithPresetStyle(to: "newCustom", data: data, styleType: .user)
        }
        
        let x = max(customPoint.x - 120, 0)
        let y = max(customPoint.y - 160, 130)
        customPointView.frame = CGRect(x: x, y: y, width: 240, height: 150)
        customPointView.updateUI(with: pointData)
        customPointView.closeAction = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.closeCustomPointView(with: pointData)
            }
        }
        customPointView.creatPointAction = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.customPointView.removeFromSuperview()
                self.presentAddPOIVC(latitude: pointData.latitude ?? 0.0, longitude: pointData.longitude ?? 0.0)
            }
        }
        self.view.addSubview(customPointView)
    }

    // 关闭点位视图，并且删除点位
    private func closeCustomPointView(with pointData: MapSearchPointMsgData) {
        customPointView.removeFromSuperview()
        let code = pointData.regionCode ?? ""
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        markerLayerManager.removeMarker("newCustom_\(code)", from: "newCustom")
    }
}

extension MapViewController: BottomSheetViewDelegate {
    
}
