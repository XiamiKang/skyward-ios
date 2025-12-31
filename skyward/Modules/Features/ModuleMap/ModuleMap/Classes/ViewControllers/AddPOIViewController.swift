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


// MARK: - 添加兴趣点页面
class AddPOIViewController: UIViewController {
    
    var customTransitioningDelegate: CustomTransitioningDelegate?
    private let uploadService = UploadManager()
    private let viewModel = MapViewModel()
    
    var deleteCustomMarker: (()-> Void)?
    
    // MARK: - Properties
    var coordinate: POICoordinate?
    var selectedType: POIType?
    var selectedImages: [UIImage] = []
    var imgUrlList: [String] = []
    private let maxImageCount = 3
    
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
        label.text = "添加兴趣点"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let coordinateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor(str: "#84888C")
        label.numberOfLines = 0
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
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "请输入兴趣点名称"
        textField.font = .systemFont(ofSize: 14)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemGray6
        textField.clearButtonMode = .whileEditing
        return textField
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
        button.backgroundColor = UIColor(str: "#F2F3F4")
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .systemGray6
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
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    // 底部按钮
    private let buttonContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor(str: "#070808"), for: .normal)
        button.backgroundColor = UIColor(str: "#F2F3F4")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("添加", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(str: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    // MARK: - Lifecycle
    init(coordinate: POICoordinate) {
        self.coordinate = coordinate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupKeyboardObservers()
        
        // 更新坐标显示
        updateCoordinateDisplay()
        // 设置占位符初始状态
        updatePlaceholder()
        // 默认选择第一个类型
        selectFirstType()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 头部
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(coordinateLabel)
        headerView.addSubview(closeButton)
        
        // 滚动区域
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 名称
        contentView.addSubview(nameTitleLabel)
        contentView.addSubview(requiredLabel1)
        contentView.addSubview(nameTextField)
        
        // 类型
        contentView.addSubview(typeTitleLabel)
        contentView.addSubview(requiredLabel2)
        contentView.addSubview(typeContainerView)
        setupTypeButtons()
        
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
        buttonContainerView.addSubview(cancelButton)
        buttonContainerView.addSubview(addButton)
        
        // 设置代理
        nameTextField.delegate = self
        descriptionTextView.delegate = self
    }
    
    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 头部约束
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            
            coordinateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            coordinateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            coordinateLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
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
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 名称部分
        NSLayoutConstraint.activate([
            requiredLabel1.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            requiredLabel1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            nameTitleLabel.centerYAnchor.constraint(equalTo: requiredLabel1.centerYAnchor),
            nameTitleLabel.leadingAnchor.constraint(equalTo: requiredLabel1.trailingAnchor, constant: 4),
            
            nameTextField.topAnchor.constraint(equalTo: nameTitleLabel.bottomAnchor, constant: 12),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        setupTypeConstraints()
        setupPhotoConstraints()
        setupDescriptionConstraints()
    }
    
    private func setupTypeButtons() {
        typeContainerView.subviews.forEach { $0.removeFromSuperview() }
        typeButtons.removeAll()
        
        let itemWidth = (UIScreen.main.bounds.width - 60) / 3
        let itemHeight: CGFloat = 80
        
        for (index, type) in POIType.allCases.enumerated() {
            let button = POITypeButton(type: type)
            button.isSelected = (selectedType == type)
            button.tag = index
            button.addTarget(self, action: #selector(typeButtonTapped(_:)), for: .touchUpInside)
            
            let col = index % 3
            let row = index / 3
            
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
        let rows = ceil(CGFloat(POIType.allCases.count) / 3)
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
    
    private func setupPhotoViews() {
        photoContainerView.subviews.forEach { $0.removeFromSuperview() }
        photoContainerView.addSubview(addPhotoButton)
        photoImageViews.removeAll()
        photoDeleteButtons.removeAll()
        
        let itemSize: CGFloat = (UIScreen.main.bounds.width - 40 - 32) / 3
        let spacing: CGFloat = 16
        
        // 已选图片
        for (index, image) in selectedImages.enumerated() {
            let imageView = UIImageView()
            imageView.image = image
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
        let addButtonX = CGFloat(selectedImages.count) * (itemSize + spacing)
        addPhotoButton.frame = CGRect(x: addButtonX, y: 0, width: itemSize, height: itemSize)
        
        // 更新添加按钮状态
        addPhotoButton.isHidden = selectedImages.count >= maxImageCount
        
        setupPhotoConstraints()
    }
    
    private func setupPhotoConstraints() {
        photoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        photoContainerView.translatesAutoresizingMaskIntoConstraints = false
//        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            photoTitleLabel.topAnchor.constraint(equalTo: typeContainerView.bottomAnchor, constant: 24),
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
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            cancelButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 60) / 2),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            
            addButton.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -20),
            addButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 60) / 2),
            addButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
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
        deleteCustomMarker?()
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        deleteCustomMarker?()
        dismiss(animated: true)
    }
    
    @objc private func addButtonTapped() {
        guard validateForm() else { return }
        savePOI()
    }
    
    @objc private func typeButtonTapped(_ sender: POITypeButton) {
        selectedType = sender.type
        typeButtons.forEach { $0.isSelected = ($0.type == selectedType) }
    }
    
    @objc private func addPhotoButtonTapped() {
        requestPhotoPermission()
    }
    
    @objc private func deletePhotoTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < selectedImages.count else { return }
        
        selectedImages.remove(at: index)
        setupPhotoViews()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Helper Methods
    private func updateCoordinateDisplay() {
        if let coord = coordinate {
            coordinateLabel.text = coord.displayString
        } else {
            coordinateLabel.text = "未获取到位置信息"
        }
    }
    
    private func updatePlaceholder() {
        placeholderLabel.isHidden = !descriptionTextView.text.isEmpty
    }
    
    private func selectFirstType() {
        guard let firstType = POIType.allCases.first else { return }
        selectedType = firstType
        // 重新设置按钮选中状态
        setupTypeButtons()
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
    
    private func savePOI() {
        // 这里实现保存逻辑，可以保存到本地或上传到服务器
        let poiName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let poiCategory = selectedType?.category ?? 1
        let poiDescription = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let poiLon = coordinate?.longitude ?? 00.00
        let poiLat = coordinate?.latitude ?? 00.00
        let poiUrlList = imgUrlList
        let userId = UserManager.shared.userId
        if let number = Int(userId) {
            print("转换成功: \(number)")  // 123
            let poiModel = UserPOIModel(name: poiName, description: poiDescription, lon: poiLon, lat: poiLat, category: poiCategory, imgUrlList: poiUrlList, state: 0, userId: number)
            viewModel.saveUserPoi(poiModel)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("操作完成")
                    case .failure(let error):
                        print("发生错误: \(error.localizedDescription)")
                    }
                } receiveValue: { [weak self] data in
                    print("保存结果: \(data)")
                    guard let self = self else { return }
                    if data != nil {
                        self.view.sw_showSuccessToast("保存兴趣点成功")
                    }else {
                        self.view.sw_showSuccessToast("保存兴趣点失败")
                    }
                    self.dismiss(animated: true)
                }
                .store(in: &viewModel.cancellables)
        }
        
        print("保存兴趣点:")
        print("名称: \(poiName)")
        print("类型: \(poiCategory)")
        print("坐标: \(poiLon)--\(poiLat)")
        print("简介: \(poiDescription)")
        print("图片数量: \(poiUrlList.count)")
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
        configuration.selectionLimit = maxImageCount - selectedImages.count
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
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
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
            charCountLabel.textColor = currentCount == 100 ? .red : .secondaryLabel
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
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        
                        self?.selectedImages.append(image)
                        
                        self?.uploadImage(image: image)
                        
                        self?.setupPhotoViews()
                    }
                }
            }
        }
    }
    
    func uploadImage(image: UIImage) {
        uploadService.uploadImage(
            image,
            fileName: "my_photo.jpg",
            compressionQuality: 0.8,
            progressHandler: { _ in
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.isSuccess, let fileUrl = response.data?.fileUrl {
                            print("上传成功！文件URL: \(fileUrl)")
                            self?.imgUrlList.append(fileUrl)
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
}

