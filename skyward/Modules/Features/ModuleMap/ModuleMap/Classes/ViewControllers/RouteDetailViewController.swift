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

class RouteDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let mapManager = MapManager()
    private let dataManager = RouteDataManager()
    
    var deleteSuccessHandler: (() -> Void)?
    var editSuccessHandler: ((Route) -> Void)?
    var uploadSuccessHandler: (() -> Void)?
    
    private var route: Route!
    
    init(route: Route) {
        super.init(nibName: nil, bundle: nil)
        self.route = route
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registeMarkerLayers()
        
        if dataManager.routeExsitInLocal(routeId: route.id) {
            DispatchQueue.mp_asyncAfter(1) {
                self.addRoutesMarkers()
                self.presentRouteDetail(route: self.route)
                self.cameraPositionMarkers()
            }
            
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
                        self?.addRoutesMarkers()
                        self?.presentRouteDetail(route: route)
                        self?.cameraPositionMarkers()
                    }
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

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
        MapConfig.shared.saveConfig()
        
        let mapView = mapManager.createMapView(in: self.view, frame: CGRectMake(0, 0, ScreenUtil.screenWidth, ScreenUtil.screenHeight))
        view.addSubview(mapView)
        
        // 设置回调
        mapManager.onMarkerSelected = { [weak self] _, _, _ in
            if let route = self?.route {
                self?.presentRouteDetail(route: route)
            }
        }
    }
    
    // MARK: - Markers
    
    private func registeMarkerLayers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        _ = markerLayerManager.createLayer(id: "myRoutesLine", name: "我的路线", isVisible: true)
        _ = markerLayerManager.createLayer(id: "myRoutesNode", name: "我的路线节点", isVisible: true)
    }
    
    func addRoutesMarkers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        
        let routeId = route.id
        let points = dataManager.readCoordinatesFromGPXFile(from: routeId)
        if points.count > 1 {
            let coordinates = points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            markerLayerManager.addLineMarker(to: "myRoutesLine", id: String(routeId), coordinates: coordinates, title: route.routeName ?? "", subTitle: route.description ?? "")
            coordinates.forEach { coordinate in
                markerLayerManager.addPointMarker(to: "myRoutesNode", id: String(coordinate.longitude), coordinate: coordinate)
            }
        }
    }
    
    func removeRoutesMarkers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        
        let routeId = route.id
        //移除线
        markerLayerManager.removeMarker("\(routeId)", from: "myRoutesLine")
        let points = dataManager.readCoordinatesFromGPXFile(from: routeId)
        //移除点
        points.forEach { coordinate in
            markerLayerManager.removeMarker(String(coordinate.longitude), from: "myRoutesNode")
        }
    }
    
    func cameraPositionMarkers() {
//        if let startLongitude = route.startLongitude, let startLatitude = route.startLatitude, let endLongitude = route.endLongitude, let endLatitude = route.endLatitude {
//            let startCoordinate = CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
//            let endCoordinate = CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
//            let bounds = TGCoordinateBounds(sw: startCoordinate, ne: endCoordinate)
//            let cameraPosition = mapManager.mapView?.cameraThatFitsBounds(bounds, withPadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50))
//            mapManager.mapView?.setCameraPosition(cameraPosition!, withDuration: 0.3, easeType: .linear)
//        }
        
        let routeId = route.id
        let coordinates = dataManager.readCoordinatesFromGPXFile(from: routeId)
        if coordinates.count > 1 {
            let bounds = TGCoordinateBounds(sw: coordinates.first!, ne: coordinates.last!)
            let cameraPosition = mapManager.mapView?.cameraThatFitsBounds(bounds, withPadding: UIEdgeInsets(top: 180, left: 60, bottom: 264, right: 60))
            mapManager.mapView?.setCameraPosition(cameraPosition!, withDuration: 0.3, easeType: .linear)
        }
    }
    
    // MARK: - private
    
    private func presentRouteDetail(route: Route) {
        
        let routeId = route.id
        
        var popupContainer: SWPopupView?
        
        let customView = LookRoutePopupView(route: route)
        customView.closeHandler = {
            popupContainer?.dismiss()
        }
        customView.deleteHandler = {
            let name = route.type == RouteType.track.rawValue ? RouteType.track.name() : RouteType.route.name()
            SWAlertView.showAlert(title: nil, message: "确定删除该\(name)吗？") {
                self.deleteRoute(routeId: routeId) {
                    popupContainer?.dismiss()
                    self.deleteSuccessHandler?()
                }
            }
        }
        customView.editHandler = {
            self.editRoute(route: route) { editedRoute in
                customView.configure(route: editedRoute)
                self.editSuccessHandler?(editedRoute)
            }
        }
        
        customView.uploadHandler = {
            self.dataManager.saveRouteToService(route) { [weak self] success in
                if success {
                    self?.uploadSuccessHandler?()
                }
            }
        }
        
        customView.showHandler = { show in
            self.visibleRoute(route: route, show: show)
        }
        
        popupContainer = SWPopupView.showFromBottom(contentView: customView)
    }
    
    private func deleteRoute(routeId: String, completion: @escaping () -> Void) {
        self.view.sw_showLoading()
        self.dataManager.deleteRouteFromService(routeId: routeId) { [weak self] success, errorMsg in
            completion()
            self?.view.sw_hideLoading()
            if success {
                self?.removeRoutesMarkers()
                self?.navigationController?.popViewController(animated: true)
            } else {
                if let errorMsg = errorMsg, !errorMsg.isEmpty {
                    self?.view.sw_showWarningToast(errorMsg)
                }
            }
        }
    }
    
    private func editRoute(route: Route, completion: @escaping (Route) -> Void) {
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView(route: route)
        customView.closeHandler = {
            popupContainer?.dismiss()
        }
        customView.confirmHandler = { [weak self] name, desc in
            var newRoute = route
            newRoute.routeName = name
            newRoute.description = desc
            self?.view.sw_showLoading()
            self?.dataManager.updateRouteToService(newRoute) { success, errorMsg in
                self?.view.sw_hideLoading()
                completion(newRoute)
                popupContainer?.dismiss()
            }
        }
        popupContainer = SWPopupView.showFromBottom(contentView: customView)
    }
    
    private func visibleRoute(route: Route, show: Bool) {
        var newRoute = route
        newRoute.isVisible = show
        self.dataManager.updateLocalRoute(route: newRoute)

        let name = route.type == RouteType.track.rawValue ? RouteType.track.name() : RouteType.route.name()
        
        if show {
            view.sw_showSuccessToast("\(name)已在地图上显示，返回地图页即可查看")
        } else {
            view.sw_showSuccessToast("\(name)已在地图上隐藏")
        }
    }
}
