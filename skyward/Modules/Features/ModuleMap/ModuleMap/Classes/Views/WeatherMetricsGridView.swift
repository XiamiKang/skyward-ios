//
//  WeatherMetricsGridView.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


// 天气详情的6个数据
import UIKit

class WeatherMetricsGridView: UIView {
    
    // MARK: - UI组件
    private let stackView = UIStackView()
    private var metricViews: [WeatherMetricView] = []
    
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
        backgroundColor = .clear
        
        // 堆叠视图
        stackView.axis = .vertical
        stackView.spacing = 12  // 增加行间距
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 创建两行，每行3个
        createGridRows()
    }
    
    private func createGridRows() {
        // 创建第一行：1, 2, 3
        let firstRow = UIStackView()
        firstRow.axis = .horizontal
        firstRow.distribution = .fillEqually
        firstRow.spacing = 12
        
        // 创建第二行：4, 5, 6
        let secondRow = UIStackView()
        secondRow.axis = .horizontal
        secondRow.distribution = .fillEqually
        secondRow.spacing = 12
        
        // 创建6个指标视图
        for _ in 0..<6 {
            let metricView = WeatherMetricView()
            metricView.translatesAutoresizingMaskIntoConstraints = false
            metricView.heightAnchor.constraint(equalToConstant: 90).isActive = true
            metricViews.append(metricView)
        }
        
        // 将视图按顺序添加到行中
        // 第一行：索引 0, 1, 2
        for i in 0..<3 {
            firstRow.addArrangedSubview(metricViews[i])
        }
        
        // 第二行：索引 3, 4, 5
        for i in 3..<6 {
            secondRow.addArrangedSubview(metricViews[i])
        }
        
        stackView.addArrangedSubview(firstRow)
        stackView.addArrangedSubview(secondRow)
    }
    
    // MARK: - 配置方法
    func configure(with metrics: [WeatherMetricItem]) {
        guard metrics.count == 6 else {
            print("需要6个天气指标数据")
            return
        }
        
        // 按顺序配置：metrics[0] -> 视图1, metrics[1] -> 视图2, 等等
        for (index, metric) in metrics.enumerated() {
            if index < metricViews.count {
                metricViews[index].configure(with: metric)
            }
        }
    }
}

// 单个天气指标视图
class WeatherMetricView: UIView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(str: "#FAFAFA")
        layer.cornerRadius = 8
        
        // 图标
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 标题
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = UIColor(str: "#84888C")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 数值
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
        ])
    }
    
    func configure(with metric: WeatherMetricItem) {
        // 使用项目中的图片资源
        iconImageView.image = MapModule.image(named: metric.iconName)
        titleLabel.text = metric.title
        valueLabel.text = metric.value
    }
}
