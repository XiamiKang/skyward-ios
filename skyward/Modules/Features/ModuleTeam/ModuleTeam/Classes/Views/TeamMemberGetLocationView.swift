//
//  TeamMemberGetLocationView.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

// MARK: - 团队成员获取位置视图
typealias TeamMemberGetLocationViewCompletion = (Bool) -> Void
typealias TeamMemberGetLocationBlock = (_ userId: String, Int?) -> Void

class TeamMemberGetLocationView: UIView, SWPopupContentView {
    
    // MARK: - UI Components
    
    /// 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "获取位置"
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
    private lazy var membersTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = swAdaptedValue(84)
        tableView.register(cellType: TeamMemberLoactionCell.self)
        return tableView
    }()
    
    // MARK: - Properties
    
    /// 团队成员数据
    private var members: [Member] = []
    
    /// 关闭回调
    var closeHandler: TeamMemberGetLocationViewCompletion?
    /// 获取位置回调
    var getUserLocationHandler: TeamMemberGetLocationBlock?
    
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
        addSubview(membersTableView)
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
    
        membersTableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(swAdaptedValue(49))
            $0.left.right.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    func configure(with members: [Member]) {
        self.members = members
        membersTableView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        closeHandler?(true)
    }
    
    // MARK: - SWPopupContentView Protocol
    func popupWillShow() {
        // 弹窗即将显示时调用
    }
    
    func popupDidShow() {
        // 弹窗已经显示时调用
    }
    
    func popupWillDismiss() {
        // 弹窗即将消失时调用
    }
    
    func popupDidDismiss() {
        // 弹窗已经消失时调用
    }
}

// MARK: - UITableView Delegate & DataSource
extension TeamMemberGetLocationView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TeamMemberLoactionCell.self)
        let member = members[indexPath.row]
        cell.configure(with: member)
        cell.getLocationHandler = {[weak self] in
            // 处理获取位置事件
            // 这里可以添加获取位置的具体实现
            if let userId = member.userId {
                self?.getUserLocationHandler?(userId, member.shortId)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(72)
    }
}

// MARK: - BaseCell Extension
// 确保TeamMemberCell有reuseIdentifier
private extension TeamMemberCell {
    static var reuseIdentifier: String {
        return "TeamMemberCell"
    }
}
