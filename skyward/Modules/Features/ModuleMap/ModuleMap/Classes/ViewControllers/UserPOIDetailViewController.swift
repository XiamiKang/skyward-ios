//
//  UserPOIDetailViewController.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/17.
//

import UIKit
import CoreLocation
import SWKit
import SDWebImage

class UserPOIDetailViewController: UIViewController {
    
    private let viewModel = WeatherViewModel()
    private let mapViewModel = MapViewModel()
    var poiData: UserPOIData?
    private var coordinate: CLLocationCoordinate2D
    // 天气数据
    private var weatherData: WeatherData?
    private var hoursData: [EveryHoursWeatherData]?
    private var daysData: [EveryDayWeatherData]?
    private var warningData: [WeatherWarningData]?
    private var precipData: [EveryHoursPrecipData]?
    // 头部视图
    private var userPOIHeadView = UserPOIHeadView()
    private var titleSegmentedView: TitleSegmentedView!
    private var userPointMsgView = UserPOIMsgView()
    private let tableView = UITableView()
    
    // 底部工具栏
    private let bottomToolView = UserBottomToolView()
    
    // 用于计算高度的容器
    private let contentContainerView = UIView()
    
    // 头部视图
    private let headerView = UIView()
    private let locationLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    init(poiData: UserPOIData) {
        self.poiData = poiData
        self.coordinate = CLLocationCoordinate2D(latitude: poiData.lat ?? 0.0, longitude: poiData.lon ?? 0.0)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        if let data = self.poiData {
            userPOIHeadView.locationLabel.text = data.name
        }
        userPOIHeadView.closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        contentContainerView.addSubview(userPOIHeadView)
        
        titleSegmentedView = TitleSegmentedView(titles: ["总览", "天气"])
        titleSegmentedView.onSelect = { [weak self] index in
            self?.handleSelection(index: index)
        }
        contentContainerView.addSubview(titleSegmentedView)
        
        if let poiData = poiData {
            userPointMsgView.setImageAndContentUI(with: poiData)
        }
        userPointMsgView.isHidden = false
        contentContainerView.addSubview(userPointMsgView)
        
        // TableView
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.isHidden = true
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
        bottomToolView.onDeleteTapped = { [weak self] in
            self?.handleDeleteTapped()
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
    }
    
    private func setupConstraints() {
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        userPOIHeadView.translatesAutoresizingMaskIntoConstraints = false
        titleSegmentedView.translatesAutoresizingMaskIntoConstraints = false
        userPointMsgView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        bottomToolView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 容器视图约束
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 头部视图约束
            userPOIHeadView.topAnchor.constraint(equalTo: contentContainerView.topAnchor, constant: 10),
            userPOIHeadView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            userPOIHeadView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            userPOIHeadView.heightAnchor.constraint(equalToConstant: 80),
            
            // 选择视图约束
            titleSegmentedView.topAnchor.constraint(equalTo: userPOIHeadView.bottomAnchor),
            titleSegmentedView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            titleSegmentedView.widthAnchor.constraint(equalToConstant: 140),
            titleSegmentedView.heightAnchor.constraint(equalToConstant: 60),
            
            // TableView约束
            userPointMsgView.topAnchor.constraint(equalTo: titleSegmentedView.bottomAnchor, constant: 5),
            userPointMsgView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            userPointMsgView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            userPointMsgView.bottomAnchor.constraint(equalTo: bottomToolView.topAnchor),
            
            // TableView约束
            tableView.topAnchor.constraint(equalTo: titleSegmentedView.bottomAnchor, constant: 5),
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
    private func handleDeleteTapped() {
        print("删除按钮点击")
        SWAlertView.showAlert(title: "删除兴趣点", message: "你确定要删除该兴趣点吗？") { [weak self] in
            guard let self = self else { return }
            if let poiId = self.poiData?.id {
                self.mapViewModel.deleteUserPoi(poiId)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] completion in
                        if case .failure(_) = completion {
                            self?.view.sw_showWarningToast("删除自定义兴趣点失败")
                        }
                    } receiveValue: { [weak self] success in
                        guard let self = self else { return }
                        if success {
                            self.view.sw_showSuccessToast("删除成功")
                        }else {
                            self.view.sw_showWarningToast("删除失败")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.closeTapped()
                        }
                    }
                    .store(in: &self.mapViewModel.cancellables)
                
            }else {
                print("用户兴趣点的ID获取失败")
            }
        }
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
            mapViewModel.openAmapNavigation(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon, destinationName: self.poiData?.name ?? "")
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

extension UserPOIDetailViewController {
    private func handleSelection(index: Int) {
        // 根据选中的索引执行相应操作
        switch index {
        case 0:
            userPointMsgView.isHidden = false
            tableView.isHidden = true
            break
        case 1:
            userPointMsgView.isHidden = true
            tableView.isHidden = false
            break
        default:
            break
        }
    }
}

extension UserPOIDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
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
    
}

extension UserPOIDetailViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        // 当sheet高度变化时，确保底部工具栏在最上层
        view.bringSubviewToFront(bottomToolView)
    }
}


