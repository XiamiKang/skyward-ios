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
import WCDBSwift

public class MapViewController: UIViewController {
    
    private let AddPOIStartViewHeight: CGFloat = 200
    private let SearchPointViewHeight: CGFloat = 160
    
    // MARK: - ViewModel
    private let viewModel = MapViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private var mapFakeSearchView: MapFakeSearchView!                                //搜索框（展示用）
    private var mapRealSearchView: MapRealSearchView!                                //搜索框（实际查询的）
    private var rightButtonStack: UIStackView!
    private var bottomButtonStack: UIStackView!
    private var middleButtonStack: UIStackView!
    private var topButtonStack: UIStackView!
    private var rightButtonsTopConstraint: NSLayoutConstraint!
    private var mapSourceTextLabel: UILabel!
    private var mapSourceImageBottomConstraint: NSLayoutConstraint!
    
    // 下边弹出框
    private var bottomSheet: BottomSheetView!
    
    // 右侧功能按钮
    private var measureButton: UIButton!
    private var layerButton: UIButton!
    private var poiButton: UIButton!
    private var teamButton: UIButton!
    private var weatherButton: UIButton!
    private var locationButton: UIButton!
    private var compassButton: UIButton!
    private var trajectoryButton: UIButton!
    private var trackHistoryButton: UIButton!
    private var safeButton: UIButton!
    private var sosButton: UIButton!
    
    // MARK: - Properties
    public let mapManager = MapManager()
    public let routeDataManager = RouteDataManager()
    var isDetailViewShowing: Bool = false {
        didSet {
            self.tabBarController?.tabBar.isHidden = isDetailViewShowing
        }
    }
    private var isSearching = false {
        didSet {
            if isSearching {
                enterSearchMode()
            } else {
                exitSearchMode()
            }
        }
    }
    private var isMeasuring = false {
        didSet {
            if isMeasuring {
                enterMeasureMode()
            } else {
                exitMeasureMode()
            }
        }
    }
    private var isAddPOIing = false {
        didSet {
            if isAddPOIing {
                enterEditMode(with: "点击地图任意位置添加兴趣点")
            } else {
                exitEditMode()
            }
        }
    }
    private var isAddRoute  = false {
        didSet {
            if isAddRoute {
                enterRouteMode()
            } else {
                exitRouteMode()
            }
        }
    }
    
    private var isAddTrack = false {
        didSet {
            if isAddTrack {
                enterTrackMode()
            } else {
                exitTrackMode()
            }
        }
    }
    
    private var isWeathering = false {
        didSet {
            if isWeathering {
                enterEditMode(with: "点击地图任意位置查看天气")
            } else {
                exitEditMode()
            }
        }
    }
    
    // 弹窗控制器
    private var layerPopupController: LayerPopupController?
    private var popupView: PopupMenuView?
    private var heightLevels: [CGFloat] = [0.35, 0.5]
    
    // 数据
    private var addPOIStartView: MapAddPOIStartView!                    // 添加个人兴趣点
    private var poiData: MapSearchPointMsgData?                         // 个人兴趣点解析数据
    private var searchPointView: MapSearchPointView!                    // 搜索经纬度的弹窗
    
    
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
    
    private func mapView() -> TGMapView {
        return mapManager.mapView ?? mapManager.createMapView(in: self.view, frame: self.view.bounds)
    }
    
    private lazy var drawMarkerManager: MapDrawMarkerManager = {
        let mgr = MapDrawMarkerManager(mapView: mapView())
        return mgr
    }()
    
    private lazy var trackManager: TrackManager = {
        let mgr = TrackManager(mapView: mapView())
        mgr.locationUpdateCompletion = { [weak self] location in
            if let altitude = location?.altitude {
                self?.trackBottomView.updateAltitude(String(format: "%.2fm", altitude))
            }
        }
        mgr.routeUpdateHandler = { [weak self] route in
            if let distance = route?.distance {
                self?.trackBottomView.updateDistance(String(format: "%.2fkm", distance))
            }
            
            if let duration = route?.travelTime {
                self?.trackBottomView.updateDuration(duration.formatHMSDuration())
            }
        }
        return mgr
    }()
    
    private lazy var routeManager: RouteManager = {
        let mgr = RouteManager()
        return mgr
    }()
    
    // MARK: - Lazy Views
    
