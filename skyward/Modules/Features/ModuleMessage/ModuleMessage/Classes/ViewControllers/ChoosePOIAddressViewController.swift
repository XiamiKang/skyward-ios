//
//  ChoosePOIAddressViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/3/25.
//

import UIKit
import SnapKit
import SWTheme
import SWKit
import TXKit
import SWNetwork
import CoreLocation

class ChoosePOIAddressViewController: UIViewController {
    
    var onSelectedAddressHandler: ((AroundPOIData) -> Void)?
    
    private let mapManager = MapManager()
    
    private let poiListView = AroundPOITableViewContainerView()
    
    private var selectedAroundPOIData: AroundPOIData?
    
    // 添加拖拽相关的约束
    private var poiListBottomConstraint: Constraint?
    private var poiListHeightConstraint: Constraint?
    private var panGesture: UIPanGestureRecognizer!
    private var startTouchY: CGFloat = 0
    private var startHeight: CGFloat = 0
    
    // 高度常量
    private let maxHeightRatio: CGFloat = 0.4 // 最高为屏幕一半
    private let minHeight: CGFloat = 130 // 最低高度100
    
    // 标记是否已经展开过
    private var hasExpandedToMax: Bool = false
    
    private let topView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenUtil.screenWidth, height: 112))
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("发送位置")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        bar.setRightTitleWithMainColorButton(title: "发送") { [weak self] in
            if let selectedAddress = self?.selectedAroundPOIData {
                self?.navigationController?.popViewController(animated: false)
                self?.onSelectedAddressHandler?(selectedAddress)
            }
            
        }
        
        return bar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupUI()
        setupConstraint()
        setupPanGesture()
        getCurrentLocationPoiData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(topView)
        topView.addSubview(navigationBar)
        view.addSubview(poiListView)
        
        // 设置圆角
        poiListView.layer.cornerRadius = 12
        poiListView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        poiListView.clipsToBounds = true
        poiListView.onSelected = { [weak self] item in
            guard let self = self else { return }
            self.selectedAroundPOIData = item
            self.mapManager.buildMessagePointMapData(with: item)
        }
    }
    
    private func setupConstraint() {
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        poiListView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            poiListBottomConstraint = make.bottom.equalToSuperview().constraint
            // 初始高度为最小高度
            poiListHeightConstraint = make.height.equalTo(minHeight).constraint
        }
    }
    
    private func setupPanGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        // 让抓手区域可以接收手势
        poiListView.setGrabberGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            startHeight = poiListView.frame.height
            startTouchY = gesture.location(in: view).y
            
        case .changed:
            let newHeight = startHeight - translation.y
            
            // 限制高度范围
            let clampedHeight = min(getMaxHeight(), max(minHeight, newHeight))
            updatePoiListHeight(clampedHeight)
            
        case .ended:
            let currentHeight = poiListView.frame.height
            let targetHeight: CGFloat
            
            // 根据滑动速度和当前高度决定最终位置
            if velocity.y < -500 {
                // 快速向上滑动，展开到最大高度
                targetHeight = getMaxHeight()
            } else if velocity.y > 500 {
                // 快速向下滑动，收缩到最小高度
                targetHeight = minHeight
            } else {
                // 慢速滑动，根据当前高度决定吸附到最近的位置
                let midHeight = (getMaxHeight() + minHeight) / 2
                if currentHeight >= midHeight {
                    targetHeight = getMaxHeight()
                } else {
                    targetHeight = minHeight
                }
            }
            
            // 动画更新高度
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.updatePoiListHeight(targetHeight)
                self.view.layoutIfNeeded()
            }
            
        default:
            break
        }
    }
    
    func updatePoiListHeight(_ height: CGFloat) {
        poiListHeightConstraint?.update(offset: height)
        view.layoutIfNeeded()
    }
    
    func getMaxHeight() -> CGFloat {
        return view.bounds.height * maxHeightRatio
    }
    
    func getMinHeight() -> CGFloat {
        return minHeight
    }
    
    private func setupMap() {
        MapConfig.shared.defaultZoom = 18
        MapConfig.shared.saveConfig()
        
        let mapView = mapManager.createMapView(in: self.view, frame: CGRectMake(0, 0, ScreenUtil.screenWidth, ScreenUtil.screenHeight))
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView) // 确保地图在底层
        
        mapManager.onMapSingleTapHandler = { [weak self] (coordinate, point) in
            guard let self = self else { return }
            serverGetPoiData(coordinate: coordinate)
        }
    }
    
    private func getCurrentLocationPoiData() {
        guard let location = LocationManager.lastLocation() else {
            print("获取位置错误")
            return
        }
        
        serverGetPoiData(coordinate: location.coordinate)
    }
    
    private func serverGetPoiData(coordinate: CLLocationCoordinate2D) {
        selectedAroundPOIData = AroundPOIData(longitude: coordinate.longitude, latitude: coordinate.latitude)
        let locationStr = "\(coordinate.longitude),\(coordinate.latitude)"
        NetworkProvider<MessageAPI>().request(.checkPOIWithAround(location: locationStr)) { [weak self] result in
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<[AroundPOIData]>.self)
                    if networkResponse.isSuccess {
                        if let dataList = networkResponse.data {
//                            print("获取的周围数据--\(dataList)")
                            self?.poiListView.loadSampleData(with: dataList)
                            // 默认选中第一个cell
                            self?.poiListView.selectFirstRow()
                            guard let firstData = dataList.first else { return }
                            self?.selectedAroundPOIData = firstData
                            self?.mapManager.buildMessagePointMapData(with: firstData)
                            
                            // 网络请求有数据返回后，展开到最大高度
                            self?.expandToMaxHeightIfNeeded()
                        }
                    } else {
                        UIWindow.topWindow?.sw_showWarningToast(networkResponse.msg ?? "")
                    }
                } catch {
                    UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                }
                
            case .failure(let error):
                print("发送错误--\(error.localizedDescription)")
                guard let aroundData = self?.selectedAroundPOIData else { return }
                self?.mapManager.buildMessagePointMapData(with: aroundData)
                self?.poiListView.loadSampleData(with: [aroundData])
            }
        }
    }
    
    // 展开到最大高度（如果需要的话）
    private func expandToMaxHeightIfNeeded() {
        // 避免重复展开
        guard !hasExpandedToMax else { return }
        hasExpandedToMax = true
        
        let maxHeight = getMaxHeight()
        let currentHeight = poiListView.frame.height
        
        // 如果当前高度不等于最大高度，则动画展开
        if currentHeight != maxHeight {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                self.updatePoiListHeight(maxHeight)
                self.view.layoutIfNeeded()
            }
        }
    }
}
