//
//  ThemeType.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

import UIKit

public protocol ThemeType {
    
    // MARK: - 功能色
    /// 主题颜色（品牌色）
    var mainColor: UIColor { get }
    /// 错误颜色
    var errorColor: UIColor { get }
    /// 提示/异常颜色
    var warningColor: UIColor { get }
    /// 成功颜色
    var successColor: UIColor { get }
    /// 分割线颜色
    var separatorColor: UIColor { get }
    
    // MARK: - 文本色
    /// 标题颜色
    var titleColor: UIColor { get }
    /// 正文颜色
    var textColor: UIColor { get }
    /// 辅助文字颜色
    var secondaryColor: UIColor { get }
    /// 禁用状态颜色
    var disabledColor: UIColor { get }
    
    // MARK: - 背景色
    /// 一级白色背景
    var backgroundColor: UIColor { get }
    /// 浅灰色背景
    var lightGrayBGColor: UIColor { get }
    /// 中灰色背景
    var mediumGrayBGColor: UIColor { get }
    /// 深灰色背景
    var darkGrayBGColor: UIColor { get }
    /// 蒙层（弹窗/弹出层后面背景）
    var maskBGColor: UIColor { get }
    /// Toast
    var toastBGColor: UIColor { get }
    
}
