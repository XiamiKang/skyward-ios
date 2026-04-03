//
//  CustomItem.swift
//  Pods
//
//  Created by TXTS on 2026/3/26.
//


import UIKit
import SWKit

// MARK: - 自定义 TableViewCell
class CustomTableViewCell: UITableViewCell {
    
    // 静态标识符
    static let identifier = "CustomTableViewCell"
    
    // UI 组件
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = MessageModule.image(named: "around_poi")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 选中时的对勾图标
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = MessageModule.image(named: "Popup-selected")
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true // 默认隐藏
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        // 添加子视图
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(checkmarkImageView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 图标约束
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // 标题约束
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            // 内容约束
            contentLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            contentLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // 对勾图标约束
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 16),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    // 配置 Cell 数据
    func configure(with item: AroundPOIData, isSelected: Bool) {
        if let name = item.name, !name.isEmpty {
            titleLabel.text = name
        } else {
            titleLabel.text = formatCoordinate(longitude: item.longitude, latitude: item.latitude)
        }
        contentLabel.text = item.address
        updateCheckmarkVisibility(isSelected: isSelected, animated: false)
    }
    
    private func formatCoordinate(longitude: Double?, latitude: Double?) -> String {
        guard let lon = longitude, let lat = latitude else {
            return "未知位置"
        }
        let lonStr = String(format: "%.6fE", lon)
        let latStr = String(format: "%.6fN", lat)
        return "\(latStr), \(lonStr)"
    }
    
    // 单独控制对勾显示状态
    private func updateCheckmarkVisibility(isSelected: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.checkmarkImageView.isHidden = !isSelected
            }
        } else {
            checkmarkImageView.isHidden = !isSelected
        }
    }
    
    // 重写选中状态变化，用于动画效果
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // 注意：这里不要直接设置 checkmarkImageView，因为 configure 方法已经处理了选中状态
        // 如果需要动画效果，可以在这里添加，但要避免覆盖 configure 的设置
        if animated {
            updateCheckmarkVisibility(isSelected: selected, animated: true)
        }
    }
}

// MARK: - 主视图，包含 TableView
class AroundPOITableViewContainerView: UIView, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    
    public var onSelected: ((AroundPOIData) -> Void)?
    
    // TableView 实例
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(CustomTableViewCell.self, forCellReuseIdentifier: CustomTableViewCell.identifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        table.showsVerticalScrollIndicator = true
        table.separatorStyle = .none
        return table
    }()
    
    // 抓手视图容器（扩大点击区域）
    private let grabberContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 抓手视觉指示器
    private let grabberView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // 数据源
    private var items: [AroundPOIData] = []
    private var selectedIndexPath: IndexPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // 添加抓手容器（扩大点击区域）
        addSubview(grabberContainerView)
        grabberContainerView.addSubview(grabberView)
        addSubview(tableView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 抓手容器约束 - 扩大点击区域
            grabberContainerView.topAnchor.constraint(equalTo: topAnchor),
            grabberContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            grabberContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            grabberContainerView.heightAnchor.constraint(equalToConstant: 44), // 扩大点击区域到44pt
            
            // 抓手视觉指示器约束
            grabberView.centerXAnchor.constraint(equalTo: grabberContainerView.centerXAnchor),
            grabberView.centerYAnchor.constraint(equalTo: grabberContainerView.centerYAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: 40),
            grabberView.heightAnchor.constraint(equalToConstant: 5),
            
            // TableView 约束
            tableView.topAnchor.constraint(equalTo: grabberContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false // 单选模式
    }
    
    // 设置抓手区域的手势识别器
    func setGrabberGestureRecognizer(_ gesture: UIGestureRecognizer) {
        grabberContainerView.addGestureRecognizer(gesture)
        gesture.delegate = self
    }
    
    // UIGestureRecognizerDelegate - 确保手势和 tableView 滚动不冲突
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func loadSampleData(with list: [AroundPOIData]) {
        items = list
        tableView.reloadData()
    }
    
    // 默认选中第一行
    public func selectFirstRow() {
        guard !items.isEmpty else { return }
        let firstIndexPath = IndexPath(row: 0, section: 0)
        selectedIndexPath = firstIndexPath
        // 使用 reloadData 而不是 selectRow，确保状态一致
        tableView.reloadData()
        // 可选：滚动到第一行
        tableView.scrollToRow(at: firstIndexPath, at: .top, animated: false)
        
        // 触发选中回调
        let selectedItem = items[firstIndexPath.row]
        onSelected?(selectedItem)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomTableViewCell.identifier, for: indexPath) as? CustomTableViewCell else {
            return UITableViewCell()
        }
        
        let item = items[indexPath.row]
        let isSelected = (selectedIndexPath == indexPath)
        cell.configure(with: item, isSelected: isSelected)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 更新选中状态
        let previousSelectedIndexPath = selectedIndexPath
        selectedIndexPath = indexPath
        
        // 刷新之前选中的 cell 和当前选中的 cell
        var indexPathsToReload: [IndexPath] = [indexPath]
        if let previous = previousSelectedIndexPath, previous != indexPath {
            indexPathsToReload.append(previous)
        }
        
        // 使用 reloadRows 刷新
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
        
        // 打印选中项的信息
        let selectedItem = items[indexPath.row]
        print("选中: \(selectedItem.name ?? "")")
        onSelected?(selectedItem)
    }
    
    // 当 tableView 开始滚动时，如果当前视图高度不是最大高度，自动展开到最大高度
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 获取父视图控制器
        if let containerView = findViewController() as? ChoosePOIAddressViewController {
            let currentHeight = frame.height
            let maxHeight = containerView.getMaxHeight()
            
            if currentHeight < maxHeight {
                UIView.animate(withDuration: 0.3) {
                    containerView.updatePoiListHeight(maxHeight)
                    containerView.view.layoutIfNeeded()
                }
            }
        }
    }
    
    // 辅助方法：获取所在的 ViewController
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}
