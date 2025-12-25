//
//  MapView.swift
//  ModuleHome
//
//  Created by 赵波 on 2025/11/18.
//

import UIKit
import SWKit
import SWTheme
import SnapKit
import TangramMap

protocol MapViewDelegate: AnyObject {
    func mapViewDidTapLocationButton(_ mapView: HomeMapView)
    func mapViewDidTapZoomButton(_ mapView: HomeMapView)
}

class HomeMapView: UIView {
    
    weak var delegate: MapViewDelegate?
    
    private let mapControlStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // 天气信息视图
    public let weatherInfoView = WeatherInfoView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .systemGray6
        self.clipsToBounds = true
        self.layer.cornerRadius = CornerRadius.large.rawValue
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    
    private func setupViews() {
        // 添加地图控制按钮
        let locationButton = createIconButton(systemName: "home_map_location_icon")
        locationButton.tag = 0
        locationButton.addTarget(self, action: #selector(mapControlButtonTapped(_:)), for: .touchUpInside)
        
        let zoomButton = createIconButton(systemName: "home_map_expand_icon")
        zoomButton.tag = 1
        zoomButton.addTarget(self, action: #selector(mapControlButtonTapped(_:)), for: .touchUpInside)
        
        mapControlStack.addArrangedSubview(locationButton)
        mapControlStack.addArrangedSubview(zoomButton)
        
        // 添加子视图
        addSubview(mapControlStack)
        addSubview(weatherInfoView)
    }
    
    private func setupConstraints() {
        
        mapControlStack.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(8)
            make.width.equalTo(32)
        }
        
        // 天气信息视图约束 - 左上角
        weatherInfoView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.height.equalTo(26)
        }
    }
    
    private func createIconButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(HomeModule.image(named: systemName), for: .normal)
        button.tintColor = .black  // 设置图标颜色为黑色
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.backgroundColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加约束确保按钮保持 32x32 尺寸
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        return button
    }
    
    @objc private func mapControlButtonTapped(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            delegate?.mapViewDidTapLocationButton(self)
        case 1:
            delegate?.mapViewDidTapZoomButton(self)
        default:
            break
        }
    }
    
    // MARK: - 公共接口
    
    /// 设置天气图标
    /// - Parameter image: 天气图标
    func setWeatherIcon(_ image: UIImage?) {
        weatherInfoView.setWeatherIcon(image)
    }
    
    /// 设置天气信息文本
    /// - Parameter text: 天气信息文本，如："中雨20°C"
    func setWeatherText(_ text: String) {
        weatherInfoView.setWeatherText(text)
    }
}
