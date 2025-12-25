//
//  PreciView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/8.
//

import UIKit

class PreciptView: UIView {
    
    // MARK: - UI组件
    private let titleLabel = UILabel()
    private let preciptContentView = BarChartView()
    private let noDataLabel = UILabel()
    
    // MARK: - 属性
    private var hoursPrecipData: [EveryHoursPrecipData] = []
    
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
        backgroundColor = .white
        
        // 标题
        titleLabel.text = "降水"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // 表格视图
        preciptContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(preciptContentView)

        // 无数据提示
        noDataLabel.text = "暂无降水数据"
        noDataLabel.font = UIFont.systemFont(ofSize: 14)
        noDataLabel.textColor = .secondaryLabel
        noDataLabel.backgroundColor = UIColor(str: "#EDF9FF")
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noDataLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            preciptContentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            preciptContentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            preciptContentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            preciptContentView.heightAnchor.constraint(equalToConstant: 250),
            
            noDataLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: preciptContentView.centerYAnchor)
        ])
    }
    
    // MARK: - 配置方法
    func configure(with data: [EveryHoursPrecipData]) {
        guard !data.isEmpty else {
            showNoData()
            return
        }
        
        // 转换为显示模型
        hoursPrecipData = data
        preciptContentView.configure(with: hoursPrecipData)
        
        // 更新UI
        noDataLabel.isHidden = true
        preciptContentView.isHidden = false
    }
    
    // MARK: - 显示无数据状态
    private func showNoData() {
        noDataLabel.isHidden = false
        preciptContentView.isHidden = true
        hoursPrecipData.removeAll()
    }
    
    // MARK: - 刷新数据
    func refresh(with data: [EveryHoursPrecipData]) {
        configure(with: data)
    }
    
    // MARK: - 获取视图高度
    func getContentHeight() -> CGFloat {
        if hoursPrecipData.isEmpty {
            return 80 // 标题高度 + 空状态高度
        } else {
            return 30 + 250 // 标题高度 + 表格高度
        }
    }
}



