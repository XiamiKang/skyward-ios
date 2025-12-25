//
//  TeamMemberLoactionDetailView.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/12.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme


class TeamMemberLocationDetailView: UIView, SWPopupContentView {
    
    // MARK: - UI Components
    
    /// 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .pingFangFontBold(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .center
        return label
    }()
    
    /// 关闭按钮
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(TeamModule.image(named: "team_close_gray"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    /// 成员列表
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(cellType: TeamLocationDetailCell.self)
        return tableView
    }()
    
    // MARK: - Properties
    private var coordinateDesc: String = "--"
    private var timeDesc: String = "--"
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(tableView)
    }
    
    private func setupConstraints() {

        titleLabel.snp.makeConstraints {
            $0.height.equalTo(swAdaptedValue(25))
            $0.top.left.equalToSuperview().inset(Layout.hMargin)
        }
        
        closeButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(swAdaptedValue(16))
            $0.centerY.equalTo(titleLabel)
            $0.width.height.equalTo(swAdaptedValue(30))
        }
    
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(swAdaptedValue(49))
            $0.left.right.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    func configure(titleDesc: String, coordinateDesc: String, timeDesc: String ) {
        self.titleLabel.text = titleDesc
        self.coordinateDesc = coordinateDesc
        self.timeDesc = timeDesc
        tableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        SWPopupView.currentPopup?.dismiss()
    }
}

// MARK: - UITableView Delegate & DataSource
extension TeamMemberLocationDetailView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TeamLocationDetailCell.self)
        if indexPath.row == 0 {
            cell.configure(title: "经纬度", content: coordinateDesc)
        } else {
            cell.configure(title: "更新时间", content: timeDesc)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(56)
    }
}


class TeamLocationDetailCell: BaseCell {
    // MARK: - UI Components
    /// 左侧标题标签
    private lazy var leftTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontMedium(ofSize: 16)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    
    /// 右侧内容标签
    private lazy var rightContentLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white
        
        contentView.addSubview(leftTitleLabel)
        contentView.addSubview(rightContentLabel)

    }
    
    private func setupConstraints() {
        leftTitleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(Layout.hMargin)
            $0.centerY.equalToSuperview()
        }
        
        rightContentLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(swAdaptedValue(36))
        }
    }
    
    // MARK: - Configuration
    /// 配置单元格
    func configure(title: String? , content: String?) {
        leftTitleLabel.text = title
        rightContentLabel.text = content
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        leftTitleLabel.text = nil
        rightContentLabel.text = nil
    }
}
