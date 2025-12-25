//
//  WeatherInfoView.swift
//  ModuleHome
//
//  Created by 赵波 on 2025/11/18.
//

import UIKit
import SWTheme
import SnapKit

class WeatherInfoView: UIView {
    
    // 天气图标
    private let weatherIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // 天气信息标签
    private let weatherLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 初始化
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 私有方法
    
    private func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 6
        
        addSubview(weatherIconImageView)
        addSubview(weatherLabel)
    }
    
    private func setupConstraints() {
        weatherIconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        weatherLabel.snp.makeConstraints { make in
            make.leading.equalTo(weatherIconImageView.snp.trailing).offset(2)
            make.trailing.equalToSuperview().inset(4)
            make.centerY.equalToSuperview()
        }
    }
    
    // MARK: - 公共接口
    
    /// 设置天气图标
    /// - Parameter image: 天气图标
    func setWeatherIcon(_ image: UIImage?) {
        weatherIconImageView.image = image?.withTintColor(.white)
    }
    
    /// 设置天气信息文本
    /// - Parameter text: 天气信息文本，如："中雨20°C"
    func setWeatherText(_ text: String) {
        weatherLabel.text = text
    }
}
