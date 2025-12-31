//
//  AppDelegate.swift
//  skyward
//
//  Created by 赵波 on 2025/11/11.
//

import TXKit
import TXRouterKit
import SWKit
import ModuleBootstrap
import ModuleHome
import ModulePersonal
import ModuleMap
import ModuleMessage
import ModuleTeam
import ModuleLogin
import SWNetwork

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // MARK: - Config && Process
    /// 配置所有的应用模块
    func setupModules() -> [ModuleType] {
        return [HomeModule(), MapModule(), MessageModule(),  PersonalModule(), TeamModule(), LoginModule()]
    }
    /// 配置所有的服务
    func setupServices() -> [AppServiceType] {
        return []
    }
    
    // MARK: - Lazy
    private lazy var _sortedServices: [AppServiceType] = {
        return self.setupServices().sorted { left, right in
            return left.priority.rawValue > right.priority.rawValue
        }
    }()
    
}


// MARK: - Life Cycle
extension AppDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        for service in _sortedServices {
            service.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        // 模块初始化
        self.setupModules().forEach{ module in
            module.moduleSetup()
            Router.default.registe(module.routeSettings)
        }
        
        // 在后台线程检查并刷新快过期的token，避免阻塞UI启动 暂时写这里，后面移至SWWakeUpService
        DispatchQueue.global().async {
            TokenManager.shared.proactivelyRefreshToken { _ in }
        }

        NetworkMonitor.shared.startMonitoring()
        
        let aWindow = UIWindow(frame: UIScreen.main.bounds)
        self.window = aWindow
        Bootstrap.shared.window = aWindow
        Bootstrap.shared.runMainFlow()
        aWindow.makeKeyAndVisible()

        return true
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationDidBecomeActive(application)
        }
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationWillResignActive(application)
        }
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationWillEnterForeground(application)
        }
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationDidEnterBackground(application)
        }
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationWillTerminate(application)
        }
    }
    
    public func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        for service in _sortedServices {
            service.application(application, performActionFor: shortcutItem, completionHandler: completionHandler)
        }
    }
}

// MARK: - Hanlde URL
extension AppDelegate {
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled = false
        for service in _sortedServices {
            let result = service.application(app, open: url, options: options)
            if case .success(let interrupt) = result {
                handled = true
                if interrupt {
                    break
                }
            }
        }
        return handled
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        if _sortedServices.isEmpty {
            return true
        }
        
        var result = false
        for service in _sortedServices {
            if service.application(application, handleOpen: url) {
                result = true
            }
        }
        return result
        
    }
    
    func application(_ application: UIApplication,
                     open url: URL,
                     sourceApplication: String?,
                     annotation: Any) -> Bool {
        if _sortedServices.isEmpty {
            return true
        }
        
        var result = false
        for service in _sortedServices {
            if service.application(application,
                                   open: url,
                                   sourceApplication: sourceApplication,
                                   annotation: annotation) {
                result = true
            }
        }
        return result
    }
}

// MARK: - APNS
extension AppDelegate {
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        for service in _sortedServices {
            service.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        for service in _sortedServices {
            service.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }
    }
    
    public func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        apply({ (service, completionHandler) -> Void? in
            service.application(
                application,
                didReceiveRemoteNotification: userInfo,
                fetchCompletionHandler: completionHandler
            )
        }, completionHandler: { results in
            let result = results.min(by: { $0.rawValue < $1.rawValue }) ?? .noData
            completionHandler(result)
        })
    }
    
    @discardableResult
    private func apply<T, S>(_ work: (AppServiceType, @escaping (T) -> Void) -> S?,
                             completionHandler: @escaping ([T]) -> Void) -> [S] {
        let dispatchGroup = DispatchGroup()
        var results: [T] = []
        var returns: [S] = []
        
        for service in _sortedServices {
            dispatchGroup.enter()
            let returned = work(service, { result in
                results.append(result)
                dispatchGroup.leave()
            })
            if let returned = returned {
                returns.append(returned)
            } else {
                dispatchGroup.leave()
            }
            if returned == nil {}
        }
        
        dispatchGroup.notify(queue: .main) {
            completionHandler(results)
        }
        
        return returns
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        for service in _sortedServices {
            service.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        for service in _sortedServices {
            service.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        for service in _sortedServices {
            service.userNotificationCenter(center, openSettingsFor: notification)
        }
    }
}

// MARK: - System Events
extension AppDelegate {
    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationDidReceiveMemoryWarning(application)
        }
    }
    
    public func applicationSignificantTimeChange(_ application: UIApplication) {
        for service in _sortedServices {
            service.applicationSignificantTimeChange(application)
        }
    }
}

// MARK: - Other Extension
extension AppDelegate {
    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        
        if _sortedServices.isEmpty {
            return true
        }
        
        var result = true
        for service in _sortedServices {
            if service.application(application, shouldAllowExtensionPointIdentifier: extensionPointIdentifier) == false {
                result = false
                break
            }
        }
        return result
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        if _sortedServices.isEmpty {
            return true
        }
        
        var result = false
        for service in _sortedServices {
            if service.application(application,
                                   continue: userActivity,
                                   restorationHandler: restorationHandler) {
                result = true
            }
        }
        return result
    }
}

