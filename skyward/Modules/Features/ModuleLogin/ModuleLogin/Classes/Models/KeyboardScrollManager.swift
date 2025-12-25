//
//  KeyboardScrollManager.swift
//  Pods
//
//  Created by TXTS on 2025/11/26.
//

import UIKit

class KeyboardScrollManager {
    
    private weak var scrollView: UIScrollView?
    private weak var viewController: UIViewController?
    private var originalContentInset: UIEdgeInsets = .zero
    private var originalContentOffset: CGPoint = .zero // 新增：保存原始偏移量
    
    init(scrollView: UIScrollView, viewController: UIViewController) {
        self.scrollView = scrollView
        self.viewController = viewController
    }
    
    func startObserving() {
        // 保存初始的 contentOffset
        originalContentOffset = scrollView?.contentOffset ?? .zero
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let scrollView = scrollView,
              let view = viewController?.view else {
            return
        }
        
//        let keyboardHeight = keyboardFrame.height
        
        // 计算键盘在scrollView中的位置
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let intersection = scrollView.frame.intersection(keyboardFrameInView)
        
        if intersection.height > 0 {
            originalContentInset = scrollView.contentInset
            originalContentOffset = scrollView.contentOffset // 保存当前偏移量
            
            var contentInset = scrollView.contentInset
            contentInset.bottom = intersection.height + 20 // 加一些额外空间
            scrollView.contentInset = contentInset
            scrollView.scrollIndicatorInsets = contentInset
            
            // 自动滚动到活动输入框
            if let activeField = findActiveTextField() {
                let rect = activeField.convert(activeField.bounds, to: scrollView)
                scrollView.scrollRectToVisible(rect, animated: true)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let scrollView = scrollView,
              let userInfo = notification.userInfo else { return }
        
        // 获取键盘动画的持续时间
        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.3
        
        UIView.animate(withDuration: duration) {
            // 恢复原始的 contentInset
            scrollView.contentInset = self.originalContentInset
            scrollView.scrollIndicatorInsets = self.originalContentInset
            
            // 回滚到初始位置或顶部
            self.scrollToInitialPosition()
        }
    }
    
    // 新增：回滚到初始位置的方法
    private func scrollToInitialPosition() {
        guard let scrollView = scrollView else { return }
        
        // 如果当前偏移量接近顶部，就直接回到顶部
        // 否则回到保存的原始位置
        if scrollView.contentOffset.y < 100 {
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        } else {
            scrollView.setContentOffset(originalContentOffset, animated: true)
        }
    }
    
    // 新增：手动触发回滚的方法（可以在点击其他地方时调用）
    func scrollToTop(animated: Bool = true) {
        guard let scrollView = scrollView else { return }
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: animated)
    }
    
    private func findActiveTextField() -> UIView? {
        return viewController?.view.findFirstResponder()
    }
    
    deinit {
        stopObserving()
    }
}

extension UIView {
    func findFirstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        }
        
        for subview in self.subviews {
            if let firstResponder = subview.findFirstResponder() {
                return firstResponder
            }
        }
        
        return nil
    }
}
