//
//  PersonalEditViewController 2.swift
//  Pods
//
//  Created by TXTS on 2026/2/4.
//

import UIKit
import SWKit

class PersonalPOIManagerViewController: PersonalBaseViewController {
    
    private lazy var managerButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("管理", for: .normal)
        button.setTitleColor(UIColor(str: "#070808"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.addTarget(self, action: #selector(managerClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor(str: "#070808"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.addTarget(self, action: #selector(cancelClick), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private lazy var managerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("删除", for: .normal)
        button.setTitleColor(UIColor(str: "#F7594B"), for: .normal)
        button.backgroundColor = UIColor(hex: "#F2F3F4")
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(deleteClick), for: .touchUpInside)
        button.isHidden = true
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 66
        tableview.allowsMultipleSelectionDuringEditing = true
        tableview.register(ProfileUserPOICell.self, forCellReuseIdentifier: "ProfileUserPOICell")
        return tableview
    }()
    
    var dataSource: [UserPOILocalData] = []
    var selectedIndexPaths: Set<IndexPath> = []
    var isEditingMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "兴趣点(0)"
        
        customNavView.addSubview(managerButton)
        customNavView.addSubview(cancelButton)
        
        view.addSubview(tableView)
        view.addSubview(managerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            managerButton.centerYAnchor.constraint(equalTo: customTitle.centerYAnchor),
            managerButton.trailingAnchor.constraint(equalTo: customNavView.trailingAnchor, constant: -16),
            managerButton.widthAnchor.constraint(equalToConstant: 60),
            managerButton.heightAnchor.constraint(equalToConstant: 40),
            
            cancelButton.centerYAnchor.constraint(equalTo: customTitle.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: customNavView.trailingAnchor, constant: -16),
            cancelButton.widthAnchor.constraint(equalToConstant: 60),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            managerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            managerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            managerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            managerView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setData() {
        if let data = UserPOILocalDBManager.shared.queryAll() {
            dataSource = data
            updateTitle()
            tableView.reloadData()
        }
    }
    
    private func updateTitle() {
        if isEditingMode {
            customTitle.text = "已选择(\(selectedIndexPaths.count))"
        } else {
            customTitle.text = "兴趣点(\(dataSource.count))"
        }
    }
    
    @objc private func managerClick() {
        isEditingMode = true
        tableView.setEditing(true, animated: true)
        managerButton.isHidden = true
        cancelButton.isHidden = false
        managerView.isHidden = false
        
        // 清空之前的选择
        selectedIndexPaths.removeAll()
        
        // 更新导航栏标题
        updateTitle()
        
        // 滑动到底部显示删除按钮
        UIView.animate(withDuration: 0.3) {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        }
    }
    
    @objc private func cancelClick() {
        isEditingMode = false
        tableView.setEditing(false, animated: true)
        managerButton.isHidden = false
        cancelButton.isHidden = true
        managerView.isHidden = true
        
        // 清空选择
        selectedIndexPaths.removeAll()
        
        // 恢复标题
        updateTitle()
        
        // 恢复底部inset
        UIView.animate(withDuration: 0.3) {
            self.tableView.contentInset = .zero
        }
    }
    
    @objc private func deleteClick() {
        guard !selectedIndexPaths.isEmpty else {
            showToast(message: "请选择要删除的兴趣点")
            return
        }
        
        // 按照索引降序排列，避免删除时索引变化
        let sortedIndexPaths = selectedIndexPaths.sorted { $0.row > $1.row }
        
        // 创建确认弹窗
        SWAlertView.showAlert(title: "确定删除选中兴趣点吗？", message: "") { [weak self] in
            guard let self = self else { return }
            self.performDelete(sortedIndexPaths)
        }
    }
    
    private func performDelete(_ indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.row < dataSource.count else { continue }
            
            let data = dataSource[indexPath.row]
            
            // 从数据库中删除
            if UserPOILocalDBManager.shared.delete(byId: data.id ?? 0) {
                // 从数据源中删除
                dataSource.remove(at: indexPath.row)
            }
        }
        
        // 更新UI
        tableView.deleteRows(at: indexPaths, with: .automatic)
        selectedIndexPaths.removeAll()
        updateTitle()
        
        // 如果删除了所有数据，退出编辑模式
        if dataSource.isEmpty {
            cancelClick()
        }
    }
}

extension PersonalPOIManagerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileUserPOICell") as! ProfileUserPOICell
        let data = dataSource[indexPath.row]
        cell.config(with: data)
        
        // 在编辑模式下显示选择状态
        if isEditingMode {
            cell.setSelectionStyle()
        }
        
        return cell
    }
    
    // MARK: - 左滑删除
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isEditingMode  // 编辑模式下禁用左滑删除
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "删除") { (_, _, completionHandler) in
            
            SWAlertView.showAlert(title: "确定删除兴趣点吗？", message: "") { [weak self] in
                guard let self = self else { return }
                self.deleteSingleItem(at: indexPath)
                completionHandler(true)
            } cancelHandler: {
                completionHandler(false)
            }
        }
        
        deleteAction.backgroundColor = UIColor(hex: "#F7594B")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func deleteSingleItem(at indexPath: IndexPath) {
        let data = dataSource[indexPath.row]
        
        // 从数据库中删除
        if UserPOILocalDBManager.shared.delete(byId: data.id ?? 0) {
            // 从数据源中删除
            dataSource.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateTitle()
        }
    }
    
    // MARK: - 多选相关
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditingMode {
            // 编辑模式下处理多选
            selectedIndexPaths.insert(indexPath)
            updateTitle()
        } else {
            // 非编辑模式下的点击处理
            tableView.deselectRow(at: indexPath, animated: true)
            // 这里可以添加点击item的处理逻辑
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditingMode {
            selectedIndexPaths.remove(indexPath)
            updateTitle()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if isEditingMode {
            return .delete // 编辑模式下显示删除标记
        } else {
            return .none // 非编辑模式下不显示
        }
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false // 编辑时不缩进
    }
}

// 如果需要，可以给ProfileUserPOICell添加选择状态的配置方法
extension ProfileUserPOICell {
    func setSelectionStyle() {
        // 这里可以根据需要设置cell在多选时的样式
        self.selectionStyle = .default
        self.multipleSelectionBackgroundView = nil
    }
}

// 如果需要Toast提示，可以添加这个扩展
extension UIViewController {
    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        let textSize = toastLabel.intrinsicContentSize
        let labelWidth = min(textSize.width + 40, self.view.frame.width - 40)
        
        toastLabel.frame = CGRect(
            x: (self.view.frame.width - labelWidth) / 2,
            y: self.view.frame.height - 100,
            width: labelWidth,
            height: textSize.height + 20
        )
        
        self.view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
