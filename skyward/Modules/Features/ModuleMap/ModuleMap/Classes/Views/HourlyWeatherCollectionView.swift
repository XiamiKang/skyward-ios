//
//  HourlyWeatherCollectionView.swift
//  Pods
//
//  Created by TXTS on 2025/12/4.
//


// 每小时天气数据
import UIKit

class HourlyWeatherCollectionView: UIView {
    
    // MARK: - UI组件
    private let collectionView: UICollectionView
    private let flowLayout: UICollectionViewFlowLayout
    
    // MARK: - 数据
    private var hourlyData: [EveryHoursWeatherData] = []
    
    // MARK: - 配置
    struct Config {
        var cellWidth: CGFloat = 50
        var cellHeight: CGFloat = 80
        var itemSpacing: CGFloat = 8
        var sectionInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    private var config = Config()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        // 创建布局
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        
        // 创建集合视图 - 关键修改：使用传入的frame或默认值
        let initialWidth = frame.width > 0 ? frame.width : UIScreen.main.bounds.width
        let initialHeight = frame.height > 0 ? frame.height : 100
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: initialWidth, height: initialHeight), collectionViewLayout: flowLayout)
        
        super.init(frame: frame)
        setupUI()
        updateLayout() // 初始化布局
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        backgroundColor = .clear
        
        // 集合视图
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self // 关键：添加代理
        collectionView.alwaysBounceHorizontal = true // 允许水平弹性滚动
        collectionView.register(HourlyWeatherCell.self, forCellWithReuseIdentifier: "HourlyWeatherCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        
        // 设置约束 - 充满整个视图
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - 配置方法
    func configure(with data: [EveryHoursWeatherData], config: Config? = nil) {
        // 更新配置
        if let config = config {
            self.config = config
        }
        
        // 转换数据
        hourlyData = data
        
        // 自动调整cell宽度
        adjustCellWidthForContent()
        
        collectionView.reloadData()
        
        // 如果内容宽度超过视图宽度，滚动到开始位置
        if collectionView.contentSize.width > bounds.width {
            collectionView.setContentOffset(.zero, animated: false)
        }
    }
    
    // MARK: - 更新布局
    private func updateLayout() {
        flowLayout.itemSize = CGSize(width: config.cellWidth, height: config.cellHeight)
        flowLayout.sectionInset = config.sectionInsets
        flowLayout.minimumLineSpacing = config.itemSpacing
        flowLayout.minimumInteritemSpacing = config.itemSpacing
        flowLayout.scrollDirection = .horizontal // 确保是水平方向
    }
    
    // MARK: - 调整cell宽度
    private func adjustCellWidthForContent() {
        let itemCount = max(1, hourlyData.count)
        let totalNeededWidth = CGFloat(itemCount) * config.cellWidth +
                              CGFloat(itemCount - 1) * config.itemSpacing +
                              config.sectionInsets.left + config.sectionInsets.right
        
        if totalNeededWidth <= bounds.width {
            // 内容不够宽，调整cell宽度以填充空间
            let availableWidth = bounds.width - config.sectionInsets.left - config.sectionInsets.right
            config.cellWidth = (availableWidth - CGFloat(itemCount - 1) * config.itemSpacing) / CGFloat(itemCount)
            config.cellWidth = max(40, config.cellWidth) // 最小宽度
        }
        
        updateLayout()
    }
    
    // MARK: - 刷新数据
    func refresh(with data: [EveryHoursWeatherData]) {
        hourlyData = data
        adjustCellWidthForContent()
        collectionView.reloadData()
    }
    
    // MARK: - 手动滚动到特定时间
    func scrollToHour(_ hour: Int, animated: Bool = true) {
        guard hour >= 0 && hour < hourlyData.count else { return }
        
        let indexPath = IndexPath(item: hour, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }
    
    // MARK: - 获取当前显示的小时
    func currentVisibleHour() -> Int? {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
            return indexPath.item
        }
        return nil
    }
}

// MARK: - UICollectionViewDataSource
extension HourlyWeatherCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyData.isEmpty ? 24 : hourlyData.count // 没有数据时显示24个占位
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HourlyWeatherCell", for: indexPath) as! HourlyWeatherCell
        
        if indexPath.item < hourlyData.count {
            cell.configure(with: hourlyData[indexPath.item])
        }
//        else {
//            // 显示占位数据
//            cell.configureAsPlaceholder(hour: indexPath.item)
//        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HourlyWeatherCollectionView: UICollectionViewDelegateFlowLayout {
    // 使用代理方法动态设置布局参数
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: config.cellWidth, height: config.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return config.sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return config.itemSpacing
    }
}
