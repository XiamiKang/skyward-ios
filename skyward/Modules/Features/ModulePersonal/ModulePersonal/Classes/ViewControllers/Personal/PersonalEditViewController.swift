//
//  PersonalEditViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/11.
//

import UIKit
import SWKit
import Moya

class PersonalEditViewController: PersonalBaseViewController {
    
    private let viewModel = PersonalViewModel()
    private var userInfoData: UserInfoData?
    private let pickerManager = AvatarPickerManager.shared
    private let uploadService = UploadManager()
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 56
        tableview.register(BindProDeviceCell.self, forCellReuseIdentifier: "BindProDeviceCell")
        return tableview
    }()
    
    var dataSource: [SettingData] = []
    var contentText: UserInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        bindViewModel()
        loadWifiData()
        // 相册管理
        pickerManager.delegate = self
        pickerManager.presentingViewController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 刷新用户数据
        viewModel.input.getUserInfoRequest.send()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FFFFFF")
        customTitle.text = "编辑资料"
        
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
    
    private func bindViewModel() {
        viewModel.$userInfoData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                self.userInfoData = data
                self.loadWifiData()
            }
            .store(in: &viewModel.cancellables)
    }
    
    private func loadWifiData() {
        var genderStr = "请选择"
        if let gender = self.userInfoData?.gender {
            if gender == 0 {
                genderStr = "未知"
            }else if gender == 1 {
                genderStr = "男"
            }else {
                genderStr = "女"
            }
        }
        dataSource = [
            SettingData(
                titleStr: "头像",
                contentStr: self.userInfoData?.avatar ?? "",
                canChange: false
            ),
            SettingData(
                titleStr: "昵称",
                contentStr: self.userInfoData?.nickname ?? "未设置",
                canChange: true
            ),
            SettingData(
                titleStr: "所在城市",
                contentStr: self.userInfoData?.city ?? "请选择",
                canChange: true
            ),
            SettingData(
                titleStr: "性别",
                contentStr: genderStr,
                canChange: true
            ),
            SettingData(
                titleStr: "简介",
                contentStr: self.userInfoData?.personalitySign ?? "一句话介绍自己",
                canChange: true
            )
        ]
        
        tableView.reloadData()
    }
}

extension PersonalEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BindProDeviceCell") as! BindProDeviceCell
        let data = dataSource[indexPath.row]
        cell.settingConfigure(with: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            print("换头像")
            let avatatModeView = AvatarModeSelectionView()
            avatatModeView.delegate = self
            avatatModeView.show(in: view)
        case 1:
            print("换昵称")
            let vc = PersonalNickNameViewController()
            vc.nickName = self.userInfoData?.nickname ?? "未设置"
            self.navigationController?.pushViewController(vc, animated: true)
        case 2:
            selectRegionTapped()
        case 3:
            print("换性别")
            let genderModeView = GenderModeSelectionView()
            genderModeView.delegate = self
            genderModeView.show(in: view)
        case 4:
            print("换个签")
            let vc = PersonalIntroductionViewController()
            vc.introduction = self.userInfoData?.personalitySign ?? "一句话介绍自己"
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            print("")
        }
    }
    
    func selectRegionTapped() {
        let regionView = RegionSelectionView()
        regionView.delegate = self
        
        // 带回显（可选）
        regionView.show(in: self.view,
                        currentProvinceCode: "110000000000",
                        currentCityCode: "110100000000")
    }
    
}

extension PersonalEditViewController: AvatarModeSelectionViewDelegate {
    func didSelectAvatarMode(_ mode: String) {
        if mode == "相册" {
            print("相册")
            pickerManager.checkPhotoLibraryPermission()
        }else {
            print("相机")
            pickerManager.checkCameraPermission()
        }
    }
}

extension PersonalEditViewController: GenderModeSelectionViewDelegate {
    func didSelectGenderMode(_ mode: Int) {
        updateGenger(sex: mode)
    }
    
    
}

extension PersonalEditViewController: AvatarPickerDelegate {
    func avatarPickerDidSelectImage(_ image: UIImage) {
        uploadImage(image: image)
    }
    
    func avatarPickerDidCancel() {
        
    }
    
    func avatarPickerDidFailWithError(_ error: String) {
        
    }
    
    func uploadImage(image: UIImage) {
        uploadService.uploadImage(
            image,
            fileName: "avatar.jpg",
            compressionQuality: 0.8,
            progressHandler: { _ in
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.isSuccess, let fileUrl = response.data?.fileUrl {
                            print("上传成功！文件URL: \(fileUrl)")
                            self?.updateAvatar(imageUrl: fileUrl)
                        } else {
                            print("上传失败: \(response.msg ?? "未知错误")")
                        }
                    case .failure(let error):
                        print("上传错误: \(error.localizedDescription)")
                    }
                }
            }
        )
    }
    
    func updateAvatar(imageUrl: String) {
        viewModel.updateAvatar(imageUrl: imageUrl)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("头像更新成功")
                    self?.viewModel.input.getUserInfoRequest.send()
                }else {
                    self?.view.sw_showSuccessToast("头像更新失败")
                }
            }
            .store(in: &viewModel.cancellables)
    }
    
    func updateGenger(sex: Int) {
        viewModel.updateGender(gender: sex)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("性别更新成功")
                    self?.viewModel.input.getUserInfoRequest.send()
                }else {
                    self?.view.sw_showSuccessToast("性别更新失败")
                }
            }
            .store(in: &viewModel.cancellables)
    }
}

extension PersonalEditViewController: RegionSelectionViewDelegate {
    func didSelectRegion(province: Region?, city: Region?) {
        if let province = province, let city = city {
            let regionName = RegionSelectionView.getFullRegionName(province: province, city: city)
            print("选择的地区: \(regionName)")
            updateUserCity(city: city.name, cityCode: city.code)
        }
    }
    
    func updateUserCity(city: String, cityCode: String) {
        viewModel.updateCity(city: city, cityCode: cityCode)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] data in
                if data {
                    self?.view.sw_showSuccessToast("城市更新成功")
                    self?.viewModel.input.getUserInfoRequest.send()
                }else {
                    self?.view.sw_showSuccessToast("城市更新失败")
                }
            }
            .store(in: &viewModel.cancellables)
    }
}
