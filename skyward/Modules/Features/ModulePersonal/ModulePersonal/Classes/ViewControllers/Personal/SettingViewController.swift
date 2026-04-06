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

class SettingViewController: PersonalBaseViewController {
    
    private let viewModel = PersonalViewModel()
    public var userInfo: UserInfoData?
    private var canTap = true  // 添加防抖标志
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 60
        tableview.isScrollEnabled = false
        tableview.register(BindProDeviceCell.self, forCellReuseIdentifier: "BindProDeviceCell")
        tableview.register(DevieceSettingCell.self, forCellReuseIdentifier: "DevieceSettingCell")
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
        
#if DEBUG
        let tap = UITapGestureRecognizer(target: self, action: #selector(goLogManager))
        tap.numberOfTapsRequired = 5
        view.addGestureRecognizer(tap)
#endif
    }
    
    @objc private func goLogManager(){
        navigationController?.pushViewController(LogExportViewController(), animated: true)
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
        let titles = ["账号与安全", "检查APP版本更新", "联系我们", "隐私政策", "用户协议", "APP端SOS发送频率"]
        let savedFrequency = SOSManager.shared.getSOSReportFrequency()
        let frequencyString = SOSReportHelper.reportString(from: savedFrequency)
        dataSource = [
            [
                SettingData(
                    titleStr: titles[0],
                    contentStr: "",
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[1],
                    contentStr: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String,
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[2],
                    contentStr: "028-86110100",
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[3],
                    contentStr: "",
                    canChange: true
                ),
                SettingData(
                    titleStr: titles[4],
                    contentStr: "",
                    canChange: true
                )],
            [
                SettingData(
                    titleStr: titles[5],
                    contentStr: frequencyString,
                    canChange: true
                )
            ]
        ]
        
        tableView.reloadData()
    }
    
    @objc private func stateBindProClick() {
        SWAlertView.showAlert(title: "确认退出登录吗？", message: "", confirmTitle: "确定") { [weak self] in
            guard let self = self else { return }
            UserManager.shared.logout()
            self.viewModel.logout()
                .receive(on: DispatchQueue.main)
                .sink { _ in
                } receiveValue: { _ in
                }
                .store(in: &self.viewModel.cancellables)
        }
        
    }
    
    private func checkAppVersion() {
        // 获取版本号并移除点号
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            view.sw_showWarningToast("无法获取应用版本号")
            return
        }
        
        let versionWithoutDots = version.replacingOccurrences(of: ".", with: "")
        
        viewModel.checkAppVersion(versionStr: versionWithoutDots)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(_):
                    // 错误处理
                    self?.view.sw_showSuccessToast("当前已是最新版本")
                }
            } receiveValue: { [weak self] versionData in
                // 处理版本数据
                self?.handleVersionCheckResult(versionData, currentVersion: version)
            }
            .store(in: &viewModel.cancellables)
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
    
    private func handleVersionCheckResult(_ data: AppVersionData, currentVersion: String) {
        // 获取服务器返回的版本名称
        guard let latestVersion = data.versionName else {
            view.sw_showWarningToast("版本信息获取失败")
            return
        }
        
        // 获取升级类型
        guard let upgradeTypeInt = data.upgradeType else {
            view.sw_showWarningToast("升级类型获取失败")
            return
        }
        
        // 0:无需升级 1:建议升级 2:强制升级
        switch upgradeTypeInt {
        case 0:
            // 无需升级
            view.sw_showSuccessToast("当前已是最新版本")
            
        case 1, 2:
            // 需要升级（建议升级或强制升级）
            // 显示更新弹窗
            AppVersionUpdateView.showUpdateDialog(
                in: self.view,
                version: latestVersion,
                upgradeType: upgradeTypeInt,
                updateUrl: data.fileUrl,
                cancelHandler: { [weak self] in
                    print("用户取消了更新")
                    // 可以在这里添加统计等逻辑
                    
                    // 如果是强制升级，用户点击取消时可能需要特殊处理
                    if upgradeTypeInt == 2 {
                        // 强制升级时，理论上不应该有取消按钮，但以防万一
                        self?.handleForceUpdateCancel()
                    }
                },
                updateHandler: {
                    print("用户点击了更新")
                    // 可以在这里添加统计等逻辑
                    
                }
            )
            
        default:
            view.sw_showWarningToast("未知的升级类型")
        }
    }

    /// 处理强制升级时用户取消的情况
    private func handleForceUpdateCancel() {
        // 可以根据业务需求决定是否退出应用或禁用部分功能
        #if DEBUG
        print("强制升级被取消 - 调试模式下继续运行")
        #else
        // 生产环境下可以再次弹窗提示必须升级
        SWAlertView.showAlert(
            title: "提示",
            message: "当前版本需要强制升级才能继续使用，请立即更新",
            confirmTitle: "确定"
        ) {
            // 可以再次尝试打开App Store
            if let appStoreURL = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
                UIApplication.shared.open(appStoreURL)
            }
        }
        #endif
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
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DevieceSettingCell") as! DevieceSettingCell
            let wifiData = dataSource[indexPath.section][indexPath.row]
            cell.configure(with: wifiData)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindProDeviceCell") as! BindProDeviceCell
        let wifiData = dataSource[indexPath.section][indexPath.row]
        cell.configure(with: wifiData)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard canTap else { return }
        canTap = false
        
        // 1秒后恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.canTap = true
        }
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let vc = AccountAndSafeViewController()
                vc.userInfo = userInfo
                self.navigationController?.pushViewController(vc, animated: true)
            }
            if indexPath.row == 1 {
                checkAppVersion()
            }
            if indexPath.row == 2 {
                contactUs()
            }
            if indexPath.row == 3 {
                showPrivacyPolicy()
            }
            if indexPath.row == 4 {
                showUserAgreement()
            }
        }
        if indexPath.section == 1 {
            let reportView = SOSReportSelectionView() // 需要创建类似的视图
            reportView.delegate = self
            reportView.show(in: view, currentReport: SOSManager.shared.getSOSReportFrequency())
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 16, y: 0, width: ScreenUtil.screenWidth-32, height: 1))
        label.backgroundColor = ThemeManager.current.mediumGrayBGColor
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 10
        }
        return 0
    }
    
    
}

extension SettingViewController: SOSReportSelectionViewDelegate {
    func didSelectSOSReport(_ report: Int) {
        // 保存上报频率
        SOSManager.shared.setSOSReportFrequency(report)
        
        // 更新显示的文本
        if dataSource.count > 2 && dataSource[2].count > 0 {
            let frequencyString = SOSReportHelper.reportString(from: report)
            dataSource[2][0].contentStr = frequencyString
            
            // 刷新对应的cell
            let indexPath = IndexPath(row: 0, section: 2)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
