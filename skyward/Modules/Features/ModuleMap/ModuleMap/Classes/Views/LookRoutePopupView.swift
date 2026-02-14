//
//  LookRoutePopupView.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/1/12.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

class LookRoutePopupView: UIView, SWPopupContentView {
    
    // MARK: - UI Components
    
    /// 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontBold(ofSize: 18)
        label.textColor = ThemeManager.current.titleColor
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 关闭按钮
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        button.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let startItemView: RouteItemView = {
        return RouteItemView(title: "起点", value: "--")
    }()
    
    private let endItemView: RouteItemView = {
        return RouteItemView(title: "终点", value: "--")
    }()
    
    private let distanceItemView: RouteItemView = {
        return RouteItemView(title: "距离", value: "--")
    }()
    
    private let durationItemView: RouteItemView = {
        return RouteItemView(title: "时长")
    }()
    
    private let altitudeItemView: RouteItemView = {
        return RouteItemView(title: "最高海拔")
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.textColor
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bottomOperateView: LookRouteOperateView = {
        let operateView = LookRouteOperateView()
        
        return operateView
    }()
    
    
    // MARK: - Properties
    
    var closeHandler: (() -> Void)?
    var deleteHandler: (() -> Void)?
    
    // MARK: - Initialization
    init(route: Route) {
        super.init(frame: .zero)
        setupUI(route: route)
        setupConstraints(route: route)
        
        // 设置路线名称
        if let routeName = route.routeName {
            titleLabel.text = routeName
        }
        
        // 设置起点信息
        if let startDesc = route.startDesc() {
            startItemView.valueLabel.attributedText = startDesc
        }
        
        // 设置终点信息
        if let endDesc = route.endDesc() {
            endItemView.valueLabel.attributedText = endDesc
        }
        
        // 设置距离信息
        if let distance = route.distance {
            distanceItemView.valueLabel.text = "\(String(format: "%.2f", distance))km"
        }
        
        // 设置时长信息
        if let duration = route.travelTime {
            durationItemView.valueLabel.text = "\(duration)秒"
        }
        
        // 设置海拔信息
        if let altitude = route.altitude {
            distanceItemView.valueLabel.text = "\(String(format: "%.2f", altitude))米"
        }
        
        // 设置描述信息
        if let desc = route.description {
            descLabel.text = desc
        }

        debugPrint("startDesc: \(route.startDesc()?.string ?? "") endDesc: \(route.endDesc()?.string ?? "")")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI(route: Route) {
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(startItemView)
        addSubview(endItemView)
        addSubview(distanceItemView)
        if route.type == RouteType.track.rawValue {
            addSubview(durationItemView)
            addSubview(altitudeItemView)
        } else {
            if route.description?.isEmpty == false {
                addSubview(descLabel)
            }
        }
        addSubview(bottomOperateView)
    }
    
    private func setupConstraints(route: Route) {

        titleLabel.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(swAdaptedValue(25))
            $0.top.left.equalToSuperview().inset(Layout.hMargin)
            $0.right.equalToSuperview().inset(32 + 9)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.right.equalToSuperview().inset(swAdaptedValue(9))
            $0.width.height.equalTo(swAdaptedValue(30))
        }
        
        startItemView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        
        endItemView.snp.makeConstraints { make in
            make.top.equalTo(startItemView.snp.bottom).offset(12)
        }
        
        distanceItemView.snp.makeConstraints { make in
            make.top.equalTo(endItemView.snp.bottom).offset(12)
            make.left.equalToSuperview()
        }
        
        if route.type == RouteType.track.rawValue {
            durationItemView.snp.makeConstraints { make in
                // 父视图的水平居中
                make.left.equalToSuperview().inset(ScreenUtil.screenWidth * 0.5)
                make.centerY.equalTo(distanceItemView)
            }
            altitudeItemView.snp.makeConstraints { make in
                make.top.equalTo(distanceItemView.snp.bottom).offset(12)
                make.bottom.equalTo(bottomOperateView.snp.top).offset(-16)
                make.left.equalToSuperview()
            }
        } else {
            if descLabel.superview == nil {
                distanceItemView.snp.remakeConstraints { make in
                    make.top.equalTo(endItemView.snp.bottom).offset(12)
                    make.left.equalToSuperview()
                    make.bottom.equalTo(bottomOperateView.snp.top).offset(-16)
                }
            } else {
                descLabel.snp.makeConstraints { make in
                    make.top.equalTo(distanceItemView.snp.bottom).offset(12)
                    make.bottom.equalTo(bottomOperateView.snp.top).offset(-16)
                    make.left.right.equalToSuperview().inset(Layout.hMargin)
                }
            }
        }
        
        bottomOperateView.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(65))
            make.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom)
            make.left.right.equalToSuperview().inset(Layout.hMargin)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        self.closeHandler?()
    }
    
    @objc private func confirmButtonTapped() {
        SWAlertView.showAlert(title: nil, message: "确定删除该路线吗？") {
            self.deleteHandler?()
        }
    }
}


