//
//  BaseNavigationViewController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import UIKit

open class BaseNavigationViewController: UINavigationController, UIGestureRecognizerDelegate {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        interactivePopGestureRecognizer?.delegate = self
        // 确保导航控制器视图有背景色
        view.backgroundColor = .white
    }
    
    // MARK: - Orientation
    open override var shouldAutorotate: Bool {
        return self.topViewController?.shouldAutorotate ?? false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.topViewController?.supportedInterfaceOrientations ?? .portrait
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
    
    // MARK: - Custom Push Action
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = false
        super.pushViewController(viewController, animated: animated)
    }
}


extension BaseNavigationViewController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        if viewControllers.count > 1 {
            interactivePopGestureRecognizer?.isEnabled = true
        } else {
            interactivePopGestureRecognizer?.isEnabled = false
        }
    }
}
