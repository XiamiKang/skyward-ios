//
//  BottomToolView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/8.
//

import UIKit
import SWKit

class BottomToolView: UIView {

    // 移除单例模式，改为普通类
    private let checkView = UIView()
    private var checkImageView = UIImageView()
    private let checkLabel = UILabel()
    private let checkButton = UIButton()
    
    private let collectionView = UIView()
    private var collectionImageView = UIImageView()
    private let collectionLabel = UILabel()
    private let collectionButton = UIButton()
    
    private let navigationView = UIView()
    private var navigationImageView = UIImageView()
    private let navigationLabel = UILabel()
    private let navigationButton = UIButton()
    
    private var isChecked: Bool = false
    private var isCollected: Bool = false
    private var poiData: PublicPOIData?
    
    // 按钮点击回调
    var onCheckTapped: (() -> Void)?
    var onCollectionTapped: (() -> Void)?
    var onNavigationTapped: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        // 添加阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        checkView.backgroundColor = .clear
        checkImageView.image = MapModule.image(named: "map_poi_checkin_unsel")
        checkLabel.text = "打卡"
        checkLabel.textColor = .black
        checkLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        checkButton.backgroundColor = .clear
        
        collectionView.backgroundColor = .clear
        collectionImageView.image = MapModule.image(named: "map_poi_collection_unsel")
        collectionLabel.text = "收藏"
        collectionLabel.textColor = .black
        collectionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        collectionButton.backgroundColor = .clear
        
        navigationView.backgroundColor = UIColor(str: "#FE6A00")
        navigationView.layer.cornerRadius = 8
        navigationImageView.image = MapModule.image(named: "map_navigation_iocn")
        navigationLabel.text = "导航"
        navigationLabel.textColor = .white
        navigationLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        navigationButton.backgroundColor = .clear
        
        addSubview(checkView)
        addSubview(collectionView)
        addSubview(navigationView)
        
        checkView.addSubview(checkImageView)
        checkView.addSubview(checkLabel)
        checkView.addSubview(checkButton)
        
        collectionView.addSubview(collectionImageView)
        collectionView.addSubview(collectionLabel)
        collectionView.addSubview(collectionButton)
        
        navigationView.addSubview(navigationImageView)
        navigationView.addSubview(navigationLabel)
        navigationView.addSubview(navigationButton)
        
        setConstraint()
    }
    
    private func setupActions() {
        checkButton.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
        collectionButton.addTarget(self, action: #selector(collectionButtonTapped), for: .touchUpInside)
        navigationButton.addTarget(self, action: #selector(navigationButtonTapped), for: .touchUpInside)
    }
    
    @objc private func checkButtonTapped() {
        if isChecked {
            UIWindow.topWindow?.sw_showSuccessToast("取消打卡成功")
            checkImageView.image = MapModule.image(named: "map_poi_checkin_unsel")
        }else {
            UIWindow.topWindow?.sw_showSuccessToast("打卡成功")
            checkImageView.image = MapModule.image(named: "map_poi_checkin_sel")
        }
        isChecked = !isChecked
        if var poi = self.poiData {
            poi.isIsCheck = isChecked
            POIDatabaseManager.shared.updatePOIWithObject(poi) { success, error in
                if success {
                    print("更新成功")
                }
            }
        }
        onCheckTapped?()
    }
    
    @objc private func collectionButtonTapped() {
        if isCollected {
            UIWindow.topWindow?.sw_showSuccessToast("取消收藏成功")
            collectionImageView.image = MapModule.image(named: "map_poi_collection_unsel")
        }else {
            UIWindow.topWindow?.sw_showSuccessToast("收藏成功")
            collectionImageView.image = MapModule.image(named: "map_poi_collection_sel")
        }
        isCollected = !isCollected
        if var poi = self.poiData {
            poi.isCollection = isCollected
            POIDatabaseManager.shared.updatePOIWithObject(poi) { success, error in
                if success {
                    print("更新成功")
                }
            }
        }
        onCollectionTapped?()
    }
    
    @objc private func navigationButtonTapped() {
        onNavigationTapped?()
    }
    
    private func setConstraint() {
        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionImageView.translatesAutoresizingMaskIntoConstraints = false
        collectionLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionButton.translatesAutoresizingMaskIntoConstraints = false
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        navigationImageView.translatesAutoresizingMaskIntoConstraints = false
        navigationLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            checkView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            checkView.widthAnchor.constraint(equalToConstant: 50),
            checkView.heightAnchor.constraint(equalToConstant: 60),
            
            checkImageView.topAnchor.constraint(equalTo: checkView.topAnchor, constant: 10),
            checkImageView.centerXAnchor.constraint(equalTo: checkView.centerXAnchor),
            checkImageView.heightAnchor.constraint(equalToConstant: 20),
            checkImageView.widthAnchor.constraint(equalToConstant: 20),
            
            checkLabel.topAnchor.constraint(equalTo: checkImageView.bottomAnchor, constant: 5),
            checkLabel.centerXAnchor.constraint(equalTo: checkView.centerXAnchor),
            
            checkButton.topAnchor.constraint(equalTo: checkView.topAnchor),
            checkButton.leadingAnchor.constraint(equalTo: checkView.leadingAnchor),
            checkButton.trailingAnchor.constraint(equalTo: checkView.trailingAnchor),
            checkButton.bottomAnchor.constraint(equalTo: checkView.bottomAnchor),
            
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: checkView.trailingAnchor, constant: 5),
            collectionView.widthAnchor.constraint(equalToConstant: 50),
            collectionView.heightAnchor.constraint(equalToConstant: 60),
            
            collectionImageView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 10),
            collectionImageView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            collectionImageView.heightAnchor.constraint(equalToConstant: 20),
            collectionImageView.widthAnchor.constraint(equalToConstant: 20),
            
            collectionLabel.topAnchor.constraint(equalTo: collectionImageView.bottomAnchor, constant: 5),
            collectionLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            
            collectionButton.topAnchor.constraint(equalTo: collectionView.topAnchor),
            collectionButton.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            collectionButton.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            collectionButton.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            
            navigationView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            navigationView.leadingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: 16),
            navigationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            navigationView.heightAnchor.constraint(equalToConstant: 50),
            
            navigationImageView.centerXAnchor.constraint(equalTo: navigationView.centerXAnchor, constant: -20),
            navigationImageView.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor),
            navigationImageView.heightAnchor.constraint(equalToConstant: 20),
            navigationImageView.widthAnchor.constraint(equalToConstant: 20),
            
            navigationLabel.leadingAnchor.constraint(equalTo: navigationImageView.trailingAnchor, constant: 5),
            navigationLabel.centerYAnchor.constraint(equalTo: navigationView.centerYAnchor),
            
            navigationButton.topAnchor.constraint(equalTo: navigationView.topAnchor),
            navigationButton.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor),
            navigationButton.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor),
            navigationButton.bottomAnchor.constraint(equalTo: navigationView.bottomAnchor),
        ])
    }
    
    func updateWithPOIData(poiData: PublicPOIData) {
        self.poiData = poiData
        guard let isCheck = poiData.isIsCheck, let isCollection = poiData.isCollection else { return }
        checkImageView.image = isCheck ? MapModule.image(named: "map_poi_checkin_sel") : MapModule.image(named: "map_poi_checkin_unsel")
        collectionImageView.image = isCollection ? MapModule.image(named: "map_poi_collection_sel") : MapModule.image(named: "map_poi_collection_unsel")
        isChecked = isCheck
        isCollected = isCollection
        
    }
}
