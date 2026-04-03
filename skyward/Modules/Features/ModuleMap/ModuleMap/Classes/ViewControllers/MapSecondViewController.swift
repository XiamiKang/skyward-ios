//
//  MapViewController.swift
//  yifan_test
//
//  Created by TXTS on 2025/11/24.
//

import UIKit
import TangramMap
import SWKit

public class MapSecondViewController: UIViewController {
    
    // MARK: - ViewModel
    private let mapManager = MapManager()
    private lazy var backButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 20, y: 50, width: 30, height: 30))
        button.setImage(MapModule.image(named: "navigation_back"), for: .normal)
        button.addTarget(self, action: #selector(backClick), for: .touchUpInside)
        return button
    }()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 判断是否是通过手势返回
        if self.isMovingFromParent {
            mapManager.reset()
        }
    }
    
    private func setupMap() {
        MapConfig.shared.defaultZoom = 16
        MapConfig.shared.saveConfig()
        let mapView = mapManager.createMapView(in: self.view, frame: self.view.frame)
        view.addSubview(mapView)
        
        view.addSubview(backButton)
    }
    
    @objc private func backClick() {
        mapManager.reset()
        self.navigationController?.popViewController(animated: true)
    }
}

