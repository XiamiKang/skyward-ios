//
//  ThemeManager.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

import TXKit

public enum ThemeStyle: String {
    case light = "light"
    case dark  = "dark"
    
    static func style(from identifier: String) -> ThemeStyle {
        return ThemeStyle(rawValue: identifier) ?? .light
    }
    
    func theme() -> ThemeType {
        switch self {
        case .light:
            return LightTheme()
        case .dark:
            return DarkTheme()
        }
    }
}

/// UI布局尺寸， 根据分辨率自动计算适配
/// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算，在320屏幕上不进行缩放
/// - Parameter originValue: 设计像素
/// - Returns: 缩放后的像素大小
public func swAdaptedValue(_ originValue: Double) -> Double {
    return ThemeManager.value(originValue)
}

/// UI布局尺寸， 根据分辨率自动计算适配，并缩放向上取整，
/// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算，在320屏幕上不进行缩放
/// - Parameter originValue: 设计像素
/// - Returns: 缩放后的像素大小
public func swAdaptedRoundValue(_ originValue: Double) -> Double {
    return ThemeManager.roundValue(originValue)
}

/// UI布局尺寸， 根据分辨率自动计算适配，并缩放向上取整，
/// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算
/// - Parameter originValue: 设计像素
/// - Returns: 缩放后的像素大小
public func swRatio(_ originValue: Double) -> Double {
    return ThemeManager.ratioValue(originValue)
}

public class ThemeManager {
    
    private var theme: ThemeType = LightTheme()
    
    private init() {}
    
    private static let scaleBaseline = 375.0
    
    private let fontScale = calFontScale()
    
    private let uiScale = calUIScale()
    
    /// 当前环境单例
    public static let shared = ThemeManager()
    
    /// 0.5 描边宽度 | 高度
    public static var dividerWidth: CGFloat = 1.0 / UIScreen.main.scale
    
    
    // MARK: - Public
    /// 当前主题类型
    public class var current: ThemeType {
        get {
            return shared.theme
        }
    }
    
    /// UI布局尺寸， 根据分辨率自动计算适配
    /// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算，在320屏幕上不进行缩放
    /// - Parameter originValue: 设计像素
    /// - Returns: 缩放后的像素大小
    static func value(_ originValue: Double) -> Double {
        return originValue * shared.fontScale
    }
    
    /// UI布局尺寸， 根据分辨率自动计算适配，并缩放向上取整
    /// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算，在320屏幕上不进行缩放
    /// - Parameter originValue: 设计像素
    /// - Returns: 缩放后的像素大小
    static func roundValue(_ originValue: Double) -> Double {
        return ceil(originValue * shared.fontScale)
    }
    
    /// UI布局尺寸， 根据分辨率自动计算适配，并缩放向上取整
    /// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算
    /// - Parameter originValue: 设计像素
    /// - Returns: 缩放后的像素大小
    static func ratioValue(_ originValue: Double) -> Double {
        return ceil(originValue * shared.uiScale)
    }
    
    /// 根据屏幕分辨率来获取不同设备上的字号大小
    /// 缩放比例：按照屏幕宽度除以基础设计稿宽度375进行计算，在320屏幕上不进行缩放
    /// - Parameter designValue: 设计稿上的字号大小
    /// - Returns: 计算后的字号大小
    static func fontSize(_ designValue: Int) -> Double {
        return CGFloat(designValue) * shared.fontScale
    }
    
    // MARK: - 字体
    public static var light16Font: UIFont = .pingFangFontLight(ofSize: ThemeManager.fontSize(16))
    public static var regular16Font: UIFont = .pingFangFontRegular(ofSize: ThemeManager.fontSize(16))
    public static var medium16Font: UIFont = .pingFangFontMedium(ofSize: ThemeManager.fontSize(16))
    public static var bold16Font: UIFont = .pingFangFontBold(ofSize: ThemeManager.fontSize(16))
 
    
    // MARK: - Private
    private static func calFontScale() -> Double {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = min(screenSize.width, screenSize.height)
        if screenWidth <= scaleBaseline {
            return 1
        }
        return screenWidth/scaleBaseline
    }
    
    private static func calUIScale() -> Double {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = min(screenSize.width, screenSize.height)
        return screenWidth / scaleBaseline
    }
}
