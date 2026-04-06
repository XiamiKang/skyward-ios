//
//  MapRealSearchView.swift
//  ModuleMap
//
//  Created by TXTS on 2026/2/24.
//

import UIKit
import SWTheme

class MapRealSearchView: UIView {
    
    var backAction: (() -> Void)?
    var searchAction: ((String) -> Void)?
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(MapModule.image(named: "navigation_back"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backClick), for: .touchUpInside)
        return button
    }()
    
    public lazy var searchTextField: UITextField = {
        // 搜索文本框
        let textField = UITextField()
        textField.placeholder = "地点/经纬度(例116.391349, 39.907375)"
        textField.borderStyle = .none
        textField.returnKeyType = .search
        textField.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textField.textColor = .black
        textField.tintColor = ThemeManager.current.mainColor
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var searchButton: UIButton = {
        let button = UIButton()
        button.setTitle("搜索", for: .normal)
        button.setTitleColor(ThemeManager.current.mainColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(searchClick), for: .touchUpInside)
        return button
    }()
    
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
        
        addSubview(backButton)
        addSubview(searchTextField)
        addSubview(searchButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 20),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            searchButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 40),
            searchButton.heightAnchor.constraint(equalToConstant: 20),
            
            searchTextField.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 5),
            searchTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -10),
            searchTextField.topAnchor.constraint(equalTo: topAnchor),
            searchTextField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    @objc private func backClick() {
        endEditing(false)
        backAction?()
    }
    
    @objc private func searchClick() {
        endEditing(false)
        if let searchText = searchTextField.text, !searchText.isEmpty {
            searchAction?(searchText)
        }
    }
}

extension MapRealSearchView: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if let searchText = textField.text, !searchText.isEmpty {
            searchAction?(searchText)
        }
        
        return true
    }
}
