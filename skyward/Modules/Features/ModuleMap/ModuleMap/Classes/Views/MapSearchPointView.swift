//
//  MapSearchPointView.swift
//  ModuleMap
//
//  Created by yifan kang on 2026/3/9.
//

import UIKit
import SWTheme
import CoreLocation

class MapSearchPointView: UIView {
    
    var navigationAction: (()->Void)?
    private let pointLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private lazy var navigationButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ThemeManager.current.mainColor
        button.setTitle("导航", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(navigationClick), for: .touchUpInside)
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
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        addSubview(pointLabel)
        addSubview(navigationButton)
        
        NSLayoutConstraint.activate([
            pointLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            pointLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            pointLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            navigationButton.topAnchor.constraint(equalTo: pointLabel.bottomAnchor, constant: 32),
            navigationButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            navigationButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            navigationButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    func config(with coordinateStr: String) {
        pointLabel.text = coordinateStr
    }
    
    @objc private func navigationClick() {
        navigationAction?()
    }
    
    func resetUI() {
        pointLabel.text = ""
    }
}
