//
//  SevenDayForecastView.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


// SevenDayForecastView.swift
import UIKit

class SevenDayForecastView: UIView {
    
    // MARK: - UI组件
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let noDataLabel = UILabel()
    
    // MARK: - 属性
    private var dailyWeatherData: [EveryDayWeatherData] = []
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTableView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        backgroundColor = .clear
        
        // 标题
        titleLabel.text = "未来天气预报"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // 表格视图
        tableView.backgroundColor = UIColor(str: "#FAFAFA")
        tableView.layer.cornerRadius = 8
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
        
        // 无数据提示
        noDataLabel.text = "暂无预报数据"
        noDataLabel.font = UIFont.systemFont(ofSize: 14)
        noDataLabel.textColor = .secondaryLabel
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(noDataLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 350), // 7行 × 50
            
            noDataLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DailyWeatherCell.self, forCellReuseIdentifier: "DailyWeatherCell")
        
        // 设置行高
        tableView.rowHeight = 50
    }
    
    // MARK: - 配置方法
    func configure(with data: [EveryDayWeatherData]) {
        guard !data.isEmpty else {
            showNoData()
            return
        }
        print("未来7天天气--------\(data)")
        // 限制最多显示7天
        let limitedData = Array(data.prefix(7))
        
        // 转换为显示模型
        dailyWeatherData = limitedData
        
        // 更新UI
        noDataLabel.isHidden = true
        tableView.isHidden = false
        tableView.reloadData()
    }
    
    // MARK: - 显示无数据状态
    private func showNoData() {
        noDataLabel.isHidden = false
        tableView.isHidden = true
        dailyWeatherData.removeAll()
    }
    
    // MARK: - 刷新数据
    func refresh(with data: [EveryDayWeatherData]) {
        configure(with: data)
    }
    
    // MARK: - 获取视图高度
    func getContentHeight() -> CGFloat {
        if dailyWeatherData.isEmpty {
            return 80 // 标题高度 + 空状态高度
        } else {
            return 30 + CGFloat(dailyWeatherData.count) * 50 // 标题高度 + 表格高度
        }
    }
}

// MARK: - UITableViewDataSource
extension SevenDayForecastView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dailyWeatherData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailyWeatherCell", for: indexPath) as! DailyWeatherCell
        
        if indexPath.row < dailyWeatherData.count {
            cell.configure(with: dailyWeatherData[indexPath.row])
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SevenDayForecastView: UITableViewDelegate {
   
}



