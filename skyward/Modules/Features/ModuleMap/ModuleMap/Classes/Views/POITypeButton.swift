//
//  POITypeButton.swift
//  yifan_test
//
//  Created by TXTS on 2025/12/2.
//

import UIKit

// MARK: - POI 类型按钮
class POITypeButton: UIButton {
    
    let type: POIType
    
    init(type: POIType) {
        self.type = type
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        
        let iconImageView = UIImageView()
        iconImageView.image = MapModule.image(named: type.iconName) ?? UIImage(systemName: "mappin.circle")
        iconImageView.tintColor = .secondaryLabel
        iconImageView.contentMode = .scaleAspectFit
        
        let titleLabel = UILabel()
        titleLabel.text = type.rawValue
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.isUserInteractionEnabled = false
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 50),
            iconImageView.heightAnchor.constraint(equalToConstant: 50),
            
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                for view in subviews {
                    if let stackView = view as? UIStackView {
                        for subview in stackView.arrangedSubviews {
                            if let imageView = subview as? UIImageView {
                                imageView.image = MapModule.image(named: type.selIconName) ?? UIImage(systemName: "mappin.circle")
                            } else if let label = subview as? UILabel {
                                label.textColor = UIColor(str: "#070808")
                                label.font = .systemFont(ofSize: 12, weight: .regular)
                            }
                        }
                    }
                }
            } else {
                for view in subviews {
                    if let stackView = view as? UIStackView {
                        for subview in stackView.arrangedSubviews {
                            if let imageView = subview as? UIImageView {
                                imageView.image = MapModule.image(named: type.iconName) ?? UIImage(systemName: "mappin.circle")
                            } else if let label = subview as? UILabel {
                                label.textColor = .secondaryLabel
                                label.font = .systemFont(ofSize: 12)
                            }
                        }
                    }
                }
            }
        }
    }
}
