//
//  RouteManageBottomView.swift
//  SWKit
//
//  Created by zhaobo on 2026/2/13.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

class RouteManageBottomView: UIView {

    // MARK: - Properties

    var selectAllHandler: ((Bool) -> Void)?
    var deleteHandler: (() -> Void)?
    var uploadHandler: (() -> Void)?

    // MARK: - UI Components

    private lazy var selectAllButton: UIButton = {
        let button = UIButton()
        button.setImage(MapModule.image(named: "route_unselected"), for: .normal)
        button.setImage(MapModule.image(named: "route_selected"), for: .selected)
        button.setTitle("全选", for: .normal)
        button.setTitleColor(ThemeManager.current.textColor, for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .selected)
        button.titleLabel?.font = .pingFangFontRegular(ofSize: 12)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        button.contentHorizontalAlignment = .left
        return button
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.mediumGrayBGColor
        button.setTitle("删除", for: .normal)
        button.setTitleColor(ThemeManager.current.errorColor, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 14)
        button.cornerRadius = CornerRadius.small.rawValue
        return button
    }()

    private lazy var uploadButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.mainColor
        button.setTitle("上传", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 14)
        button.cornerRadius = CornerRadius.small.rawValue
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = ThemeManager.current.backgroundColor

        addSubview(selectAllButton)
        addSubview(deleteButton)
        addSubview(uploadButton)
        uploadButton.isHidden = true
    }

    private func setupConstraints() {
        selectAllButton.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(76))
            make.height.equalTo(swAdaptedValue(32))
            make.left.equalToSuperview().offset(Layout.hMargin)
            make.top.equalToSuperview().inset(swAdaptedValue(8))
        }

        deleteButton.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(76))
            make.height.equalTo(swAdaptedValue(32))
            make.centerY.equalTo(selectAllButton)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
        
        uploadButton.snp.makeConstraints { make in
            make.width.equalTo(swAdaptedValue(76))
            make.height.equalTo(swAdaptedValue(32))
            make.centerY.equalTo(selectAllButton)
            make.right.equalToSuperview().inset(Layout.hMargin)
        }
    }

    private func setupActions() {
        selectAllButton.addAction(UIAction { [weak self] _ in
            self?.selectAllButton.isSelected.toggle()
            self?.selectAllHandler?(self?.selectAllButton.isSelected ?? false)
        }, for: .touchUpInside)

        deleteButton.addAction(UIAction { [weak self] _ in
            self?.deleteHandler?()
        }, for: .touchUpInside)

        uploadButton.addAction(UIAction { [weak self] _ in
            self?.uploadHandler?()
        }, for: .touchUpInside)
    }

    // MARK: - Public Methods

    func showUploadButton(_ show: Bool) {
        uploadButton.isHidden = !show

        if show {
            deleteButton.snp.updateConstraints { make in
                make.right.equalToSuperview().inset(swAdaptedValue(12) + swAdaptedValue(76) + Layout.hMargin)
            }
        } else {
            deleteButton.snp.updateConstraints { make in
                make.right.equalToSuperview().inset(Layout.hMargin)
            }
        }
    }

    func setSelectAll(_ selected: Bool) {
        selectAllButton.isSelected = selected
    }
}
