//
//  LogExportViewController.swift
//  Alamofire
//
//  Created by zhaobo on 2026/1/26.
//

import UIKit
import SWKit

class LogExportViewController: UIViewController {
    
    private var logFiles: [URL] = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 55
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LogFileCell")
        return tableView
    }()
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("日志管理")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 加载日志文件
        logFiles = Logger.getLogFiles()
        
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
    
   func clearLogsTapped(_ sender: Any) {
       Logger.deleteAllLogs()
        logFiles.removeAll()
        tableView.reloadData()
        
        let alert = UIAlertController(title: "提示", message: "日志已清理", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

extension LogExportViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogFileCell", for: indexPath)
        let fileURL = logFiles[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = fileURL.lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let fileURL = logFiles[indexPath.row]
        
        // 显示分享菜单
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // iPad 适配
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = tableView.cellForRow(at: indexPath)
        }
        
        present(activityViewController, animated: true)
    }
}

extension URL {
    var fileSize: Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}