    private lazy var weatherInfoView: WeatherInfoView = {
        let weatherInfoView = WeatherInfoView()
        view.addSubview(weatherInfoView)
        weatherInfoView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(26))
            make.top.equalToSuperview().inset(ScreenUtil.safeAreaTop + swAdaptedValue(80))
            make.leading.equalToSuperview().inset(Layout.hMargin)
        }
        weatherInfoView.addTapGestureTarget(self, action: #selector(onCurrentWeather))
        return weatherInfoView
    }()
    
    private lazy var measureBottomView: MeasureBottomView = {
        let view = MeasureBottomView()
        view.revocationButton.addAction(UIAction {[weak self] _ in
            self?.drawMarkerManager.revocationDistance()
            if self?.drawMarkerManager.coordinates.count == 0 {
                self?.measureBottomView.isHidden = true
            }
        }, for: .touchUpInside)
        view.deleteButton.addAction(UIAction {[weak self] _ in
            self?.drawMarkerManager.clear()
            self?.measureBottomView.isHidden = true
        }, for: .touchUpInside)
        
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(40))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(swAdaptedValue(24) + ScreenUtil.safeAreaBottom)
        }
        
        return view
    }()
    
    private lazy var routeBottomView: RouteBottomView = {
       let view = RouteBottomView()
        view.revocationButton.addAction(UIAction {[weak self] _ in
            if self?.routeManager.revocation() == true {
                self?.drawMarkerManager.revocationRoute()
                if self?.drawMarkerManager.coordinates.count == 0 {
                    self?.routeBottomView.isHidden = true
                }
            }
        }, for: .touchUpInside)
        view.confirmButton.addAction(UIAction {[weak self] _ in
            if self?.routeManager.isValidSessionRoute() == true {
                self?.view.sw_showLoading()
                self?.routeManager.assembleSessionRoute { [weak self] route in
                    self?.view.sw_hideLoading()
                    self?.presentAddRouteVC(route: route)
                }
            } else {
                self?.view.sw_showWarningToast("保存路线至少需要 2个点")
            }
        }, for: .touchUpInside)
        view.deleteButton.addAction(UIAction {[weak self] _ in
            if self?.routeManager.clear() == true {
                self?.drawMarkerManager.clear()
                self?.routeBottomView.isHidden = true
            }
        }, for: .touchUpInside)
        
        self.view.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(40))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(swAdaptedValue(24) + ScreenUtil.safeAreaBottom)
        }
        return view
    }()
    
    private lazy var trackBottomView: RecordTrackBottomView = {
        let bottomView = RecordTrackBottomView()
        // 开始记录回调
        bottomView.startRecordHandler = { [weak self] in
            self?.startRecordTrack()
        }
        // 结束记录回调
        bottomView.endRecordHandler = { [weak self] in
            self?.trackManager.stopRecord()
            if self?.trackManager.isValidSessionRoute() == true {
                self?.view.sw_showLoading()
                self?.trackManager.assembleSessionRoute { [weak self] route in
                    self?.view.sw_hideLoading()
                    self?.presentAddTrackVC(route: route)
                }
            } else {
                self?.view.sw_showWarningToast("距离太短，不能保存轨迹记录")
                self?.endRecordTrack()
            }
        }
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(148) + ScreenUtil.safeAreaBottom)
            make.bottom.left.right.equalToSuperview()
        }
        return bottomView
    }()
    
    private lazy var topMaskView: UIView = {
        let topMaskView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenUtil.screenWidth, height: 44 + ScreenUtil.statusBarHeight))
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = topMaskView.bounds
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(1.0).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        topMaskView.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(topMaskView)
        
        return topMaskView
    }()
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.backgroundColor = .clear
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.setLeftButton(image: SWKitModule.image(named: "nav_arrow")?.withTintColor(.white)) { [weak self] in
            if self?.isMeasuring == true {
                self?.isMeasuring = false
            }
            if self?.isAddRoute == true {
                self?.isAddRoute = false
            }
            if self?.isAddTrack == true {
                self?.isAddTrack = false
            }
            if self?.isWeathering == true {
                self?.mapManager.hideWeatherPointMarker()
                self?.isWeathering = false
            }
            if self?.isAddPOIing == true {
                self?.mapManager.hideWeatherPointMarker()
                self?.isAddPOIing = false
                self?.hideAddPOIStartView()
            }
        }
        topMaskView.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        return bar
    }()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = .all
        
        setupMap()
        setupUI()
        setupConstraints()
        bindViewModel()
        setupMarkerLayer()
        // 初始化天气，将图层设为不可见
        setupWeatherLayer()
        loadInitialData()
        setupNotifications()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        loadRoutesMarkers()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

// MARK: - Setup
extension MapViewController {
    
