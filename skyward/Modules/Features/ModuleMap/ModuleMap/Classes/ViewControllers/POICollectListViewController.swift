//
//  POIListViewController 2.swift
//  Pods
//
//  Created by TXTS on 2026/2/28.
//


import UIKit
import TXKit
import SWKit
import SWTheme

class POICollectListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var POIChooseType: PublicPOIChooseType
    
    let customNavView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    public var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(MapModule.image(named: "default_back"), for: .normal)
        return button
    }()
    
    let customTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private var isManageState: Bool = false {
        didSet {
            manageButton.isSelected = isManageState
            manageButton.setTitle(isManageState ? "取消" : "管理", for: .normal)
            manageBottomView.isHidden = !isManageState
            tableView.reloadData()
            
            if !isManageState {
                setSelectAll(false)
            }
            
            // 调整tableView底部约束
            tableView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(isManageState ? 80 : 0)
            }
        }
    }
    
    private lazy var manageButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("管理", for: .normal)
        button.setTitleColor(UIColor(str: "#070808"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.addTarget(self, action: #selector(manageClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 66
        tableview.register(ProfileUserPublicPOICell.self, forCellReuseIdentifier: "ProfileUserPublicPOICell")
        return tableview
    }()
    
    private lazy var manageBottomView: ProfileManageBottomView = {
        let view = ProfileManageBottomView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.selectAllHandler = { [weak self] isAll in
            self?.setSelectAll(isAll)
        }
        view.deleteHandler = { [weak self] in
            self?.deleteSelectedItems()
        }
        return view
    }()
    
    private let nodataView = NoDataView()
    
    var dataSource: [PublicPOIData] = []
    var selectedIndexPaths: Set<IndexPath> = []
    
    init(type: PublicPOIChooseType) {
        POIChooseType = type
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraint()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        setNavigationView()
        customTitle.text = POIChooseType == .checkout ? "打卡(0)" : "收藏(0)"
        
        customNavView.addSubview(manageButton)
        view.addSubview(tableView)
        view.addSubview(manageBottomView)
        
        nodataView.isHidden = true
        nodataView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nodataView)
    }
    
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            manageButton.centerYAnchor.constraint(equalTo: customTitle.centerYAnchor),
            manageButton.trailingAnchor.constraint(equalTo: customNavView.trailingAnchor, constant: -16),
            manageButton.heightAnchor.constraint(equalToConstant: 40),
            
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            manageBottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            manageBottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            manageBottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            manageBottomView.heightAnchor.constraint(equalToConstant: 80),
            
            nodataView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 20),
            nodataView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nodataView.widthAnchor.constraint(equalTo: view.widthAnchor),
            nodataView.heightAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    private func setNavigationView() {
        view.addSubview(customNavView)
        customNavView.addSubview(backButton)
        customNavView.addSubview(customTitle)
        
        NSLayoutConstraint.activate([
            // 自定义导航栏
            customNavView.topAnchor.constraint(equalTo: view.topAnchor),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 104),
            
            // 返回按钮
            backButton.leadingAnchor.constraint(equalTo: customNavView.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            
            customTitle.centerXAnchor.constraint(equalTo: customNavView.centerXAnchor),
            customTitle.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    @objc public func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func loadData() {
        if POIChooseType == .checkout {
            if let data = UserPublicPOIDBManager.shared.queryCheckData() {
                dataSource = data
                if dataSource.isEmpty {
                    manageButton.isHidden = true
                    nodataView.isHidden = false
                } else {
                    nodataView.isHidden = true
                    manageButton.isHidden = isManageState ? false : dataSource.isEmpty
                    updateTitle()
                    tableView.reloadData()
                }
            }
        }else {
            if let data = UserPublicPOIDBManager.shared.queryCollectData() {
                dataSource = data
                if dataSource.isEmpty {
                    manageButton.isHidden = true
                    nodataView.isHidden = false
                } else {
                    nodataView.isHidden = true
                    manageButton.isHidden = isManageState ? false : dataSource.isEmpty
                    updateTitle()
                    tableView.reloadData()
                }
            }
        }
        
    }
    
    private func updateTitle() {
        let totalCount = dataSource.count
        customTitle.text = "兴趣点(\(totalCount))"
        
        // 更新全选状态
        manageBottomView.setSelectAll(selectedIndexPaths.count == totalCount && totalCount > 0)
    }
    
    private func setSelectAll(_ isAll: Bool) {
        selectedIndexPaths.removeAll()
        if isAll {
            for i in 0..<dataSource.count {
                selectedIndexPaths.insert(IndexPath(row: i, section: 0))
            }
        }
        tableView.reloadData()
        updateTitle()
    }
    
    private func deleteSelectedItems() {
        guard !selectedIndexPaths.isEmpty else {
            view.sw_showSuccessToast("请选择需要删除的兴趣点")
            return
        }
        
        let message = selectedIndexPaths.count == 1 ? "确定删除选中兴趣点吗？" : "确定删除选中的\(selectedIndexPaths.count)个兴趣点吗？"
        
        SWAlertView.showAlert(title: nil, message: message) { [weak self] in
            guard let self = self else { return }
            
            // 按行号降序排序，避免删除时索引变化
            let sortedIndexPaths = self.selectedIndexPaths.sorted { $0.row > $1.row }
            
            for indexPath in sortedIndexPaths {
                guard indexPath.row < self.dataSource.count else { continue }
                var data = self.dataSource[indexPath.row]
                
                if POIChooseType == .checkout {
                    data.isIsCheck = false
                }else {
                    data.isCollection = false
                }
                UserPublicPOIDBManager.shared.update(poiData: data, byId: data.id ?? "")
            }
            
            self.selectedIndexPaths.removeAll()
            
            if self.dataSource.isEmpty {
                self.isManageState = false
                self.loadData()
            } else {
                self.tableView.deleteRows(at: Array(sortedIndexPaths), with: .automatic)
                self.updateTitle()
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func manageClick() {
        isManageState.toggle()
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileUserPublicPOICell") as! ProfileUserPublicPOICell
        let data = dataSource[indexPath.row]
        let isSelected = selectedIndexPaths.contains(indexPath)
        cell.config(with: data, isManageState: isManageState, isSelected: isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isManageState {
            if selectedIndexPaths.contains(indexPath) {
                selectedIndexPaths.remove(indexPath)
            } else {
                selectedIndexPaths.insert(indexPath)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
            updateTitle()
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let data = dataSource[indexPath.row]
            let vc = POIPublicDetailViewController(poiData: data)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - 左滑删除（非编辑模式）
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isManageState else { return nil }
        
        let deleteAction = UIContextualAction(style: .normal, title: "删除") { [weak self] (_, _, completionHandler) in
            SWAlertView.showAlert(title: nil, message: "确定删除兴趣点吗？") {
                self?.deleteSingleItem(at: indexPath)
                completionHandler(true)
            } cancelHandler: {
                completionHandler(false)
            }
        }
        
        deleteAction.backgroundColor = UIColor(str: "#F7594B")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteSingleItem(at indexPath: IndexPath) {
        var data = dataSource[indexPath.row]
        if POIChooseType == .checkout {
            data.isIsCheck = false
        }else {
            data.isCollection = false
        }
        UserPublicPOIDBManager.shared.update(poiData: data, byId: data.id ?? "")
        loadData()
    }
}
