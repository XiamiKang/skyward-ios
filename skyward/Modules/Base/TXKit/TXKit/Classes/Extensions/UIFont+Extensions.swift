//
//  UIFont+Extensions.swift
//  
//
//  Created by hushijun on 2024/7/31.
//

import UIKit


extension UIFont {
    
    // MARK: - 系统字体
    
    /// light字体，对应设计稿中的weight=300
    public class func systemFontLight(ofSize fontSize: CGFloat) -> UIFont {
        return .systemFont(ofSize: fontSize, weight: .light)
    }
    
    /// regular字体，对应设计稿中的weight=400
    public class func systemFontRegular(ofSize fontSize: CGFloat) -> UIFont {
        return .systemFont(ofSize: fontSize, weight: .regular)
    }
    
    /// medium字体，对应设计稿中的weight=500
    public class func systemFontMedium(ofSize fontSize: CGFloat) -> UIFont {
        return .systemFont(ofSize: fontSize, weight: .medium)
    }
    
    /// bold字体，对应设计稿中的weight=600
    public class func systemFontBold(ofSize fontSize: CGFloat) -> UIFont {
        return .systemFont(ofSize: fontSize, weight: .bold)
    }
    
    // MARK: - 平方字体【PingFang SC】
    //     Font: PingFangSC-Regular
    //     Font: PingFangSC-Ultralight
    //     Font: PingFangSC-Thin
    //     Font: PingFangSC-Light
    //     Font: PingFangSC-Medium
    //     Font: PingFangSC-Semibold
    /// light字体，对应设计稿中的weight=300
    public class func pingFangFontLight(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Light", size: fontSize) ?? systemFontLight(ofSize: fontSize)
    }
    
    /// regular字体，对应设计稿中的weight=400
    public class func pingFangFontRegular(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Regular", size: fontSize) ?? systemFontRegular(ofSize: fontSize)
    }
    
    /// medium字体，对应设计稿中的weight=500
    public class func pingFangFontMedium(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Medium", size: fontSize) ?? systemFontMedium(ofSize: fontSize)
    }
    
    /// bold字体，对应设计稿中的weight=600
    public class func pingFangFontBold(ofSize fontSize: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Semibold", size: fontSize) ?? systemFontBold(ofSize: fontSize)
    }
    
}
