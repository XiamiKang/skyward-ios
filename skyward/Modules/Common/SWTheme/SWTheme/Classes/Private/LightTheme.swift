//
//  LightTheme.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

import TXKit

class LightTheme: ThemeType {
    
    // MARK: - 功能色
    /// 主题颜色（品牌色）
    var mainColor: UIColor = .init(str: "#FE6A00")
    /// 错误颜色
    var errorColor: UIColor = .init(str: "#F7594B")
    /// 警告/提示/异常颜色
    var warningColor: UIColor = .init(str: "#FF9447")
    /// 成功颜色
    var successColor: UIColor = .init(str: "#16C282")
    /// 分割线颜色
    var separatorColor: UIColor = .init(str: "#DFE0E2")
    
    // MARK: - 文本色
    /// 标题颜色
    var titleColor: UIColor = .init(str: "#070808")
    /// 正文颜色
    var textColor: UIColor = .init(str: "#84888C")
    /// 辅助文字颜色
    var secondaryColor: UIColor = .init(str: "#303236")
    /// 禁用状态颜色
    var disabledColor: UIColor = .init(str: "#C4C7CA")
    
    // MARK: - 背景色
    /// 一级白色背景
    var backgroundColor: UIColor = .white
    /// 二级背景灰
    var lightGrayBGColor: UIColor = .init(str: "#FAFAFA")
    /// 中灰色背景
    var mediumGrayBGColor: UIColor = .init(str: "#F2F3F4")
    /// 深灰色背景
    var darkGrayBGColor: UIColor = .init(str: "#DFE0E2")
    /// 蒙层（弹窗/弹出层后面背景）
    var maskBGColor: UIColor = .black.withAlphaComponent(0.5)
    /// Toast
    var toastBGColor: UIColor = .black.withAlphaComponent(0.8)
}
