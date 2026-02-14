//
//  RouteListViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/9.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme
import SnapKit

class RouteListViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDataSourcePrefetching {
    
    private var viewModel: RouteListViewModel
    
    
    init(type: RouteType) {
        viewModel = RouteListViewModel(type: type)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override
    override public var hasNavBar: Bool {
        return false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.loadPageData()
    }
    
    override public func setupViews() {
        super.setupViews()
        view.addSubview(navigationBar)
        if viewModel.type == .track {
            view.addSubview(segmentView)
        }
        view.addSubview(tableView)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        if viewModel.type == .track {
            segmentView.snp.makeConstraints { make in
                make.height.equalTo(44)
                make.top.equalTo(navigationBar.snp.bottom)
                make.left.right.equalToSuperview()
            }
            tableView.snp.makeConstraints { make in
                make.top.equalTo(segmentView.snp.bottom)
                make.bottom.left.right.equalToSuperview()
            }
        } else {
            tableView.snp.makeConstraints { make in
                make.top.equalTo(navigationBar.snp.bottom)
                make.bottom.left.right.equalToSuperview()
            }
        }
    }
    
    public override func bindViewModel() {
        super.bindViewModel()
        
        bindPublisher(viewModel.$naviTitle.eraseToAnyPublisher()) { [weak self] navTitle in
            self?.navigationBar.setTitle(navTitle)
        }
        
        bindPublisher(viewModel.$remoteTitle.eraseToAnyPublisher()) { [weak self] remoteTitle in
            self?.segmentView.updateTitle(at: 0, title: remoteTitle)
        }
        
        bindPublisher(viewModel.$localTitle.eraseToAnyPublisher()) { [weak self] localTitle in
            self?.segmentView.updateTitle(at: 1, title: localTitle)
        }

        bindPublisher(viewModel.$routeList.eraseToAnyPublisher()) { [weak self] list in
            self?.emptyView.isHidden = list.count > 0
            self?.manageButton.isHidden = list.count == 0
            self?.tableView.reloadData()
            self?.viewModel.syncRouteList()
        }
        
        bindPublisher(viewModel.$isLoading.eraseToAnyPublisher()) { [weak self] isLoading in
            if isLoading {
                self?.view.sw_showLoading()
            } else {
                self?.view.sw_hideLoading()
            }
        }
    }
    
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        bar.addSubview(manageButton)
        manageButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(30))
            make.right.equalToSuperview().inset(Layout.hMargin)
            make.centerY.equalToSuperview()
        }
        return bar
    }()
    
    private lazy var manageButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .pingFangFontRegular(ofSize: 14)
        button.setTitle("管理", for: .normal)
        button.setTitle("取消", for: .selected)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.addAction(UIAction { [weak self] _ in
            let manageState = !button.isSelected
            self?.setManageState(manageState)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var segmentView: SegmentedControlView = {
        let segmentView = SegmentedControlView()
        segmentView.onSelectedIndexChanged = { [weak self] index in
            if index == 0 {
                self?.viewModel.isLocal = false
            } else {
                self?.viewModel.isLocal = true
            }
            if self?.viewModel.isManageState == true {
                self?.setManageState(false)
            }
        }
        segmentView.configure(titles: [viewModel.localTitle, viewModel.remoteTitle], defaultIndex: 0)

        return segmentView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.prefetchDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = swAdaptedValue(104)
        tableView.register(cellType: RouteListCell.self)
        return tableView
    }()
    
    private lazy var emptyView: SWBlankView = {
        let view = SWBlankView(title: "暂无数据")
        view.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: tableView.topAnchor, constant: swAdaptedValue(80)),
            view.centerXAnchor.constraint(equalTo: tableView.centerXAnchor)
        ])
        return view
    }()
    
    private lazy var manageBottomView: RouteManageBottomView = {
        let manageBottomView = RouteManageBottomView()
        manageBottomView.selectAllHandler = { [weak self] isAll in
            self?.viewModel.setSelectAll(isAll)
        }
        manageBottomView.deleteHandler = { [weak self] in
            let msg = self?.viewModel.type == .track ? "确定删除选中轨迹吗？" : "确定删除选中路线吗？"
            SWAlertView.showAlert(title: nil, message: msg) {
                self?.view.sw_showLoading()
                self?.viewModel.deleteSelectedRoutes { [weak self]  in
                    self?.view.sw_hideLoading()
                }
            }
        }
        manageBottomView.uploadHandler = { [weak self] in
            self?.view.sw_showLoading()
            self?.viewModel.uploadSelectedRoutes { [weak self]  in
                self?.view.sw_hideLoading()
            }
        }
        
        view.addSubview(manageBottomView)
        manageBottomView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48) + ScreenUtil.safeAreaBottom)
            make.bottom.left.right.equalToSuperview()
        }
        
        return manageBottomView
    }()
    
    
    // MARK: - Actions
    private func setManageState(_ manageState: Bool) {
        viewModel.setManageState(manageState)
        viewModel.setSelectAll(false)
        manageButton.isSelected = manageState
        manageBottomView.isHidden = !manageState
        manageBottomView.showUploadButton(viewModel.isLocal)
        manageBottomView.setSelectAll(false)
        tableView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(manageState ? (swAdaptedValue(48) + ScreenUtil.safeAreaBottom) : 0)
        }
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.routeList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: RouteListCell.self)
        if viewModel.routeList.count > indexPath.row {
            let route = viewModel.routeList[indexPath.row]
            cell.configure(with: route, isManageState: viewModel.isManageState)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let route = viewModel.routeList[indexPath.row]
        
        if viewModel.isManageState {
            let selected = route.selected ?? false
            viewModel.routeList[indexPath.row].selected = !selected
            return
        }
        
        let vc = RouteDetailViewController(route: route)
        vc.deleteSuccessHandler = {
            self.viewModel.deleteRouteSuccess(route)
        }
        vc.editSuccessHandler = { route in
            self.viewModel.editRouteSuccess(route)
        }
        vc.uploadSuccessHandler = {
            self.viewModel.uploadRouteSuccess(route)
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - UITableView DataSource Prefetching

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // 找出预加载索引中最大的行号
        guard let maxRow = indexPaths.map({ $0.row }).max() else {
            return
        }

        // 当预加载的行接近当前数据末尾时（倒数第2条），触发加载
        let preloadThreshold = 2
        let shouldLoadMore = maxRow >= viewModel.routeList.count - preloadThreshold

        if shouldLoadMore {
            viewModel.loadMoreIfNeeded()
        }
    }
}

