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

class SettingViewController: PersonalBaseViewController {
    
    private let viewModel = PersonalViewModel()
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 60
        tableview.register(BindProDeviceCell.self, forCellReuseIdentifier: "BindProDeviceCell")
        return tableview
    }()
    
    private lazy var bottomButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("退出登录", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(stateBindProClick), for: .touchUpInside)
        return button
    }()
    
    var dataSource: [[SettingData]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        loadWifiData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "设置"
        
        view.addSubview(tableView)
        view.addSubview(bottomButton)
        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomButton.topAnchor),
            
            bottomButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -ScreenUtil.safeAreaBottom),
            bottomButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    private func loadWifiData() {
        let titles = ["检查APP版本更新", "联系我们", "隐私政策", "用户协议", "修改密码", "注销账号"]
        dataSource = [
            [SettingData(
                titleStr: titles[0],
                contentStr: "1.0.0",
                canChange: true
            ),
            SettingData(
                titleStr: titles[1],
                contentStr: "028-86110100",
                canChange: true
            ),
            SettingData(
                titleStr: titles[2],
                contentStr: "",
                canChange: true
            ),
            SettingData(
                titleStr: titles[3],
                contentStr: "",
                canChange: true
            )],
            [
                SettingData(
                    titleStr: titles[4],
                    contentStr: "",
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[5],
                    contentStr: "",
                    canChange: true
                ),
            ]
        ]
        
        tableView.reloadData()
    }
    
    @objc private func stateBindProClick() {
        SWAlertView.showAlert(title: "确认退出登录吗？", message: "", confirmTitle: "确定") { [weak self] in
            guard let self = self else { return }
            self.viewModel.logout()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    if case .failure(_) = completion {
                        self?.view.sw_showWarningToast("退出登录失败")
                    }
                } receiveValue: { [weak self] success in
                    if success {
                        TokenManager.shared.clearTokens()
                        self?.view.sw_showSuccessToast("退出登录成功")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            SWRouter.handle(RouteTable.loginPageUrl)
                        }
                    } else {
                        self?.view.sw_showWarningToast("退出登录失败")
                    }
                }
                .store(in: &self.viewModel.cancellables)
        }
        
    }
    
    func contactUs() {
        SWAlertView.showAlert(title: "联系我们", message: "客服电话：028-86110100") {
            
        }
    }
    
    private func showUserAgreement() {
        // 跳转到用户服务协议页面
        let webVC = WebViewController(
            fileName: "UserAgreement",
            title: "用户服务协议"
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showPrivacyPolicy() {
        // 跳转到隐私政策页面
        let webVC = WebViewController(
            fileName: "PrivacyPolicy",
            title: "隐私协议"
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindProDeviceCell") as! BindProDeviceCell
        let wifiData = dataSource[indexPath.section][indexPath.row]
        cell.configure(with: wifiData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                view.sw_showSuccessToast("当前已是最新版本")
            }
            if indexPath.row == 1 {
                contactUs()
            }
            if indexPath.row == 2 {
                showPrivacyPolicy()
            }
            if indexPath.row == 3 {
                showUserAgreement()
            }
        }
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                let vc = ForgotPasswordViewController()
                vc.isLoginVC = false
                self.navigationController?.pushViewController(vc, animated: true)
            }
            if indexPath.row == 1 {
                let vc = CancelAccountViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 20
        }
        return 0
    }
    
    
}

