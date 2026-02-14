//
//  RouteItemView.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/1/30.
//

import UIKit
import SnapKit
import SWKit
import SWTheme

class RouteItemView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontMedium(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(title: String, value: String? = nil) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        
        titleLabel.text = title
        valueLabel.text = value
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(valueLabel)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.height.equalTo(swAdaptedValue(20))
            $0.top.equalToSuperview()
            $0.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        valueLabel.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(swAdaptedValue(20))
            $0.top.bottom.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right).offset(8)
            $0.right.equalToSuperview().inset(Layout.hMargin)
        }
    }
}
