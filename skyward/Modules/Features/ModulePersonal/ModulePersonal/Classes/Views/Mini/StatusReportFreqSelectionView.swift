//
//  StatusReportFreqSelectionView.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/20.
//

import UIKit
import SWKit

class StatusReportFreqSelectionView: UIView {
    
    weak var delegate: StatusReportFreqSelectionViewDelegate?
    private var selectedFreq: String = "常规模式（2分钟）"
    
    private let options = StatusReportFreqHelper.allOptions
    private var optionButtons: [UIButton] = []
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "设备参数更新频率"
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
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        createOptionButtons()
        setupConstraints()
    }
    
    private func createOptionButtons() {
        for (index, option) in options.enumerated() {
            let button = createOptionButton(title: option)
            button.tag = index
            button.addTarget(self, action: #selector(optionButtonTapped(_:)), for: .touchUpInside)
            optionButtons.append(button)
            contentView.addSubview(button)
        }
    }
    
    private func createOptionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor(hex: "#070808")
        
        let checkmarkImageView = UIImageView()
        checkmarkImageView.image = PersonalModule.image(named: "default_selected")
        checkmarkImageView.isHidden = true
        checkmarkImageView.tag = 100
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(checkmarkImageView)
        
        button.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 0),
            stackView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        return button
    }
    
    // 在 StatusReportFreqSelectionView 中添加完整的约束设置
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 350),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 设置选项按钮的约束
        var previousButton: UIButton?
        for button in optionButtons {
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            if let previous = previousButton {
                button.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 12).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
            }
            
            previousButton = button
        }
        
        if let lastButton = optionButtons.last {
            lastButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16).isActive = true
        }
    }
    
    // 在 StatusReportFreqSelectionView 中添加显示和隐藏方法
    func show(in view: UIView, currentFreq: UInt8) {
        self.selectedFreq = StatusReportFreqHelper.freqString(from: currentFreq)
        updateSelectionUI()
        
        frame = view.bounds
        view.addSubview(self)
        
        containerView.transform = CGAffineTransform(translationX: 0, y: 350)
        alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 350)
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
    
    private func updateSelectionUI() {
        for button in optionButtons {
            if let stackView = button.subviews.first as? UIStackView,
               let titleLabel = stackView.arrangedSubviews.first as? UILabel,
               let checkmark = stackView.arrangedSubviews.last as? UIImageView {
                
                let buttonTitle = titleLabel.text ?? ""
                checkmark.isHidden = buttonTitle != selectedFreq
            }
        }
    }
    
    @objc private func optionButtonTapped(_ sender: UIButton) {
        selectedFreq = options[sender.tag]
        updateSelectionUI()
        
        var reportData = Data()
        switch sender.tag {
        case 0:
            reportData.append(0) // 查询上报
        case 1:
            reportData.append(60) // 1分钟
        case 2:
            reportData.append(120) // 2分钟
        case 3:
            reportData.append(240) // 4分钟
        default:
            reportData.append(240)  // 默认4分钟
        }
        BluetoothManager.shared.sendCommand(.setStatusReportTime, messageContent: reportData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            let freqValue = StatusReportFreqHelper.freqValue(from: self.selectedFreq)
            self.delegate?.didSelectStatusReportFreq(freqValue)
            self.hide()
        }
    }
    
    @objc private func closeButtonTapped() {
        hide()
    }
    
}

protocol StatusReportFreqSelectionViewDelegate: AnyObject {
    func didSelectStatusReportFreq(_ freq: UInt8)
}
