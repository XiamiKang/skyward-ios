//
//  TeamRemoveMemberViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/3.
//

import TXKit
import SWKit
import SWTheme
import SWNetwork

class TeamRemoveMemberViewController: BaseViewController {
    
    // MARK: - Properties
    private var teamId: String
    /// 成员列表
    private var members: [Member] = []
    
    private var selectedMembers: [Member] = []
    
    public var removeCompletion: (([Member]) -> Void)?
    
    // MARK: - Initialization
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor public init(teamId: String, members: [Member]) {
        self.teamId = teamId
        self.members = members
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        view.addSubview(bottomButton)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalTo(bottomButton.snp.top).offset(-Layout.vInset)
            make.left.right.equalToSuperview()
        }
        
        bottomButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.hMargin)
            make.height.equalTo(swAdaptedValue(48))
            make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + swAdaptedValue(12))
        }
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
    }
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("移除")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(cellType: TeamMemberRemoveCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    private lazy var bottomButton: UIButton = {
        let bottomButton = UIButton(type: .system)
        bottomButton.setTitle("移除", for: .normal)
        bottomButton.backgroundColor = UIColor(str: "#FFE0B9")
        bottomButton.setTitleColor(.white, for: .normal)
        bottomButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        bottomButton.layer.cornerRadius = 8
        bottomButton.addTarget(self, action: #selector(removeMembers), for: .touchUpInside)
        
        return bottomButton
    }()
    
    // MARK: - Actions
    
    @objc func removeMembers() {
        guard selectedMembers.count > 0 else {
            // 可以添加一个提示，告诉用户请先选择要移除的成员
            return
        }
        
        var params = [String : Any]()
        params["requestId"] = Int(Date().timeIntervalSince1970)
        params["teamId"] = teamId
        params["memberIds"] = selectedMembers.compactMap { $0.userId }
        
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.removeMember_pub, qos:.qos1)
        }
        
        navigationController?.popViewController(animated: false)
    }
    
   
    //MARK: - private

}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension TeamRemoveMemberViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TeamMemberRemoveCell.self)
        var member = members[indexPath.row]
        cell.configure(with: member)
        cell.onCheckBoxHandler = { [weak self] in
            member.selected = !member.selected
            cell.checkBoxButton.isSelected = member.selected
            if member.selected {
                // 添加到已选择成员列表
                self?.selectedMembers.append(member)
            } else {
                // 从已选择成员列表移除
                if let index = self?.selectedMembers.firstIndex(where: { $0.userId == member.userId }) {
                    self?.selectedMembers.remove(at: index)
                }
            }
            if let selectMemebers = self?.selectedMembers, selectMemebers.count > 0 {
                self?.bottomButton.backgroundColor = ThemeManager.current.mainColor
            } else {
                self?.bottomButton.backgroundColor = UIColor(str: "#FFE0B9")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(72)
    }
}


