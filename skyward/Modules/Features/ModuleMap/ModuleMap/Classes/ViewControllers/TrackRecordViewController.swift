//
//  TrackRecordViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/17.
//

import UIKit
import CoreLocation
import SWKit
import SWTheme

class TrackRecordViewController: UIViewController {
    var customTransitioningDelegate: CustomTransitioningDelegate?
    
    var records: [Route] = []
    
    var onClickCloseHandler: (() -> (Void))?
    var onClickLookHandler: (([CLLocationCoordinate2D]) -> (Void))?
    var onClickUnLookHandler: (() -> (Void))?
    var onClickDeleteHandler: ((Bool) -> (Void))?
    
    private lazy var recordDataManager: RouteDataManager = {
        let mgr = RouteDataManager()
        return mgr
    }()
    
    private lazy var uploadManager: UploadManager = {
        let mgr = UploadManager()
        return mgr
    }()
    
    private lazy var mapService: MapService = {
        let mapService = MapService()
        return mapService
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "我的历史轨迹"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = swAdaptedValue(56)
        tableView.register(cellType: TrackRecordCell.self)
        return tableView
    }()
    
    private lazy var emptyView: SWBlankView = {
        let view = SWBlankView(title: "暂未搜索到结果")
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        
        closeButton.addAction(UIAction {[weak self] _  in
            self?.dismiss(animated: true)
            self?.onClickCloseHandler?()
        }, for: .touchUpInside)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(headerView)
        view.addSubview(tableView)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        emptyView.isHidden = records.count > 0
    }
    
    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func uploadRoute(_ route: Route) {
//        view.sw_showLoading()
//        recordDataManager.saveRouteToService(route) { [weak self] rspRoute, errorMsg in
//            self?.view.sw_hideLoading()
//            if let rspRoute = rspRoute {
//                self?.view.sw_showSuccessToast("上传成功")
//                self?.recordDataManager.replaceRouteFromOldToNew(old: route, new: rspRoute)
//            } else {
//                if let msg = errorMsg {
//                    self?.view.sw_showWarningToast(msg)
//                }
//            }
//        }
    }
    
    func lookRoute(_ record: Route) {

    }
    
    func deleteRoute(_ record: Route) {
        SWAlertView.showAlert(title: nil, message: "确定删除轨迹吗？") {
            self.recordDataManager.deleteRouteFromService(routeId: record.id, completion: { [weak self] success, errorMsg in
                self?.onClickDeleteHandler?(true)
                self?.records.removeAll(where: { $0.id == record.id })
                self?.tableView.reloadData()
                if let count = self?.records.count, count > 0 {
                    self?.emptyView.isHidden = false
                } else {
                    self?.emptyView.isHidden = true
                }
            })
        }
    }
}


// MARK: - UITableView Delegate & DataSource
extension TrackRecordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TrackRecordCell.self)
        let record = records[indexPath.row]
        cell.configure(with: record)
        cell.onClickUploadHandler = {[weak self] in
            self?.uploadRoute(record)
        }
        cell.onClickLookHandler = {[weak self] in
//            self?.lookRoute(record)
        }
        
        cell.onClickDeleteHandler = {[weak self] in
            self?.deleteRoute(record)
        }
        return cell
    }
}
