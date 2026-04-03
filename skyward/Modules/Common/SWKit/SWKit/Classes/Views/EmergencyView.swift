//
//  EmergencyView.swift
//  Pods
//
//  Created by TXTS on 2026/3/22.
//


import UIKit

class EmergencyView: UIView {
    
    // 渐变层
    private var gradientLayer: CAGradientLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        setupGradientLayer()
    }
    
    private func setupGradientLayer() {
        let gradient = CAGradientLayer()
        layer.addSublayer(gradient)
        gradientLayer = gradient
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBorderGradient()
    }
    
    private func updateBorderGradient() {
        guard let gradientLayer = gradientLayer else { return }
        
        let bounds = self.bounds
        let borderWidth: CGFloat = 28
        
        // 清除旧的子层
        gradientLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // 创建四个方向的渐变
        // 上边缘
        let topGradient = CAGradientLayer()
        topGradient.frame = bounds
        topGradient.colors = [
            UIColor.red.withAlphaComponent(0.5).cgColor,
            UIColor.red.withAlphaComponent(0.2).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        topGradient.locations = [0, 0.5, 1]
        topGradient.startPoint = CGPoint(x: 0.5, y: 0)
        topGradient.endPoint = CGPoint(x: 0.5, y: borderWidth / bounds.height)
        gradientLayer.addSublayer(topGradient)
        
        // 下边缘
        let bottomGradient = CAGradientLayer()
        bottomGradient.frame = bounds
        bottomGradient.colors = [
            UIColor.red.withAlphaComponent(0.5).cgColor,
            UIColor.red.withAlphaComponent(0.2).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        bottomGradient.locations = [0, 0.5, 1]
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 1)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1 - borderWidth / bounds.height)
        gradientLayer.addSublayer(bottomGradient)
        
        // 左边缘
        let leftGradient = CAGradientLayer()
        leftGradient.frame = bounds
        leftGradient.colors = [
            UIColor.red.withAlphaComponent(0.5).cgColor,
            UIColor.red.withAlphaComponent(0.2).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        leftGradient.locations = [0, 0.5, 1]
        leftGradient.startPoint = CGPoint(x: 0, y: 0.5)
        leftGradient.endPoint = CGPoint(x: borderWidth / bounds.width, y: 0.5)
        gradientLayer.addSublayer(leftGradient)
        
        // 右边缘
        let rightGradient = CAGradientLayer()
        rightGradient.frame = bounds
        rightGradient.colors = [
            UIColor.red.withAlphaComponent(0.5).cgColor,
            UIColor.red.withAlphaComponent(0.2).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        rightGradient.locations = [0, 0.5, 1]
        rightGradient.startPoint = CGPoint(x: 1, y: 0.5)
        rightGradient.endPoint = CGPoint(x: 1 - borderWidth / bounds.width, y: 0.5)
        gradientLayer.addSublayer(rightGradient)
        
        // 添加四个角的渐变
        addCornerGradients(to: gradientLayer, bounds: bounds, borderWidth: borderWidth)
        
        // 设置整体遮罩
        setupMaskLayer(borderWidth: borderWidth)
    }
    
    private func addCornerGradients(to parentLayer: CAGradientLayer, bounds: CGRect, borderWidth: CGFloat) {
        let cornerSize = borderWidth * 1.2
        
        // 左上角
        let topLeftCorner = CAGradientLayer()
        topLeftCorner.frame = CGRect(x: 0, y: 0, width: cornerSize * 2, height: cornerSize * 2)
        topLeftCorner.colors = [
            UIColor.red.withAlphaComponent(0.3).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        topLeftCorner.locations = [0, 0.5, 1]
        topLeftCorner.startPoint = CGPoint(x: 0, y: 0)
        topLeftCorner.endPoint = CGPoint(x: 1, y: 1)
        parentLayer.addSublayer(topLeftCorner)
        
        // 右上角
        let topRightCorner = CAGradientLayer()
        topRightCorner.frame = CGRect(x: bounds.width - cornerSize * 2, y: 0, width: cornerSize * 2, height: cornerSize * 2)
        topRightCorner.colors = [
            UIColor.red.withAlphaComponent(0.3).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        topRightCorner.locations = [0, 0.5, 1]
        topRightCorner.startPoint = CGPoint(x: 1, y: 0)
        topRightCorner.endPoint = CGPoint(x: 0, y: 1)
        parentLayer.addSublayer(topRightCorner)
        
        // 左下角
        let bottomLeftCorner = CAGradientLayer()
        bottomLeftCorner.frame = CGRect(x: 0, y: bounds.height - cornerSize * 2, width: cornerSize * 2, height: cornerSize * 2)
        bottomLeftCorner.colors = [
            UIColor.red.withAlphaComponent(0.3).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        bottomLeftCorner.locations = [0, 0.5, 1]
        bottomLeftCorner.startPoint = CGPoint(x: 0, y: 1)
        bottomLeftCorner.endPoint = CGPoint(x: 1, y: 0)
        parentLayer.addSublayer(bottomLeftCorner)
        
        // 右下角
        let bottomRightCorner = CAGradientLayer()
        bottomRightCorner.frame = CGRect(x: bounds.width - cornerSize * 2, y: bounds.height - cornerSize * 2, width: cornerSize * 2, height: cornerSize * 2)
        bottomRightCorner.colors = [
            UIColor.red.withAlphaComponent(0.3).cgColor,
            UIColor.red.withAlphaComponent(0).cgColor
        ]
        bottomRightCorner.locations = [0, 0.5, 1]
        bottomRightCorner.startPoint = CGPoint(x: 1, y: 1)
        bottomRightCorner.endPoint = CGPoint(x: 0, y: 0)
        parentLayer.addSublayer(bottomRightCorner)
    }
    
    private func setupMaskLayer(borderWidth: CGFloat) {
        let bounds = self.bounds
        let screenRadius = getScreenCornerRadius()
        
        // 创建外部路径
        let outerPath = UIBezierPath(roundedRect: bounds, cornerRadius: screenRadius)
        
        // 创建内部路径
        let insetRect = bounds.insetBy(dx: borderWidth, dy: borderWidth)
        let innerRadius = max(0, screenRadius - borderWidth + 5)
        let innerPath = UIBezierPath(roundedRect: insetRect, cornerRadius: innerRadius)
        
        // 组合成环形路径
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        
        let combinedPath = UIBezierPath()
        combinedPath.append(outerPath)
        combinedPath.append(innerPath)
        maskLayer.path = combinedPath.cgPath
        
        // 应用遮罩
        self.layer.mask = maskLayer
        gradientLayer?.mask = maskLayer
    }
    
    private func getScreenCornerRadius() -> CGFloat {
        let screenSize = UIScreen.main.bounds.size
        let minSize = min(screenSize.width, screenSize.height)
        
        switch minSize {
        case 375: return 40
        case 390: return 47
        case 393: return 47
        case 428: return 53
        case 320: return 35
        default: return 45
        }
    }
    
    // MARK: - Animation
    func startFlashing() {
        let flashAnimation = CABasicAnimation(keyPath: "opacity")
        flashAnimation.fromValue = 0.4
        flashAnimation.toValue = 1.0
        flashAnimation.duration = 0.7
        flashAnimation.autoreverses = true
        flashAnimation.repeatCount = .infinity
        flashAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer.add(flashAnimation, forKey: "flashAnimation")
    }
    
    func stopFlashing() {
        layer.removeAllAnimations()
    }
}
