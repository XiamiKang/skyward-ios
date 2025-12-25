//
//  TrackRecordCell.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/17.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SnapKit

class TrackRecordCell: BaseCell {
    
    var onClickUploadHandler: (() -> (Void))?
    var onClickLookHandler: (() -> (Void))?
    var onClickDeleteHandler: (() -> (Void))?
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.pingFangFontRegular(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        return label
    }()
    
    private let uploadLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = ThemeManager.current.mainColor
        label.font = UIFont.pingFangFontBold(ofSize: 12)
        label.textColor = .white
        label.text = "未上传"
        label.textAlignment = .center
        label.layer.cornerRadius = CornerRadius.small.rawValue
        label.layer.masksToBounds = true
        return label
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton()
        button.setImage(MapModule.image(named: "record_upload_icon"), for: .normal)
        return button
    }()
    
    private let lookButton: UIButton = {
        let button = UIButton()
        button.setImage(MapModule.image(named: "record_unlook_icon"), for: .normal)
        button.setImage(MapModule.image(named: "record_look_icon"), for: .selected)
        return button
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(MapModule.image(named: "record_delete_icon"), for: .normal)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        
        uploadButton.addTarget(self, action: #selector(clickUpload), for: .touchUpInside)
        lookButton.addTarget(self, action: #selector(clickLook), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(clickDelete), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(nameLabel)
        contentView.addSubview(uploadLabel)
        contentView.addSubview(uploadButton)
        contentView.addSubview(lookButton)
        contentView.addSubview(deleteButton)
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
        
        uploadLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(Layout.hSpacing)
            make.centerY.equalToSuperview()
        }
        
        uploadButton.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(20))
            make.right.equalTo(lookButton.snp.left).offset(-Layout.hSpacing)
            make.centerY.equalToSuperview()
        }
        
        lookButton.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(20))
            make.right.equalTo(deleteButton.snp.left).offset(-Layout.hSpacing)
            make.centerY.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(20))
            make.right.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with record: TrackRecord) {
        nameLabel.text = record.name
        uploadLabel.isHidden = record.uploadStatus == .uploaded
        uploadButton.isHidden = record.uploadStatus == .uploaded
        lookButton.isSelected = record.isLook
        
    }
    
    @objc private func clickUpload() {
        onClickUploadHandler?()
    }
    
    @objc private func clickLook() {
        onClickLookHandler?()
    }
    @objc private func clickDelete() {
        onClickDeleteHandler?()
    }
}

