//
//  POIMsgView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/4.
//

import Foundation

import UIKit

class POIMsgView: UIView {
    
    // MARK: - Properties
    private let triangleHeight: CGFloat = 8
    
    typealias DismissHandler = () -> Void
    typealias AddPOIHandler = () -> Void
    
    var onDismiss: DismissHandler?
    var onAddPOI: AddPOIHandler?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let triangleView: UnderTriangleView = {
        let view = UnderTriangleView()
        view.fillColor = .white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .darkGray
        label.text = "兴趣点信息"
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .gray
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let coordinateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        return label
    }()
    
    private let altitudeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private lazy var addPOIButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("添加兴趣点", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.layer.cornerRadius = 6
        button.addTarget(self, action: #selector(addPOIButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initialization
    init(name: String, coordinate: String, altitude: String) {
        super.init(frame: .zero)
        setupData(name: name, coordinate: coordinate, altitude: altitude)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupData(name: String, coordinate: String, altitude: String) {
        titleLabel.text = name
        coordinateLabel.text = "经纬度: \(coordinate)"
        altitudeLabel.text = "海拔: \(altitude)"
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // 添加视图层级
        addSubview(containerView)
        addSubview(triangleView)
        
        // 容器内部视图
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(coordinateLabel)
        containerView.addSubview(altitudeLabel)
        containerView.addSubview(addPOIButton)
    }
    
    private func setupConstraints() {
        // 启用自动布局
        containerView.translatesAutoresizingMaskIntoConstraints = false
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        coordinateLabel.translatesAutoresizingMaskIntoConstraints = false
        altitudeLabel.translatesAutoresizingMaskIntoConstraints = false
        addPOIButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 三角形约束（在容器下方，正中间）
        NSLayoutConstraint.activate([
            triangleView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            triangleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            triangleView.widthAnchor.constraint(equalToConstant: 16),
            triangleView.heightAnchor.constraint(equalToConstant: triangleHeight)
        ])
        
        // 容器约束
        let containerWidth: CGFloat = 280
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: containerWidth),
            containerView.bottomAnchor.constraint(equalTo: triangleView.topAnchor)
        ])
        
        // 标题和关闭按钮
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // 经纬度标签
        NSLayoutConstraint.activate([
            coordinateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            coordinateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            coordinateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // 海拔标签
        NSLayoutConstraint.activate([
            altitudeLabel.topAnchor.constraint(equalTo: coordinateLabel.bottomAnchor, constant: 8),
            altitudeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            altitudeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
        
        // 添加兴趣点按钮
        NSLayoutConstraint.activate([
            addPOIButton.topAnchor.constraint(equalTo: altitudeLabel.bottomAnchor, constant: 16),
            addPOIButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            addPOIButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            addPOIButton.heightAnchor.constraint(equalToConstant: 40),
            addPOIButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // 设置自身高度
        let totalHeight: CGFloat = 180 // 预估高度
        self.heightAnchor.constraint(equalToConstant: totalHeight + triangleHeight).isActive = true
    }
    
    // MARK: - Button Actions
    @objc private func closeButtonTapped() {
        hide()
    }
    
    @objc private func addPOIButtonTapped() {
        onAddPOI?()
        hide()
    }
    
    // MARK: - Show/Hide
    func show(from view: UIView, at point: CGPoint) {
        // 添加到指定视图
        view.addSubview(self)
        
        // 计算位置，让三角形尖尖指向指定的点
        let containerWidth: CGFloat = 280
        let totalHeight: CGFloat = 180 + triangleHeight
        
        self.frame = CGRect(
            x: point.x - containerWidth / 2, // 水平居中
            y: point.y - totalHeight,        // 在指定点上方显示
            width: containerWidth,
            height: totalHeight
        )
        
        // 添加动画
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 点击空白处隐藏
        if let touch = touches.first {
            let location = touch.location(in: self)
            if !containerView.frame.contains(location) && !triangleView.frame.contains(location) {
                hide()
            }
        }
    }
}

// MARK: - 三角形视图（朝下）
class UnderTriangleView: UIView {
    
    private let triangleLayer = CAShapeLayer()
    
    var fillColor: UIColor = .white {
        didSet {
            triangleLayer.fillColor = fillColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        // 配置三角形图层
        triangleLayer.fillColor = fillColor.cgColor
        triangleLayer.strokeColor = nil
        triangleLayer.lineWidth = 0
        layer.addSublayer(triangleLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTrianglePath()
    }
    
    private func updateTrianglePath() {
        let triangleWidth: CGFloat = bounds.width
        let triangleHeight: CGFloat = bounds.height
        
        let path = UIBezierPath()
        
        if triangleWidth > 0 && triangleHeight > 0 {
            // 绘制朝下的三角形
            // 点1：左上角
            let point1 = CGPoint(x: 0, y: 0)
            // 点2：底部中点（尖尖）
            let point2 = CGPoint(x: triangleWidth / 2, y: triangleHeight)
            // 点3：右上角
            let point3 = CGPoint(x: triangleWidth, y: 0)
            
            path.move(to: point1)
            path.addLine(to: point2)
            path.addLine(to: point3)
            path.close()
        }
        
        triangleLayer.path = path.cgPath
    }
}


