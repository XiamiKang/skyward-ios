//
//  MaskView.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//


import UIKit

class MaskView: UIView {
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        // 半透明黑色背景
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // 点击背景关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - 显示方法
    func show() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        // 设置全屏尺寸
        frame = window.bounds
        
        // 添加到 window
        window.addSubview(self)
        
        // 动画显示
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    // MARK: - 隐藏方法
    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    // MARK: - 点击事件
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        hide()
    }
}

extension MaskView {
    // 设置背景颜色和透明度
    func setBackground(color: UIColor, alpha: CGFloat) {
        backgroundColor = color.withAlphaComponent(alpha)
    }
    
    // 设置点击背景是否关闭
    func setTapToDismiss(_ enabled: Bool) {
        gestureRecognizers?.forEach { gesture in
            if let tapGesture = gesture as? UITapGestureRecognizer {
                tapGesture.isEnabled = enabled
            }
        }
    }
    
    // 显示动画选项
    func show(with duration: TimeInterval = 0.3, options: UIView.AnimationOptions = []) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        frame = window.bounds
        window.addSubview(self)
        
        alpha = 0
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.alpha = 1
        })
    }
}
