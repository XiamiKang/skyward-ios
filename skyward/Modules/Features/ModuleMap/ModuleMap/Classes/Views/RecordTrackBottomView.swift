//
//  RecordTrackBottomView.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/2.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme

class RecordTrackBottomView: UIView {
    
    var endRecordHandler: (() -> Void)?
    var startRecordHandler: (() -> Void)?

    // MARK: - UI Components

    /// 顶部数据容器
    private lazy var dataStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 20
        return stack
    }()

    /// 距离卡片
    private lazy var distanceCard: MetricCardView = {
        let card = MetricCardView(title: "距离", value: "0.00km")
        return card
    }()

    /// 时长卡片
    private lazy var durationCard: MetricCardView = {
        let card = MetricCardView(title: "时长", value: "00:00:00")
        return card
    }()

    /// 当前海拔卡片
    private lazy var altitudeCard: MetricCardView = {
        let card = MetricCardView(title: "当前海拔", value: "--")
        return card
    }()

    /// 记录按钮
    private lazy var recordButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("开始记录", for: .normal)
        button.setTitle("结束记录", for: .selected)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
        button.backgroundColor = ThemeManager.current.mainColor
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .black.alpha(0.8)
        layer.cornerRadius = CornerRadius.large.rawValue
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        // 添加子视图
        addSubview(dataStackView)
        addSubview(recordButton)

        // 配置数据卡片
        dataStackView.addArrangedSubview(distanceCard)
        dataStackView.addArrangedSubview(durationCard)
        dataStackView.addArrangedSubview(altitudeCard)
    }

    private func setupConstraints() {
        dataStackView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(Layout.hMargin)
        }

        recordButton.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.equalTo(dataStackView.snp.bottom).offset(Layout.vMargin)
            make.left.right.equalToSuperview().inset(Layout.hMargin)
        }
    }

    // MARK: - Actions

    @objc private func recordButtonTapped() {
        let isRecording = recordButton.isSelected
        if isRecording {
            // 结束记录
            endRecordHandler?()
        } else {
            // 开始记录
            startRecordHandler?()
        }
        recordButton.isSelected = !isRecording
    }

    // MARK: - Public Methods

    /// 更新距离显示
    func updateDistance(_ distance: String) {
        distanceCard.configure(value: distance)
    }

    /// 更新时长显示
    func updateDuration(_ duration: String) {
        durationCard.configure(value: duration)
    }

    /// 更新海拔显示
    func updateAltitude(_ altitude: String) {
        altitudeCard.configure(value: altitude)
    }
    
    func clean() {
        distanceCard.configure(value: "0.00km")
        durationCard.configure(value: "00:00:00")
        altitudeCard.configure(value: "--")
        recordButton.isSelected = false
    }
}

// MARK: - MetricCardView

/// 指标卡片视图
private class MetricCardView: UIView {

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .pingFangFontMedium(ofSize: 16)
        label.textAlignment = .center
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(str: "#A0A3A7")
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    init(title: String, value: String? = nil) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        
        titleLabel.text = title
        valueLabel.text = value
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(valueLabel)
        addSubview(titleLabel)
    }
    
    private func setupConstraints() {
        valueLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(22))
            make.top.left.right.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(18))
            make.top.equalTo(valueLabel.snp.bottom).offset(swAdaptedValue(4))
            make.bottom.left.right.equalToSuperview()
        }
    }

    func configure(value: String) {
        valueLabel.text = value
    }
}
