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
    
    var records: [TrackRecord] = []
    
    var onClickCloseHandler: (() -> (Void))?
    var onClickLookHandler: (([CLLocationCoordinate2D]) -> (Void))?
    var onClickUnLookHandler: (() -> (Void))?
    var onClickDeleteHandler: ((Bool) -> (Void))?
    
    private lazy var recordDataManager: TrackDataManager = {
        let mgr = TrackDataManager()
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
    
    func uploadTrackRecord(_ record: TrackRecord) {
        guard let fileUrl = record.localFileUrl,
              let data = recordDataManager.getTrackRecordGPXData(from: record),
              let index = records.firstIndex(where: { $0.name == record.name && $0.localFileUrl == fileUrl }) else {
            return
        }
        view.sw_showLoading()
        uploadManager.uploadFile(fileData: data, fileName: record.name, mimeType: "gpx") { progress in
            print("上传进度： \(progress)")
        } completion: {[weak self] result in
            DispatchQueue.main.async {
                self?.view.sw_hideLoading()
                switch result {
                case .success(let response):
                    if response.isSuccess, let fileUrl = response.data?.fileUrl {
                        print("上传成功！文件URL: \(fileUrl)")
                        self?.view.sw_showLoading()
                        self?.mapService.saveUserTrack(name: record.name, fileUrl: fileUrl) { result in
                            DispatchQueue.main.async {
                                self?.view.sw_hideLoading()
                                switch result {
                                case .success(let response):
                                    if response.statusCode == 200 {
                                        self?.records[index].uploadStatus = .uploaded
                                        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                                        if let record = self?.records[index] {
                                            self?.recordDataManager.updateUploadStatusRecord(record)
                                        }
                                    }
                                    
                                case .failure(let error):
                                    debugPrint("保存失败：\(error.localizedDescription)")
                                }
                            }
                        }
                    } else {
                        print("上传失败: \(response.msg ?? "未知错误")")
                    }
                case .failure(let error):
                    print("上传错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func lookTrackRecord(_ record: TrackRecord) {
        guard let index = records.firstIndex(where: { $0.name == record.name && $0.id == record.id}) else {
            return
        }
        
        let isLook = record.isLook
        records[index].isLook = !isLook
        if isLook {
            onClickUnLookHandler?()
        } else {
            let coordinates = recordDataManager.readRecordCoordinates(from: record)
            onClickLookHandler?(coordinates)
        }
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    func deleteTrackRecord(_ record: TrackRecord) {
        SWAlertView.showAlert(title: nil, message: "确定删除轨迹吗？") {
            if self.recordDataManager.deleteRecord(record) {
                self.onClickDeleteHandler?(true)
                self.records.removeAll(where: { $0.id == record.id })
                self.tableView.reloadData()
                self.emptyView.isHidden = self.records.count > 0
            }
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
            self?.uploadTrackRecord(record)
        }
        cell.onClickLookHandler = {[weak self] in
            self?.lookTrackRecord(record)
        }
        
        cell.onClickDeleteHandler = {[weak self] in
            self?.deleteTrackRecord(record)
        }
        return cell
    }
}
