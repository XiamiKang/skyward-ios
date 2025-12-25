//
//  Device.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/17.
//


import UIKit
import CoreBluetooth
import SWKit

public class DeviceListViewController: PersonalBaseViewController {
    
    // MARK: - 数据
    private var selectedDeviceType: Int = 0 // 0: 行者mini, 1: 行者pro
    private var devices: [BluetoothDeviceInfo] = []
    private var proDevices: [WiFiDevice] = []
    private let viewModel = PersonalViewModel()
    
    // MARK: - UI组件
    private let optionView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "#F5F5F5")
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let miniButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("行者mini", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .white
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let proButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("行者pro", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.black, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(hex: "#F5F5F5")
        button.layer.cornerRadius = 6
        return button
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    // MARK: - 生命周期
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupActions()
        bindViewModel()
        loadInitialData()
        setupNotifications()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadDevices()
    }
    
}

// MARK: - UI设置
extension DeviceListViewController {
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加自定义导航栏
        customNavView.addSubview(optionView)
        
        // 添加选项视图
        optionView.addSubview(miniButton)
        optionView.addSubview(proButton)
        
        // 添加设备列表
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            // 选项视图
            optionView.centerXAnchor.constraint(equalTo: customNavView.centerXAnchor),
            optionView.bottomAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: -8),
            optionView.widthAnchor.constraint(equalToConstant: 200),
            optionView.heightAnchor.constraint(equalToConstant: 36),
            
            // mini按钮
            miniButton.leadingAnchor.constraint(equalTo: optionView.leadingAnchor, constant: 2),
            miniButton.topAnchor.constraint(equalTo: optionView.topAnchor, constant: 2),
            miniButton.bottomAnchor.constraint(equalTo: optionView.bottomAnchor, constant: -2),
            miniButton.widthAnchor.constraint(equalToConstant: 96),
            
            // pro按钮
            proButton.trailingAnchor.constraint(equalTo: optionView.trailingAnchor, constant: -2),
            proButton.topAnchor.constraint(equalTo: optionView.topAnchor, constant: 2),
            proButton.bottomAnchor.constraint(equalTo: optionView.bottomAnchor, constant: -2),
            proButton.widthAnchor.constraint(equalToConstant: 96),
            
            // 设备列表
            collectionView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MiniDeviceCell.self, forCellWithReuseIdentifier: "MiniDeviceCell")
        collectionView.register(BindDeviceCell.self, forCellWithReuseIdentifier: "BindDeviceCell")
        collectionView.register(ProDeviceCell.self, forCellWithReuseIdentifier: "ProDeviceCell")
    }
    
    private func setupActions() {
        miniButton.addTarget(self, action: #selector(miniButtonTapped), for: .touchUpInside)
        proButton.addTarget(self, action: #selector(proButtonTapped), for: .touchUpInside)
    }
    
    
    private func loadDevices() {
        if selectedDeviceType == 0 {
            // 行者mini设备
            let savedDevices = BluetoothManager.shared.getAllSavedDevices()
            print("保存的设备数量: \(savedDevices.count)")
            
            for device in savedDevices {
                print("设备: \(device.displayName)")
                print("UUID: \(device.uuid)")
                print("IMEI: \(device.imei)")
                print("最后连接: \(device.lastConnectedDate)")
            }
            devices = savedDevices

        } else {
            // 行者pro设备
            proDevices = WiFiDeviceStorageManager.shared.getAllDevices()
        }
        collectionView.reloadData()
    }
    
    private func bindViewModel() {
        viewModel.$deviceListData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let _ = self else { return }
//                self.devices = data
//                self.addTestMarkers()
            }
            .store(in: &viewModel.cancellables)
    }
    
    private func loadInitialData(){
        let baseModel = BaseModel(pageNum: 1, pageSize: 20)
        viewModel.input.deviceListRequest.send(baseModel)
    }
    
    private func updateOptionButtons() {
        if selectedDeviceType == 0 {
            miniButton.backgroundColor = .white
            proButton.backgroundColor = UIColor(hex: "#F5F5F5")
        } else {
            miniButton.backgroundColor = UIColor(hex: "#F5F5F5")
            proButton.backgroundColor = .white
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refreshDeviceList(_:)),
                                               name: .deviceListNeedToUpdate,
                                               object: nil)
    }
    
    @objc private func refreshDeviceList(_ notification: Notification) {
        loadDevices()
    }
    
    // MARK: - 按钮点击事件
    @objc private func miniButtonTapped() {
        selectedDeviceType = 0
        updateOptionButtons()
        loadDevices()
    }
    
    @objc private func proButtonTapped() {
        selectedDeviceType = 1
        updateOptionButtons()
        loadDevices()
    }
}

