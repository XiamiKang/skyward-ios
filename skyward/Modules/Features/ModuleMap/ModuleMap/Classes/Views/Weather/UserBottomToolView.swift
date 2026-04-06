//
//  UserBottomToolView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/17.
//

import UIKit
import SWTheme
import SWKit

class UserBottomToolView: UIView {
    
    private let deleteButton = UIButton()
    private let editButton = UIButton()
    private let showButton = UIButton()
    
    private let navigationView = UIView()
    private var navigationImageView = UIImageView()
    private let navigationLabel = UILabel()
    private let navigationButton = UIButton()
    
    // 按钮点击回调
    var onDeleteTapped: (() -> Void)?
    var onEditTapped: (() -> Void)?
    var onShowTapped: ((Bool) -> Void)?
    var onNavigationTapped: (() -> Void)?
    
    // 状态
    var isPOIHide: Bool = false
    
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
        
        var config = UIButton.Configuration.plain()
        config.image = MapModule.image(named: "map_user_delete")
        config.title = "删除"
        config.imagePlacement = .top
        config.imagePadding = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            outgoing.foregroundColor = UIColor.black
            return outgoing
        }
        deleteButton.configuration = config
        
        var eidtConfig = UIButton.Configuration.plain()
        eidtConfig.image = MapModule.image(named: "map_user_edit")
        eidtConfig.title = "编辑"
        eidtConfig.imagePlacement = .top
        eidtConfig.imagePadding = 8
        eidtConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            outgoing.foregroundColor = UIColor.black
            return outgoing
        }
        editButton.configuration = eidtConfig
        
        var showConfig = UIButton.Configuration.plain()
        showConfig.image = MapModule.image(named: "map_user_hide")
        showConfig.title = "隐藏"
        showConfig.imagePlacement = .top
        showConfig.imagePadding = 8
        showConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            outgoing.foregroundColor = UIColor.black
            return outgoing
        }
        showButton.configuration = showConfig
        
        navigationView.backgroundColor = UIColor(str: "#FE6A00")
        navigationView.layer.cornerRadius = 8
        navigationImageView.image = MapModule.image(named: "map_navigation_iocn")
        navigationLabel.text = "导航"
        navigationLabel.textColor = .white
        navigationLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        navigationButton.backgroundColor = .clear
        
        addSubview(deleteButton)
        addSubview(editButton)
        addSubview(showButton)
        addSubview(navigationView)
        
        navigationView.addSubview(navigationImageView)
        navigationView.addSubview(navigationLabel)
        navigationView.addSubview(navigationButton)
        
        setConstraint()
    }
    
    private func setupActions() {
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        showButton.addTarget(self, action: #selector(showButtonTapped), for: .touchUpInside)
        navigationButton.addTarget(self, action: #selector(navigationButtonTapped), for: .touchUpInside)
    }
    
    @objc private func deleteButtonTapped() {
        onDeleteTapped?()
    }
    
    @objc private func editButtonTapped() {
        onEditTapped?()
    }
    
    @objc private func showButtonTapped() {
        if isPOIHide {
            var showConfig = UIButton.Configuration.plain()
            showConfig.image = MapModule.image(named: "map_user_show")
            showConfig.title = "显示"
            showConfig.imagePlacement = .top
            showConfig.imagePadding = 8
            showConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                outgoing.foregroundColor = UIColor.black
                return outgoing
            }
            showButton.configuration = showConfig
        }else {
            var showConfig = UIButton.Configuration.plain()
            showConfig.image = MapModule.image(named: "map_user_hide")
            showConfig.title = "隐藏"
            showConfig.imagePlacement = .top
            showConfig.imagePadding = 8
            showConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                outgoing.foregroundColor = UIColor.black
                return outgoing
            }
            showButton.configuration = showConfig
        }
        onShowTapped?(isPOIHide)
        isPOIHide = !isPOIHide
    }
    
    @objc private func navigationButtonTapped() {
        onNavigationTapped?()
    }
    
    private func setConstraint() {
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        showButton.translatesAutoresizingMaskIntoConstraints = false
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        navigationImageView.translatesAutoresizingMaskIntoConstraints = false
        navigationLabel.translatesAutoresizingMaskIntoConstraints = false
        navigationButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            deleteButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            deleteButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            deleteButton.widthAnchor.constraint(equalToConstant: 50),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            
            editButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            editButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 5),
            editButton.widthAnchor.constraint(equalToConstant: 50),
            editButton.heightAnchor.constraint(equalToConstant: 50),
            
            showButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            showButton.leadingAnchor.constraint(equalTo: editButton.trailingAnchor, constant: 5),
            showButton.widthAnchor.constraint(equalToConstant: 50),
            showButton.heightAnchor.constraint(equalToConstant: 50),
            
            navigationView.centerYAnchor.constraint(equalTo: showButton.centerYAnchor),
            navigationView.leadingAnchor.constraint(equalTo: showButton.trailingAnchor, constant: 16),
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
    
    func changeShowState(_ isShow: Bool) {
        var showConfig = UIButton.Configuration.plain()
        showConfig.image = MapModule.image(named: isShow ? "map_user_show" : "map_user_hide")
        showConfig.title = isShow ? "显示" : "隐藏"
        showConfig.imagePlacement = .top
        showConfig.imagePadding = 8
        showConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            outgoing.foregroundColor = UIColor.black
            return outgoing
        }
        showButton.configuration = showConfig
    }
}
