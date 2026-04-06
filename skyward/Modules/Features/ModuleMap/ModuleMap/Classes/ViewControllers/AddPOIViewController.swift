//
//  AddPOIViewController.swift
//  yifan_test
//
//  Created by TXTS on 2025/12/2.
//

import UIKit
import Photos
import PhotosUI
import SWKit
import SWNetwork
import Moya
import SWTheme
import SDWebImage

// MARK: - 添加兴趣点页面
class AddPOIViewController: UIViewController {
    
    private let viewModel = MapViewModel()
    
    var deleteCustomMarker: ((UserPOILocalData?) -> Void)?
    
    // MARK: - 新建
    var coordinate: POICoordinate?                  // 经纬度
    var poiData: MapSearchPointMsgData?             // 地址解析
    
    // MARK: - 属性
    var selectedType: POIType?
    var imgUrlList: [String] = []
    private let maxImageCount = 3
    private var poiId: String?
    
    // 添加变量跟踪当前编辑的控件
    private var activeField: UIView?
    private let scrollViewBottomInset: CGFloat = 0 // 底部边距
    
    // MARK: - UI Components - 头部
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "保存兴趣点"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        return button
    }()
    
    // MARK: - UI Components - 内容区域
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    // MARK: - 表单组件
    // 兴趣点名称
    private let nameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "兴趣点名称"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    private let requiredLabel1: UILabel = {
        let label = UILabel()
        label.text = "*"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .red
        return label
    }()
    
    private let nameTitleRemindLabel: UILabel = {
        let label = UILabel()
        label.text = "最长不超过60个字符"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.textColor = .black
        textField.font = .systemFont(ofSize: 14, weight: .medium)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.clearButtonMode = .whileEditing
        textField.tintColor = ThemeManager.current.mainColor
        textField.textColor = .black
        return textField
    }()
    
    private let nameTextPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入兴趣点名称"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.numberOfLines = 0
        return label
    }()
    
    // 类型选择
    private let typeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "类型"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    private let requiredLabel2: UILabel = {
        let label = UILabel()
        label.text = "*"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .red
        return label
    }()
    
    private let typeContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private var typeButtons: [POITypeButton] = []
    
    // 位置
    private let addressTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "位置"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    private lazy var addressNameLabel: UILabel = {
        let label = UILabel()
        label.text = poiData?.name ?? "--"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private lazy var addressLogAndLatLabel: UILabel = {
        let label = UILabel()
        label.text = "经纬度：--"
        if let coordinate = coordinate {
            let longitudeStr = String(format: "%.6f", coordinate.longitude)
            let latitudeStr = String(format: "%.6f", coordinate.latitude)
            label.text = "经纬度：\(longitudeStr)°E, \(latitudeStr)°N"
        }
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
        return label
    }()
    
    private lazy var addressAltitudeLabel: UILabel = {
        let label = UILabel()
        label.text = "海拔：--"
        if let altitude = poiData?.altitude {
            label.text = "海拔：\(altitude)米"
        }
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
        return label
    }()
    
    // 照片
    private let photoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "照片"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .black
        return label
    }()
    
    private let photoContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private var photoImageViews: [UIImageView] = []
    private var photoDeleteButtons: [UIButton] = []
    
    private let addPhotoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_poi_addImage"), for: .normal)
        button.backgroundColor = ThemeManager.current.mediumGrayBGColor
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = .black
        textView.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textView.tintColor = ThemeManager.current.mainColor
        textView.layer.cornerRadius = 8
        textView.layer.masksToBounds = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }()
    
    // 添加占位符Label
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "请输入介绍（选填）"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightGray
        label.numberOfLines = 0
        return label
    }()
    
    private let charCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0/100"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.textAlignment = .right
        return label
    }()
    
    // 底部按钮
    private let buttonContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("保存", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(str: "#FFE0B9")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    // MARK: - Init
    init(coordinate: POICoordinate, poiData: MapSearchPointMsgData?) {
        self.coordinate = coordinate
        self.poiData = poiData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        poiId = "\(Date().timeIntervalSince1970)"
        setupUI()
        setupConstraints()
        setupActions()
        setupKeyboardObservers()
        
        // 设置占位符初始状态
        updatePlaceholder()
        updateNamePlaceholder()
        // 添加监听
        addTextFieldObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // 头部
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        
        // 滚动区域
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 名称
        contentView.addSubview(nameTitleLabel)
        contentView.addSubview(requiredLabel1)
        contentView.addSubview(nameTitleRemindLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(nameTextPlaceholderLabel)
        
        // 类型
        contentView.addSubview(typeTitleLabel)
        contentView.addSubview(requiredLabel2)
        contentView.addSubview(typeContainerView)
        setupTypeButtons()
        
        // 位置
        contentView.addSubview(addressTitleLabel)
        contentView.addSubview(addressNameLabel)
        contentView.addSubview(addressLogAndLatLabel)
        contentView.addSubview(addressAltitudeLabel)
        
        // 照片
        contentView.addSubview(photoTitleLabel)
        contentView.addSubview(photoContainerView)
        setupPhotoViews()
        
        // 简介
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(placeholderLabel) // 添加占位符
        contentView.addSubview(charCountLabel)
        
        // 底部按钮
        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(addButton)
        
        // 设置代理
        nameTextField.delegate = self
        descriptionTextView.delegate = self
    }
    
    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 头部约束
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // 滚动区域约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupFormConstraints()
        setupButtonConstraints()
    }
    
    private func setupFormConstraints() {
        nameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        requiredLabel1.translatesAutoresizingMaskIntoConstraints = false
        nameTitleRemindLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 名称部分
        NSLayoutConstraint.activate([
            requiredLabel1.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            requiredLabel1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            nameTitleLabel.centerYAnchor.constraint(equalTo: requiredLabel1.centerYAnchor),
            nameTitleLabel.leadingAnchor.constraint(equalTo: requiredLabel1.trailingAnchor, constant: 4),
            
            nameTitleRemindLabel.centerYAnchor.constraint(equalTo: requiredLabel1.centerYAnchor),
            nameTitleRemindLabel.leadingAnchor.constraint(equalTo: nameTitleLabel.trailingAnchor, constant: 10),
            
            nameTextField.topAnchor.constraint(equalTo: nameTitleLabel.bottomAnchor, constant: 12),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            nameTextPlaceholderLabel.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            nameTextPlaceholderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
        ])
        
        setupTypeConstraints()
        setupAddressConstraints()
        setupPhotoConstraints()
        setupDescriptionConstraints()
    }
    
    private func setupTypeButtons() {
        typeContainerView.subviews.forEach { $0.removeFromSuperview() }
        typeButtons.removeAll()
        
        let itemWidth = (UIScreen.main.bounds.width - 60) / 4
        let itemHeight: CGFloat = 80
        
        for (index, type) in POIType.allCases.enumerated() {
            let button = POITypeButton(type: type)
            button.isSelected = (selectedType == type)
            button.tag = index
            button.addTarget(self, action: #selector(typeButtonTapped(_:)), for: .touchUpInside)
            
            let col = index % 4
            let row = index / 4
            
            button.frame = CGRect(
                x: CGFloat(col) * (itemWidth + 10),
                y: CGFloat(row) * (itemHeight + 10),
                width: itemWidth,
                height: itemHeight
            )
            
            typeContainerView.addSubview(button)
            typeButtons.append(button)
        }
        
        // 更新容器高度
        let rows = ceil(CGFloat(POIType.allCases.count) / 4)
        let totalHeight = rows * (itemHeight + 10) - 10
        
        typeContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            typeContainerView.heightAnchor.constraint(equalToConstant: totalHeight)
        ])
    }
    
    private func setupTypeConstraints() {
        typeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        requiredLabel2.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            requiredLabel2.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            requiredLabel2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            typeTitleLabel.centerYAnchor.constraint(equalTo: requiredLabel2.centerYAnchor),
            typeTitleLabel.leadingAnchor.constraint(equalTo: requiredLabel2.trailingAnchor, constant: 4),
            
            typeContainerView.topAnchor.constraint(equalTo: typeTitleLabel.bottomAnchor, constant: 12),
            typeContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            typeContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupAddressConstraints() {
        addressTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addressNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLogAndLatLabel.translatesAutoresizingMaskIntoConstraints = false
        addressAltitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addressTitleLabel.topAnchor.constraint(equalTo: typeContainerView.bottomAnchor, constant: 24),
            addressTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addressTitleLabel.widthAnchor.constraint(equalToConstant: 35),
            
            addressNameLabel.centerYAnchor.constraint(equalTo: addressTitleLabel.centerYAnchor),
            addressNameLabel.leadingAnchor.constraint(equalTo: addressTitleLabel.trailingAnchor, constant: 10),
            addressNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            addressLogAndLatLabel.topAnchor.constraint(equalTo: addressNameLabel.bottomAnchor, constant: 5),
            addressLogAndLatLabel.leadingAnchor.constraint(equalTo: addressTitleLabel.trailingAnchor, constant: 10),
            
            addressAltitudeLabel.topAnchor.constraint(equalTo: addressLogAndLatLabel.bottomAnchor, constant: 5),
            addressAltitudeLabel.leadingAnchor.constraint(equalTo: addressTitleLabel.trailingAnchor, constant: 10),
        ])
    }
    
    private func setupPhotoViews() {
        photoContainerView.subviews.forEach { $0.removeFromSuperview() }
        photoContainerView.addSubview(addPhotoButton)
        photoImageViews.removeAll()
        photoDeleteButtons.removeAll()
        
        let itemSize: CGFloat = (UIScreen.main.bounds.width - 40 - 32) / 3
        let spacing: CGFloat = 16
        
        // 已选图片
        for (index, imageUrl) in imgUrlList.enumerated() {
            let imageView = UIImageView()
            if imageUrl.contains("http") {
                imageView.sd_setImage(with: URL(string: imageUrl))
            }else {
                if FileManager.default.fileExists(atPath: imageUrl) {
                    let image = UIImage(contentsOfFile: imageUrl)
                    imageView.image = image
                } else {
                    print("文件不存在: \(imageUrl)")
                }
            }
            
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 8
            imageView.layer.masksToBounds = true
            imageView.isUserInteractionEnabled = true
            imageView.clipsToBounds = true // 添加这行，确保图片不会超出边界
            
            let deleteButton = UIButton(type: .custom)
            deleteButton.setImage(MapModule.image(named: "map_poi_deleteImage"), for: .normal)
            deleteButton.tag = index
            deleteButton.addTarget(self, action: #selector(deletePhotoTapped(_:)), for: .touchUpInside)
            
            let x = CGFloat(index) * (itemSize + spacing)
            imageView.frame = CGRect(x: x, y: 0, width: itemSize, height: itemSize)
            deleteButton.frame = CGRect(x: x + itemSize - 25, y: 5, width: 20, height: 20) // 调整位置
            
            photoContainerView.addSubview(imageView)
            photoContainerView.addSubview(deleteButton)
            photoImageViews.append(imageView)
            photoDeleteButtons.append(deleteButton)
        }
        
        // 添加按钮位置
        let addButtonX = CGFloat(imgUrlList.count) * (itemSize + spacing)
        addPhotoButton.frame = CGRect(x: addButtonX, y: 0, width: itemSize, height: itemSize)
        
        // 更新添加按钮状态
        addPhotoButton.isHidden = imgUrlList.count >= maxImageCount
        
        setupPhotoConstraints()
    }
    
    private func setupPhotoConstraints() {
        photoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        photoContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            photoTitleLabel.topAnchor.constraint(equalTo: addressAltitudeLabel.bottomAnchor, constant: 24),
            photoTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            photoContainerView.topAnchor.constraint(equalTo: photoTitleLabel.bottomAnchor, constant: 12),
            photoContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            photoContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            photoContainerView.heightAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 80) / 3),
        ])
    }
    
    private func setupDescriptionConstraints() {
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        charCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            descriptionTextView.topAnchor.constraint(equalTo: photoContainerView.bottomAnchor, constant: 20),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 120),
            descriptionTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // 占位符约束
            placeholderLabel.topAnchor.constraint(equalTo: descriptionTextView.topAnchor, constant: 10),
            placeholderLabel.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(equalTo: descriptionTextView.trailingAnchor, constant: -8),
            
            charCountLabel.bottomAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: -8),
            charCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),
        ])
    }
    
    private func setupButtonConstraints() {
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            addButton.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -20),
            addButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 20),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addPhotoButton.addTarget(self, action: #selector(addPhotoButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasType = selectedType != nil
        let hasDescription = !descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImages = !imgUrlList.isEmpty
        
        // 如果没有任何数据，直接关闭
        if !hasName && !hasType && !hasDescription && !hasImages {
            deleteCustomMarker?(nil)
            dismiss(animated: true)
            return
        }
        
        SWAlertView.showAlert(title: nil, message: "确定不保存兴趣点吗？",confirmTitle: "继续编辑", cancelTitle: "不保存", confirmHandler: {
            print("继续编辑")
        }) { [weak self] in
            print("不保存")
            guard let self = self else { return }
            self.deleteCustomMarker?(nil)
            self.dismiss(animated: true)
        }
    }
    
    @objc private func addButtonTapped() {
        // 单独检查缺失的数据并提示
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasType = selectedType != nil
        
        if !hasName {
            view.sw_showWarningToast("请输入兴趣点名称")
            return
        }
        
        if !hasType {
            view.sw_showWarningToast("请选择兴趣点类型")
            return
        }
        
        savePOI()
    }
    
    @objc private func typeButtonTapped(_ sender: POITypeButton) {
        selectedType = sender.type
        typeButtons.forEach { $0.isSelected = ($0.type == selectedType) }
        updateAddButtonState()
    }
    
    @objc private func addPhotoButtonTapped() {
        requestPhotoPermission()
    }
    
    @objc private func deletePhotoTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < imgUrlList.count else { return }
        
        imgUrlList.remove(at: index)
        
        setupPhotoViews()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    private func updatePlaceholder() {
        placeholderLabel.isHidden = !descriptionTextView.text.isEmpty
    }
    
    private func updateNamePlaceholder() {
        let text = nameTextField.text ?? ""
        nameTextPlaceholderLabel.isHidden = !text.isEmpty
    }
    
    private func validateForm() -> Bool {
        // 验证名称
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            view.sw_showWarningToast("请输入兴趣点名称")
            return false
        }
        
        // 验证类型
        guard selectedType != nil else {
            view.sw_showWarningToast("请选择兴趣点类型")
            return false
        }
        
        // 验证坐标
        guard coordinate != nil else {
            view.sw_showWarningToast("位置信息无效")
            return false
        }
        
        return true
    }
    
    private func addTextFieldObserver() {
        // 监听文本框变化
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        updateAddButtonState()
        updateNamePlaceholder()
    }

    private func updateAddButtonState() {
        let hasName = !(nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasType = selectedType != nil
        
        if hasName && hasType {
            addButton.backgroundColor = ThemeManager.current.mainColor
            addButton.isEnabled = true
        } else {
            addButton.backgroundColor = UIColor(str: "#FFE0B9")
            addButton.isEnabled = false
        }
    }
    
    private func savePOI() {
        // 这里实现保存逻辑，可以保存到本地或上传到服务器
        let poiName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let poiCategory = selectedType?.category ?? 1
        let poiDescription = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let poiLon = coordinate?.longitude ?? 00.00
        let poiLat = coordinate?.latitude ?? 00.00
        let poiUrlList = imgUrlList
        var userPOILocalData = UserPOILocalData(poiId: poiId, name: poiName, address: poiData?.name, description: poiDescription, lon: poiLon, lat: poiLat, category: poiCategory)
        for (index, imageUrl) in imgUrlList.enumerated() {
            if index == 0 {
                userPOILocalData.imageData1 = imageUrl
            }
            if index == 1 {
                userPOILocalData.imageData2 = imageUrl
            }
            if index == 2 {
                userPOILocalData.imageData3 = imageUrl
            }
        }
        if let altitude = Double(poiData?.altitude ?? "00") {
            userPOILocalData.altitude = altitude
        }
        
        print("保存兴趣点:")
        print("名称: \(poiName)")
        print("类型: \(poiCategory)")
        print("坐标: \(poiLon)--\(poiLat)")
        print("简介: \(poiDescription)")
        print("图片数量: \(poiUrlList.count)")
        
        if UserPOILocalDBManager.shared.insertOrUpdate(poiData: userPOILocalData) {
            UIWindow.topWindow?.sw_showSuccessToast("保存兴趣点成功")
            viewModel.uploadLocalPOIDataToNetwork(userPOILocalData, type: "save")
            let poiData = UserPOILocalDBManager.shared.query(byPoiId: userPOILocalData.poiId ?? "")
            self.deleteCustomMarker?(poiData)
            self.dismiss(animated: true)
        }
        
    }
    
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Photo Picker
    private func requestPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            presentPhotoPicker()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self?.presentPhotoPicker()
                    } else {
                        self?.showPhotoPermissionAlert()
                    }
                }
            }
        default:
            showPhotoPermissionAlert()
        }
    }
    
    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = maxImageCount - imgUrlList.count
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showPhotoPermissionAlert() {
        let alert = UIAlertController(
            title: "需要照片权限",
            message: "请允许访问照片以选择图片",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight-100, right: 0)
        
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        
        // 如果正在编辑descriptionTextView，滚动到可见位置
        if let activeField = activeField {
            let activeRect = activeField.convert(activeField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(activeRect, animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: scrollViewBottomInset, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        activeField = nil
    }

}

// MARK: - UITextFieldDelegate
extension AddPOIViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            descriptionTextView.becomeFirstResponder()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
        nameTextPlaceholderLabel.isHidden = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
        updateNamePlaceholder()
    }
}

