//
//  SOSAlertView.swift
//  Pods
//
//  Created by TXTS on 2026/3/23.
//


import UIKit
import SWTheme

public class SOSAlertView: UIView {

    // MARK: - UI Components
    private let backgroundMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let sosImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // 设置SOS图标 - 使用系统图标
        if let sosImage = SWKitModule.image(named: "SOS") {
            imageView.image = sosImage
        }
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SOS状态确认"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.text = "为了确保您的安全，请确认是否继续开启SOS？"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UIColor(str: "#303236")
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("关闭SOS", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = ThemeManager.current.mediumGrayBGColor
        button.layer.cornerRadius = 6
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("继续开启", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ThemeManager.current.mainColor
        button.layer.cornerRadius = 6
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        addSubview(backgroundMaskView)
        addSubview(containerView)

        containerView.addSubview(sosImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(cancelButton)
        containerView.addSubview(confirmButton)

        NSLayoutConstraint.activate([
            // 蒙板铺满整个视图
            backgroundMaskView.topAnchor.constraint(equalTo: topAnchor),
            backgroundMaskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundMaskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // 容器视图居中，宽度为屏幕宽度的80%，最大宽度400
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),

            // SOS ImageView
            sosImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            sosImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            sosImageView.widthAnchor.constraint(equalToConstant: 72),
            sosImageView.heightAnchor.constraint(equalToConstant: 72),

            // 标题
            titleLabel.topAnchor.constraint(equalTo: sosImageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // 内容
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // 并排按钮
            cancelButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 24),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),

            confirmButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 24),
            confirmButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            confirmButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 40),
            confirmButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 12),
            confirmButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
        ])

        // 添加按钮点击事件
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        SOSManager.shared.closeSOSState()
        BluetoothManager.shared.closeSOS()
        hide()
    }

    @objc private func confirmButtonTapped() {
        hide()
    }

    // MARK: - Public Methods
    /// 显示在指定的Window上
    public func showInWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        frame = window.bounds
        window.addSubview(self)
        
        // 添加动画效果
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }
    
    /// 显示在指定的View上
    public func show(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }

    public func hide() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

