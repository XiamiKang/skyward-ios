//
//  MessagePOIShowView.swift
//  ModuleMessage
//
//  Created by TXTS on 2026/3/30.
//

import UIKit
import SWKit

class MessagePOIShowView: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .gray
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ContainerView
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // TitleLabel
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            
            // SubtitleLabel
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
        ])
    }
    
    // MARK: - Public Method
    func configure(with data: AroundPOIData) {
        if let name = data.name, !name.isEmpty {
            titleLabel.text = name
        } else {
            titleLabel.text = formatCoordinate(longitude: data.longitude, latitude: data.latitude)
        }
        
        if let address = data.address, !address.isEmpty {
            subtitleLabel.text = address
        } else if titleLabel.text == formatCoordinate(longitude: data.longitude, latitude: data.latitude) {
            subtitleLabel.text = "未提供详细地址"
        } else {
            subtitleLabel.text = formatCoordinate(longitude: data.longitude, latitude: data.latitude)
        }
        
        // 如果没有副标题内容，调整副标题约束
        if subtitleLabel.text?.isEmpty ?? true {
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        }
    }
    
    // MARK: - Helper
    private func formatCoordinate(longitude: Double?, latitude: Double?) -> String {
        guard let lon = longitude, let lat = latitude else {
            return "未知位置"
        }
        let lonStr = String(format: "%.6fE", lon)
        let latStr = String(format: "%.6fN", lat)
        return "\(latStr), \(lonStr)"
    }
    
    // MARK: - Action
    @objc private func viewTapped() {
        print("POI view tapped")
    }
}
