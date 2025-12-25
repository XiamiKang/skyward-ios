//
//  UserBottomToolView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/17.
//

import UIKit

class UserBottomToolView: UIView {
    
    private let deleteView = UIView()
    private var deleteImageView = UIImageView()
    private let deleteLabel = UILabel()
    private let deleteButton = UIButton()
    
    private let navigationView = UIView()
    private var navigationImageView = UIImageView()
    private let navigationLabel = UILabel()
    private let navigationButton = UIButton()
    
    // 按钮点击回调
    var onDeleteTapped: (() -> Void)?
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
        
        deleteView.backgroundColor = UIColor(str: "#F2F3F4")
        deleteView.layer.cornerRadius = 8
        deleteImageView.image = MapModule.image(named: "map_user_delete")
        deleteLabel.text = "删除"
        deleteLabel.textColor = .black
        deleteLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        deleteButton.backgroundColor = .clear
        
        navigationView.backgroundColor = UIColor(str: "#FE6A00")
        navigationView.layer.cornerRadius = 8
        navigationImageView.image = MapModule.image(named: "map_navigation_iocn")
        navigationLabel.text = "导航"
        navigationLabel.textColor = .white
        navigationLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        navigationButton.backgroundColor = .clear
        
        addSubview(deleteView)
        addSubview(navigationView)
        
        deleteView.addSubview(deleteImageView)
        deleteView.addSubview(deleteLabel)
        deleteView.addSubview(deleteButton)
        
        navigationView.addSubview(navigationImageView)
        navigationView.addSubview(navigationLabel)
        navigationView.addSubview(navigationButton)
        
        setConstraint()
    }
    
    private func setupActions() {
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        navigationButton.addTarget(self, action: #selector(navigationButtonTapped), for: .touchUpInside)
    }
    
    @objc private func deleteButtonTapped() {
        onDeleteTapped?()
    }
    
    @objc private func navigationButtonTapped() {
        onNavigationTapped?()
    }
    
    private func setConstraint() {
        deleteView.translatesAutoresizingMaskIntoConstraints = false
        deleteImageView.translatesAutoresizingMaskIntoConstraints = false
        deleteLabel.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        navigationImageView.translatesAutoresizingMaskIntoConstraints = false
        navigationLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            deleteView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            deleteView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            deleteView.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 48)/2),
            deleteView.heightAnchor.constraint(equalToConstant: 50),
            
            deleteImageView.centerXAnchor.constraint(equalTo: deleteView.centerXAnchor, constant: -20),
            deleteImageView.centerYAnchor.constraint(equalTo: deleteView.centerYAnchor),
            deleteImageView.heightAnchor.constraint(equalToConstant: 20),
            deleteImageView.widthAnchor.constraint(equalToConstant: 20),
            
            deleteLabel.leadingAnchor.constraint(equalTo: deleteImageView.trailingAnchor, constant: 5),
            deleteLabel.centerYAnchor.constraint(equalTo: deleteView.centerYAnchor),
            
            deleteButton.topAnchor.constraint(equalTo: deleteView.topAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: deleteView.leadingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: deleteView.trailingAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: deleteView.bottomAnchor),
            
            navigationView.centerYAnchor.constraint(equalTo: deleteView.centerYAnchor),
            navigationView.leadingAnchor.constraint(equalTo: deleteView.trailingAnchor, constant: 16),
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
}
