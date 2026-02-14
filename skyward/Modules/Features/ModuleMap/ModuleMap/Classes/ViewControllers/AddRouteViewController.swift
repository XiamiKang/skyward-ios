//
//  AddRouteViewController.swift
//  yifan_test
//
//  Created by TXTS on 2025/12/2.
//

import UIKit
import CoreLocation
import SnapKit
import TXKit
import SWKit
import SWTheme

class AddRouteViewController: BaseViewController {
    
    // MARK: - Properties

    private let dataManager = RouteDataManager()

    private lazy var mapManager: MapManager = {
        let manager = MapManager()
        manager.onMapSingleTapHandler = { [weak self] (coordinate, point) in
            if self?.distanceManager.coordinates.count == 0 {
                self?.routeBottomView.isHidden = false
            }
            self?.distanceManager.addRouteLine(at: coordinate)
            self?.writePoint(coordinate)
        }
        return manager
    }()
    
    private lazy var distanceManager: DistanceMeasurementManager = {
        var mapView = mapManager.mapView
        if mapView == nil {
            mapView = mapManager.createMapView(in: self.view, frame: self.view.frame)
        }
        let distanceManager = DistanceMeasurementManager(mapView: mapView!)
        return distanceManager
    }()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataManager.startRecord(type: .route)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent {
            mapManager.reset()
            mapManager.stopLocationTracking()
            
            dataManager.endRecord()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        let mapView = mapManager.createMapView(in: self.view, frame: CGRectMake(0, 0, ScreenUtil.screenWidth, ScreenUtil.screenHeight))
        
        view.addSubview(mapView)
        view.addSubview(panel)
        view.addSubview(topMaskView)
        view.addSubview(navigationBar)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        panel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(swAdaptedValue(121) + ScreenUtil.safeAreaBottom)
            make.right.equalToSuperview().inset(Layout.hMargin)
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
        bar.setTitle("绘制路线", color: .white)
        bar.setLeftButton(image: SWKitModule.image(named: "nav_arrow")?.withTintColor(.white)) { [weak self] in
            self?.navigationController?.popViewController(animated: false)
        }
        return bar
    }()
    
    private lazy var panel: MapFunctionPanelView = {
        let panel = MapFunctionPanelView()
        panel.configure(types: [.location, .safety, .sos])
        panel.onButtonTapped = { [weak self] type in
            switch type {
            case .location:
                self?.mapManager.moveToUserLocation()
            case .safety:
                ReportManager.report(.safety)
            default: break
            }
        }
        panel.onSOSLongPressTriggered = {
            ReportManager.report(.sos)
        }
        return panel
    }()
    
    private lazy var routeBottomView: RouteBottomView = {
       let view = RouteBottomView()
        view.revocationButton.addAction(UIAction {[weak self] _ in
            if self?.dataManager.sessionRouteRemoveLastPoint() == true {
                self?.distanceManager.revocation()
                if self?.distanceManager.coordinates.count == 0 {
                    self?.routeBottomView.isHidden = true
                }
            }
        }, for: .touchUpInside)
        view.confirmButton.addAction(UIAction {[weak self] _ in
            self?.prepareSaveRoute { image in
                self?.presentAddRouteVC(image: image)
            }
        }, for: .touchUpInside)
        view.deleteButton.addAction(UIAction {[weak self] _ in
            if self?.dataManager.sessionRouteRemoveAllPoint() == true {
                self?.distanceManager.clear()
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
    
    // MARK: - 增删改查
    
    func writePoint(_ point: CLLocationCoordinate2D) {
        let point = RecordPoint(latitude: point.latitude, longitude: point.longitude)
        if dataManager.writePointToSessionTxtFile(point) {
            dataManager.updateSessionRoute(point: point)
        }
    }
    
    func saveRoute(name: String, desc: String?, coverImage: UIImage?, completion: @escaping ()->Void) {
        dataManager.updateSessionRoute(name: name, desc: desc)
        guard let route = dataManager.sessionRoute else {
            return
        }
        
        self.view.sw_showLoading()
        self.dataManager.saveRouteToService(route, coverImage: coverImage) { [weak self] success in
            self?.view.sw_hideLoading()
            if success {
                completion()
            }
        }
    }
    
    // MARK: - private
    
    private func prepareSaveRoute(completion: @escaping (UIImage?) -> Void) {
        let group = DispatchGroup()
        
        group.enter()
        dataManager.assembleSessionRoute {
            group.leave()
        }
        var screenshot: UIImage?
        group.enter()
        getScreenShot { image in
            screenshot = image
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(screenshot)
        }
    }
    
    private func getScreenShot(completion: @escaping (UIImage?) -> Void) {
        // 设置截图回调
        mapManager.onScreenshotCaptured = { [weak self] screenshot in
            Logger.debug("完成执行截图")
            // 恢复 UI
            self?.panel.isHidden = false
            self?.navigationBar.isHidden = false

            // 裁剪出路线区域的正方形截图
            var croppedImage: UIImage?
            if let cropBounds = self?.distanceManager.getCropBoundsRect() {
                croppedImage = screenshot.cropImage(to: cropBounds)
                Logger.debug("截图裁剪区域：\(cropBounds) 截图尺寸：\(croppedImage!.size)")
            } else {
                // 如果无法获取路线边界，使用原图
                croppedImage = screenshot
            }
            completion(croppedImage)
        }
        
        // 调整相机位置以显示所有规划的路线点
        distanceManager.fitAllCoordinates(animated: true) { [weak self] in
            // 延迟一下等待地图渲染完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Logger.debug("开始执行截图")
                self?.panel.isHidden = true
                self?.navigationBar.isHidden = true
                self?.mapManager.mapView?.captureScreenshot(false)
            }
        }
    }
    
    private func presentAddRouteVC(image: UIImage? = nil) {
        guard let route = dataManager.sessionRoute else {
            return
        }
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView(route: route)
        customView.closeHandler = {
            popupContainer?.dismiss()
        }
        customView.confirmHandler = {[weak self] name, desc in
            self?.dataManager.checkSensitiveWords(name + (desc ?? "")) { [weak self] success, msg  in
                if success {
                    self?.saveRoute(name: name, desc: desc, coverImage: image) { [weak self] in
                        self?.dataManager.endRecord()
                        self?.distanceManager.clear()
                        self?.routeBottomView.isHidden = true
                        popupContainer?.dismiss()
                    }
                }
                if let msg = msg {
                    self?.view.sw_showWarningToast(msg)
                }
            }
        }
        popupContainer = SWPopupView.showFromBottom(contentView: customView,
                                                    configuration: SWPopupConfiguration(dismissOnMaskTap: false))
    }
    
    //MARK: - Notification

    @objc func appDidTermination() {
        // 如果正在记录，杀程序需要endRecord
        Logger.debug("app被杀死了，需要：\(dataManager) 执行endRecord()")
        dataManager.endRecord()
    }
}
