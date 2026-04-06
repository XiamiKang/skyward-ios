//
//  POIManageBottomView.swift
//  Pods
//
//  Created by TXTS on 2026/2/26.
//

import UIKit
import SWKit
import SWTheme

// 底部管理视图
class ProfileManageBottomView: UIView {
    
    var selectAllHandler: ((Bool) -> Void)?
    var deleteHandler: (() -> Void)?
    
    private lazy var selectAllButton: UIButton = {
        let button = UIButton()
        button.setTitle("全选", for: .normal)
        button.setTitle("取消全选", for: .selected)
        button.setImage(MapModule.image(named: "route_unselected"), for: .normal)
        button.setImage(MapModule.image(named: "route_selected"), for: .selected)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .selected)
        button.titleLabel?.font = .pingFangFontRegular(ofSize: 14)
        button.contentHorizontalAlignment = .left
        var configuration = UIButton.Configuration.plain()
        configuration.imagePadding = 5
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        button.configuration = configuration
        button.addTarget(self, action: #selector(selectAllClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setTitle("删除", for: .normal)
        button.setTitleColor(ThemeManager.current.mainColor, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 14)
        button.backgroundColor = UIColor(str: "#F2F3F4")
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(deleteClick), for: .touchUpInside)
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
        addSubview(selectAllButton)
        addSubview(deleteButton)
        
        selectAllButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(36)
        }
        
        // 添加上分割线
        let line = UIView()
        line.backgroundColor = UIColor(str: "#F0F0F0")
        addSubview(line)
        line.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    func setSelectAll(_ isAll: Bool) {
        selectAllButton.isSelected = isAll
    }
    
    @objc private func selectAllClick() {
        selectAllButton.isSelected.toggle()
        selectAllHandler?(selectAllButton.isSelected)
    }
    
    @objc private func deleteClick() {
        deleteHandler?()
    }
}
