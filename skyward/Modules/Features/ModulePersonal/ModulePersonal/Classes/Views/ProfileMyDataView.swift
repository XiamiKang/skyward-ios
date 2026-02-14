//
//  ProfileMyDataView.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/2/3.
//

import UIKit
import SWKit

let itemWidth = (UIScreen.main.bounds.width - 64)/4
let itemHeight = itemWidth/77*54

class ProfileMyDataView: UIView {
    
    var selectedIndex: ((Int) -> Void)?
    
    private let titleTextLabel: UILabel = {
        let label = UILabel()
        label.text = "我的数据"
        label.textColor = UIColor(str: "#070808")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        
        collectionView.register(ProfileMyDataCell.self, forCellWithReuseIdentifier: "ProfileMyDataCell")
        return collectionView
    }()
    
    private var dataSource: [ProfileMyDataItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setDateSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        
        addSubview(titleTextLabel)
        addSubview(collectionView)
        
        setupConstraints()
    }

    private func setupConstraints() {
        titleTextLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleTextLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            collectionView.topAnchor.constraint(equalTo: titleTextLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }
    
    private func setDateSource() {
        dataSource = [
            ProfileMyDataItem(imageName: "profile_cell_trajectory", itemName: "历史轨迹(0)"),
            ProfileMyDataItem(imageName: "profile_cell_POI", itemName: "兴趣点(0)"),
            ProfileMyDataItem(imageName: "profile_cell_route", itemName: "绘制路线(0)"),
            ProfileMyDataItem(imageName: "profile_cell_checkout", itemName: "打卡(0)"),
            ProfileMyDataItem(imageName: "profile_cell_collect", itemName: "收藏(0)"),
            ProfileMyDataItem(imageName: "profile_cell_offline", itemName: "离线缓存(0)"),
        ]
        collectionView.reloadData()
    }
    
    func updateData(with trajectoryNum: Int = 0, POINum: Int = 0, routeNum: Int = 0, checkoutNum: Int = 0, collectNum: Int = 0, offlineNum: Int = 0) {
        dataSource = [
            ProfileMyDataItem(imageName: "profile_cell_trajectory", itemName: "历史轨迹(\(trajectoryNum)"),
            ProfileMyDataItem(imageName: "profile_cell_POI", itemName: "兴趣点(\(POINum))"),
            ProfileMyDataItem(imageName: "profile_cell_route", itemName: "绘制路线(\(routeNum))"),
            ProfileMyDataItem(imageName: "profile_cell_checkout", itemName: "打卡(\(checkoutNum))"),
            ProfileMyDataItem(imageName: "profile_cell_collect", itemName: "收藏(\(collectNum))"),
            ProfileMyDataItem(imageName: "profile_cell_offline", itemName: "离线缓存(\(offlineNum))"),
        ]
        collectionView.reloadData()
    }
}

extension ProfileMyDataView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileMyDataCell", for: indexPath) as! ProfileMyDataCell
        cell.configure(with: dataSource[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex?(indexPath.row)
    }
}
