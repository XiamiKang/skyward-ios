//
//  RouteListCell.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/9.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SnapKit

class RouteListCell: BaseCell {
    private var paragraphStyle: NSMutableParagraphStyle!
    
    var onClickUploadHandler: (() -> (Void))?
    
    private let checkboxImageView: UIImageView = {
        let imageV = UIImageView()
        imageV.image = MapModule.image(named: "route_unselected")
        return imageV
    }()
    
    private let coverImageView: UIImageView = {
        let imageV = UIImageView()
        imageV.backgroundColor = ThemeManager.current.mediumGrayBGColor
        imageV.contentMode = .scaleAspectFill
        imageV.cornerRadius = CornerRadius.large.rawValue
        return imageV
    }()
    
    private let uploadLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = ThemeManager.current.mainColor
        label.font = UIFont.pingFangFontMedium(ofSize: 10)
        label.textColor = .white
        label.text = "未上传"
        label.textAlignment = .center
        label.cornerRadius = CornerRadius.small.rawValue
        label.layer.maskedCorners = [.layerMinXMaxYCorner]
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.pingFangFontMedium(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 2
        return label
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        return label
    }()
    
    private let uploadButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: swAdaptedValue(24), height: swAdaptedValue(39)))
        button.titleLabel?.font = .pingFangFontRegular(ofSize: 12)
        button.setImage(MapModule.image(named: "record_upload_icon"), for: .normal)
        button.setTitle("上传", for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .highlighted)
        button.imageUpTitleDown(spacing: 2)
        return button
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.minimumLineHeight = swAdaptedValue(20)
        paragraphStyle.maximumLineHeight = swAdaptedValue(20)
        paragraphStyle.alignment = .left
        
        setupUI()
        
        uploadButton.addTarget(self, action: #selector(clickUpload), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        // 重置可见性
        checkboxImageView.isHidden = true
        uploadLabel.isHidden = true
        uploadButton.isHidden = true

        // 重置内容
        coverImageView.sd_cancelCurrentImageLoad()  // 取消图片加载
        coverImageView.image = nil
        nameLabel.text = ""
        descLabel.text = ""
        timeLabel.text = ""

        // 清除回调
        onClickUploadHandler = nil

        // 恢复约束到初始状态
        coverImageView.snp.updateConstraints { make in
            make.left.equalToSuperview().inset(Layout.hMargin)
        }
        nameLabel.snp.updateConstraints { make in
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
    }
    
    private func setupUI() {
        contentView.addSubview(checkboxImageView)
        contentView.addSubview(coverImageView)
        coverImageView.addSubview(uploadLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(uploadButton)
        
        checkboxImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(24))
            make.left.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
        
        coverImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(82))
            make.top.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        uploadLabel.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(36))
            make.height.equalTo(swAdaptedValue(14))
            make.top.right.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(coverImageView)
            make.left.equalTo(coverImageView.snp.right).offset(Layout.hInset)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        descLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(17))
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(swAdaptedValue(4))
        }
        
        timeLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(17))
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(descLabel.snp.bottom).offset(swAdaptedValue(4))
        }
        
        uploadButton.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(24))
            make.height.equalTo(swAdaptedValue(39))
            make.right.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with route: Route, isManageState: Bool) {
        checkboxImageView.isHidden = !isManageState
        if let selected = route.selected, selected == true {
            checkboxImageView.image = MapModule.image(named: "route_selected")
        } else {
            checkboxImageView.image = MapModule.image(named: "route_unselected")
        }
        
        uploadLabel.isHidden = route.uploaded == true
        uploadButton.isHidden = route.uploaded == true
        
        if let coverUrl = route.coverImageUrl, let URL = URL(string: coverUrl) {
            coverImageView.sd_setImage(with: URL)
        }
        
        nameLabel.attributedText = NSAttributedString(string: route.routeName ?? "--",
                                                      attributes: [.paragraphStyle: paragraphStyle!])
        if let distance = route.distance {
            if let duration = route.travelTime, duration > 0 {
                descLabel.text = "距离：\(String(format: "%.2f", distance))km  时长：\(duration.formatHMSDuration())"
            } else {
                descLabel.text = "距离：\(String(format: "%.2f", distance))km"
            }
        }
        
        if let createTime = route.createTime {
            timeLabel.text = "保存时间：\(createTime)"
        }
        
        // layout
        if checkboxImageView.isHidden {
            coverImageView.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(Layout.hMargin)
            }
        } else {
            coverImageView.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(Layout.hMargin + swAdaptedValue(24) + 12)
            }
        }
        
        if uploadButton.isHidden {
            nameLabel.snp.updateConstraints { make in
                make.right.equalToSuperview().inset(Layout.hMargin)
            }
        } else {
            nameLabel.snp.updateConstraints { make in
                make.right.equalToSuperview().inset(Layout.hMargin + swAdaptedValue(24) + 4)
            }
        }
        
    }
    
    @objc private func clickUpload() {
        onClickUploadHandler?()
    }
}


