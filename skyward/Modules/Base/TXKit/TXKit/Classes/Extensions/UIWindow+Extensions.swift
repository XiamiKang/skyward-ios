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
    
    /// Returns the current navigation controller
    public class func currentNavigationController() -> UINavigationController? {
        let topViewController = self.topViewController()
        return navigationController(of: topViewController)
    }
    
    /// Returns the navigation controller from given view controller's hierarchy.
    public class func navigationController(of viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        return navigationController(of: viewController.parent)
    }
    
    /// Finds a specific view controller type in the current navigation controller's stack
    public class func findViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        guard let navigationController = self.currentNavigationController() else {
            return nil
        }
        
        return findViewController(ofType: type, in: navigationController)
    }
    
    /// Finds a specific view controller type in the given navigation controller's stack
    public class func findViewController<T: UIViewController>(ofType type: T.Type, in navigationController: UINavigationController) -> T? {
        for viewController in navigationController.viewControllers {
            //工程结构是window->navi->tab-moduleVC
            if let tabBarController = viewController as? UITabBarController {
                for child in tabBarController.viewControllers ?? [] {
                    if let target = child as? T {
                        return target
                    }
                }
            }

            if let targetViewController = viewController as? T {
                return targetViewController
            }
        }
        return nil
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
