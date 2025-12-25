//
//  BarChartView.swift
//  Pods
//
//  Created by TXTS on 2025/12/5.
//

import UIKit

class BarChartView: UIView {
    
    // MARK: - 属性
    private var data: [EveryHoursPrecipData] = []
    private let barSpacing: CGFloat = 7
    private let bottomMargin: CGFloat = 30
    private let leftMargin: CGFloat = 16
    private let topMargin: CGFloat = 20
    private let maxBarHeight: CGFloat = 150
    
    // MARK: - 子视图
    private let scrollView = UIScrollView()
    private let barsContainer = UIView()
    private let valueLabelsContainer = UIView()
    private var titleLabel = UILabel()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - 配置方法
    func configure(with data: [EveryHoursPrecipData]) {
        self.data = data
        setupBars()
        setupXAxisLabels()
        setupYAxisLabels()
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        backgroundColor = UIColor(str: "#EDF9FF")
        layer.masksToBounds = true
        layer.cornerRadius = 8
        
        // 滚动视图
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        // 柱状容器
        scrollView.addSubview(barsContainer)
        
        // 数值标签容器
        addSubview(valueLabelsContainer)
        
        titleLabel.text = "未来24小时无降水"
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        addSubview(titleLabel)
    }
    
    // MARK: - 布局
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 计算实际需要的总宽度
        let totalBarsWidth = CGFloat(data.count) * (calculateBarWidth() + barSpacing)
        let chartWidth = max(totalBarsWidth + leftMargin * 2, bounds.width)
        
        // 滚动视图布局
        scrollView.frame = CGRect(x: 0, y: topMargin,
                                 width: bounds.width,
                                 height: bounds.height - bottomMargin - topMargin)
        scrollView.contentSize = CGSize(width: chartWidth, 
                                       height: scrollView.bounds.height)
        
        // 柱状容器布局
        barsContainer.frame = CGRect(x: leftMargin, y: 0, 
                                    width: totalBarsWidth, 
                                    height: scrollView.bounds.height)
        
        // 数值标签容器布局
        valueLabelsContainer.frame = CGRect(x: 0,
                                           y: scrollView.frame.maxY,
                                           width: bounds.width,
                                           height: bottomMargin)
        
        titleLabel.frame = CGRect(x: bounds.width/2-80,
                                  y: 10,
                                  width: 160,
                                  height: 30)
        
        
    }
    
    // MARK: - 创建柱状图
    private func setupBars() {
        // 清除旧的柱子
        barsContainer.subviews.forEach { $0.removeFromSuperview() }
        valueLabelsContainer.subviews.forEach { $0.removeFromSuperview() }
        
        guard !data.isEmpty else { return }
        
        let barWidth = calculateBarWidth()
        let maxValue = data.map { $0.precipValue }.max() ?? 1
        
        // 创建每根柱子
        for (index, barData) in data.enumerated() {
            // 计算柱子高度（归一化到最大高度）
            var normalizedHeight = 0.0
            if barData.precipValue != 0 {
                normalizedHeight = (barData.precipValue / maxValue) * maxBarHeight
            }
            
            // 柱子位置
            let xPosition = CGFloat(index) * (barWidth + barSpacing)
            let yPosition = barsContainer.bounds.height - normalizedHeight
            
            // 创建柱子
            let barView = UIView(frame: CGRect(x: xPosition, 
                                              y: yPosition, 
                                              width: barWidth, 
                                              height: normalizedHeight))
            barView.backgroundColor = .systemBlue
            barView.layer.cornerRadius = barWidth / 4
            barView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            barView.clipsToBounds = true
            
            // 添加触摸效果
            barView.isUserInteractionEnabled = true
            barView.tag = index
            
            barsContainer.addSubview(barView)
            
            // 添加数值标签
            let valueLabel = UILabel()
            valueLabel.text = String(format: "%.1f", barData.precipValue)
            valueLabel.font = .systemFont(ofSize: 10)
            valueLabel.textColor = .darkGray
            valueLabel.textAlignment = .center
            valueLabel.frame = CGRect(x: xPosition - barWidth / 2, 
                                     y: -20, 
                                     width: barWidth * 2, 
                                     height: 15)
            barsContainer.addSubview(valueLabel)
            
            
            // 添加动画
            let finalFrame = barView.frame
            barView.frame = CGRect(x: xPosition, 
                                  y: barsContainer.bounds.height, 
                                  width: barWidth, 
                                  height: 0)
            
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.05, 
                          options: .curveEaseOut, animations: {
                barView.frame = finalFrame
            })
        }
    }
    
    // MARK: - 设置X轴标签
    private func setupXAxisLabels() {
        guard !data.isEmpty else { return }
        
        let barWidth = calculateBarWidth()
        
        for (index, barData) in data.enumerated() {
            let xPosition = leftMargin + CGFloat(index) * (barWidth + barSpacing) + barWidth / 2
            
            let label = UILabel()
            label.text = barData.hourString ?? "\(index + 1)"
            label.font = .systemFont(ofSize: 10)
            label.textColor = .darkGray
            label.textAlignment = .center
            
            // 每隔3个标签显示一个
            if index % 3 == 0 {
                label.frame = CGRect(x: xPosition - 20, 
                                   y: 5, 
                                   width: 40, 
                                   height: 20)
                valueLabelsContainer.addSubview(label)
            }
        }
    }
    
    // MARK: - 设置Y轴标签
    private func setupYAxisLabels() {
        guard let maxValue = data.map({ $0.precipValue }).max() else { return }
        
        let yPositions: [CGFloat] = [0.25, 0.5, 0.75, 1.0]
        
        for position in yPositions {
            let yValue = maxValue * position
            let yPosition = barsContainer.bounds.height - (maxBarHeight * position)
            
            let label = UILabel()
            label.text = String(format: "%.0f", yValue)
            label.font = .systemFont(ofSize: 10)
            label.textColor = .gray
            label.textAlignment = .right
            
            label.frame = CGRect(x: -leftMargin + 5, 
                               y: yPosition - 10, 
                               width: leftMargin - 10, 
                               height: 10)
            barsContainer.addSubview(label)
            
            // 添加水平网格线
            let gridLine = UIView()
            gridLine.backgroundColor = UIColor.lightGray.withAlphaComponent(0.9)
            gridLine.frame = CGRect(x: 0,
                                   y: yPosition, 
                                   width: barsContainer.bounds.width, 
                                   height: 0.5)
            barsContainer.insertSubview(gridLine, at: 0)
        }
    }
    
    // MARK: - 计算柱子宽度
    private func calculateBarWidth() -> CGFloat {
        guard !data.isEmpty else { return 20 }
        let availableWidth = bounds.width - leftMargin * 2
        let maxBarWidth = (availableWidth / CGFloat(data.count)) - barSpacing
        return min(maxBarWidth, 30)
    }
    
}
