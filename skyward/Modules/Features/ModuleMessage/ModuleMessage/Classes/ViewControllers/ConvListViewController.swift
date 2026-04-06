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
import SWNetwork

public class ConvListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    let viewModel = ConvListViewModel()
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(cellType: ConversationCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private let navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.setTitle("消息")
        return bar
    }()
    
    // MARK: - Override
    
    override public var hasNavBar: Bool {
        return false
    }
    
    public override func viewWillAppearForOtherTimes(_ animated: Bool) {
        super.viewWillAppearForOtherTimes(animated)
        viewModel.popFromCurrentConversation()
    }
    
    public override func setupViews() {
        super.setupViews()
        view.addSubview(navigationBar)
        view.addSubview(tableView)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
        //会话列表
        bindPublisher(viewModel.$convList.eraseToAnyPublisher()) { [weak self] convList in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - UITableView DataSource & Delegate Methods
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.convList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: ConversationCell.self)
        let conv = viewModel.convList[indexPath.row]
        cell.configure(with: conv)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(80)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let conv = viewModel.didSelectRowAt(row: indexPath.row) else {
            return
        }
        
        let vc = ConvViewController(conversation: conv)
        vc.onCurrentConversationLatestMessageDidChangedHandler = { [weak self] in
            self?.viewModel.currentConversationLatestMessageDidChanged()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
