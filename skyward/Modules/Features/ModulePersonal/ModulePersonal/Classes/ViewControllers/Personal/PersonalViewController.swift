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
    private var poiNum = 0
    
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
//        if #available(iOS 11.0, *) {
//            tableView.contentInsetAdjustmentBehavior = .never
//        }
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }()
    
    private let profileMyDataView = ProfileMyDataView()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setData()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        checkLoginStatus()
        tableView.reloadData()
    }
}

// MARK: - UI设置
extension PersonalViewController {
    
    private func setupUI() {
        view.backgroundColor = UIColor(str: "#F2F3F4")
        
        view.addSubview(headBgImageView)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            headBgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            headBgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headBgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headBgImageView.heightAnchor.constraint(equalToConstant: 200),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(ProfileMessageCell.self, forCellReuseIdentifier: "ProfileMessageCell")
        tableView.register(ProfileFunctionOneCell.self, forCellReuseIdentifier: "ProfileFunctionOneCell")
        tableView.register(ProfileFunctionTwoCell.self, forCellReuseIdentifier: "ProfileFunctionTwoCell")
        tableView.register(ProfileFunctionThreeCell.self, forCellReuseIdentifier: "ProfileFunctionThreeCell")
        tableView.register(ProfileFunctionFourCell.self, forCellReuseIdentifier: "ProfileFunctionFourCell")
    }
    
    private func setData() {
        if let poiData = UserPOILocalDBManager.shared.queryAll() {
            poiNum = poiData.count
            tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
        }
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

extension PersonalViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 3
        }
        return 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileMessageCell") as! ProfileMessageCell
            cell.editUserInfoAction = { [weak self] in
                guard let self = self else { return }
                let editVC = PersonalEditViewController()
                self.navigationController?.pushViewController(editVC, animated: true)
            }
            if let userInfo = userProfile {
                cell.configure(profile: userInfo)
            }
            return cell
        }
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            profileMyDataView.frame = CGRect(x: 16, y: 5, width: UIScreen.main.bounds.width-32, height: UIScreen.main.bounds.width/2)
            profileMyDataView.layer.cornerRadius = 10
            profileMyDataView.updateData(with: 0, POINum: poiNum, routeNum: 0, checkoutNum: 0, collectNum: 0, offlineNum: 0)
            profileMyDataView.selectedIndex = { [weak self] index in
                switch index {
                case 0:
                    print("历史轨迹")
                    SWRouter.handle(RouteTable.routeListPageUrl, parameters: ["type" : "1"])
                case 1:
                    print("兴趣点")
                    let vc = PersonalPOIManagerViewController()
                    self?.navigationController?.pushViewController(vc, animated: true)
                case 2:
                    print("绘制路线")
                    SWRouter.handle(RouteTable.routeListPageUrl, parameters: ["type" : "0"])
                case 3:
                    print("打卡")
                case 4:
                    print("收藏")
                case 5:
                    print("离线缓存")
                default:
                    print(index)
                }
            }
            cell.contentView.addSubview(profileMyDataView)
            
            return cell
        }
        if indexPath.section == 2 {
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
        let cell = UITableViewCell()
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100
        }
        if indexPath.section == 1 {
            return UIScreen.main.bounds.width/2 + 30
        }
        return 56
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
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
                let deviceVC = DeviceListViewController(selectedDeviceType: 0)
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
    }
    
}


