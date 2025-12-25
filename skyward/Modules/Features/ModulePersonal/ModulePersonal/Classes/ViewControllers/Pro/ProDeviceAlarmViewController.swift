//
//  ProDeviceAlarmViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit

struct ProDeviceAlarmInfo {
    let statu: Int  // 0：正常；1：异常
    let value: String
}

class ProDeviceAlarmViewController: PersonalBaseViewController {
    
    var dataSource: [ProDeviceAlarmInfo] = [
        ProDeviceAlarmInfo(statu: 0, value: "姿态故障"),
        ProDeviceAlarmInfo(statu: 0, value: "定位故障"),
        ProDeviceAlarmInfo(statu: 0, value: "信标信号故障"),
        ProDeviceAlarmInfo(statu: 0, value: "接收链路故障"),
        ProDeviceAlarmInfo(statu: 0, value: "发射链路故障")
    ]
    
    // 添加状态枚举
    enum ViewState {
        case loading     // 正在获取中
        case empty       // 暂无数据
        case normal      // 正常显示数据
    }
    
    private var currentState: ViewState = .loading {
        didSet {
            updateViewState()
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        tableView.register(ProDeviceAlarmCell.self, forCellReuseIdentifier: "ProDeviceAlarmCell")
        return tableView
    }()
    
    private lazy var getDeviceAlarmButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("获取设备告警", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(getDeviceAlarmClick), for: .touchUpInside)
        return button
    }()
    
    // MARK: - 状态视图
    private lazy var statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = PersonalModule.image(named: "device_pro_deviceWarning")
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(hex: "#070808")
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var statusContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        // 初始状态为正在获取中
        showLoading()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "设备告警"
        
        // 添加状态容器视图
        view.addSubview(statusContainerView)
        statusContainerView.addSubview(statusImageView)
        statusContainerView.addSubview(statusLabel)
        
        // 添加原有视图
        view.addSubview(tableView)
        view.addSubview(getDeviceAlarmButton)
        
        NSLayoutConstraint.activate([
            // tableView 约束
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 按钮约束保持不变
            getDeviceAlarmButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            getDeviceAlarmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            getDeviceAlarmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            getDeviceAlarmButton.heightAnchor.constraint(equalToConstant: 48),
            
            // 状态容器视图约束 - 占据整个 tableView 区域
            statusContainerView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            statusContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusContainerView.bottomAnchor.constraint(equalTo: getDeviceAlarmButton.topAnchor, constant: -16),
            
            // 状态图片约束
            statusImageView.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            statusImageView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 80),
            statusImageView.widthAnchor.constraint(equalToConstant: 30),
            statusImageView.heightAnchor.constraint(equalToConstant: 30),
            
            // 状态文字约束
            statusLabel.topAnchor.constraint(equalTo: statusImageView.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: statusContainerView.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusContainerView.trailingAnchor, constant: -40),
        ])
    }
    
    // MARK: - 更新视图状态
    private func updateViewState() {
        switch currentState {
        case .loading:
            // 显示状态视图，隐藏 tableView
            statusContainerView.isHidden = false
            statusImageView.isHidden = false
            statusLabel.isHidden = false
            tableView.isHidden = true
            
            // 设置加载状态文字
            statusLabel.text = "正在获取中..."
            
        case .empty:
            // 显示状态视图，隐藏 tableView
            statusContainerView.isHidden = false
            statusImageView.isHidden = false
            statusLabel.isHidden = false
            tableView.isHidden = true
            
            // 设置空状态文字
            statusLabel.text = "暂无设备告警"
            
        case .normal:
            // 隐藏状态视图，显示 tableView
            statusContainerView.isHidden = true
            tableView.isHidden = false
        }
    }
    
    // MARK: - 加载动画相关
    @objc private func getDeviceAlarmClick() {
        // 点击按钮时显示加载状态
        showLoading()
        
        // 模拟获取数据
        simulateFetchingData()
    }
    
    // MARK: - 模拟数据获取
    private func simulateFetchingData() {
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // 这里模拟几种情况：
            // 1. 有数据 - 显示正常状态
            // 2. 无数据 - 显示空状态
            
            let hasData = Bool.random() // 随机决定是否有数据
            
            if hasData {
                // 切换到正常状态
                self.showNormal()
            } else {
                // 切换到空状态
                self.showEmpty()
            }
        }
    }
}

extension ProDeviceAlarmViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProDeviceAlarmCell") as! ProDeviceAlarmCell
        cell.configure(with: dataSource[indexPath.row])
        return cell
    }
}

// MARK: - 状态切换的便捷方法
extension ProDeviceAlarmViewController {
    /// 显示加载状态（正在获取中）
    func showLoading() {
        currentState = .loading
    }
    
    /// 显示正常数据状态
    func showNormal() {
        currentState = .normal
    }
    
    /// 显示空数据状态（暂无设备告警）
    func showEmpty() {
        currentState = .empty
    }
    
    /// 显示正常数据状态，并更新数据源
    func showNormal(with data: [ProDeviceAlarmInfo]) {
        self.dataSource = data
        tableView.reloadData()
        currentState = .normal
    }
}

class ProDeviceAlarmCell: UITableViewCell {
    static let identifier = "ProDeviceAlarmCell"
    
    // MARK: - UI Components
    private let alarmImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(alarmImageView)
        contentView.addSubview(contentLabel)
        
        alarmImageView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            alarmImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            alarmImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            alarmImageView.widthAnchor.constraint(equalToConstant: 40),
            alarmImageView.heightAnchor.constraint(equalToConstant: 40),
            
            contentLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentLabel.leadingAnchor.constraint(equalTo: alarmImageView.trailingAnchor, constant: 8),
        ])
        
        // 设置单元格样式
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    // MARK: - Configuration
    func configure(with alarmData: ProDeviceAlarmInfo) {
        // cell名称
        alarmImageView.image = alarmData.statu == 0 ? PersonalModule.image(named: "device_pro_alarm_0") : PersonalModule.image(named: "device_pro_alarm_1")
        
        // cell内容
        contentLabel.text = alarmData.value
        contentLabel.textColor = alarmData.statu == 0 ? UIColor(str: "#070808") : UIColor(str: "#F7594B")
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        alarmImageView.image = nil
        contentLabel.text = nil
    }
}

