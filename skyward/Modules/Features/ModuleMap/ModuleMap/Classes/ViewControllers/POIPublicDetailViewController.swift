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

class POIPublicDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let mapManager = MapManager()
    
    private var poiData: PublicPOIData!
    
    init(poiData: PublicPOIData) {
        self.poiData = poiData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        creatPOIMarker(with: poiData)
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
        showUserPointDetail(with: poiData)
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
        mapManager.onMarkerSelected = { [weak self] markerId, data, layerId in
            guard let self = self else { return }
            print("\(markerId)----点--被点击")
            showUserPointDetail(with: poiData)
        }
    }
    
    func showUserPointDetail(with poiData: PublicPOIData) {
        let weatherVC = POIWeatherDetailViewController(poiData: poiData)
        if let sheet = weatherVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheet.delegate = weatherVC
        }
        present(weatherVC, animated: true)
    }
    
    private func creatPOIMarker(with poiData: PublicPOIData) {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            print("标记层管理器未初始化")
            return
        }
        _ = markerLayerManager.createLayer(id: "campsite", name: "露营地", isVisible: true)
        _ = markerLayerManager.createLayer(id: "scenicSpots", name: "风景名胜", isVisible: true)
        _ = markerLayerManager.createLayer(id: "gasStation", name: "加油站", isVisible: true)
        _ = markerLayerManager.createLayer(id: "medical", name: "医疗", isVisible: true)
        
       var styleStr = "campsite"
        switch poiData.category {
        case 1:
            styleStr = "campsite"
        case 2:
            styleStr = "scenicSpots"
        case 3:
            styleStr = "gasStation"
        case 4:
            styleStr = "medical"
        default:
            styleStr = "campsite"
        }
        
        addMarkerWirtStyle(poiData: poiData, styleStr: styleStr)
        
        
    }
    
    private func addMarkerWirtStyle(poiData: PublicPOIData, styleStr: String) {
        guard let markerLayerManager = mapManager.markerLayerManager, let mapView = mapManager.mapView else {
            print("标记层管理器未初始化")
            return
        }
        // 移除所有的marker
        markerLayerManager.removeAllMarkers(in: styleStr)
        // 重新添加新的marker
        
        if let lat = poiData.wgsLat, let lon = poiData.wgsLon, let id = poiData.id {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let data = MarkerData(
                id: "\(styleStr)_\(id)",
                coordinate: coordinate,
                title: poiData.name ?? "",
                subtitle: poiData.address ?? ""
            )
            markerLayerManager.addMarker(to: styleStr, data: data)
            
            let cententCorrdinate = CLLocationCoordinate2D(latitude: coordinate.latitude-0.003, longitude: coordinate.longitude)
            if let positon = TGCameraPosition(center: cententCorrdinate, zoom: 16, bearing: 0, pitch: mapView.pitch) {
                mapView.fly(to: positon, withSpeed: 6)
            }
        }
        
    }
}
