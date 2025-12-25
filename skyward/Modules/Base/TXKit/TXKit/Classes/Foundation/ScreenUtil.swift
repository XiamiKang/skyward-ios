//
//  SceenUtil.swift
//  TXKit
//
//  Created by zhaobo on 2025/11/19.
//

import UIKit

public struct ScreenUtil {
    
    // MARK: - 屏幕尺寸
    
    /// 获取当前屏幕宽度（点数）
    public static var screenWidth: CGFloat {
        return screenSize.width
    }
    
    /// 获取当前屏幕高度（点数）
    public static var screenHeight: CGFloat {
        return screenSize.height
    }
    
    /// 获取屏幕尺寸（兼容所有版本）
    public static var screenSize: CGSize {
        // 优先尝试获取 keyWindow 的尺寸
        if let window = getKeyWindow() {
            return window.bounds.size
        }
        
        // 备选方案：使用 UIScreen
        return UIScreen.main.bounds.size
    }
    
    // MARK: - 安全区域
    
    /// 安全区域 insets（兼容所有版本）
    public static var safeAreaInsets: UIEdgeInsets {
        guard #available(iOS 11.0, *) else {
            return .zero
        }
        
        if let window = getKeyWindow() {
            return window.safeAreaInsets
        }
        
        return .zero
    }
    
    /// 顶部安全区域高度
    public static var safeAreaTop: CGFloat {
        return safeAreaInsets.top
    }
    
    /// 底部安全区域高度
    public static var safeAreaBottom: CGFloat {
        return safeAreaInsets.bottom
    }
    
    // MARK: - 状态栏和导航栏
    
    /// 状态栏高度
    public static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let statusBarManager = windowScene.statusBarManager {
                return statusBarManager.statusBarFrame.height
            }
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
        return 0
    }
    
    /// 导航栏高度（包含状态栏）
    public static var navigationBarHeight: CGFloat {
        return statusBarHeight + 44
    }
    
    /// 标签栏高度
    public static var tabBarHeight: CGFloat {
        return 49 + safeAreaInsets.bottom
    }
    
    // MARK: - 设备信息
    
    /// 是否是 iPhone X 系列（有刘海屏）
    public static var isIPhoneXSeries: Bool {
        return safeAreaBottom > 0
    }
    
    /// 屏幕缩放比例
    public static var scale: CGFloat {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.screen.scale
            }
        }
        return UIScreen.main.scale
    }
    
    /// 获取 keyWindow（兼容所有版本）
    public static func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