    // MARK: - 地图初始化
    private func setupMap() {
        
        MapConfig.shared.defaultZoom = 16
        MapConfig.shared.showUserLocation = true
        MapConfig.shared.saveConfig()
        let mapView = mapManager.createMapView(in: self.view, frame: CGRect(x: 0, y: 0, width: ScreenUtil.screenWidth, height: ScreenUtil.screenHeight))
        view.addSubview(mapView)
        
        // 设置回调
        mapManager.onSceneLoaded = { _ in
            
        }
        
        mapManager.onUserLocationUpdated = { (coordinate, _) in
            print("用户位置更新: \(coordinate.latitude), \(coordinate.longitude)")
        }
        
        mapManager.onMarkerSelected = { [weak self] markerId, data, layerId in
            print("\(layerId)--层 \(markerId)----点--被点击")
            if markerId.contains("custom") {
                print("点击的----------------\(data.id)")
                let pointId = String(markerId.dropFirst(7))
                self?.getUserPointData(pointId: pointId)
                return
            }else if markerId.contains("campsite") || markerId.contains("scenicSpots") || markerId.contains("gasStation") || markerId.contains("medical") {
                if let result = markerId.components(separatedBy: "_").last {
                    self?.showWeatherDetail(with: result)
                }
                return
            } else if layerId == "route_line" {
                self?.presentRouteDetail(data: data)
                return
            }
        }
        mapManager.onMapSingleTapHandler = {[weak self] (coordinate, point) in
            guard let self = self else { return }
            if self.isMeasuring == true {
                self.drawMarkerManager.addDistanceLine(at: coordinate)
                self.measureBottomView.isHidden = false
                return
            }
            if self.isAddRoute == true {
                self.drawMarkerManager.addRouteLine(at: coordinate)
                self.routeManager.writePoint(coordinate)
                self.routeBottomView.isHidden = false
                return
            }
            if self.isAddPOIing == true {
                self.mapManager.createWeatherPointMarker(with: coordinate)
                let location = "\(coordinate.longitude),\(coordinate.latitude)"
                if NetworkMonitor.shared.isConnected {
                    self.viewModel.input.customPointRequest.send(location)
                }else {
                    self.poiData = nil
                    self.addPOIStartView.config(coordinate)
                    self.showAddPOIStartView(with: nil)
                }
                return
            }
            if self.isWeathering == true {
                self.mapManager.createWeatherPointMarker(with: coordinate)
                self.showWeatherPointView(with: coordinate)
                return
            }
            print("地图单点----点--被点击")
            view.endEditing(false)
        }
        
        mapManager.onMapPanHandler = { [weak self] in
            guard let self = self else { return }
            print("地图拖动")
            creatPublicMarkers()
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.current.mediumGrayBGColor
        setupSearchView()
        setupRightButtons()
        setupMaskView()
        setupAddPOIView()
        setupSearchPointView()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeMapSource(_:)), name: .updateMapSource, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showNote(_:)), name: .updateVectorAnnotation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showWeather(_:)), name: .updateWeatherLayers, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCampgroundPoi(_:)), name: .updateCampgroundLayer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showScenicPoi(_:)), name: .updateScenicLayer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showGasStationPoi(_:)), name: .updateGasStationLayer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMedicalPoi(_:)), name: .updateMedicalLayer, object: nil)
    }
    
    private func setupSearchView() {
        // 搜索视图
        mapFakeSearchView = MapFakeSearchView()
        view.addSubview(mapFakeSearchView)
        
        mapRealSearchView = MapRealSearchView()
        mapRealSearchView.isHidden = true
        mapRealSearchView.backAction = { [weak self] in
            guard let self = self else { return }
            isSearching = false
        }
        mapRealSearchView.searchAction = { [weak self] searchText in
            guard let self = self else { return }
            searchLocation(searchText)
        }
        view.addSubview(mapRealSearchView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onSearch))
        mapFakeSearchView.addGestureRecognizer(tapGesture)
    }
    
    private func setupRightButtons() {
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
        
        // 轨迹按钮
        trajectoryButton = createIconButton(
            imageName: "map_trajectory",
            title: "轨迹",
            action: #selector(onTrack)
        )
        trajectoryButton.setTitle("记录中", for: .selected)
        trajectoryButton.setTitleColor(ThemeManager.current.mainColor, for: .selected)
        trajectoryButton.setImage(MapModule.image(named: "map_trajectory_ing"), for: .selected)
        
        // 顶部按钮堆栈
        topButtonStack = UIStackView(arrangedSubviews: [poiButton, trajectoryButton])
        topButtonStack.axis = .vertical
        topButtonStack.spacing = 12
        topButtonStack.distribution = .fillEqually
        topButtonStack.backgroundColor = .white
        topButtonStack.layer.cornerRadius = 12
        topButtonStack.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        topButtonStack.isLayoutMarginsRelativeArrangement = true
        
        // 天气按钮
        weatherButton = createCircleButton(
            imageName: "map_weather",
            action: #selector(onWeather)
        )
        
        // 测距功能项
        measureButton = createCircleButton(
            imageName: "map_distance",
            action: #selector(onMeasure)
        )
        
        // 图层功能项
        layerButton = createCircleButton(
            imageName: "map_layers",
            action: #selector(onBasemapPopup)
        )
        
        // 指北按钮
        compassButton = createCircleButton(
            imageName: "map_compass",
            action: #selector(onCompass)
        )
        
        // 底部按钮堆栈
        middleButtonStack = UIStackView(arrangedSubviews: [weatherButton, measureButton, layerButton, compassButton])
        middleButtonStack.axis = .vertical
        middleButtonStack.spacing = 8
        
        // 历史轨迹
        trackHistoryButton = createCircleButton(
            imageName: "map_trajectory",
            action: #selector(onTrackHistory)
        )
        trackHistoryButton.isHidden = true
        
        // 定位按钮
        locationButton = createCircleButton(
            imageName: "map_myLocation",
            action: #selector(onStartLocation)
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
        bottomButtonStack = UIStackView(arrangedSubviews: [trackHistoryButton, locationButton, safeButton, sosButton])
        bottomButtonStack.axis = .vertical
        bottomButtonStack.spacing = 8
        
        // 主右侧堆栈
        rightButtonStack = UIStackView(arrangedSubviews: [topButtonStack, middleButtonStack, bottomButtonStack])
        rightButtonStack.axis = .vertical
        rightButtonStack.spacing = 8
        rightButtonStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(rightButtonStack)
    }
    
    private func setupMaskView() {
        mapSourceTextLabel = UILabel()
        mapSourceTextLabel.translatesAutoresizingMaskIntoConstraints = false
        mapSourceTextLabel.text = "数据来自：长光卫星技术股份有限公司GS(2025)1834号"
        mapSourceTextLabel.textColor = .white
        mapSourceTextLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        mapSourceTextLabel.layer.shadowColor = UIColor.black.cgColor
        mapSourceTextLabel.layer.shadowOffset = CGSize(width: 0, height: 1)  // 阴影偏移量
        mapSourceTextLabel.layer.shadowOpacity = 0.8  // 添加阴影透明度
        mapSourceTextLabel.layer.shadowRadius = 2  // 添加阴影模糊半径
        view.addSubview(mapSourceTextLabel)
        
        mapSourceImageBottomConstraint = mapSourceTextLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -88)
        NSLayoutConstraint.activate([
            mapSourceTextLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            mapSourceImageBottomConstraint,
        ])
    }
    
    private func setupAddPOIView() {
        addPOIStartView = MapAddPOIStartView(frame: CGRect(x: 0, y: ScreenUtil.screenHeight, width: ScreenUtil.screenWidth, height: AddPOIStartViewHeight))
        addPOIStartView.AddPOIAction = { [weak self] (coordinate, poiData) in
            guard let self = self else { return }
            self.presentAddPOIVC(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        view.addSubview(addPOIStartView)
    }
    
    private func setupSearchPointView() {
        searchPointView = MapSearchPointView(frame: CGRect(x: 0, y: ScreenUtil.screenHeight, width: ScreenUtil.screenWidth, height: SearchPointViewHeight))
        view.addSubview(searchPointView)
    }
    
    private func setupConstraints() {
        
        rightButtonsTopConstraint = rightButtonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 82)
        NSLayoutConstraint.activate([
            
            // 搜索视图
            mapFakeSearchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mapFakeSearchView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapFakeSearchView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapFakeSearchView.heightAnchor.constraint(equalToConstant: 50),
            
            mapRealSearchView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mapRealSearchView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mapRealSearchView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mapRealSearchView.heightAnchor.constraint(equalToConstant: 50),
            
            // 右侧按钮堆栈
            rightButtonsTopConstraint,
            rightButtonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    private func createIconButton(imageName: String, title: String, action: Selector) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 12)
        button.setTitle(title, for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.setImage(MapModule.image(named: imageName), for: .normal)
        button.imageUpTitleDown()
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createCircleButton(imageName: String, isRadius: Bool = false, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
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
            icon.widthAnchor.constraint(equalToConstant: isRadius ? 44 : 24),
            icon.heightAnchor.constraint(equalToConstant: isRadius ? 44 : 24),
            
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return button
    }
}

// MARK: - ViewModel Binding
extension MapViewController {
    private func bindViewModel() {
        
        viewModel.loadWeatherInfo { [weak self] weatherInfo in
            if let icon = weatherInfo.icon {
                self?.weatherInfoView.setWeatherIcon(SWKitModule.image(named: icon))
            }
            
            let district = weatherInfo.district ?? "--"
            let text = weatherInfo.text ?? "--"
            let temp = weatherInfo.temp ?? "--"
            self?.weatherInfoView.setWeatherText(district + " " + text + " " + temp + "℃")
        }

        viewModel.$customPointData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if let customPointData = data?.first {
                    self.poiData = customPointData
                    self.showAddPOIStartView(with: customPointData)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$weatherData
            .receive(on: DispatchQueue.main)
            .sink { _ in
            }
            .store(in: &cancellables)
        
        // 监听错误
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .sink { error in
                guard let _ = error else { return }
            }
            .store(in: &cancellables)
        
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
            .store(in: &cancellables)
    }
    
    private func showLoading() {
        // 显示加载指示器
        view.makeToastActivity(.center)
    }
    
    private func hideLoading() {
        // 隐藏加载指示器
        view.hideToastActivity()
    }
    
    // 在 viewDidLoad 中调用数据请求
    private func loadInitialData() {
        
        // 请求路线列表数据
        let routeModel = RouteListReq(type: 0)
        viewModel.input.routeListRequest.send(routeModel)
        
        // 请求POI数据
        let poiModel = PublicPOIListModel(
            pageNum: 1,
            pageSize: 100
        )
        // 请求用户自定义兴趣点
        viewModel.input.userPoiListRequest.send(poiModel)
        
        loadRoutesMarkers()
        // 请求城市天气数据
        viewModel.input.weatherRequest.send()
    }
    
    private func setupBottomSheet(data: [MapSearchPointMsgData], isNetwork: Bool) {
        // 创建配置
        if data.count == 0  || !isNetwork {
            heightLevels = [0.35]
        }else {
            heightLevels = [0.2, 0.5, 0.8]
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
        contentView.choosePointAction = { [weak self] searchData in
            self?.bottomSheet.hide()

            guard let lon = searchData.longitude, let lat = searchData.latitude else { return }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            LocationManager().navigationToGaodeMap(with: coordinate, destinationName: searchData.name ?? "")
        }
        contentView.touchCellAction = {  [weak self] searchData in
            guard let lon = searchData.longitude, let lat = searchData.latitude, let mapView = self?.mapManager.mapView else { return }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            if let positon = TGCameraPosition(center: coordinate, zoom: mapView.zoom, bearing: 0, pitch: mapView.pitch) {
                mapView.fly(to: positon, withSpeed: 6)
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
    
    @objc private func onSearch() {
        isSearching = true
    }
    
    @objc private func onMeasure() {
        isMeasuring = true
    }

    @objc private func onBasemapPopup() {
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
                        self?.isAddPOIing = true
                    }
                ),
                PopupMenuItem(
                    title: "添加路线",
                    iconName: "map_addPoint_2",
                    action: { [weak self] in
                        self?.isAddRoute = true
                    }
                )
            ]
            showMenuPopover(items: items, type: .poi)
        }
    }

    // 天气
    @objc private func onWeather() {
        isWeathering = true
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
    
    @objc private func onTrack() {
        isAddTrack = true
    }
    
    @objc private func onTrackHistory() {
        SWRouter.handle(RouteTable.routeListPageUrl, parameters: ["type" : "1"])
    }
    
    @objc private func onSafeReport() {
        ReportManager.report(.safety)
    }
    
    @objc private func onSOS() {
        ReportManager.report(.openSOS)
    }
    
    @objc private func onCurrentWeather() {
        LocationManager().getCurrentLocation { location, error in
            if let location = location {
                self.showWeatherPointView(with: location.coordinate)
            }
        }
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
            ReportManager.report(.openSOS)
            // 显示成功提示
            SWAlertView.showConfirmAlert(title: "SOS报警", message: "SOS报警信息已经发送成功，请您保持自身安全，等待救援")
        }else {
            if let _ = BluetoothManager.shared.connectedPeripheral {
                BluetoothManager.shared.openSOS()
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
    
    private func updateButtonAppearance(_ button: UIButton, isActive: Bool) {
        UIView.animate(withDuration: 0.3) {
            button.backgroundColor = isActive ? .blue : .white
            button.tintColor = isActive ? .white : .blue
        }
    }
    
    func captureScreenshot(coordinates: [CLLocationCoordinate2D], completion: @escaping (UIImage?) -> Void) {
        guard let mapView = mapManager.mapView, let bounds = MapMarkerTool.getSWAndNE(coordinates) else {
            completion(nil)
            return
        }
        
        // 设置截图回调
        mapManager.onScreenshotCaptured = { [weak self] screenshot in
            self?.mapManager.showLocationMarker()
            // 裁剪出路线区域的正方形截图
            let cropBounds = MapMarkerTool.getCropRouteBoundsRect(mapView: mapView, bounds: bounds)
            let croppedImage = screenshot.cropImage(to: cropBounds)
            completion(croppedImage)
        }
        
        // 调整相机位置以显示所有规划的路线点
        MapMarkerTool.cameraPositionFitAllCoordinates(mapView: mapView, bounds: bounds) {
            self.mapManager.hideLocationMarker()
            // 延迟一下等待地图渲染完成
            DispatchQueue.mp_asyncAfter(0.5) {
                mapView.captureScreenshot(false)
            }
        }
    }
}

// MARK: - 搜索
extension MapViewController {
    
    private func searchLocation(_ query: String) {
        if viewModel.determineSearchType(query) == .coordinate {
            print("---------这是坐标---------")
            if let coordinate = parseCoordinate(from: query) {
                mapManager.createPointLocationMarker(with: coordinate)
                DispatchQueue.main.async {
                    self.showSearchPointView(with: coordinate)
                }
                
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
                        self.mapManager.buildSearchDataPointMapData(with: data)
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
            if #available(iOS 16.0, *) {
                // 自定义高度为屏幕高度的 60%
                sheet.detents = [
                    .custom { context in
                        return context.maximumDetentValue * (isInChina() ? 0.7 : 0.9)
                    }
                ]
            } else {
                // iOS 15 的备选方案
                sheet.detents = [.large()]
            }
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
    }
    
    private func presentAddPOIVC(latitude: Double, longitude: Double) {
        let coordinate = POICoordinate(latitude: latitude, longitude: longitude)
        
        // 创建添加页面
        let addPOIVC = AddPOIViewController(coordinate: coordinate, poiData: poiData)
        addPOIVC.deleteCustomMarker = { [weak self] userPOILocalData in
            guard let self = self else { return }
            self.hideAddPOIStartView()
            if let poiData = userPOILocalData {
                self.createCustomPOIMarker(with: poiData)
            }
        }
        addPOIVC.isModalInPresentation = true
        // 展示页面
        present(addPOIVC, animated: true)
    }
    
    private func presentAddRouteVC(route: Route?) {
        guard let route = route else { return }
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView(route: route)
        customView.closeHandler = { [weak self] in
            self?.isAddRoute = false
            popupContainer?.dismiss()
        }
        customView.confirmHandler = { [weak self] name, desc in
            guard let coordinates = self?.drawMarkerManager.coordinates else { return }
            popupContainer?.sw_showLoading()
            self?.captureScreenshot(coordinates: coordinates) { [weak self] screenshot in
                self?.routeManager.saveSessionRoute(newName: name, desc: desc, coverImage: screenshot) { [weak self] success in
                    popupContainer?.sw_hideLoading()
                    if success {
                        self?.isAddRoute = false
                        popupContainer?.dismiss()
                    }
                }
            }
        }
        popupContainer = SWPopupView.showFromBottom(contentView: customView,
                                                    configuration: SWPopupConfiguration(dismissOnMaskTap: false))
    }
    
    private func presentAddTrackVC(route: Route?) {
        guard let route = route else { return }
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView(route: route)
        customView.closeHandler = { [weak self] in
            self?.endRecordTrack()
            popupContainer?.dismiss()
        }
        customView.confirmHandler = { [weak self] name, desc in
            guard let coordinates = self?.trackManager.coordinates else { return }
            popupContainer?.sw_showLoading()
            self?.captureScreenshot(coordinates: coordinates) { [weak self] screenshot in
                self?.trackManager.saveSessionRoute(newName: name, coverImage: screenshot) { [weak self] success in
                    popupContainer?.sw_hideLoading()
                    if success {
                        self?.endRecordTrack()
                        popupContainer?.dismiss()
                    }
                }
            }
        }
        popupContainer = SWPopupView.showFromBottom(contentView: customView,
                                                    configuration: SWPopupConfiguration(dismissOnMaskTap: false))
    }
    
    private func showAlert(title: String, message: String, confirmText: String = "确定") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: confirmText, style: .default))
        present(alert, animated: true)
    }
}

extension MapViewController {
    
    // 当用户点击兴趣点时显示天气详情
    func showWeatherDetail(with poiId: String) {
        POIDatabaseManager.shared.fetchPOI(by: poiId) { [weak self] poi in
            if let poi = poi {
                print("公共兴趣点数据-----\(poi)")
                let weatherVC = POIWeatherDetailViewController(poiData: poi)
                if let sheet = weatherVC.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.prefersEdgeAttachedInCompactHeight = true
                    sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
                    sheet.delegate = weatherVC
                }
                self?.present(weatherVC, animated: true)
            }
        }
        
    }
    
    func showUserPointDetail(with poiData: UserPOILocalData) {
        let userPoiVC = UserPOIDetailViewController(poiData: poiData)
        userPoiVC.deletedUserPOISuccess = { [weak self] in
            guard let self = self else { return }
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            if let code = poiData.poiId {
                markerLayerManager.removeMarker("custom_\(code)", from: "custom")
            }
        }
        userPoiVC.hideOrShowUserPOISuccess = { [weak self] isShowPOI in
            guard let self = self else { return }
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            if let code = poiData.id {
                markerLayerManager.setMarkerVisible(isShowPOI, markerId: "custom_\(code)", in: "custom")
            }
        }
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
        if let id = Int(pointId), let poiData = UserPOILocalDBManager.shared.query(byId: id) {
            showUserPointDetail(with: poiData)
        }
    }
    
}
// LayerPopup中的通知方法
extension MapViewController {
    
    @objc private func changeMapSource(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let sceneUrl = userInfo["sceneUrl"] as? String {
            if sceneUrl.contains("天地图") {
                mapSourceTextLabel.text = "数据来自：中华人民共和国自然资源部GS(2025)1508号"
            }else if sceneUrl.contains("吉林") {
                mapSourceTextLabel.text = "数据来自：长光卫星技术股份有限公司GS(2025)1834号"
            }
            mapManager.switchTileSource(to: sceneUrl)
        }
            
    }
    
    @objc private func showNote(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let isShow = userInfo["isVisible"] as? Bool {
            mapManager.uploadNotesLayer(with: isShow)
        }
    }
    
    @objc private func showWeather(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let isWeather = userInfo["isVisible"] as? Bool {
            mapManager.ShowOrHideCityWeatherLayer(isShow: isWeather)
        }
    }
    
    @objc private func showCampgroundPoi(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        creatPublicMarkers()
        if let isCampground = userInfo["isVisible"] as? Bool {
            // 安全地访问 markerLayerManager
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            markerLayerManager.setLayerVisible(isCampground, layerId: "campsite")
        }
    }
    
    @objc private func showScenicPoi(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        creatPublicMarkers()
        if let isCampground = userInfo["isVisible"] as? Bool {
            // 安全地访问 markerLayerManager
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            markerLayerManager.setLayerVisible(isCampground, layerId: "scenicSpots")
        }
    }
    
    @objc private func showGasStationPoi(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        creatPublicMarkers()
        if let isCampground = userInfo["isVisible"] as? Bool {
            // 安全地访问 markerLayerManager
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            markerLayerManager.setLayerVisible(isCampground, layerId: "gasStation")
        }
    }
    
    @objc private func showMedicalPoi(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        creatPublicMarkers()
        if let isCampground = userInfo["isVisible"] as? Bool {
            // 安全地访问 markerLayerManager
            guard let markerLayerManager = mapManager.markerLayerManager else {
                print("标记层管理器未初始化")
                return
            }
            markerLayerManager.setLayerVisible(isCampground, layerId: "medical")
        }
    }
    
    @objc private func showSelectPoi(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
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
            if let medical = poiLayers["医疗"] {
                markerLayerManager.setLayerVisible(medical, layerId: "medical")
            }
        }
    }
    
    // 展示天气气泡视图
    public func showWeatherPointView(with coordinate: CLLocationCoordinate2D) {
        let weatherVC = POIWeatherDetailViewController(coordinate: coordinate)
        if let sheet = weatherVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheet.delegate = weatherVC
        }
        self.present(weatherVC, animated: true)
    }
}

extension MapViewController: BottomSheetViewDelegate {
    
}


// MARK: - 编辑模式
extension MapViewController {
    
    
    private func enterEditMode(with titleText: String?) {
        navigationBar.setTitle(titleText, color: .white)
        topMaskView.isHidden = false
        mapFakeSearchView.isHidden = true
        topButtonStack.isHidden = true
        middleButtonStack.isHidden = true
        weatherInfoView.isHidden = true
        
        rightButtonsTopConstraint.constant = swAdaptedValue(500)
        mapSourceImageBottomConstraint.constant = -20
        self.tabBarController?.tabBar.isHidden = true
        
        removeRouteMarkerLayers()
    }
    
    private func exitEditMode() {
        navigationBar.setTitle(nil)
        topMaskView.isHidden = true
        mapFakeSearchView.isHidden = false
        topButtonStack.isHidden = false
        middleButtonStack.isHidden = false
        weatherInfoView.isHidden = false
        
        rightButtonsTopConstraint.constant = swAdaptedValue(82)
        mapSourceImageBottomConstraint.constant = -88
        self.tabBarController?.tabBar.isHidden = false
        
        loadRoutesMarkers()
    }
    
    private func enterSearchMode() {
        mapFakeSearchView.isHidden = true
        mapRealSearchView.isHidden = false
        topButtonStack.isHidden = true
        middleButtonStack.isHidden = true
        
        mapRealSearchView.searchTextField.becomeFirstResponder()
        rightButtonsTopConstraint.constant = swAdaptedValue(500)
        mapSourceImageBottomConstraint.constant = -20
        self.tabBarController?.tabBar.isHidden = true
    }
    
    private func exitSearchMode() {
        mapFakeSearchView.isHidden = false
        mapRealSearchView.isHidden = true
        topButtonStack.isHidden = false
        middleButtonStack.isHidden = false
        
        rightButtonsTopConstraint.constant = swAdaptedValue(82)
        mapSourceImageBottomConstraint.constant = -88
        self.tabBarController?.tabBar.isHidden = false
        
        hideSearchPointView()
    }
    
    private func enterTrackMode() {
        enterEditMode(with: "记录轨迹")
        trackBottomView.isHidden = false
        trackHistoryButton.isHidden = false
        rightButtonsTopConstraint.constant = swAdaptedValue(370)
    }
    
    private func exitTrackMode() {
        exitEditMode()
        trackBottomView.isHidden = true
        trackHistoryButton.isHidden = true
    }
    
    private func startRecordTrack() {
        trajectoryButton.isSelected = true
        trackManager.startRecord()
    }
    
    private func endRecordTrack() {
        isAddTrack = false
        trajectoryButton.isSelected = false
        trackBottomView.clean()
        trackManager.endRecord()
    }
    
    private func enterRouteMode() {
        enterEditMode(with: "绘制路线")
        rightButtonsTopConstraint.constant = swAdaptedValue(500)
        routeManager.startRecord()
    }
    
    private func exitRouteMode() {
        exitEditMode()
        routeBottomView.isHidden = true
        drawMarkerManager.clear()
        routeManager.endRecord()
    }
    
    private func enterMeasureMode() {
        enterEditMode(with: "测距")
        rightButtonsTopConstraint.constant = swAdaptedValue(500)
    }
    
    private func exitMeasureMode() {
        exitEditMode()
        measureBottomView.isHidden = true
        drawMarkerManager.clear()
    }
}

// MARK: - 添加兴趣点的视图动画
extension MapViewController {
    
    private func showAddPOIStartView(with poiData: MapSearchPointMsgData?) {
        if let poiData = poiData {
            self.addPOIStartView.config(poiData)
        }
        if addPOIStartView.frame.origin.y == ScreenUtil.screenHeight {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.addPOIStartView?.frame = CGRect(x: 0, y: ScreenUtil.screenHeight-AddPOIStartViewHeight, width: ScreenUtil.screenWidth, height: AddPOIStartViewHeight)
            }
        }
    }
    
    private func hideAddPOIStartView() {
        mapManager.hideWeatherPointMarker()
        if addPOIStartView.frame.origin.y == ScreenUtil.screenHeight-AddPOIStartViewHeight {
            self.addPOIStartView.resetUI()
            self.addPOIStartView?.frame = CGRect(x: 0, y: ScreenUtil.screenHeight, width: ScreenUtil.screenWidth, height: AddPOIStartViewHeight)
        }
    }
}

// MARK: - 添加兴趣点的视图动画
extension MapViewController {
    
    private func showSearchPointView(with coordinate: CLLocationCoordinate2D) {
        let longitudeStr = String(format: "%.6f", coordinate.longitude)
        let latitudeStr = String(format: "%.6f", coordinate.latitude)
        let destinationName = "\(longitudeStr),\(latitudeStr)"
        self.searchPointView.config(with: destinationName)
        self.searchPointView.navigationAction = {
            LocationManager().navigationToGaodeMap(with: coordinate, destinationName: destinationName)
        }
        if searchPointView.frame.origin.y == ScreenUtil.screenHeight {
            UIView.animate(withDuration: 0.3) { [weak self] in
                guard let self = self else { return }
                self.searchPointView?.frame = CGRect(x: 0, y: ScreenUtil.screenHeight-SearchPointViewHeight, width: ScreenUtil.screenWidth, height: SearchPointViewHeight)
            }
        }
    }
    
    private func hideSearchPointView() {
        mapManager.hideWeatherPointMarker()
        if searchPointView.frame.origin.y == ScreenUtil.screenHeight-SearchPointViewHeight {
            self.searchPointView.resetUI()
            self.searchPointView?.frame = CGRect(x: 0, y: ScreenUtil.screenHeight, width: ScreenUtil.screenWidth, height: SearchPointViewHeight)
        }
    }
}
