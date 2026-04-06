//
//  MiniDeviceMsgViewController.swift
//  SWKit
//
//  Created by TXTS on 2025/12/15.
//

import UIKit
import SWKit

class MiniDeviceSatelliteSendResultController: PersonalBaseViewController {
    
    let imeiStr: String
    let noMsgView = UIView()
    let noMsgImageView = UIImageView()
    let noMsgText = UILabel()
    
    // 计算属性：生成排序后的数据源
    private var dataSource: [MiniDeviceSendResultData] {
        return MiniDeviceSendResultDBManager.shared.qureyFromSendResultWithIMEI(imeiStr) ?? []
    }
    
    // 统计卡片数据模型
    struct StatCard {
        let title: String
        let resultType: SatelliteSendResult
        var count: Int = 0
    }
    
    // 统计卡片数组
    private var statCards: [StatCard] = [
        StatCard(title: "成功(铱星返回成功)", resultType: .success),
        StatCard(title: "失败(铱星返回失败)", resultType: .failure),
        StatCard(title: "超时(铱星发送超时)", resultType: .timeout),
        StatCard(title: "失败(铱星模块未响应)", resultType: .noResponse)
    ]
    
    init(imeiStr: String) {
        self.imeiStr = imeiStr
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Components
    private lazy var statsContainerView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SatelliteResultCell.self, forCellReuseIdentifier: "SatelliteResultCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupNotifications()
        refreshTableView()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "发送结果"
        
        view.addSubview(statsContainerView)
        view.addSubview(tableView)
        
        // 创建两行统计卡片
        createStatRows()
        
        // 设置无数据视图
        setupNoMsgView()
    }
    
    private func createStatRows() {
        // 第一行：成功、失败
        let firstRowStackView = createStatRow(cards: Array(statCards[0...1]))
        // 第二行：超时、无响应
        let secondRowStackView = createStatRow(cards: Array(statCards[2...3]))
        
        statsContainerView.addArrangedSubview(firstRowStackView)
        statsContainerView.addArrangedSubview(secondRowStackView)
    }
    
    private func createStatRow(cards: [StatCard]) -> UIStackView {
        let rowStackView = UIStackView()
        rowStackView.axis = .horizontal
        rowStackView.spacing = 12
        rowStackView.distribution = .fillEqually
        
        for card in cards {
            let cardView = createStatCardView(title: card.title, resultType: card.resultType)
            cardView.heightAnchor.constraint(equalToConstant: 70).isActive = true
            rowStackView.addArrangedSubview(cardView)
        }
        
        return rowStackView
    }
    
    private func createStatCardView(title: String, resultType: SatelliteSendResult) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
        
        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.text = "0"
        countLabel.textColor = .black
        countLabel.textAlignment = .center
        countLabel.font = .systemFont(ofSize: 16, weight: .medium)
        countLabel.tag = resultType.rawValue.hashValue // 用枚举rawValue作为tag标识
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.textColor = UIColor(str: "#84888C")
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        containerView.addSubview(countLabel)
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            countLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            countLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            countLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])
        
        return containerView
    }
    
    private func setupNoMsgView() {
        noMsgView.backgroundColor = .white
        noMsgView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noMsgView)
        
        noMsgImageView.image = PersonalModule.image(named: "device_mini_noMsg")
        noMsgImageView.translatesAutoresizingMaskIntoConstraints = false
        noMsgView.addSubview(noMsgImageView)
        
        noMsgText.text = "暂无消息"
        noMsgText.textColor = UIColor(str: "#74777B")
        noMsgText.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        noMsgText.translatesAutoresizingMaskIntoConstraints = false
        noMsgView.addSubview(noMsgText)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 统计容器视图
            statsContainerView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            statsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statsContainerView.heightAnchor.constraint(equalToConstant: 140),
            
            // 表格视图
            tableView.topAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 无数据视图
            noMsgView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 0),
            noMsgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noMsgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noMsgView.heightAnchor.constraint(equalToConstant: 300),
            
            noMsgImageView.centerXAnchor.constraint(equalTo: noMsgView.centerXAnchor),
            noMsgImageView.topAnchor.constraint(equalTo: noMsgView.topAnchor, constant: 80),
            noMsgImageView.widthAnchor.constraint(equalToConstant: 96),
            noMsgImageView.heightAnchor.constraint(equalToConstant: 96),
            
            noMsgText.centerXAnchor.constraint(equalTo: noMsgView.centerXAnchor),
            noMsgText.topAnchor.constraint(equalTo: noMsgImageView.bottomAnchor, constant: 5)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(satelliteSendResultRefresh),
                                               name: .didReceiveSatelliteSendResult,
                                               object: nil)
    }
    
    @objc private func satelliteSendResultRefresh() {
        refreshTableView()
    }
    
    private func refreshTableView() {
        // 检查是否有数据
        let hasData = dataSource.count != 0
        noMsgView.isHidden = hasData
        tableView.isHidden = !hasData
        statsContainerView.isHidden = !hasData
        
        if hasData {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // 更新统计数字
                self.updateStatCounts()
                self.tableView.reloadData()
            }
        }
    }
    
    private func updateStatCounts() {
        // 遍历统计容器视图中的卡片
        for rowStackView in statsContainerView.arrangedSubviews {
            guard let rowStackView = rowStackView as? UIStackView else { continue }
            
            for cardView in rowStackView.arrangedSubviews {
                // 找到countLabel
                if let countLabel = cardView.subviews.first(where: { $0 is UILabel && $0.tag != 0 }) as? UILabel {
                    // 直接使用tag值，不转换为UInt8
                    switch countLabel.tag {
                    case SatelliteSendResult.success.rawValue.hashValue:
                        let count = dataSource.filter { $0.resultEnum == .success }.count
                        countLabel.text = "\(count)"
                    case SatelliteSendResult.failure.rawValue.hashValue:
                        let count = dataSource.filter { $0.resultEnum == .failure }.count
                        countLabel.text = "\(count)"
                    case SatelliteSendResult.timeout.rawValue.hashValue:
                        let count = dataSource.filter { $0.resultEnum == .timeout }.count
                        countLabel.text = "\(count)"
                    case SatelliteSendResult.noResponse.rawValue.hashValue:
                        let count = dataSource.filter { $0.resultEnum == .noResponse }.count
                        countLabel.text = "\(count)"
                    default:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MiniDeviceSatelliteSendResultController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SatelliteResultCell") as! SatelliteResultCell
        
        let data = dataSource[indexPath.row]
        cell.configure(with: data)
        
        return cell
    }
}

class SatelliteResultCell: UITableViewCell {
    static let identifier = "SatelliteResultCell"
    
    private let resultImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .gray
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
        contentView.addSubview(resultImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            resultImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resultImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            resultImageView.widthAnchor.constraint(equalToConstant: 40),
            resultImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: resultImageView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: resultImageView.trailingAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
        
        
        // 设置单元格样式
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    // MARK: - Configuration
    func configure(with sendResultData: MiniDeviceSendResultData) {
        let isSuccess = sendResultData.resultEnum == .success
        resultImageView.image = isSuccess ? PersonalModule.image(named: "device_mini_result_success") : PersonalModule.image(named: "device_mini_result_fail")
        nameLabel.text = "\(sendResultData.commandStr)发送\(sendResultData.resultStr)"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: sendResultData.time)
        timeLabel.text = dateString
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        timeLabel.text = nil
    }
}
