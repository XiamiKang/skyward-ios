//
//  HourlyWeatherCell.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


// HourlyWeatherCell.swift
import UIKit

class HourlyWeatherCell: UICollectionViewCell {
    
    // MARK: - UI组件
    private let containerView = UIView()
    private let timeLabel = UILabel()
    private let iconImageView = UIImageView()
    private let tempLabel = UILabel()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        // 容器视图
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // 时间标签
        timeLabel.textColor = UIColor(str: "#84888C")
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00"
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 天气图标
        iconImageView.image = MapModule.image(named: "100")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 温度标签
        tempLabel.textColor = UIColor(str: "#070808")
        tempLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        tempLabel.textAlignment = .center
        tempLabel.text = "10°C"
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到容器
        containerView.addSubview(timeLabel)
        containerView.addSubview(iconImageView)
        containerView.addSubview(tempLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 容器
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // 时间标签
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 5),
            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // 天气图标
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // 温度标签
            tempLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            tempLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            
        ])
    }
    
    // MARK: - 配置方法
    func configure(with model: EveryHoursWeatherData) {
        timeLabel.text = "\(model.hourString ?? "00"):00"
        tempLabel.text = "\(model.temp ?? "00")°C"
        // 设置天气图标
        setWeatherIcon(model.icon ?? "100")
    }
    
    // MARK: - 设置天气图标
    private func setWeatherIcon(_ iconCode: String) {
        // 根据iconCode设置图标
        iconImageView.image = MapModule.image(named: iconCode)
    }
    
    // MARK: - 重用准备
    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        tempLabel.text = nil
        iconImageView.image = nil
        containerView.backgroundColor = .clear
    }
}
