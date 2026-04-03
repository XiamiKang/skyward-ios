//
//  ProfileUserPOICell 2.swift
//  Pods
//
//  Created by TXTS on 2026/3/3.
//

import UIKit
import SWKit

class ProfileUserPublicPOICell: UITableViewCell {
    
    private let checkboxImageView: UIImageView = {
        let imageV = UIImageView()
        imageV.image = MapModule.image(named: "route_selected")
        imageV.isHidden = true
        return imageV
    }()
    
    private var POIImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private var POINameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(str: "#070808")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    private var POIAddressLabel: UILabel = {
        let label = UILabel()
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        checkboxImageView.isHidden = true
        checkboxImageView.image = MapModule.image(named: "route_unselected")
        POIImageView.image = nil
        POINameLabel.text = ""
        POIAddressLabel.text = ""
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(checkboxImageView)
        contentView.addSubview(POIImageView)
        contentView.addSubview(POINameLabel)
        contentView.addSubview(POIAddressLabel)
        
        checkboxImageView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        POIImageView.snp.makeConstraints { make in
            make.width.height.equalTo(36)
            make.left.equalTo(checkboxImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        
        POINameLabel.snp.makeConstraints { make in
            make.top.equalTo(POIImageView)
            make.left.equalTo(POIImageView.snp.right).offset(12)
            make.right.equalToSuperview().inset(16)
        }
        
        POIAddressLabel.snp.makeConstraints { make in
            make.bottom.equalTo(POIImageView)
            make.left.equalTo(POIImageView.snp.right).offset(12)
            make.right.equalToSuperview().inset(16)
        }
    }
    
    func config(with poiData: PublicPOIData, isManageState: Bool = false, isSelected: Bool = false) {
        // 设置图标
        if let category = poiData.category {
            POIImageView.image = MapModule.image(named: "poi_type_sel_\(category)")
        } else {
            POIImageView.image = MapModule.image(named: "poi_type_sel_1")
        }
        
        POINameLabel.text = poiData.name ?? ""
        POIAddressLabel.text = poiData.address ?? "--"
        
        // 管理状态配置
        checkboxImageView.isHidden = !isManageState
        checkboxImageView.image = MapModule.image(named: isSelected ? "route_selected" : "route_unselected")
        
        // 更新左边距
        POIImageView.snp.updateConstraints { make in
            make.left.equalTo(checkboxImageView.snp.right).offset(isManageState ? 12 : 0)
        }
    }
}
