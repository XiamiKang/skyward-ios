//
//  CustomPresentationController.swift
//  yifan_test
//
//  Created by TXTS on 2025/12/2.
//

import UIKit

class CustomPresentationController: UIPresentationController {
    
    private let presentationHeight: CGFloat
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    private var keyboardHeight: CGFloat = 0
    private var isKeyboardVisible = false
    
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         heightPercentage: CGFloat = 0.7) {
        self.presentationHeight = UIScreen.main.bounds.height * heightPercentage
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        // 监听键盘
        setupKeyboardObservers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        keyboardHeight = keyboardFrame.height
        isKeyboardVisible = true
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
            // 强制更新布局
            self.containerView?.setNeedsLayout()
            self.containerView?.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        keyboardHeight = 0
        isKeyboardVisible = false
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: UIView.AnimationOptions(rawValue: animationCurve)) {
            self.containerView?.setNeedsLayout()
            self.containerView?.layoutIfNeeded()
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        
        let screenHeight = containerView.bounds.height
        
        // 如果有键盘，调整高度
        let finalHeight: CGFloat
        if isKeyboardVisible {
            // 当键盘显示时，让控制器几乎占据整个屏幕
            finalHeight = screenHeight - keyboardHeight - 50 // 留出一些顶部空间
        } else {
            finalHeight = presentationHeight
        }
        
        let yPosition = screenHeight - finalHeight
        
        return CGRect(
            x: 0,
            y: yPosition,
            width: containerView.bounds.width,
            height: finalHeight
        )
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        
        // 添加上方圆角
        presentedView?.layer.cornerRadius = 12
        presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView?.layer.masksToBounds = true
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerView = containerView else { return }
        
        // 添加遮罩视图
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)
        
        // 动画显示遮罩
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 1
        })
    }
    
    @objc private func handleTap() {
        presentedViewController.dismiss(animated: true)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        // 动画隐藏遮罩
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 0
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        
        if completed {
            dimmingView.removeFromSuperview()
        }
    }
}

// CustomTransitioningDelegate.swift
class CustomTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    let heightPercentage: CGFloat
    
    init(heightPercentage: CGFloat = 0.7) {
        self.heightPercentage = heightPercentage
        super.init()
    }
    
    func presentationController(forPresented presented: UIViewController,
                               presenting: UIViewController?,
                               source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            heightPercentage: heightPercentage
        )
    }
}
