//
//  POIWeatherDetailViewController.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


import UIKit
import CoreLocation
import SWKit

class POIWeatherDetailViewController: UIViewController {
    
    // MARK: - Properties
    var poiTitle: String?
    var address: String?
    var coordinate: CLLocationCoordinate2D
    private var weatherData: WeatherData?
    private var hoursData: [EveryHoursWeatherData]?
    private var daysData: [EveryDayWeatherData]?
    private var warningData: [WeatherWarningData]?
    private var precipData: [EveryHoursPrecipData]?
    private let viewModel = WeatherViewModel()
    private let mapViewModel = MapViewModel()
    
    // 使用UITableView替代UIScrollView
    private let tableView = UITableView()
    
    // 底部工具栏
    private let bottomToolView = BottomToolView()
    
    // 用于计算高度的容器
    private let contentContainerView = UIView()
    
    // 头部视图
    private let headerView = UIView()
    private let locationLabel = UILabel()
    private let addressLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    // MARK: - Initializer
    init(title: String, address: String, coordinate: CLLocationCoordinate2D) {
        self.poiTitle = title
        self.address = address
        self.coordinate = coordinate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        bindViewModel()
        
        // 获取天气数据
        fetchWeatherData()
        
        // 设置sheet控制器代理
        sheetPresentationController?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 确保底部工具栏在最上层
        view.bringSubviewToFront(bottomToolView)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // 容器视图
        contentContainerView.backgroundColor = .white
        view.addSubview(contentContainerView)
        
        // TableView
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        contentContainerView.addSubview(tableView)
        
        // 底部工具栏
        contentContainerView.addSubview(bottomToolView)
        setupBottomToolView()
        
        setupConstraints()
    }
    
    private func setupBottomToolView() {
        bottomToolView.backgroundColor = .white
        
        // 添加顶部边框
        let border = UIView()
        border.backgroundColor = UIColor.systemGray5
        bottomToolView.addSubview(border)
        border.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: bottomToolView.topAnchor),
            border.leadingAnchor.constraint(equalTo: bottomToolView.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: bottomToolView.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // 设置按钮点击事件
        bottomToolView.onCheckTapped = { [weak self] in
            self?.handleCheckTapped()
        }
        
        bottomToolView.onCollectionTapped = { [weak self] in
            self?.handleCollectionTapped()
        }
        
        bottomToolView.onNavigationTapped = { [weak self] in
            self?.handleNavigationTapped()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(WeatherDetailCell.self, forCellReuseIdentifier: "WeatherDetailCell")
        tableView.register(PreciptCell.self, forCellReuseIdentifier: "PreciptCell")
        tableView.register(WeatherWarningCell.self, forCellReuseIdentifier: "WeatherWarningCell")
        tableView.register(ForecastCell.self, forCellReuseIdentifier: "ForecastCell")
        tableView.register(SunUpAndMoonDownCell.self, forCellReuseIdentifier: "SunUpAndMoonDownCell")
        // 注册悬停header
        tableView.register(WeatherHeaderView.self, forHeaderFooterViewReuseIdentifier: "WeatherHeaderView")
    }
    
    private func setupConstraints() {
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 容器视图约束
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // TableView约束
            tableView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomToolView.topAnchor),
            
            // 底部工具栏约束 - 固定在容器底部
            bottomToolView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            bottomToolView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            bottomToolView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            bottomToolView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    // MARK: - 按钮点击处理
    private func handleCheckTapped() {
        print("打卡按钮点击")
        // 实现打卡功能
    }
    
    private func handleCollectionTapped() {
        print("收藏按钮点击")
        // 实现收藏功能
    }
    
    private func handleNavigationTapped() {
        print("导航按钮点击")
        // 实现导航功能
        LocationManager().getCurrentLocation { [weak self] location, error in
            guard let self = self else { return }
            let startLat = location?.coordinate.latitude ?? 0.0
            let startLon = location?.coordinate.latitude ?? 0.0
            let endLat = self.coordinate.latitude
            let endLon = self.coordinate.longitude
            mapViewModel.openAmapNavigation(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon, destinationName: self.poiTitle ?? "")
        }
        
    }
    
    // MARK: - bindViewModel
    private func bindViewModel() {
        viewModel.$pointWeatherData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.weatherData = data
                self.tableView.reloadData()
            }
            .store(in: &viewModel.cancellables)
        
        viewModel.$hoursWeatherData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.hoursData = data
                self.tableView.reloadData()
            }
            .store(in: &viewModel.cancellables)
        