class LookRouteOperateView: UIStackView {
    
    // MARK: - UI Components
    
    private lazy var deleteButton: UIButton = {
        let button = createOperateButton(imageName: "record_delete_icon", title: "删除")
        button.tag = 0
        return button
    }()
    
    private lazy var editButton: UIButton = {
        let button = createOperateButton(imageName: "route_edit", title: "编辑")
        button.tag = 1
        return button
    }()
    
    private lazy var showButton: UIButton = {
        let button = createOperateButton(imageName: "record_unlook_icon", title: "显示")
        button.tag = 2
        return button
    }()
    
    
    private lazy var uploadButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = ThemeManager.current.mainColor
        button.setImage(MapModule.image(named: "route_upload"), for: .normal)
        button.setTitle("上传", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.layer.masksToBounds = true
        return button
    }()
    
    // MARK: - Properties
    
    var operateHandler: ((Int) -> Void)? // tag: 0=删除, 1=编辑, 2=显示, 3=隐藏, 4=上传
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 16
        
        addButtons()
    }
    
    private func addButtons() {
        addArrangedSubview(deleteButton)
        addArrangedSubview(editButton)
        addArrangedSubview(showButton)
        addArrangedSubview(uploadButton)
        
        editButton.setImage(MapModule.image(named: "record_look_icon"), for: .selected)
        
        // 添加按钮点击事件
        deleteButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        showButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        uploadButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    // MARK: - Helper
    private func createOperateButton(imageName: String, title: String) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .clear
        button.setImage(MapModule.image(named: imageName), for: .normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
        button.titleLabel?.font = .pingFangFontRegular(ofSize: 12)
        button.titleLabel?.textAlignment = .center
        
        // 图片在上，文字在下，并居中对齐
        let spacing: CGFloat = 4
        let imageSize = CGSize(width: 20, height: 20)
        button.titleLabel?.sizeToFit()
        let btnTitleWidth = CGRectGetWidth(button.titleLabel!.bounds)
        
        button.imageEdgeInsets = UIEdgeInsets(
            top: -(imageSize.height + spacing),
            left: 0,
            bottom: 0,
            right: -btnTitleWidth
        )
        
        button.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(imageSize.height + spacing),
            right: 0
        )
        
        button.contentHorizontalAlignment = .center
        button.contentVerticalAlignment = .center
        return button
    }
    
    // MARK: - Actions
    @objc private func buttonTapped(_ sender: UIButton) {
        if sender == uploadButton {
            operateHandler?(4)
        } else {
            operateHandler?(sender.tag)
        }
    }
    
    // MARK: - Public Methods
    
    /// 显示或隐藏上传按钮
    func showUploadButton(_ show: Bool) {
        uploadButton.isHidden = !show
        updateButtonSpacing()
    }
    
    /// 更新按钮宽度和间距
    private func updateButtonSpacing() {
        // 计算可见按钮
        let visibleButtons = arrangedSubviews.filter { !$0.isHidden }
        let buttonCount = visibleButtons.count
        
        if buttonCount == 0 {
            return
        }
        
        // 移除所有现有约束
        for button in visibleButtons {
            button.snp.removeConstraints()
        }
        
        // 计算可用宽度
        let totalWidth = bounds.width
        
        // 检查是否包含上传按钮
        let hasUploadButton = visibleButtons.contains(uploadButton)
        
        if hasUploadButton {
            // 包含上传按钮的情况
            let spacingTotal = CGFloat(buttonCount - 1) * spacing
            let flexibleWidth = (totalWidth - 175 - spacingTotal) / CGFloat(buttonCount - 1)
            
            for button in visibleButtons {
                if button == uploadButton {
                    button.snp.makeConstraints { make in
                        make.width.equalTo(175)
                        make.height.equalTo(48)
                    }
                } else {
                    button.snp.makeConstraints { make in
                        make.width.equalTo(flexibleWidth)
                        make.height.equalTo(48)
                    }
                }
            }
        } else {
            // 不包含上传按钮的情况
            let spacingTotal = CGFloat(buttonCount - 1) * spacing
            let equalWidth = (totalWidth - spacingTotal) / CGFloat(buttonCount)
            
            for button in visibleButtons {
                button.snp.makeConstraints { make in
                    make.width.equalTo(equalWidth)
                    make.height.equalTo(48)
                }
            }
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        updateButtonSpacing()
    }
}