// MARK: - UICollectionView扩展
extension DeviceListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if selectedDeviceType == 0 {
            return devices.isEmpty ? 1 : devices.count + 1
        }else {
            return proDevices.isEmpty ? 1 : proDevices.count + 1
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if selectedDeviceType == 0 {
            if devices.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BindDeviceCell", for: indexPath) as! BindDeviceCell
                return cell
            } else {
                if indexPath.row == devices.count {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BindDeviceCell", for: indexPath) as! BindDeviceCell
                    return cell
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MiniDeviceCell", for: indexPath) as! MiniDeviceCell
                cell.configure(with: devices[indexPath.item])
                return cell
            }
        }else {
            if proDevices.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BindDeviceCell", for: indexPath) as! BindDeviceCell
                return cell
            } else {
                if indexPath.row == proDevices.count {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BindDeviceCell", for: indexPath) as! BindDeviceCell
                    return cell
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProDeviceCell", for: indexPath) as! ProDeviceCell
                cell.configure(proDevices[indexPath.row])
                return cell
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let spacing: CGFloat = 12
        let totalWidth = collectionView.frame.width - padding * 2 - spacing
        let width = totalWidth / 2
        return CGSize(width: width, height: width)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedDeviceType == 0 {
            if devices.isEmpty {
                // 点击绑定设备
                print("绑定设备")
                showBindDeviceSheet()
            } else {
                if indexPath.row == devices.count {
                    showBindDeviceSheet()
                    return
                }
                let device = devices[indexPath.item]
                print("点击设备: \(device.displayName)")
                // 这里可以跳转到设备详情页面
                navigateToMiniDeviceDetail(with: device)
                BluetoothManager.shared.stopScanning()
            }
        }else {
            if proDevices.isEmpty {
                // 点击绑定设备
                print("绑定设备")
                showBindDeviceSheet()
            } else {
                if indexPath.row == proDevices.count {
                    showBindDeviceSheet()
                    return
                }
                navigateToProDeviceDetail()
            }
        }
    }
}

// MARK: - 使用方法
extension DeviceListViewController {
    func showBindDeviceSheet() {
        if selectedDeviceType == 0 {
            BluetoothManager.shared.disconnectPeripheral()
            let bindDeviceVC = BindMiniDeviceViewController()
            bindDeviceVC.modalPresentationStyle = .overFullScreen
            bindDeviceVC.onDismiss = { [weak self] uuidStr in
                self?.loadDevices()
                self?.isConnectedDevice(uuidStr: uuidStr)
            }
            present(bindDeviceVC, animated: false, completion: nil)
        }else {
            print("行者Pro")
            let bindProDeviceVC = BindProDeviceViewController()
            self.navigationController?.pushViewController(bindProDeviceVC, animated: true)
        }
    }
    
    private func navigateToMiniDeviceDetail(with device: BluetoothDeviceInfo) {
        let detailVC = MiniDeviceDetailViewController()
        detailVC.deviceInfo = device
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func navigateToProDeviceDetail() {
        let detailVC = ProDeviceDetailViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    private func isConnectedDevice(uuidStr: String) {
        let sevedDevices = MiniDeviceStorageManager.shared.getAllSavedDevices()
        
        for device in sevedDevices {
            if device.uuid == uuidStr {
                navigateToMiniDeviceDetail(with: device)
            }
        }
    }
}

// MARK: - UIColor扩展
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
