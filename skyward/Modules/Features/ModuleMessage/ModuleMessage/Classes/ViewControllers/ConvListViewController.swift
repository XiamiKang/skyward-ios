//
//  ConvListViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme
import SnapKit

class ConvListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var conversationArray: [Conversation] = []
    
    // MARK: - Override
    override public var hasNavBar: Bool {
        return false
    }
    
    public override func viewDidLoad() {
        // 移除未使用的conv1变量，因为在后续代码中已正确初始化conversationArray
        conversationArray = [
            Conversation(id: "125", type: .service, title: "服务中心", avatarUrl: "avatar_service", lastMessage: Message(id: "12367", content: "")),
            Conversation(id: "124", type: .group, title: "天行探索开发群",avatarUrl: "avatar_safety", lastMessage: Message(id: "123", content: "接口文档在哪里")),
            Conversation(id: "123", type: .single, title: "张小四",avatarUrl: "avatar_sos", lastMessage: Message(id: "1234", content: "今晚去吃烧烤")),
            Conversation(id: "122", type: .single, title: "夏树", lastMessage: Message(id: "12345", content: "要去爬山"))
        ]
        
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.current.backgroundColor
        
        // 调用setupActions设置代理
        setupActions()
    }
    
    override public func setupViews() {
        super.setupViews()
        
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: ScreenUtil.screenWidth, height: swAdaptedValue(217)))
        tableHeaderView.addSubview(sosTopCardView)
        tableHeaderView.addSubview(safetyTopCardView)
        tableHeaderView.addSubview(searchBarContainer)
        
        let imgV = UIImageView(image: MessageModule.image(named: "message_search_icon"))
        searchBarContainer.addSubview(imgV)
        imgV.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(20))
            make.left.equalToSuperview().inset(Layout.hInset)
            make.centerY.equalToSuperview()
        }
        searchBarContainer.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(40))
            make.left.equalTo(imgV.snp.right).offset(4)
            make.top.right.equalToSuperview()
        }
        
        tableView.tableHeaderView = tableHeaderView
        view.addSubview(tableView)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        sosTopCardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.hMargin)
            make.trailing.equalToSuperview().dividedBy(2).offset(-6)
            make.top.equalToSuperview().inset(Layout.vMargin)
            make.height.equalTo(swAdaptedValue(129))
        }
        
        safetyTopCardView.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.centerX).offset(6)
            make.trailing.equalToSuperview().inset(Layout.hMargin)
            make.top.height.equalTo(sosTopCardView)
        }
        
        searchBarContainer.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(40))
            make.leading.trailing.equalToSuperview().inset(Layout.hMargin)
            make.top.equalTo(sosTopCardView.snp.bottom).offset(swAdaptedValue(24))
        }
    }
    
    private func setupActions() {
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchField.delegate = self
        
        sosTopCardView.onActionCallback = {
            ReportManager.report(.sos)
        }
        
        safetyTopCardView.onActionCallback = {
            ReportManager.report(.safety)
        }
    }
    
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "ConversationCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    private let sosTopCardView: TopCardView = {
        let label = TopCardView(frame: .zero, type: .sos)
        return label
    }()
    
    private let safetyTopCardView: TopCardView = {
        let label = TopCardView(frame: .zero, type: .safety)
        return label
    }()
    
    private let searchBarContainer: UIView = {
        let searchBarContainer = UIView()
        searchBarContainer.backgroundColor = ThemeManager.current.mediumGrayBGColor
        searchBarContainer.layer.cornerRadius = CornerRadius.medium.rawValue
        return searchBarContainer
    }()
    
    private let searchField: UITextField = {
        let searchField = UITextField()
        searchField.borderStyle = .none
        searchField.placeholder = "搜索联系人/聊天记录"
        searchField.textColor = ThemeManager.current.textColor
        searchField.font = UIFont.systemFont(ofSize: 14)
        searchField.isUserInteractionEnabled = true
        searchField.isEnabled = true
        return searchField
    }()
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    // MARK: - UITableView DataSource & Delegate Methods
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversationArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell", for: indexPath) as! ConversationCell
        let conv = conversationArray[indexPath.row]
        cell.configure(with: conv)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(72)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conv = conversationArray[indexPath.row]
        let vc = ConvViewController()
        vc.title = conv.title
        navigationController?.pushViewController(vc, animated: true)
    }
}
