//
//  ProDeciceSettingManageCell.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/10.
//

import UIKit

struct ProDeviceSettingManageData {
    let imageStr: String?
    let title: String?
}

class ProDeviceSettingManageCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    public  var tipLabe = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        tipLabe.translatesAutoresizingMaskIntoConstraints = false
        tipLabe.textColor = .white
        tipLabe.backgroundColor = UIColor(str: "#F7594B")
        tipLabe.layer.masksToBounds = true
        tipLabe.layer.cornerRadius = 8
        tipLabe.isHidden = true
        tipLabe.textAlignment = .center
        tipLabe.font = .systemFont(ofSize: 12, weight: .medium)
        contentView.addSubview(tipLabe)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 2),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            tipLabe.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            tipLabe.trailingAnchor.constraint(equalTo: trailingAnchor),
            tipLabe.heightAnchor.constraint(equalToConstant: 16),
            tipLabe.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
        ])
        
    }
    
    func confign(with data: ProDeviceSettingManageData) {
        imageView.image = PersonalModule.image(named: data.imageStr ?? "")
        titleLabel.text = data.title
    }
}
