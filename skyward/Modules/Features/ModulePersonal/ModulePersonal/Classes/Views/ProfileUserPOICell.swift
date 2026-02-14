//
//  ProfileUserPOICell.swift
//  SWKit
//
//  Created by TXTS on 2026/2/4.
//

import UIKit
import SWKit

class ProfileUserPOICell: UITableViewCell {
    
    private var POIImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private var POINameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(str: "#070808")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private var POIAddressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(POIImageView)
        contentView.addSubview(POINameLabel)
        contentView.addSubview(POIAddressLabel)
        
        NSLayoutConstraint.activate([
            POIImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            POIImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            POIImageView.widthAnchor.constraint(equalToConstant: 36),
            POIImageView.heightAnchor.constraint(equalToConstant: 36),
            
            POINameLabel.topAnchor.constraint(equalTo: POIImageView.topAnchor),
            POINameLabel.leadingAnchor.constraint(equalTo: POIImageView.trailingAnchor, constant: 12),
            POINameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            POIAddressLabel.bottomAnchor.constraint(equalTo: POIImageView.bottomAnchor),
            POIAddressLabel.leadingAnchor.constraint(equalTo: POIImageView.trailingAnchor, constant: 12),
            POIAddressLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }
    
    func config(with poiData: UserPOILocalData) {
        if let category = poiData.category {
            POIImageView.image = PersonalModule.image(named: "poi_type_sel_\(category)")
        }else {
            POIImageView.image = PersonalModule.image(named: "poi_type_sel_1")
        }
        
        POINameLabel.text = poiData.name ?? ""
        POIAddressLabel.text = poiData.address ?? "--"
    }
    
}
