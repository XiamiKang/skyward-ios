//
//  RegionSelectionViewDelegate.swift
//  Pods
//
//  Created by TXTS on 2025/12/23.
//


import UIKit

protocol RegionSelectionViewDelegate: AnyObject {
    func didSelectRegion(province: Region?, city: Region?)
}

class RegionSelectionView: UIView {
    
    weak var delegate: RegionSelectionViewDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "选择城市"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor(hex: "#070808")
        label.textAlignment = .center
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(PersonalModule.image(named: "default_close"), for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(hex: "#F2F3F4") // 可以根据设计调整颜色
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("确定", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor(hex: "#FE6A00") // 可以根据设计调整颜色
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var provinces: [Region] = []
    private var cities: [Region] = []
    
    private var selectedProvince: Region?
    private var selectedCity: Region?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        loadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(pickerView)
        containerView.addSubview(cancelButton)
        containerView.addSubview(confirmButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 450),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            pickerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            pickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            pickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            pickerView.heightAnchor.constraint(equalToConstant: 280),
            
            cancelButton.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cancelButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width-48)/2),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            confirmButton.topAnchor.constraint(equalTo: pickerView.bottomAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            confirmButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width-48)/2),
            confirmButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadData() {
        provinces = RegionDataManager.shared.provinces
        if let firstProvince = provinces.first {
            selectedProvince = firstProvince
            cities = RegionDataManager.shared.getCities(forProvinceCode: firstProvince.code)
            selectedCity = cities.first
        }
        pickerView.reloadAllComponents()
    }
    
    func show(in view: UIView, currentProvinceCode: String? = nil, currentCityCode: String? = nil) {
        frame = view.bounds
        view.addSubview(self)
        
        // 设置回显
        if let provinceCode = currentProvinceCode,
           let province = RegionDataManager.shared.findRegion(byCode: provinceCode) {
            selectedProvince = province
            cities = RegionDataManager.shared.getCities(forProvinceCode: provinceCode)
            
            if let cityCode = currentCityCode,
               let city = RegionDataManager.shared.findRegion(byCode: cityCode) {
                selectedCity = city
            } else if let firstCity = cities.first {
                selectedCity = firstCity
            }
            
            // 更新PickerView选中位置
            if let provinceIndex = provinces.firstIndex(where: { $0.code == province.code }) {
                pickerView.selectRow(provinceIndex, inComponent: 0, animated: false)
                
                if let cityIndex = cities.firstIndex(where: { $0.code == selectedCity?.code }) {
                    pickerView.selectRow(cityIndex, inComponent: 1, animated: false)
                }
            }
        }
        
        // 动画显示
        containerView.transform = CGAffineTransform(translationX: 0, y: 320)
        alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    @objc private func closeButtonTapped() {
        hide()
    }
    
    @objc private func confirmButtonTapped() {
        delegate?.didSelectRegion(province: selectedProvince, city: selectedCity)
        hide()
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 320)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if !containerView.frame.contains(location) {
            hide()
        }
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension RegionSelectionView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2 // 省和市两列
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return provinces.count
        case 1:
            return cities.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return provinces[row].name
        case 1:
            return cities[row].name
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: // 选择了省份
            selectedProvince = provinces[row]
            cities = RegionDataManager.shared.getCities(forProvinceCode: selectedProvince!.code)
            selectedCity = cities.first
            
            pickerView.reloadComponent(1)
            
            if cities.count > 0 {
                pickerView.selectRow(0, inComponent: 1, animated: true)
            }
            
        case 1: // 选择了城市
            selectedCity = cities[row]
            
        default:
            break
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let width = pickerView.bounds.width
        switch component {
        case 0:
            return width * 0.45
        case 1:
            return width * 0.45
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = UIColor(hex: "#070808")
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        
        let text: String
        switch component {
        case 0:
            text = provinces[row].name
        case 1:
            text = cities[row].name
        default:
            text = ""
        }
        
        label.text = text
        return label
    }
}

// MARK: - 使用示例扩展
extension RegionSelectionView {
    
    /// 便捷显示方法
    static func show(in viewController: UIViewController,
                    currentSelection: (provinceCode: String?, cityCode: String?)? = nil,
                    completion: @escaping (Region?, Region?) -> Void) {
        
        guard let view = viewController.view else { return }
        
        let regionView = RegionSelectionView()
        regionView.delegate = RegionSelectionViewDelegateHandler(completion: completion)
        
        if let selection = currentSelection {
            regionView.show(in: view, 
                          currentProvinceCode: selection.provinceCode,
                          currentCityCode: selection.cityCode)
        } else {
            regionView.show(in: view)
        }
    }
    
    /// 获取完整的地区名称
    static func getFullRegionName(province: Region?, city: Region?) -> String {
        var parts: [String] = []
        
        if let provinceName = province?.name {
            parts.append(provinceName)
        }
        
        if let cityName = city?.name, cityName != province?.name {
            parts.append(cityName)
        }
        
        return parts.joined(separator: " ")
    }
}

// MARK: - 代理处理类（用于处理闭包回调）
private class RegionSelectionViewDelegateHandler: RegionSelectionViewDelegate {
    
    private let completion: (Region?, Region?) -> Void
    
    init(completion: @escaping (Region?, Region?) -> Void) {
        self.completion = completion
    }
    
    func didSelectRegion(province: Region?, city: Region?) {
        completion(province, city)
    }
}
