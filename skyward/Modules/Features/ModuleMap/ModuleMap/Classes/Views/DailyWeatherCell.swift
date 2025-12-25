//
//  DailyWeatherCell.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


// DailyWeatherCell.swift
import UIKit

class DailyWeatherCell: UITableViewCell {
    
    // MARK: - UI组件
    private let dateLabel = UILabel()
    private let weekdayLabel = UILabel()
    private let dayIconImageView = UIImageView()
    private let tempRangeLabel = UILabel()

    
    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        // 日期标签
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = UIColor(str: "#070808")
        dateLabel.textAlignment = .left
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        // 星期标签
        weekdayLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        weekdayLabel.textColor = UIColor(str: "#070808")
        weekdayLabel.textAlignment = .left
        weekdayLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(weekdayLabel)
        
        // 白天天气图标
        dayIconImageView.contentMode = .scaleAspectFit
        dayIconImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dayIconImageView)
        
        // 温度范围标签
        tempRangeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        tempRangeLabel.textColor = UIColor(str: "#070808")
        tempRangeLabel.textAlignment = .right
        tempRangeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tempRangeLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 日期标签
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // 星期标签
            weekdayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 86),
            weekdayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // 白天天气图标
            dayIconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dayIconImageView.widthAnchor.constraint(equalToConstant: 20),
            dayIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // 温度范围标签
            tempRangeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tempRangeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    
    // MARK: - 配置方法
    func configure(with model: EveryDayWeatherData) {
        
        let dateStr = model.fxDate
        // 1. 解析日期并获取星期几
        let formattedDate = formatChineseDate(dateStr)
        let weekday = getSimpleWeekdayDisplay(dateStr)
        
        // 2. 获取天气图标、最低温和最高温
        let icon = model.iconDay ?? "100"
        let tempMin = model.tempMin ?? "--"
        let tempMax = model.tempMax ?? "--"
        
        dateLabel.text = formattedDate
        weekdayLabel.text = weekday
        dayIconImageView.image = MapModule.image(named: "\(icon)")
        tempRangeLabel.text = "\(tempMin)°C/\(tempMax)°C"
    }
    
    func formatChineseDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "日期未知" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else { return dateString }
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale(identifier: "zh_CN") // 设置为中文环境
        outputFormatter.dateFormat = "M月d日"
        
        return outputFormatter.string(from: date)
    }

    // 获取星期几的函数
    func getSimpleWeekdayDisplay(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "日期未知" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let targetDate = formatter.date(from: dateString) else { return dateString }
        
        let calendar = Calendar.current
        
        // 处理今日、明日
        if calendar.isDateInToday(targetDate) {
            return "今日"
        } else if calendar.isDateInTomorrow(targetDate) {
            return "明日"
        }
        
        // 获取周几（中文）
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"  // E 格式会返回"周日"、"周一"等
        
        return formatter.string(from: targetDate)
    }
 
    
    // MARK: - 重用准备
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = nil
        weekdayLabel.text = nil
        dayIconImageView.image = nil
        tempRangeLabel.text = nil
    }
}
