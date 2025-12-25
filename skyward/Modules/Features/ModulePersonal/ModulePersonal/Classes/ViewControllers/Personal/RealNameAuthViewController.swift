//
//  RealNameAuthViewController.swift
//  ModulePersonal
//
//  Created by zhaobo on 2025/12/15.
//

import UIKit
import TXKit
import SWKit

class RealNameAuthViewController: PersonalBaseViewController {
    
    var isRealName: Bool = false
    var authTypes: [RealNameAuthItem] = []
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(RealNameAuthCell.self, forCellReuseIdentifier: "RealNameAuthCell")
        tableview.register(RealNameAuthInfoCell.self, forCellReuseIdentifier: "RealNameAuthInfoCell")
        return tableview
    }()
    
    var dataSource: [SettingData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        if isRealName {
            loadAuthInfoData()
        } else {
            loadAuthTypeData()
        }
        
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "实名认证"
        
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    
    private func loadAuthTypeData() {
        authTypes = [
            RealNameAuthItem(type: .alipay, icon: PersonalModule.image(named: "realname_alipay"), title: "支付宝实名认证", info: "无需录入个人信息，一键授权，安全便捷"),
            RealNameAuthItem(type: .wechat, icon: PersonalModule.image(named: "realname_wechat"), title: "微信实名认证", info: "无需录入个人信息，一键授权，安全便捷")
        ]
        
        tableView.reloadData()
    }
    
    private func loadAuthInfoData() {
        let titles = ["当前实名信息", "证件类型", "姓名", "证件号码"]
        dataSource = [
            SettingData(
                titleStr: titles[0],
                contentStr: "",
                canChange: true
            ),
            SettingData(
                titleStr: titles[1],
                contentStr: "证件号码",
                canChange: true
            ),
            SettingData(
                titleStr: titles[2],
                contentStr: "刘**",
                canChange: true
            ),
            SettingData(
                titleStr: titles[3],
                contentStr: "510000*********111",
                canChange: true
            )
        ]
        
        tableView.reloadData()
    }
    
    func realNameAuth(type: RealNameAuthType) {

    }
}

extension RealNameAuthViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isRealName {
            return dataSource.count
        }
        return authTypes.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isRealName {
            return 52
        }
        return 94
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isRealName {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RealNameAuthInfoCell") as! RealNameAuthInfoCell
            let data = dataSource[indexPath.row]
            cell.configure(with: data.titleStr, value: data.contentStr)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "RealNameAuthCell") as! RealNameAuthCell
        let data = authTypes[indexPath.row]
        cell.configure(with: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isRealName {
            return
        }
        let data = authTypes[indexPath.row]
        realNameAuth(type: data.type)
    }
}