        viewModel.$daysWeatherData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.daysData = data
                self.tableView.reloadData()
            }
            .store(in: &viewModel.cancellables)
        
        viewModel.$weatherWarningData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.warningData = data
                self.tableView.reloadData()
            }
            .store(in: &viewModel.cancellables)
        
        viewModel.$hoursPrecipData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.precipData = data
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
            .store(in: &viewModel.cancellables)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Data
    private func fetchWeatherData() {
        viewModel.input.pointWeatherRequest.send(coordinate)
        viewModel.input.hoursWeatherRequest.send(coordinate)
        viewModel.input.daysWeatherRequest.send(coordinate)
        viewModel.input.weatherWarningRequest.send(coordinate)
        viewModel.input.hoursPrecipRequest.send(coordinate)
    }
}

// MARK: - UITableView DataSource & Delegate
extension POIWeatherDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5 // 天气详情 + 降水图表 + 预警 + 7天预报 + 日出日落
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            // 天气详情
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherDetailCell", for: indexPath) as! WeatherDetailCell
            if let weatherData = weatherData, let hoursData = hoursData {
                cell.configure(withCurrentWeather: weatherData, hourlyWeather: hoursData)
            }
            return cell
            
        case 1:
            // 降水图表
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreciptCell", for: indexPath) as! PreciptCell
            if let precipData = precipData {
                cell.configWithEveryHoursPrecipData(precipData)
            }
            return cell
            
        case 2:
            // 灾害预警
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherWarningCell", for: indexPath) as! WeatherWarningCell
            if let warningData = warningData?.first {
                cell.configure(warningData)
            }
            return cell
            
        case 3:
            // 7天预报
            let cell = tableView.dequeueReusableCell(withIdentifier: "ForecastCell", for: indexPath) as! ForecastCell
            if let daysData = daysData {
                cell.configWithEveryDayWeatherData(daysData)
            }
            return cell
            
        case 4:
            //
            let cell = tableView.dequeueReusableCell(withIdentifier: "SunUpAndMoonDownCell", for: indexPath) as! SunUpAndMoonDownCell
            if let daysData = daysData?.first {
                cell.config(daysData)
            }
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 390 // 天气详情高度
        case 1:
            return 300 // 降水图表高度
        case 2:
            return 240 // 预警高度自适应
        case 3:
            return 400 // 7天预报高度
        case 4:
            return 330 //
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 390
        case 1:
            return 300
        case 2:
            return 200
        case 3:
            return 400
        case 4:
            return 330 // 7天预报高度
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            // 第一个section的header作为悬停头部
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "WeatherHeaderView") as! WeatherHeaderView
            if let title = poiTitle, let address = address {
                header.configure(title: title, subtitle: address)
            }
            header.closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 80 // 悬停头部的高度
        }
        return 0
    }
}

// 24小时降水量
class PreciptCell: UITableViewCell {
    private let preciptView = PreciptView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(preciptView)
        preciptView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            preciptView.topAnchor.constraint(equalTo: contentView.topAnchor),
            preciptView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            preciptView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            preciptView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            preciptView.heightAnchor.constraint(equalToConstant: 280)
        ])
    }
    
    func configWithEveryHoursPrecipData(_ data: [EveryHoursPrecipData]) {
        preciptView.configure(with: data)
    }
}

// 7天预报Cell
class ForecastCell: UITableViewCell {
    private let forecastView = SevenDayForecastView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(forecastView)
        forecastView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            forecastView.topAnchor.constraint(equalTo: contentView.topAnchor),
            forecastView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            forecastView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            forecastView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            forecastView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }
    
    func configWithEveryDayWeatherData(_ data: [EveryDayWeatherData]) {
        forecastView.configure(with: data)
    }
}

// MARK: - UISheetPresentationControllerDelegate
extension POIWeatherDetailViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        // 当sheet高度变化时，确保底部工具栏在最上层
        view.bringSubviewToFront(bottomToolView)
    }
}
