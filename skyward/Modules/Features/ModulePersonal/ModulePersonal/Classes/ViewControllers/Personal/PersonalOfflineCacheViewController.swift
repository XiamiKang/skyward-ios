//
//  PersonalOfflineCacheViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/2/26.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SnapKit

class PersonalOfflineCacheViewController: PersonalBaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(ProfileOfflineCacheCell.self, forCellReuseIdentifier: "ProfileOfflineCacheCell")
        return tableview
    }()
    
    private let databaseManager = POIDatabaseManager.shared
    private let downloadManager = POIDownloadManager.shared
        
    private var cacheInfo: (size: String, time: String, count: Int) = ("0B", "未知", 0)
    
    private let nodataView = NoDataView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        loadCacheInfo()
        
        // 监听下载完成通知，刷新数据
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDownloadCompleted),
            name: .poiDownloadCompleted,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "离线缓存(1)"
        
        view.addSubview(tableView)
        
        nodataView.isHidden = true
        view.addSubview(nodataView)
    }
    
    private func setupConstraints() {

        tableView.snp.makeConstraints { make in
            make.top.equalTo(customNavView.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        nodataView.snp.makeConstraints { make in
            make.top.equalTo(customNavView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(300)
        }
    }
    
    private func loadCacheInfo() {
        // 获取数据库完整信息
        databaseManager.getDatabaseInfo { [weak self] size, time, count in
            self?.cacheInfo = (size, time, count)
            self?.tableView.reloadData()
        }
    }
    
    @objc private func handleDownloadCompleted() {
        // 下载完成后刷新数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadCacheInfo()
        }
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileOfflineCacheCell") as! ProfileOfflineCacheCell
        // 从 downloadManager 获取下载时间
        let downloadTime = downloadManager.lastDownloadTime
        cell.configureSimple(version: "1.0", fileSize: "108.4M", downloadTime: downloadTime)
        return cell
    }
}
