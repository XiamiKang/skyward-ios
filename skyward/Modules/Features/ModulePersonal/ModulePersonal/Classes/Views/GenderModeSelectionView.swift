//
//  ProfileChangeAvatarView.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/19.
//

import Foundation
import UIKit
import SWKit

protocol GenderModeSelectionViewDelegate: AnyObject {
    func didSelectGenderMode(_ mode: Int)
}

class GenderModeSelectionView: UIView {
    
    weak var delegate: GenderModeSelectionViewDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "性别选择"
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
    
    private lazy var manView: UIView = {
        let view = createModeView(title: "男", tag: 1)
        return view
    }()
    
    private lazy var womanView: UIView = {
        let view = createModeView(title: "女", tag: 2)
        return view
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
        containerView.addSubview(manView)
        containerView.addSubview(womanView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        manView.translatesAutoresizingMaskIntoConstraints = false
        womanView.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            manView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            manView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            manView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            manView.heightAnchor.constraint(equalToConstant: 50),
            
            womanView.topAnchor.constraint(equalTo: manView.bottomAnchor, constant: 16),
            womanView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            womanView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            womanView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createModeView(title: String, tag: Int) -> UIView {
        let view = UIView()
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.tag = tag
        button.addTarget(self, action: #selector(modeButtonTapped(_:)), for: .touchUpInside)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor(hex: "#070808")
        
        let nextImageView = UIImageView()
        nextImageView.image = PersonalModule.image(named: "default_next")
        
        view.addSubview(titleLabel)
        view.addSubview(nextImageView)
        view.addSubview(button)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        nextImageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            nextImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            nextImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextImageView.widthAnchor.constraint(equalToConstant: 16),
            nextImageView.heightAnchor.constraint(equalToConstant: 16),
            
            button.topAnchor.constraint(equalTo: view.topAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        return view
    }
    
    func show(in view: UIView) {
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
    
    @objc private func closeButtonTapped() {
        hide()
    }
    
    @objc private func modeButtonTapped(_ sender: UIButton) {
        self.delegate?.didSelectGenderMode(sender.tag)
        self.hide()
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
