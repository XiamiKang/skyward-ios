//
//  WorkModeSelectionView.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/20.
//

import UIKit
import SWKit

protocol WorkModeSelectionViewDelegate: AnyObject {
    func didSelectWorkMode(_ mode: UInt8)
}

class WorkModeSelectionView: UIView {
    
    weak var delegate: WorkModeSelectionViewDelegate?
    private var selectedMode: String = "工作模式"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "设备模式"
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
    
    private lazy var workModeButton: UIButton = {
        let button = createModeButton(title: "工作模式")
        button.tag = 1
        button.addTarget(self, action: #selector(modeButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var standbyModeButton: UIButton = {
        let button = createModeButton(title: "待机模式")
        button.tag = 0
        button.addTarget(self, action: #selector(modeButtonTapped(_:)), for: .touchUpInside)
        return button
    }()
    
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
        containerView.addSubview(workModeButton)
        containerView.addSubview(standbyModeButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        workModeButton.translatesAutoresizingMaskIntoConstraints = false
        standbyModeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 240),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            workModeButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            workModeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            workModeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            workModeButton.heightAnchor.constraint(equalToConstant: 50),
            
            standbyModeButton.topAnchor.constraint(equalTo: workModeButton.bottomAnchor, constant: 16),
            standbyModeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            standbyModeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            standbyModeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createModeButton(title: String) -> UIButton {
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
    
    func show(in view: UIView, currentMode: UInt8) {
        self.selectedMode = WorkModeHelper.modeString(from: currentMode)
        updateSelectionUI()
        
        frame = view.bounds
        view.addSubview(self)
        
        // 动画显示
        containerView.transform = CGAffineTransform(translationX: 0, y: 240)
        alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    private func updateSelectionUI() {
        // 更新所有按钮的选中状态
        let buttons = [workModeButton, standbyModeButton]
        
        for button in buttons {
            if let stackView = button.subviews.first as? UIStackView,
               let checkmark = stackView.arrangedSubviews.last as? UIImageView {
                
                let buttonTitle = (stackView.arrangedSubviews.first as? UILabel)?.text ?? ""
                checkmark.isHidden = buttonTitle != selectedMode
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        hide()
    }
    
    @objc private func modeButtonTapped(_ sender: UIButton) {
        let modes = [0: "待机模式", 1: "工作模式"]
        selectedMode = modes[sender.tag] ?? "工作模式"
        updateSelectionUI()
        
        var workModeData = Data()
        if sender.tag == 0 {
            workModeData.append(0x00) // 待机模式
        }else {
            workModeData.append(0x01) // 工作模式
        }
        BluetoothManager.shared.sendCommand(.setWorkMode, messageContent: workModeData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            let modeValue = WorkModeHelper.modeValue(from: self.selectedMode)
            self.delegate?.didSelectWorkMode(modeValue)
            self.hide()
        }
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 240)
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
