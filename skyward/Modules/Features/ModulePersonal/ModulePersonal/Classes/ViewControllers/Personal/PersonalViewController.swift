//
//  TxtsPersonalController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//

import UIKit
import SWKit
import Combine

// 功能项模型
struct FunctionItem {
    var icon: UIImage?
    var title: String
    var info: String
    var hasArrow: Bool
}


public class PersonalViewController: UIViewController {
    
    // MARK: - 数据
    private var userProfile: UserInfoData?
    private let viewModel = PersonalViewModel()
    private var emergencyInfoData: EmergencyInfoData?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI组件
    private let headBgImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = PersonalModule.image(named: "profile_head_bg")
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.isScrollEnabled = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        checkLoginStatus()
    }
}

// MARK: - UI设置
extension PersonalViewController {
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(headBgImageView)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            headBgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headBgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headBgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headBgImageView.heightAnchor.constraint(equalToConstant: 200),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProfileHeaderView.self, forHeaderFooterViewReuseIdentifier: "ProfileHeaderView")
        tableView.register(ProfileFunctionHeaderView.self, forHeaderFooterViewReuseIdentifier: "ProfileFunctionHeaderView")
        tableView.register(ProfileFunctionOneCell.self, forCellReuseIdentifier: "ProfileFunctionOneCell")
        tableView.register(ProfileFunctionTwoCell.self, forCellReuseIdentifier: "ProfileFunctionTwoCell")
        tableView.register(ProfileFunctionThreeCell.self, forCellReuseIdentifier: "ProfileFunctionThreeCell")
        tableView.register(ProfileFunctionFourCell.self, forCellReuseIdentifier: "ProfileFunctionFourCell")
    }
    
    // 检查登录状态
    private func checkLoginStatus() {
        viewModel.checkEmergency()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                self.emergencyInfoData = data
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.checkUserInfo()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                self.userProfile = data
                self.updateLoginStatus(isLoggedIn: true, userInfo: data)
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // 更新登录状态
    func updateLoginStatus(isLoggedIn: Bool, userInfo: UserInfoData? = nil) {
        userProfile = userInfo
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
@available(iOS 13.0, *)
extension PersonalViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // 第一部分：个人资料，第二部分：功能列表
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 0 : 3
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileFunctionOneCell") as! ProfileFunctionOneCell
            if let emergencyInfoData = emergencyInfoData {
                cell.changeInfoLabel(emergencyInfoData)
            }
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileFunctionTwoCell") as! ProfileFunctionTwoCell
            cell.changeDeviceImage()
            return cell
//        case 2:
//            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileFunctionThreeCell") as! ProfileFunctionThreeCell
//            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileFunctionFourCell") as! ProfileFunctionFourCell
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ProfileHeaderView") as? ProfileHeaderView else {
                return nil
            }
            header.editUserInfoAction = { [weak self] in
                guard let self = self else { return }
                let editVC = PersonalEditViewController()
                self.navigationController?.pushViewController(editVC, animated: true)
            }
            if let userInfo = userProfile {
                header.configure(profile: userInfo)
            }
            return header
        } else {
            guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ProfileFunctionHeaderView") as? ProfileFunctionHeaderView else {
                return nil
            }
            return header
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 160 : 35
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 这里可以添加具体的跳转逻辑
        switch indexPath.row {
        case 0:
            // 紧急救援服务
            let emergencyVC = EmergencyServiceViewController()
            if let emergencyInfoData = emergencyInfoData {
                emergencyVC.contentText = emergencyInfoData.phone != nil ? "\(emergencyInfoData.name ?? "")\("(\(emergencyInfoData.phone ?? ""))")" : "未设置"
            }
            navigationController?.pushViewController(emergencyVC, animated: true)
            break
        case 1:
            // 我的卫星装备
            let deviceVC = DeviceListViewController()
            navigationController?.pushViewController(deviceVC, animated: true)
            break
//        case 2:
//            // 实名认证
//            let realNameVC = RealNameAuthViewController()
//            navigationController?.pushViewController(realNameVC, animated: true)
//            break
        case 2:
            // 设置
            let settingVC = SettingViewController()
            navigationController?.pushViewController(settingVC, animated: true)
            break
        default:
            break
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
}


