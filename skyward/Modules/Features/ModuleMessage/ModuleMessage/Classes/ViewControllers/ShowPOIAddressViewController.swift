//
//  ChoosePOIAddressViewController 2.swift
//  Pods
//
//  Created by TXTS on 2026/3/30.
//


import UIKit
import SnapKit
import SWTheme
import SWKit
import TXKit
import SWNetwork

class ShowPOIAddressViewController: UIViewController {
    
    var onSelectedAddressHandler: ((AroundPOIData) -> Void)?
    
    private let mapManager = MapManager()
    
    private let poiShowView = MessagePOIShowView()
    
    private var selectedAroundPOIData: AroundPOIData
    
    private let minHeight: CGFloat = 110 // 最低高度100
    
    private let topView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: ScreenUtil.screenWidth, height: 112))
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("查看位置")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        return bar
    }()
    
    init(aroundPOIData: AroundPOIData) {
        self.selectedAroundPOIData = aroundPOIData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        setupUI()
        setupConstraint()
        showPOIView()
       
        mapManager.buildMessagePointMapData(with: selectedAroundPOIData)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(topView)
        topView.addSubview(navigationBar)
        view.addSubview(poiShowView)
        
        // 设置圆角
        poiShowView.layer.cornerRadius = 12
        poiShowView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        poiShowView.clipsToBounds = true
    }
    
    private func setupConstraint() {
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        poiShowView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(minHeight)
        }
    }

    private func setupMap() {
        MapConfig.shared.defaultZoom = 18
        MapConfig.shared.showUserLocation = false
        MapConfig.shared.saveConfig()
        
        let mapView = mapManager.createMapView(in: self.view, frame: CGRectMake(0, 0, ScreenUtil.screenWidth, ScreenUtil.screenHeight))
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView) // 确保地图在底层
    }
    
    private func showPOIView() {
        poiShowView.configure(with: selectedAroundPOIData)
    }
  
}



