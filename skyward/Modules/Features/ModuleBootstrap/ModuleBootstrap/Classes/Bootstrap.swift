//
//  Bootstrap.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

/**
 启动导航的管理
 有广告， 启动页->闪屏流程->主流程
 无广告， 启动页->闪屏流程->广告屏流程->主流程
 */

import TXKit
import SWKit
import ModuleLogin

final public class Bootstrap {
    
    private init() {
        
        // 暂时这样写
        setupNotifications()
    }
    
    public static let shared = Bootstrap()
    
    /// App使用的window
    public weak var window: UIWindow? = nil

    
    public func runSplashFlow() {
        switchRootVC(animated: true) {
            self.window?.rootViewController = self.rootVC()
        }
    }
    
    public func runAdFlow() {
        switchRootVC(animated: true) {
            self.window?.rootViewController = self.rootVC()
        }
    }
    
    public func runLoginFlow() {
        switchRootVC(animated: true) {
            self.window?.rootViewController = self.loginVC()
        }
    }
    
    public func runMainFlow() {
        switchRootVC(animated: true) {
            if UserManager.shared.isLogin {
                self.window?.rootViewController = self.rootVC()
            } else {
                self.window?.rootViewController = self.loginVC()
            }
            
        }
    }
    
    
    func loginVC() -> UIViewController {
        let launchVC = LaunchViewController()
        let navi = BaseNavigationViewController(rootViewController: launchVC)
        return navi
    }
    
    func rootVC() -> UIViewController {
//        let isFirstAppRun = true // 是否第一次运行App， 是则进入登录页 （后期token过期也走登录页）
//        var isNeedShowGuide = false // 是否需要显示引导页
        let tabVC = TabBarController(1000)
        let navi = BaseNavigationViewController(rootViewController: tabVC)
        return navi
    }
    
    
    /// 增加切换rootVC的过度动画
    /// - Parameters:
    ///   - animated: 是否有动画，默认没有动画
    ///   - completion: 动画完成
    private func switchRootVC(animated: Bool = false,
                              needSwitch: @escaping (()->Void),
                              completion: (()->Void)? = nil) {
        guard animated else {
            needSwitch()
            completion?()
            return
        }
        
        guard let window = self.window else {
            needSwitch()
            completion?()
            return
        }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            let oldState = UIView.areAnimationsEnabled
            UIView.setAnimationsEnabled(false)
            needSwitch()
            UIView.setAnimationsEnabled(oldState)
        }, completion: { _ in
            completion?()
        })
    }
    
    // MARK: - Notification
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStatusInfoUpdate(_:)),
            name: .loginSuccess,
            object: nil
        )
    }
    
    @objc private func handleStatusInfoUpdate(_ notification: Notification) {
        DispatchQueue.main.async {
            self.runMainFlow()
        }
    }
}

