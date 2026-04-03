//
//  NoDataView.swift
//  SWKit
//
//  Created by TXTS on 2026/2/26.
//

import UIKit

public class NoDataView: UIView {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.image = SWKitModule.image(named: "blank_icon")
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无数据"
        label.textColor = UIColor(str: "#84888C")
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(imageView)
        addSubview(textLabel)
        
        NSLayoutConstraint.activate([
            
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            imageView.widthAnchor.constraint(equalToConstant: 96),
            imageView.heightAnchor.constraint(equalToConstant: 96),
            
            textLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            textLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
        ])
    }
}
