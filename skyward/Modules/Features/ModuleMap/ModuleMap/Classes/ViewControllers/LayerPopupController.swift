//
//  BaseMapLayer.swift
//  yifan_test
//
//  Created by TXTS on 2025/11/27.
//


import UIKit
import Combine
import SWTheme

// MARK: - 主控制器
public class LayerPopupController: UIViewController {
    
    // MARK: - ViewModel
    private let viewModel = LayerPopupViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // 注册Cell和Header
        collectionView.register(MapOptionCell.self, forCellWithReuseIdentifier: "MapOptionCell")
        collectionView.register(AnnotationOptionCell.self, forCellWithReuseIdentifier: "AnnotationOptionCell")
        collectionView.register(SectionHeaderView.self,
                              forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                              withReuseIdentifier: "SectionHeaderView")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "图层"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor(str: "#070808"), for: .normal)
        button.backgroundColor = ThemeManager.current.mediumGrayBGColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("确定", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(str: "#FE6A00")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }
    
    // MARK: - 设置UI
    private func setupUI() {
        view.backgroundColor = .white
        
        // 设置头部
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        // 添加子视图
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(collectionView)
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Title
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            // Close Button
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // CollectionView
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -16),
            
            // cancel Button
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 44)/2),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            
            // confirm Button
            confirmButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 44)/2),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    // MARK: - ViewModel绑定
    private func bindViewModel() {
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 创建布局
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let self = self, sectionIndex < self.viewModel.sections.count else {
                return nil
            }
            
            let section = self.viewModel.sections[sectionIndex]
            
            switch section.type {
            case .map:
                return self.createMapSectionLayout()
            case .annotation, .poi:
                return self.createAnnotationSectionLayout()
            }
        }
    }
    
    private func createMapSectionLayout() -> NSCollectionLayoutSection {
        // 计算item大小
        let totalWidth = view.bounds.width - 40
        let itemWidth = (totalWidth - 20) / 3
        let itemHeight: CGFloat = 100.0
        
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                             heightDimension: .absolute(itemHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                      subitem: item,
                                                      count: 3)
        group.interItemSpacing = .fixed(10)
        
        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        // Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(30))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createAnnotationSectionLayout() -> NSCollectionLayoutSection {
        // 计算item大小
        let totalWidth = view.bounds.width - 40
        let itemWidth = (totalWidth - 20) / 3
        let itemHeight: CGFloat = 40
        
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth),
                                             heightDimension: .absolute(itemHeight))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .absolute(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                      subitem: item,
                                                      count: 3)
        group.interItemSpacing = .fixed(10)
        
        // Section
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        // Header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(30))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    // MARK: - 点击事件
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func confirmButtonTapped() {
        let selectedOptions = viewModel.selectedOptions
        let currentOptions = viewModel.currentSelectedOptions
        
        // 处理地图切换
        if let mapDict = selectedOptions["selectedMap"] as? [String: String],
           let sceneName = mapDict["name"],
           let currentMap = viewModel.currentSelectedOptions["selectedMap"] as? [String: String],
           let currentName = currentMap["name"] {
            
            if sceneName != currentName {
                UserDefaults.standard.set(sceneName, forKey: "ChooseTileSourceName")
                handleMapSourceLayerDisplay(sceneName)
            }
        }
        
        // 处理矢量注记 - 单独处理
        if let vectorAnnotations = selectedOptions["selectedVectorAnnotations"] as? [String],
           let currentVector = currentOptions["selectedVectorAnnotations"] as? [String] {
            if Set(vectorAnnotations) != Set(currentVector) {
                let isVectorVisible = viewModel.handleVectorAnnotationLayer(vectorAnnotations)
                handleVectorAnnotationLayerDisplay(isVectorVisible)
            }
        }
        
        // 处理天气 - 单独处理
        if let weatherAnnotations = selectedOptions["selectedWeatherAnnotations"] as? [String],
           let currentWeather = currentOptions["selectedWeatherAnnotations"] as? [String] {
            if Set(weatherAnnotations) != Set(currentWeather) {
                let isWeatherVisible = viewModel.handleWeatherAnnotationLayer(weatherAnnotations)
                handleWeatherLayerDisplay(isWeatherVisible)
            }
        }
        

        // 处理兴趣点 - 分别处理每个POI类型
        handlePOIChanges(selectedOptions: selectedOptions, currentOptions: currentOptions)
        
        // 关闭弹窗
        dismiss(animated: true)
    }
    
    // MARK: - 新增：处理POI变化的辅助方法
    private func handlePOIChanges(selectedOptions: [String: Any], currentOptions: [String: Any]) {
        // 处理露营地
        if let selected = selectedOptions["selectedCampgrounds"] as? [String],
           let current = currentOptions["selectedCampgrounds"] as? [String] {
            if Set(selected) != Set(current) {
                let isVisible = viewModel.handleCampgroundLayer(selected)
                handleCampgroundLayerDisplay(isVisible)
            }
        }
        
        // 处理风景名胜
        if let selected = selectedOptions["selectedScenics"] as? [String],
           let current = currentOptions["selectedScenics"] as? [String] {
            if Set(selected) != Set(current) {
                let isVisible = viewModel.handleScenicLayer(selected)
                handleScenicLayerDisplay(isVisible)
            }
        }
        
        // 处理加油站
        if let selected = selectedOptions["selectedGasStations"] as? [String],
           let current = currentOptions["selectedGasStations"] as? [String] {
            if Set(selected) != Set(current) {
                let isVisible = viewModel.handleGasStationLayer(selected)
                handleGasStationLayerDisplay(isVisible)
            }
        }
        
        // 处理医疗
        if let selected = selectedOptions["selectedMedicals"] as? [String],
           let current = currentOptions["selectedMedicals"] as? [String] {
            if Set(selected) != Set(current) {
                let isVisible = viewModel.handleMedicalLayer(selected)
                handleMedicalLayerDisplay(isVisible)
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension LayerPopupController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.sections[section].items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = viewModel.sections[indexPath.section]
        let item = section.items[indexPath.item]
        
        switch section.type {
        case .map:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MapOptionCell", for: indexPath) as! MapOptionCell
            if let mapSource = item as? MapSource {
                cell.configure(with: mapSource)
            }
            return cell
            
        default: // .annotation, .poi,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnnotationOptionCell", for: indexPath) as! AnnotationOptionCell
            if let option = item as? AnnotationOption {
                cell.configure(with: option)
            }
            if let option = item as? POIOption {
                cell.configure(with: option)
            }
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "SectionHeaderView",
                for: indexPath
            ) as! SectionHeaderView
            
            header.configure(with: viewModel.sections[indexPath.section].title)
            return header
        }
        
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate
extension LayerPopupController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = viewModel.sections[indexPath.section]
        
        switch section.type {
        case .map:
            // 地图单选
            viewModel.selectMap(at: indexPath)
            
        default:
            // 标注、兴趣点、天气多选
            viewModel.toggleAnnotationOption(at: indexPath)
        }
        
        // 更新cell显示
        UIView.performWithoutAnimation {
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

// MARK: - 辅助方法
extension LayerPopupController {
    
    // 根据地图名称获取对应的图片名
    private func getImageNameForMap(_ mapName: String) -> String {
        switch mapName {
        case "天地图街道":
            return "map1"
        case "天地图影像":
            return "map2"
        case "吉林长光影像":
            return "map3"
        case "海图":
            return "map4"
        case "谷歌地图":
            return "map5"
        case "谷歌卫星":
            return "map6"
        default:
            return "map1"
        }
    }
    
    // 处理图源
    private func handleMapSourceLayerDisplay(_ sceneUrl: String) {
        // 发送通知更新图源
        NotificationCenter.default.post(
            name: .updateMapSource,
            object: nil,
            userInfo: ["sceneUrl": sceneUrl]
        )
    }
    
    // 处理矢量注记 - 单独处理
    private func handleVectorAnnotationLayerDisplay(_ isVisible: Bool) {
        NotificationCenter.default.post(
            name: .updateVectorAnnotation,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
    
    // 处理天气 - 单独处理
    private func handleWeatherLayerDisplay(_ isVisible: Bool) {
        NotificationCenter.default.post(
            name: .updateWeatherLayers,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
    
    // 处理露营地
    private func handleCampgroundLayerDisplay(_ isVisible: Bool) {
        NotificationCenter.default.post(
            name: .updateCampgroundLayer,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
    
    // 处理风景名胜
    private func handleScenicLayerDisplay(_ isVisible: Bool) {
        NotificationCenter.default.post(
            name: .updateScenicLayer,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
    
    // 处理加油站
    private func handleGasStationLayerDisplay(_ isVisible: Bool) {
        NotificationCenter.default.post(
            name: .updateGasStationLayer,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
    
    // 处理医疗
    private func handleMedicalLayerDisplay(_ isVisible: Bool) {
        NotificationCenter.default.post(
            name: .updateMedicalLayer,
            object: nil,
            userInfo: ["isVisible": isVisible]
        )
    }
}

extension Notification.Name {
    public static let updateMapSource = Notification.Name("updateMapSource")                               // 图源
    public static let updateVectorAnnotation = Notification.Name("updateVectorAnnotation")                 // 注记
    public static let updateWeatherLayers = Notification.Name("updateWeatherLayers")                       // 天气
    public static let updateCampgroundLayer = Notification.Name("updateCampgroundLayer")                   // 露营地
    public static let updateScenicLayer = Notification.Name("updateScenicLayer")                           // 风景名胜
    public static let updateGasStationLayer = Notification.Name("updateGasStationLayer")                   // 加油站
    public static let updateMedicalLayer = Notification.Name("updateMedicalLayer")                         // 医疗
}



