//
//  ProfileChangeAvatarView.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/19.
//

import Foundation
import UIKit
import SWKit

protocol AvatarModeSelectionViewDelegate: AnyObject {
    func didSelectAvatarMode(_ mode: String)
}

class AvatarModeSelectionView: UIView {
    
    weak var delegate: AvatarModeSelectionViewDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "更换头像"
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
    
    private lazy var cameraView: UIView = {
        let view = createModeView(imageStr: "profile_cell_camera", title: "拍照", tag: 0)
        return view
    }()
    
    private lazy var photoView: UIView = {
        let view = createModeView(imageStr: "profile_cell_photo", title: "从相册上传", tag: 1)
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
        containerView.addSubview(cameraView)
        containerView.addSubview(photoView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        photoView.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            cameraView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            cameraView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cameraView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            cameraView.heightAnchor.constraint(equalToConstant: 50),
            
            photoView.topAnchor.constraint(equalTo: cameraView.bottomAnchor, constant: 16),
            photoView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            photoView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            photoView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func createModeView(imageStr: String, title: String, tag: Int) -> UIView {
        let view = UIView()
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.tag = tag
        button.addTarget(self, action: #selector(modeButtonTapped(_:)), for: .touchUpInside)
        
        let imageView = UIImageView()
        imageView.image = PersonalModule.image(named: imageStr)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor(hex: "#070808")
        
        let nextImageView = UIImageView()
        nextImageView.image = PersonalModule.image(named: "default_next")
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(nextImageView)
        view.addSubview(button)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        nextImageView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            
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
        let modes = [0: "相机", 1: "相册"]
        let chooseModel = modes[sender.tag] ?? "相册"
        self.delegate?.didSelectAvatarMode(chooseModel)
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
