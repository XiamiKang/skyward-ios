//
//  TeamSettingViewController.swift
//  skyward
//
//  Created by zhaobo on 2025/12/3.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SWNetwork

// MARK: - 团队设置视图控制器
class TeamSettingViewController: BaseViewController {
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("队伍设置")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    /// 顶部团队信息视图
    private lazy var teamInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    /// 团队头像
    private lazy var teamAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = swAdaptedValue(30)
        imageView.image = TeamModule.image(named: "team_group_avatar")
        return imageView
    }()
    
    /// 团队名称
    private lazy var teamNameLabel: UILabel = {
        let label = UILabel()
        label.text = team?.name ?? ""
        label.font = .pingFangFontMedium(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 1
        return label
    }()
    
    /// 团队群号
    private lazy var teamGroupIdLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 1
        return label
    }()
    
    /// 编辑按钮
    private lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(TeamModule.image(named: "team_edit"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        return button
    }()
    
    /// 成员标题
    private lazy var membersTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontMedium(ofSize: 14)
        label.textColor = ThemeManager.current.titleColor
        label.text = "队员"
        return label
    }()
    
    private lazy var moreMembersButton: UIButton = {
        let button = UIButton()
        button.setImage(TeamModule.image(named: "team_arrow_gray"), for: .normal)
        return button
    }()
    
    /// 成员集合视图
    private lazy var membersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let itemWidth = (ScreenUtil.screenWidth - 2 * Layout.hMargin - swAdaptedValue(40)) / 5 // 5个成员一行
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth + swAdaptedValue(44))
        layout.minimumLineSpacing = swAdaptedValue(12)
        layout.minimumInteritemSpacing = swAdaptedValue(8)
        layout.sectionInset = UIEdgeInsets(top: Layout.vMargin, left: Layout.hMargin, bottom: 0, right: Layout.hMargin)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TeamMemberCollectionCell.self, forCellWithReuseIdentifier: "TeamMemberCollectionCell")
        return collectionView
    }()
    
    /// 解散队伍按钮
    private lazy var disbandTeamButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.errorColor
        button.setTitle("解散队伍", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.addTarget(self, action: #selector(disbandTeamButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    var teamId: String?
    /// 团队数据
    private var team: Team? {
        didSet {
            guard let team = self.team else {
                return
            }
            DBManager.shared.insertToDb(objects: [team], intoTable: DBTableName.team.rawValue)
            
            DispatchQueue.main.async {[weak self] in
                
                if let teamName = team.name {
                    let memberCount = team.members?.count ?? 0
                    self?.teamNameLabel.text = teamName + "(\(memberCount))"
                }
                if let teamId = team.id {
                    self?.teamGroupIdLabel.text = "群号：" + teamId
                }
                if let teamAvatar = team.teamAvatar {
                    self?.teamAvatarImageView.sd_setImage(with: URL(string: teamAvatar), placeholderImage: TeamModule.image(named: "team_group_avatar"))
                }
                self?.membersCollectionView.reloadData()
            }
        }
    }
    
    // MARK: - Initialization
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 指定初始化器，通过conversation构造实例
    @MainActor public init(teamId: String) {
        self.teamId = teamId
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MQTTManager.shared.addDelegate(self)
        MQTTManager.shared.subscribe(to: TeamAPI.teamInfo_sub, qos: .qos1)
        getTeamInfo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            MQTTManager.shared.removeDelegate(self)
            MQTTManager.shared.unsubscribe(from: TeamAPI.teamInfo_sub)
        }
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        view.addSubview(navigationBar)
        
        // 添加子视图
        view.addSubview(teamInfoView)
        teamInfoView.addSubview(teamAvatarImageView)
        teamInfoView.addSubview(teamNameLabel)
        teamInfoView.addSubview(teamGroupIdLabel)
        teamInfoView.addSubview(editButton)
        
        view.addSubview(membersTitleLabel)
        view.addSubview(moreMembersButton)
        view.addSubview(membersCollectionView)
        view.addSubview(disbandTeamButton)
    }

    
    override public func setupConstraints() {
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        teamInfoView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(swAdaptedValue(80))
        }
        
        teamAvatarImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(swAdaptedValue(16))
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(swAdaptedValue(60))
        }
        
        teamNameLabel.snp.makeConstraints {
            $0.left.equalTo(teamAvatarImageView.snp.right).offset(swAdaptedValue(12))
            $0.top.equalTo(teamAvatarImageView).offset(swAdaptedValue(8))
            $0.right.lessThanOrEqualTo(editButton.snp.left).offset(-swAdaptedValue(16))
        }
        
        teamGroupIdLabel.snp.makeConstraints {
            $0.left.equalTo(teamNameLabel)
            $0.top.equalTo(teamNameLabel.snp.bottom).offset(swAdaptedValue(8))
            $0.right.lessThanOrEqualTo(editButton.snp.left).offset(-swAdaptedValue(16))
        }
        
        editButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-swAdaptedValue(16))
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(swAdaptedValue(24))
        }
        
        membersTitleLabel.snp.makeConstraints {
            $0.top.equalTo(teamInfoView.snp.bottom).offset(swAdaptedValue(16))
            $0.left.equalToSuperview().offset(swAdaptedValue(16))
        }
        
        moreMembersButton.snp.makeConstraints {
            $0.width.height.equalTo(swAdaptedValue(30))
            $0.centerY.equalTo(membersTitleLabel)
            $0.right.equalToSuperview().inset(swAdaptedValue(9))
        }
        
        membersCollectionView.snp.makeConstraints {
            $0.top.equalTo(membersTitleLabel.snp.bottom).offset(swAdaptedValue(16))
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(disbandTeamButton.snp.top).offset(-swAdaptedValue(24))
        }
        
        disbandTeamButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(swAdaptedValue(16))
            $0.height.equalTo(swAdaptedValue(48))
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-swAdaptedValue(16))
        }
    }
    
    // MARK: - Actions
    /// 编辑按钮点击
    @objc private func editButtonTapped() {
        guard let team = self.team else {
            return
        }
        navigationController?.pushViewController(TeamSettingEditViewController(team: team), animated: true)
    }
    
    /// 解散队伍按钮点击
    @objc private func disbandTeamButtonTapped() {
        SWAlertView.showDestructiveAlert(title: "确认解散", message: "解散后所有队员将失去与成员的联系，同时聊天记录也将被删除", destructiveHandler: {
            var params = [String : Any]()
            params["requestId"] = Int(Date().timeIntervalSince1970)
            params["id"] = self.teamId
            
            if let jsonStr = params.dataValue?.jsonString {
                MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.teamDisband_pub, qos:.qos1)
            }
        })
    }
    
    /// 执行解散队伍操作
    private func performDisbandTeam() {
        // 这里可以添加解散队伍的网络请求
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 解散成功后返回上一页
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    /// 邀请成员
    private func inviteMembers() {
        guard let teamId = self.teamId else {
            return
        }
        let vc = TeamInviteMemberViewController(teamId: teamId)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 移除成员
    private func removeMembers() {
        guard var members = team?.members else { return }
        let filterMembers = members.filter({$0.userId != UserManager.shared.userInfo?.id})
        guard let teamId = self.teamId, filterMembers.count > 0 else {
            if filterMembers.count == 0 {
                view.sw_showWarningToast("队伍目前只有一人")
            }
            return
        }
        
        let vc = TeamRemoveMemberViewController(teamId: teamId, members: filterMembers)
        vc.removeCompletion = { [weak self] membersToRemove in
            let ids = Set(membersToRemove.map(\.userId))
            members.removeAll { ids.contains($0.userId) }
            self?.team?.members = members
            self?.membersCollectionView.reloadData()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func getTeamInfo() {
        if let teamId = teamId, let team = DBManager.shared.queryFromDb(fromTable: DBTableName.team.rawValue, cls: Team.self)?.first(where: { $0.id == teamId }) {
            self.team = team
        }
        
        var params = [String : Any]()
        params["id"] = teamId
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.teamInfo_pub, qos:.qos1)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension TeamSettingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let members = team?.members else {
            return 0
        }
        if members.count == 0 {
            return 0
        }
        return members.count + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeamMemberCollectionCell", for: indexPath) as! TeamMemberCollectionCell
        
        guard let members = team?.members else {
            return cell
        }
        
        if indexPath.item < members.count {
            // 普通成员
            let member = members[indexPath.item]
            cell.configure(with: .member(member))
        } else if indexPath.item == members.count {
            // 邀请按钮
            cell.configure(with: .invite)
        } else {
            // 移除按钮
            cell.configure(with: .remove)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let members = team?.members else {
            return
        }
        
        if indexPath.item < members.count {
            // 点击了普通成员
        } else if indexPath.item == members.count {
            // 点击了邀请按钮
            inviteMembers()
        } else {
            // 点击了移除按钮
            removeMembers()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (ScreenUtil.screenWidth - 2 * Layout.hMargin - swAdaptedValue(40)) / 5 // 5个成员一行
        return CGSize(width: itemWidth, height: swAdaptedValue(70))
    }
}

// MARK: - MQTTManagerDelegate
extension TeamSettingViewController: MQTTManagerDelegate {
    
    public func mqttManager(_ manager: MQTTManager, didReceiveMessage message: String, fromTopic topic: String) {
        guard topic == TeamAPI.teamInfo_sub else {
            return
        }
        do {
            guard let jsonData = message.data(using: .utf8) else {
                print("[JSON解析] 消息转换为Data失败")
                return
            }
            
            let rsp = try JSONDecoder().decode(MQTTResponse<Team>.self, from: jsonData)
            guard let team = rsp.data else {
                return
            }
            
            DispatchQueue.main.async {[weak self] in
                if team.isDisband == true {
                    if let teamId = team.id, let conversations = DBManager.shared.queryFromDb(fromTable: DBTableName.conversation.rawValue, cls: Conversation.self)?.filter({$0.teamId != teamId}) {
                        DBManager.shared.deleteFromDb(fromTable: DBTableName.conversation.rawValue)
                        DBManager.shared.insertToDb(objects: conversations, intoTable: DBTableName.conversation.rawValue)
                    }
                    self?.navigationController?.popToRootViewController(animated: false)
                    SWRouter.handle(RouteTable.teamPageUrl)
                    return
                }
                self?.team = team
            }
        } catch {
            print("[JSON解析] 解析失败: \(error)")
        }
    }
}
