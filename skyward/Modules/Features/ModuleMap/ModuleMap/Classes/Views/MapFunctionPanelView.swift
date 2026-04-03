//
//  MapFunctionPanelView.swift
//  ModuleMap
//
//  Created by Claude on 2026/2/11.
//

import UIKit
import SWKit
import SWTheme

/// 地图功能按钮类型
enum MapFunctionType: CaseIterable {
    case weather          // 天气
    case measure          // 测距
    case layers           // 图层
    case compass          // 指北
    case location         // 定位
    case safety           // 报平安
    case sos              // SOS

    var imageName: String {
        switch self {
        case .weather: return "map_weather"
        case .measure: return "map_distance"
        case .layers: return "map_layers"
        case .compass: return "map_compass"
        case .location: return "map_myLocation"
        case .safety: return "map_safe"
        case .sos: return "map_sos"
        }
    }

    /// 是否为圆形按钮（保平安和SOS）
    var isCircular: Bool {
        switch self {
        case .safety, .sos: return true
        default: return false
        }
    }
}

/// 地图功能按钮面板
class MapFunctionPanelView: UIStackView {

    // MARK: - Callbacks

    var onButtonTapped: ((MapFunctionType) -> Void)?
    var onSOSLongPressTriggered: (() -> Void)?

    // MARK: - Properties

    private var functionButtons: [MapFunctionType: UIButton] = [:]

    private let buttonSize: CGFloat = swAdaptedValue(44)
    private let buttonSpacing: CGFloat = swAdaptedValue(10)

    // SOS 长按相关
    private var sosLongPressTimer: Timer?
    private var sosPressStartTime: Date?
    private let sosLongPressDuration: TimeInterval = 3.0

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        axis = .vertical
        spacing = buttonSpacing
        alignment = .trailing
        distribution = .equalSpacing
    }

    // MARK: - Public Methods

    /// 配置功能按钮
    /// - Parameter types: 按钮类型数组，按顺序从上到下排列
    func configure(types: [MapFunctionType]) {
        // 清除现有按钮
        functionButtons.values.forEach { $0.removeFromSuperview() }
        functionButtons.removeAll()

        // 创建按钮
        for type in types {
            let button = createButton(type: type)
            functionButtons[type] = button
            addArrangedSubview(button)
        }
    }

    /// 显示/隐藏指定类型的按钮
    func setButtonHidden(_ type: MapFunctionType, isHidden: Bool) {
        functionButtons[type]?.isHidden = isHidden
    }

    /// 更新按钮状态
    /// - Parameters:
    ///   - type: 按钮类型
    ///   - isSelected: 是否选中
    func updateButtonState(_ type: MapFunctionType, isSelected: Bool) {
        guard let button = functionButtons[type] else { return }
        button.isSelected = isSelected
        button.backgroundColor = isSelected ? ThemeManager.current.mainColor : .white

        // 更新图标颜色
        if let icon = button.subviews.first as? UIImageView {
            icon.tintColor = isSelected ? .white : ThemeManager.current.titleColor
        }
    }

    // MARK: - Private Methods

    private func createButton(type: MapFunctionType) -> UIButton {
        let button = UIButton()
        button.backgroundColor = .white

        // 统一尺寸
        button.snp.makeConstraints { make in
            make.width.height.equalTo(buttonSize)
        }

        // 圆角
        button.cornerRadius = type.isCircular ? buttonSize * 0.5 : CornerRadius.medium.rawValue

        // 添加图标
        button.setImage(MapModule.image(named: type.imageName), for: .normal)

        // SOS按钮添加长按手势
        if type == .sos {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSOSLongPress(_:)))
            longPressGesture.minimumPressDuration = 0.1
            button.addGestureRecognizer(longPressGesture)
        } else {
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        }

        // 存储类型标识
        button.tag = type.hashValue

        return button
    }

    // MARK: - SOS 长按处理

    @objc private func handleSOSLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let _ = functionButtons[.sos] else { return }

        switch gesture.state {
        case .began:
            sosPressStartTime = Date()
            startSOSLongPressTimer()
            updateSOSButtonUI(isPressed: true)

        case .changed:
            updateSOSProgress()

        case .ended, .cancelled, .failed:
            cancelSOSLongPress()
            updateSOSButtonUI(isPressed: false)

        default:
            break
        }
    }

    private func startSOSLongPressTimer() {
        sosLongPressTimer?.invalidate()
        sosLongPressTimer = Timer.scheduledTimer(withTimeInterval: sosLongPressDuration, repeats: false) { [weak self] _ in
            self?.triggerSOS()
        }
    }

    private func updateSOSProgress() {
        guard let startTime = sosPressStartTime else { return }
        let elapsedTime = Date().timeIntervalSince(startTime)
        let progress = min(elapsedTime / sosLongPressDuration, 1.0)

        if let button = functionButtons[.sos] {
            button.alpha = 0.5 + (progress * 0.5)
        }
    }

    private func cancelSOSLongPress() {
        sosLongPressTimer?.invalidate()
        sosLongPressTimer = nil
        sosPressStartTime = nil
        functionButtons[.sos]?.alpha = 1.0
    }

    private func triggerSOS() {
        updateSOSButtonUI(isPressed: false)
        onSOSLongPressTriggered?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.functionButtons[.sos]?.alpha = 1.0
        }
    }

    private func updateSOSButtonUI(isPressed: Bool) {
        guard let button = functionButtons[.sos] else { return }
        UIView.animate(withDuration: 0.2) {
            button.transform = isPressed ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
            button.backgroundColor = isPressed ? UIColor.systemRed.withAlphaComponent(0.8) : .white
        }
    }

    // MARK: - Actions

    @objc private func buttonTapped(_ sender: UIButton) {
        for (type, button) in functionButtons {
            if button == sender {
                onButtonTapped?(type)
                break
            }
        }
    }
}
