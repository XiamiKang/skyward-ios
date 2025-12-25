//
//  AppServiceType.swift
//  skyward
//
//  Created by 赵波 on 2025/11/11.
//

import UIKit

/// 服务的处理结果，目前主要用于Handle URL逻辑
/// fail: 服务无法被处理
/// success: 服务可以被正常处理，参数interrupt标明服务是否继续并向下传递
public enum AppServiceResult {
    case fail
    case success(interrupt: Bool)
}

public enum AppServicePriority: Int {
    case low = 1
    case normal = 100
    case high = 1000
}

public protocol AppServiceType {
    
    var priority: AppServicePriority { get }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?)
    
    // MARK: - Life Cycle
    func applicationDidBecomeActive(_ application: UIApplication)
    func applicationWillResignActive(_ application: UIApplication)
    func applicationWillEnterForeground(_ application: UIApplication)
    func applicationDidEnterBackground(_ application: UIApplication)
    func applicationWillTerminate(_ application: UIApplication)
    
    // MARK: - Handle URL
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> AppServiceResult
    
    // MARK: - APNS
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    
    // MARK: - UNUserNotification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void)
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?)
    
    // MARK: - System Events
    func applicationDidReceiveMemoryWarning(_ application: UIApplication)
    func applicationSignificantTimeChange(_ application: UIApplication)
    
    // MARK: - Extension
    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool
    
    func application(_ application: UIApplication,
                           open url: URL,
                           sourceApplication: String?,
                           annotation: Any) -> Bool
   
    func application(_ application: UIApplication,
                           continue userActivity: NSUserActivity,
                           restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool
    
    func application(_ application: UIApplication, 
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void)

}
 

extension AppServiceType {
    public var priority: AppServicePriority {
        return .normal
    }
    
    public func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        return false
    }
    
    // MARK: - Life Cycle
    public func applicationDidBecomeActive(_ application: UIApplication) {}
    public func applicationWillResignActive(_ application: UIApplication) {}
    public func applicationWillEnterForeground(_ application: UIApplication) {}
    public func applicationDidEnterBackground(_ application: UIApplication) {}
    public func applicationWillTerminate(_ application: UIApplication) {}
    
    // MARK: - Handle URL
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> AppServiceResult {
        return .fail
    }
    
    public func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return false
    }
    
    public func application(_ application: UIApplication,
                            open url: URL,
                            sourceApplication: String?,
                            annotation: Any) -> Bool {
        return false
    }
    
    // MARK: - APNS
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {}
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
    public func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {}
    
    // MARK: - UNUserNotification
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {}
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {}
    public func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {}
    
    // MARK: - System Events
    public func applicationDidReceiveMemoryWarning(_ application: UIApplication) {}
    public func applicationSignificantTimeChange(_ application: UIApplication) {}
    
    // MARK: - Extension
    public func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        return true
    }
    
    public func application(_ application: UIApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        return false
    }
    
    public func application(_ application: UIApplication,
                            performActionFor shortcutItem: UIApplicationShortcutItem,
                            completionHandler: @escaping (Bool) -> Void) {}
}
