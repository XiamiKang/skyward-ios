//
//  UIWindow+Extensions.swift
//
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024 Longfor. All rights reserved.
//

import UIKit

extension UIWindow {
    
    /// 顶部Window
    public static var topWindow: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first
        if let windowScene = scene as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        return nil
    }
    
    /// Returns the top most controller
    public class func topViewController() -> UIViewController? {
        let window = UIApplication.shared.delegate?.window
        let rootViewController = window??.rootViewController
        return topMost(of: rootViewController)
    }
    
    /// Returns the top most view controller from given view controller's stack.
    public class func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        return viewController
    }
}
