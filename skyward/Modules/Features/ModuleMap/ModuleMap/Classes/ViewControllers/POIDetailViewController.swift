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

class POIDetailViewController: BaseViewController {
    
    // MARK: - Properties
    private let mapManager = MapManager()
    
    private var poiData: UserPOILocalData!
    
    init(poiData: UserPOILocalData) {
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
    
    func showUserPointDetail(with poiData: UserPOILocalData) {
        let userPoiVC = UserPOIDetailViewController(poiData: poiData)
        userPoiVC.deletedUserPOISuccess = { [weak self] in
            guard let self = self else { return }
            navigationController?.popViewController(animated: true)
        }
        userPoiVC.editUserPOI = { [weak self] poiData in
            guard let self = self else { return }
            presentEditVC(poiData: poiData)
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
    
    private func creatPOIMarker(with poiData: UserPOILocalData) {
        guard let markerLayerManager = mapManager.markerLayerManager, let mapView = mapManager.mapView else {
            print("标记层管理器未初始化")
            return
        }
        _ = markerLayerManager.createLayer(id: "userPOI", name: "兴趣点", isVisible: true)
        
        let coordinate = CLLocationCoordinate2D(latitude: poiData.lat ?? 00, longitude: poiData.lon ?? 00)
        let data = MarkerData(
            id: "userPOI_\(poiData.id ?? 0)",
            coordinate: coordinate,
            title: poiData.name ?? "",
            subtitle: poiData.address ?? ""
        )
        markerLayerManager.addMarker(to: "userPOI", data: data)
        
        let cententCorrdinate = CLLocationCoordinate2D(latitude: coordinate.latitude-0.003, longitude: coordinate.longitude)
        if let positon = TGCameraPosition(center: cententCorrdinate, zoom: 16, bearing: 0, pitch: mapView.pitch) {
            mapView.fly(to: positon, withSpeed: 6)
        }
    }
    
    private func presentEditVC(poiData: UserPOILocalData) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let addPOIVC = EditPOIViewController(poiData: poiData)
            addPOIVC.deleteCustomMarker = { [weak self] userPOILocalData in
                guard let self = self else { return }
                showUserPointDetail(with: poiData)
            }
            addPOIVC.isModalInPresentation = true
            // 展示页面
            self?.present(addPOIVC, animated: true)
        }
    }
}