// MARK: - UITextViewDelegate
extension AddPOIViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let currentCount = textView.text.count
        charCountLabel.text = "\(currentCount)/100"
        
        if currentCount > 100 {
            textView.text = String(textView.text.prefix(100))
            charCountLabel.textColor = .red
        } else {
            charCountLabel.textColor = currentCount == 100 ? .red : .lightGray
        }
        
        placeholderLabel.isHidden = true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        DispatchQueue.main.async {
            self.updatePlaceholder()
        }
        
        return updatedText.count <= 100
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeField = textView
        // 开始编辑时滚动到可见位置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let textViewRect = textView.convert(textView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(textViewRect, animated: true)
        }
        updatePlaceholder()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        activeField = nil
        // 结束编辑时保持占位符状态
        updatePlaceholder()
    }
}

// MARK: - PHPickerViewControllerDelegate
extension AddPOIViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self else { return }
                if let image = object as? UIImage {
                    // 保存图片到本地--返回图片路径
                    let imageName = "\(poiId ?? "txts")-\(Date().timeIntervalSince1970)"
                    ImageManager.shared.saveImage(image, name: imageName) { result in
                        switch result {
                        case .success(let path):
                            print("图片保存成功: \(path)")
                            DispatchQueue.main.async {
                                self.imgUrlList.append(path)
                                self.setupPhotoViews()
                            }
                        case .failure(let error):
                            print("图片保存失败: \(error)")
                        }
                    }
                }
            }
        }
    }
}



