//
//  BaseTableViewController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import UIKit

open class BaseTableViewController: BaseViewController {
    
    open override func setupViews() {
        super.setupViews()
        view.addSubview(tableView)
    }
    
    // MARK: - Table View Configurations
    open var tableStyle: UITableView.Style {
        return .plain
    }
    
    open var tableContentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        return .never
    }
    
    // MARK: - Lazy Properties
    public lazy var tableView: UITableView = {
        let aTableView = UITableView(frame: UIScreen.main.bounds, style: tableStyle)
        aTableView.backgroundColor = .clear
        aTableView.separatorStyle = .none
        aTableView.showsVerticalScrollIndicator = false
        aTableView.showsHorizontalScrollIndicator = false
        aTableView.rowHeight = UITableView.automaticDimension
        aTableView.automaticallyAdjustsScrollIndicatorInsets = false

        aTableView.contentInsetAdjustmentBehavior = tableContentInsetAdjustmentBehavior
        
        aTableView.dataSource = self
        aTableView.delegate = self
        
        if #available(iOS 15.0, *) {
            aTableView.sectionHeaderTopPadding = 0
        }
        
        return aTableView
    }()
}

extension BaseTableViewController: UITableViewDataSource, UITableViewDelegate {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
