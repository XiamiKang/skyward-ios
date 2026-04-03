//
//  RouteDetailViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/9.
//

import UIKit
import CoreLocation
import SnapKit
import TangramMap
import TXKit
import SWKit
import SWNetwork

class RouteDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let mapManager = MapManager()
    private let dataManager = RouteDataManager()
    
    var deleteSuccessHandler: (() -> Void)?
    var editSuccessHandler: ((Route) -> Void)?
    var uploadSuccessHandler: ((Route) -> Void)?
    var visibleSuccessHandler: ((Route) -> Void)?
    var coverSuccesHandler: (() -> Void)?
    
    private var route: Route
    private var showingPopupView: LookRoutePopupView?
    
    init(route: Route) {
        self.route = route
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registeMarkerLayers()
        
        if let _ = dataManager.getLocalRoute(routeId: route.id) {
            loadUI()
            return
        }
        view.sw_showLoading()
        dataManager.downloadRouteGPXFile(route) { [weak self] errorMsg in
            DispatchQueue.main.async {
                self?.view.sw_hideLoading()
                if let errorMsg = errorMsg {
                    self?.view.sw_showWarningToast(errorMsg)
                } else {
                    if let route = self?.route {
                        self?.dataManager.saveServiceRouteToLocal(route)
                        self?.loadUI()
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
            MapConfig.shared.defaultZoom = 16
            MapConfig.shared.saveConfig()
            
            mapManager.reset()
            mapManager.stopLocationTracking()
        }
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        setupMap()
        view.addSubview(topMaskView)
        view.addSubview(navigationBar)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
    }
    
    // MARK: - UI Components
    
    private let topMaskView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenUtil.screenWidth, height: 44 + ScreenUtil.statusBarHeight))
        // 添加渐变背景
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(1.0).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        return view
    }()
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.backgroundColor = .clear
        bar.setLeftButton(image: SWKitModule.image(named: "nav_arrow")?.withTintColor(.white)) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    private func setupMap() {
        MapConfig.shared.defaultZoom = 18
        MapConfig.shared.showUserLocation = false
        MapConfig.shared.saveConfig()
        
        let mapView = mapManager.createMapView(in: self.view, frame: CGRectMake(0, 0, ScreenUtil.screenWidth, ScreenUtil.screenHeight))
        view.addSubview(mapView)
        
        // 设置回调
        mapManager.onMarkerSelected = { [weak self] _, _, _ in
            self?.presentRouteDetail()
        }
    }
    // MARK: - Load
    
    private func loadUI() {
        addRoutesMarkers()
        cameraPositionMarkers()
        presentRouteDetail()
        slientCompleteRouteToServerIfNeeded()
    }
    
    private func slientCompleteRouteToServerIfNeeded() {
        guard NetworkMonitor.shared.isConnected else {
            return
        }
        
        let route = self.route
        
        assembleRoute { [weak self] screenshot in
            let needCompleteAddr = (route.startName == nil && self?.route.startName?.isEmpty == false) || (route.endName == nil && self?.route.endName?.isEmpty == false)
            let needCompleteCover = (route.coverImageUrl == nil || route.coverImageUrl?.isEmpty == true) && screenshot != nil

            if needCompleteCover {
                // 更新本地数据
                if route.uploaded == true {
                    self?.dataManager.uploadRouteCoverToServer(screenshot!) { [weak self] fileUrl in
                        if var route = self?.route {
                            route.coverImageUrl = fileUrl
                            self?.dataManager.updateRouteToServer(route)
                            //TODO: 封面同步列表
                        }
                    }
                } else {
                    RouteDataManager.saveRouteCoverToLocal(screenshot, routeId: route.id)
                    self?.coverSuccesHandler?()
                }
            } else {
                if needCompleteAddr {
                    if let route = self?.route {
                        self?.dataManager.updateRouteToServer(route)
                    }
                }
            }
        }
    }
    
    // MARK: - Markers
    
    private func registeMarkerLayers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        _ = markerLayerManager.createLayer(id: "route_line", name: "我的路线", isVisible: true)
        _ = markerLayerManager.createLayer(id: "route_node", name: "我的路线节点", isVisible: true)
        _ = markerLayerManager.createLayer(id: "track_start", name: "轨迹起点", isVisible: true)
        _ = markerLayerManager.createLayer(id: "track_end", name: "轨迹终点", isVisible: true)
    }
    
    func addRoutesMarkers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        
        let routeId = route.id
        let coordinates = dataManager.readCoordinatesFromGPXFile(from: routeId)
        if coordinates.count > 1 {
            markerLayerManager.addLineMarker(to: "route_line", id: String(routeId), coordinates: coordinates, title: route.routeName ?? "", subTitle: route.description ?? "")
            if route.type == RouteType.track.rawValue {
                markerLayerManager.addPointMarker(to: "track_start", id: "1", coordinate: coordinates.first!)
                markerLayerManager.addPointMarker(to: "track_end", id: "2", coordinate: coordinates.last!)
            } else {
                coordinates.forEach { coordinate in
                    markerLayerManager.addPointMarker(to: "route_node", id: String(coordinate.longitude), coordinate: coordinate)
                }
            }
        }
    }
    
    func removeRoutesMarkers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        
        let routeId = route.id
        //移除线
        markerLayerManager.removeMarker("\(routeId)", from: "route_line")
        let points = dataManager.readCoordinatesFromGPXFile(from: routeId)
        //移除点
        points.forEach { coordinate in
            markerLayerManager.removeMarker(String(coordinate.longitude), from: "route_node")
        }
    }
    
    func cameraPositionMarkers() {
        let coordinates = dataManager.readCoordinatesFromGPXFile(from: route.id)
        guard let mapView = mapManager.mapView, let (sw, ne) = MapMarkerTool.getSWAndNE(coordinates) else {
            return
        }
        let bounds = TGCoordinateBounds(sw: sw, ne: ne)
        let cameraPosition = mapView.cameraThatFitsBounds(bounds, withPadding: UIEdgeInsets(top: 180, left: 60, bottom: 280, right: 60))
        mapView.cameraPosition = cameraPosition
    }
    
    // MARK: - 弹窗
    
    private func presentRouteDetail() {
        let route = self.route
        // 防止重复弹出
        guard showingPopupView == nil else { return }

        let customView = LookRoutePopupView(route: route)
        showingPopupView = customView

        // 使用约束布局，让高度根据子视图自适应
        view.addSubview(customView)
        customView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        // 强制布局以获取实际高度
        customView.layoutIfNeeded()

        // 设置初始位置在屏幕底部之外
        customView.transform = CGAffineTransform(translationX: 0, y: customView.bounds.height)

        // 从底部弹出动画
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            customView.transform = .identity
        }

        customView.closeHandler = { [weak self] in
            self?.dismissRouteDetail(customView)
        }

        customView.deleteHandler = { [weak self] in
            let name = route.type == RouteType.track.rawValue ? RouteType.track.name() : RouteType.route.name()
            SWAlertView.showAlert(title: nil, message: "确定删除该\(name)吗？") {
                self?.deleteRoute { [weak self] success in
                    if success {
                        self?.removeRoutesMarkers()
                        self?.dismissRouteDetail(customView)
                        self?.deleteSuccessHandler?()
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }

        customView.editHandler = { [weak self] in
            self?.presentEditRoute(route: route) { [weak self] in
                self?.editRoute { [weak self] success in
                    if success, let newRoute = self?.route {
                        customView.configure(route: newRoute)
                        self?.editSuccessHandler?(newRoute)
                    }
                }
            }
        }

        customView.uploadHandler = { [weak self] in
            self?.saveRoute { [weak self] success in
                if success, let newRoute = self?.route {
                    self?.dismissRouteDetail(customView)
                    self?.uploadSuccessHandler?(newRoute)
                }
            }
        }

        customView.showHandler = { [weak self] show in
            self?.visibleRoute(show: show)
        }
    }

    private func dismissRouteDetail(_ detailView: LookRoutePopupView) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            detailView.transform = CGAffineTransform(translationX: 0, y: detailView.bounds.height)
        } completion: { _ in
            detailView.removeFromSuperview()
            self.showingPopupView = nil
        }
    }
    
    private func presentEditRoute(route: Route, completion: @escaping () -> Void) {
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView(route: route)
        customView.closeHandler = {
            popupContainer?.dismiss()
        }
        customView.confirmHandler = { name, desc in
            self.route.routeName = name
            self.route.description = desc
            popupContainer?.dismiss()
            completion()
        }
        popupContainer = SWPopupView.showFromBottom(contentView: customView)
    }
    
    // MARK: - 增删改查
    
    private func deleteRoute(completion: @escaping (Bool) -> Void) {
        let routeId = route.id
        if route.uploaded == true {
            view.sw_showLoading()
            dataManager.deleteRouteFromServer(routeId: routeId) { [weak self] success in
                self?.view.sw_hideLoading()
                completion(success)
            }
        } else {
            completion(dataManager.deleteRouteFromLocal(routeId))
        }
    }
    
    private func editRoute(completion: @escaping (Bool) -> Void) {
        if route.uploaded == true {
            view.sw_showLoading()
            dataManager.updateRouteToServer(route) { [weak self] success in
                self?.view.sw_hideLoading()
                completion(success)
            }
        } else {
            completion(dataManager.updateLocalRoute(route: route))
        }
    }
    
    private func saveRoute(completion: @escaping (Bool) -> Void) {
        view.sw_showLoading()
        assembleRoute { [weak self] image in
            guard let route = self?.route else {
                return
            }
            self?.dataManager.saveRouteToServer(route, coverImage: image) { success in
                self?.view.sw_hideLoading()
                self?.route.uploaded = true
                completion(success)
            }
        }
    }
    
    private func visibleRoute(show: Bool) {
        route.isVisible = show
        if dataManager.updateLocalRoute(route: route) {
            visibleSuccessHandler?(route)
            let name = route.type == RouteType.track.rawValue ? RouteType.track.name() : RouteType.route.name()
            
            if show {
                view.sw_showSuccessToast("\(name)已在地图上显示，返回地图页即可查看")
            } else {
                view.sw_showSuccessToast("\(name)已在地图上隐藏")
            }
        } else {
            route.isVisible = !show
        }
    }
    
    // MARK: - 保存上传
    
    private func assembleRoute(completion: @escaping (UIImage?) -> Void) {
        let route = self.route
        let group = DispatchGroup()
 
        group.enter()
        RouteDataManager.assembleRoute(route) { [weak self] updatedRoute in
            self?.route = updatedRoute
            // 更新到数据库
            self?.dataManager.updateLocalRoute(route: updatedRoute)
            // 更新弹窗UI
            self?.showingPopupView?.configure(route: updatedRoute)
            group.leave()
        }
        
        var screenshot: UIImage?
        
        if (route.coverImageUrl == nil || route.coverImageUrl?.isEmpty == true), RouteDataManager.getRouteCoverFromLocal(routeId: route.id) == nil {
            group.enter()
            getScreenShot { image in
                screenshot = image
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(screenshot)
        }
    }
    
    private func getScreenShot(completion: @escaping (UIImage?) -> Void) {
        let coordinates = dataManager.readCoordinatesFromGPXFile(from: route.id)
        guard let mapView = mapManager.mapView, let bounds = MapMarkerTool.getSWAndNE(coordinates) else {
            completion(nil)
            return
        }
        // 设置截图回调
        mapManager.onScreenshotCaptured = { screenshot in
            // 裁剪出路线区域的正方形截图
            let cropBounds = MapMarkerTool.getCropRouteBoundsRect(mapView: mapView, bounds: bounds)
            let croppedImage = screenshot.cropImage(to: cropBounds)
            completion(croppedImage)
        }

        // 调整相机位置以显示所有规划的路线点
        let bounds2 = TGCoordinateBounds(sw: bounds.0, ne: bounds.1)
        let cameraPosition = mapView.cameraThatFitsBounds(bounds2, withPadding: UIEdgeInsets(top: 180, left: 60, bottom: 280, right: 60))
        mapView.cameraPosition = cameraPosition

        DispatchQueue.mp_asyncAfter(0.5) {
            mapView.captureScreenshot(false)
        }
    }
}