class UserPOIHeadView: UIView {
    
    public let locationLabel = UILabel()
    public let closeButton = UIButton(type: .custom)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        // 位置信息
        locationLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        locationLabel.textColor = .black
        addSubview(locationLabel)
        
        // 关闭按钮
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .systemGray
        addSubview(closeButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            locationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            closeButton.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}


class UserPOIMsgView: UIView {
    
    private let typeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "类型"
        label.textColor = .black
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    private let imageTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "照片"
        label.textColor = .black
        label.font = .systemFont(ofSize: 16, weight: .regular)
        return label
    }()
    private let typeTextLabel: UILabel = {
        let label = UILabel()
        label.text = "露营地"
        label.textColor = .black
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    private let photoContainerView: UIView = {
        let view = UIView()
        return view
    }()
    private var photoImageViews: [UIImageView] = []
    private let contentTextLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        
        addSubview(typeTitleLabel)
        addSubview(imageTitleLabel)
        addSubview(typeTextLabel)
        addSubview(photoContainerView)
        addSubview(contentTextLabel)
        setupConstraints()
    }
    
    private func setupConstraints() {
        typeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        typeTextLabel.translatesAutoresizingMaskIntoConstraints = false
        photoContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            typeTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            typeTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            typeTextLabel.centerYAnchor.constraint(equalTo: typeTitleLabel.centerYAnchor),
            typeTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
    
    func setImageAndContentUI(with userPOIData: UserPOIData) {
        
        if userPOIData.category == 1 {
            typeTextLabel.text = "露营地"
        }
        if userPOIData.category == 2 {
            typeTextLabel.text = "风景名胜"
        }
        if userPOIData.category == 3 {
            typeTextLabel.text = "加油站"
        }
        
        if userPOIData.imgUrlList?.count != 0  {
            let itemSize: CGFloat = (UIScreen.main.bounds.width - 30 - 32) / 3
            let spacing: CGFloat = 15
            for (index, imageUrl) in userPOIData.imgUrlList!.enumerated() {
                let imageView = UIImageView()
                if let avatarUrl = URL(string: imageUrl) {
                    imageView.sd_setImage(with: avatarUrl)
                }
                imageView.contentMode = .scaleAspectFill
                imageView.layer.cornerRadius = 8
                imageView.layer.masksToBounds = true
                imageView.isUserInteractionEnabled = true
                imageView.clipsToBounds = true // 添加这行，确保图片不会超出边界
                
                let x = CGFloat(index) * (itemSize + spacing)
                imageView.frame = CGRect(x: x, y: 0, width: itemSize, height: itemSize)
                
                photoContainerView.addSubview(imageView)
                photoImageViews.append(imageView)
            }
            
            NSLayoutConstraint.activate([
                imageTitleLabel.topAnchor.constraint(equalTo: typeTitleLabel.bottomAnchor, constant: 10),
                imageTitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                
                photoContainerView.topAnchor.constraint(equalTo: imageTitleLabel.bottomAnchor, constant: 5),
                photoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                photoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                photoContainerView.heightAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 62) / 3),
            ])
            if userPOIData.description != "" {
                NSLayoutConstraint.activate([
                    contentTextLabel.topAnchor.constraint(equalTo: photoContainerView.bottomAnchor, constant: 10),
                    contentTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                    contentTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                ])
            }
        }else {
            imageTitleLabel.isHidden = true
            if userPOIData.description != "" {
                NSLayoutConstraint.activate([
                    contentTextLabel.topAnchor.constraint(equalTo: typeTitleLabel.bottomAnchor, constant: 10),
                    contentTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                    contentTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                ])
            }
        }
        
    }
    
}
