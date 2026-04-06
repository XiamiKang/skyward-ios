//
//  SettingViewController.swift
//  ModulePersonal
//
//  Created by zhaobo on 2025/12/15.
//

import UIKit
import TXKit
import SWKit
import SWNetwork
import ModuleLogin
import SWTheme

class AccountAndSafeViewController: PersonalBaseViewController {
    
    public var userInfo: UserInfoData?
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 60
        tableview.register(BindProDeviceCell.self, forCellReuseIdentifier: "BindProDeviceCell")
        tableview.register(DevieceSettingCell.self, forCellReuseIdentifier: "DevieceSettingCell")
        return tableview
    }()
    
    var dataSource: [SettingData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        loadWifiData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "账号与安全"
        
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
    
    private func loadWifiData() {
        let titles = ["手机号", "修改密码", "实名认证", "注销账号"]
        dataSource = [
            SettingData(
                titleStr: titles[0],
                contentStr: userInfo?.phone?.hidePhoneNumber() ?? "",
                canChange: true
            ),
            SettingData(
                titleStr: titles[1],
                contentStr: "",
                canChange: true
            ),
            SettingData(
                titleStr: titles[2],
                contentStr: UserManager.shared.realNameAuthStatus ? "已认证" : "未认证",
                canChange: true
            ),
            SettingData(
                titleStr: titles[3],
                contentStr: "",
                canChange: true
            )
        ]
        
        tableView.reloadData()
    }
    
}

extension AccountAndSafeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindProDeviceCell") as! BindProDeviceCell
        let wifiData = dataSource[indexPath.row]
        cell.configure(with: wifiData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let changePhoneVC = ChangePhoneViewController()
            changePhoneVC.userInfo = userInfo
            navigationController?.pushViewController(changePhoneVC, animated: true)
        }
        if indexPath.row == 1 {
            let vc = ForgotPasswordViewController()
            vc.isLoginVC = false
            self.navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.row == 2 {
            let realNameVC = RealNameAuthViewController()
            realNameVC.userInfo = userInfo
            navigationController?.pushViewController(realNameVC, animated: true)
        }
        if indexPath.row == 3 {
            let vc = CancelAccountViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
