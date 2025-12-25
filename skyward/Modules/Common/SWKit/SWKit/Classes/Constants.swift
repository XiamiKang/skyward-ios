//
//  Constants.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import SWTheme

/// 应用通用常量定义
public enum Constants {
    
    /// 默认的网络错误提示语
    public static let serviceError = "系统繁忙，请重试"
    public static let networkError = "网络异常，请检查"
    public static let noData = "暂无数据"
    
    /// t o k e n
    public static let accessTK = "accessTK"
    public static let refreshTK = "refreshTK"
}

/// 统一管理布局相关常量
/// 集成屏幕适配功能，自动根据设备尺寸调整值
public enum Layout {
    // MARK: - 边距 (Margin) - 视图与屏幕边缘的距离
    public static let hMargin: CGFloat = CGFloat(swAdaptedValue(16)) // 水平边距
    public static let vMargin: CGFloat = CGFloat(swAdaptedValue(16)) // 垂直边距
    
    public static let hInset: CGFloat = CGFloat(swAdaptedValue(12)) // 水平边距
    public static let vInset: CGFloat = CGFloat(swAdaptedValue(12)) // 垂直边距
    
    // MARK: - 间距 (Spacing) - 视图之间的距离
    public static let hSpacing: CGFloat = CGFloat(swAdaptedValue(8))  // 水平间距
    public static let vSpacing: CGFloat = CGFloat(swAdaptedValue(8))  // 垂直间距
    
    // MARK: - 尺寸级别 (Size Level) - 提供多种尺寸选择
    public enum SpacingSize {
        case tiny      // 极小 - 4px
        case small     // 小 - 8px
        case medium    // 中等 - 16px
        case large     // 大 - 24px
        case extraLarge // 特大 - 32px
        
        // 获取原始值（设计稿像素）
        private var rawValue: Double {
            switch self {
            case .tiny:
                return 4
            case .small:
                return 8
            case .medium:
                return 16
            case .large:
                return 24
            case .extraLarge:
                return 32
            }
        }
        
        // 获取适配后的值
        public var value: CGFloat {
            return CGFloat(swAdaptedValue(rawValue))
        }
    }
    
    // MARK: - 便捷方法
    /// 获取指定尺寸级别的间距
    public static func spacing(_ size: SpacingSize) -> CGFloat {
        return size.value
    }
}

/// 圆角半径 - 使用枚举实现
public enum CornerRadius: CGFloat {
    case small = 4.0     // 小圆角
    case medium = 8.0    // 中等圆角
    case large = 12.0    // 大圆角
}

/// 边框宽度 - 使用枚举实现
public enum BorderWidth: CGFloat {
    case thin = 0.5      // 细边框
    case normal = 1.0    // 普通边框
    case thick = 2.0     // 粗边框
}

/// APP中的通知名定义，都统一在这里配置
public extension Notification.Name {
    static let loginSuccess = Notification.Name(rawValue: "noti.loginSuccess")
    static let logoutSuccess = Notification.Name(rawValue: "noti.logoutSuccess")
    
    static let switchSceneMapSuccess = Notification.Name(rawValue: "noti.switchSceneMapSuccess")
    /// 收到团队新消息
    static let receiveTeamNewMessage = Notification.Name(rawValue: "noti.receiveTeamNewMessage")
}
