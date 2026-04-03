//
//  MapFakeSearchView.swift
//  ModuleMap
//
//  Created by TXTS on 2026/2/24.
//

import UIKit

class MapFakeSearchView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        translatesAutoresizingMaskIntoConstraints = false
        
        // 搜索图标
        let searchIcon = UIImageView(image: MapModule.image(named: "map_search"))
        searchIcon.tintColor = .black
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchIcon)
        
        let searchTextLabel = UILabel()
        searchTextLabel.text = "地点/经纬度(例116.391349, 39.907375)"
        searchTextLabel.textColor = UIColor(str: "#A0A3A7")
        searchTextLabel.font = .systemFont(ofSize: 14, weight: .regular)
        searchTextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchTextLabel)
        
        NSLayoutConstraint.activate([
            searchIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            searchIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            searchTextLabel.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 5),
            searchTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            searchTextLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
}
