//
//  WeatherDetailView.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


// WeatherDetailView.swift
import UIKit

class WeatherDetailCell: UITableViewCell {
    
    // 上部分：当前天气
    private let currentWeatherView = UIView()
    private let weatherIconImageView = UIImageView()
    private let temperatureLabel = UILabel()
    private let weatherTextLabel = UILabel()
    private let highLowTempLabel = UILabel()
    
    // 中部分：每小时天气
    private let hourlyWeatherView = HourlyWeatherCollectionView()
    
    // 下部分：天气指标网格
    private let metricsGridView = WeatherMetricsGridView()
    
    // MARK: - 属性
    private var currentWeatherData: WeatherData?
    private var hourlyWeatherData: [EveryHoursWeatherData] = []
    
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
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        // 设置当前天气视图
        setupCurrentWeatherView()
        
        // 布局所有视图
        layoutAllViews()
    }
    
    private func setupCurrentWeatherView() {
        currentWeatherView.backgroundColor = .white
        currentWeatherView.translatesAutoresizingMaskIntoConstraints = false
        
        // 天气图标
        weatherIconImageView.image = MapModule.image(named: "100")
        weatherIconImageView.contentMode = .scaleAspectFit
        weatherIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 温度标签
        temperatureLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        temperatureLabel.textColor = .black
        temperatureLabel.text = "--°C"
        temperatureLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 天气状况文字
        weatherTextLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        weatherTextLabel.textColor = .systemGray2
        weatherTextLabel.text = "晴"
        weatherTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 最高最低温度
        highLowTempLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        highLowTempLabel.textColor = .systemGray2
        highLowTempLabel.text = "--°C/--°C"
        highLowTempLabel.translatesAutoresizingMaskIntoConstraints = false
        
        currentWeatherView.addSubview(weatherIconImageView)
        currentWeatherView.addSubview(temperatureLabel)
        currentWeatherView.addSubview(weatherTextLabel)
        currentWeatherView.addSubview(highLowTempLabel)
        
        NSLayoutConstraint.activate([
            
            weatherIconImageView.centerYAnchor.constraint(equalTo: currentWeatherView.centerYAnchor),
            weatherIconImageView.centerXAnchor.constraint(equalTo: currentWeatherView.centerXAnchor, constant: -40),
            weatherIconImageView.widthAnchor.constraint(equalToConstant: 60),
            weatherIconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            temperatureLabel.topAnchor.constraint(equalTo: weatherIconImageView.topAnchor, constant: 4),
            temperatureLabel.leadingAnchor.constraint(equalTo: weatherIconImageView.trailingAnchor, constant: 5),
            
            weatherTextLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 8),
            weatherTextLabel.leadingAnchor.constraint(equalTo: weatherIconImageView.trailingAnchor, constant: 5),
            
            highLowTempLabel.topAnchor.constraint(equalTo: weatherTextLabel.topAnchor),
            highLowTempLabel.leadingAnchor.constraint(equalTo: weatherTextLabel.trailingAnchor, constant: 2),
            
        ])
    }
    
    private func layoutAllViews() {
        hourlyWeatherView.translatesAutoresizingMaskIntoConstraints = false
        metricsGridView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(currentWeatherView)
        contentView.addSubview(hourlyWeatherView)
        contentView.addSubview(metricsGridView)
        
        NSLayoutConstraint.activate([
            currentWeatherView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            currentWeatherView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            currentWeatherView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            currentWeatherView.heightAnchor.constraint(equalToConstant: 60),
            
            hourlyWeatherView.topAnchor.constraint(equalTo: currentWeatherView.bottomAnchor, constant: 5),
            hourlyWeatherView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hourlyWeatherView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hourlyWeatherView.heightAnchor.constraint(equalToConstant: 100),
            
            metricsGridView.topAnchor.constraint(equalTo: hourlyWeatherView.bottomAnchor, constant: 5),
            metricsGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            metricsGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            metricsGridView.heightAnchor.constraint(equalToConstant: 190),
        ])
    }
    
    // MARK: - 配置方法
    func configure(withCurrentWeather current: WeatherData, 
                  hourlyWeather: [EveryHoursWeatherData],
                  locationName: String? = nil) {
        // 保存数据
        self.currentWeatherData = current
        self.hourlyWeatherData = hourlyWeather
        
        // 更新当前天气
        updateCurrentWeather(current, locationName: locationName)
        
        // 更新每小时天气
        updateHourlyWeather(hourlyWeather)
        
        // 更新天气指标
        updateWeatherMetrics(current: current)
        
        // 计算并更新最高最低温度
        updateHighLowTemperatures()
    }
    
    // MARK: - 更新当前天气
    private func updateCurrentWeather(_ data: WeatherData, locationName: String?) {
        // 更新温度
        if let temp = data.temp {
            temperatureLabel.text = "\(temp)°C"
        }
        
        // 更新天气状况
        weatherTextLabel.text = data.text ?? "--"
        
        // 更新天气图标
        if let iconCode = data.icon {
            updateWeatherIcon(iconCode)
        }
    }
    
    // MARK: - 更新每小时天气
    private func updateHourlyWeather(_ data: [EveryHoursWeatherData]) {
        hourlyWeatherView.configure(with: data)
    }
    
    // MARK: - 更新天气指标
    private func updateWeatherMetrics(current: WeatherData) {
        let metrics = [
            WeatherMetricItem(
                title: "降水量",
                iconName: "map_weather_precip",
                value: "\(current.precip ?? "0.00")mm"
            ),
            WeatherMetricItem(
                title: "能见度",
                iconName: "map_weather_vis",
                value: "\(current.vis ?? "--")KM"
            ),
            WeatherMetricItem(
                title: "风",
                iconName: "map_weather_windDir",
                value: "\(current.windDir ?? "--")\(current.windScale ?? "--")级"
            ),
            WeatherMetricItem(
                title: "湿度",
                iconName: "map_weather_humidity",
                value: "\(current.humidity ?? "--")%"
            ),
            WeatherMetricItem(
                title: "云量",
                iconName: "map_weather_cloud",
                value: current.cloud ?? "--"
            ),
            WeatherMetricItem(
                title: "气压",
                iconName: "map_weather_pressure",
                value: "\(current.pressure ?? "--")hPa"
            )
        ]
        
        metricsGridView.configure(with: metrics)
    }
    
    // MARK: - 计算最高最低温度
    private func updateHighLowTemperatures() {
        guard !hourlyWeatherData.isEmpty else { return }
        
        // 提取所有温度值
        let temperatures = hourlyWeatherData.compactMap { data -> Double? in
            guard let tempString = data.temp else { return nil }
            return Double(tempString)
        }
        
        // 计算最高最低
        if let maxTemp = temperatures.max(), let minTemp = temperatures.min() {
            highLowTempLabel.text = String(format: "%.0f°C/%.0f°C", minTemp, maxTemp)
        }
    }
    
    // MARK: - 更新天气图标
    private func updateWeatherIcon(_ iconCode: String) {
        // 使用你的天气图标系统
        weatherIconImageView.image = MapModule.image(named: iconCode) ?? UIImage(systemName: "questionmark.circle")
    }
    
    // MARK: - 刷新数据
    func refreshCurrentWeather(_ data: WeatherData) {
        updateCurrentWeather(data, locationName: nil)
        updateWeatherMetrics(current: data)
    }
    
    func refreshHourlyWeather(_ data: [EveryHoursWeatherData]) {
        hourlyWeatherView.configure(with: data)
        updateHighLowTemperatures()
    }
}

// MARK: - 数据模型
struct WeatherMetricItem {
    let title: String
    let iconName: String
    let value: String
}
