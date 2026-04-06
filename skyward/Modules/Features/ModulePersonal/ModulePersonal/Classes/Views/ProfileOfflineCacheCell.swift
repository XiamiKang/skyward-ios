//
//  ProfileOfflineCacheCell.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/2/26.
//

import UIKit
import SWKit
import SnapKit

class ProfileOfflineCacheCell: UITableViewCell {
    
    private var cacheNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(str: "#070808")
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private var cacheSizeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    private var cacheTimeLabel: UILabel = {
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
        cacheNameLabel.text = ""
        cacheSizeLabel.text = ""
        cacheTimeLabel.text = ""
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(cacheNameLabel)
        contentView.addSubview(cacheSizeLabel)
        contentView.addSubview(cacheTimeLabel)
        
        cacheNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        cacheSizeLabel.snp.makeConstraints { make in
            make.top.equalTo(cacheNameLabel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        cacheTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(cacheSizeLabel.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview()
        }
    }
    
    func configureSimple(version: String?,
                         fileSize: String?,
                         downloadTime: Date?) {
        
        if let version = version, !version.isEmpty {
            cacheNameLabel.text = "公共兴趣点 V\(version)"
        } else {
            cacheNameLabel.text = "公共兴趣点"
        }
        
        if let fileSize = fileSize, !fileSize.isEmpty {
            cacheSizeLabel.text = "大小：\(fileSize)"
        } else {
            cacheSizeLabel.text = "大小：未下载"
        }
        
        if let downloadTime = downloadTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            cacheTimeLabel.text = "时间：\(formatter.string(from: downloadTime))"
        } else {
            cacheTimeLabel.text = "时间：下载中"
        }
    }
}

