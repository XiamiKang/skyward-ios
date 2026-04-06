//
//  UIButton+Extensions.swift
//  TXKit
//
//  Created by zhaobo on 2026/2/4.
//

import UIKit

public extension UIButton {
    
    // MARK: - 上图下文布局
    
    /// 设置按钮为上图下文的布局样式
    /// - Parameters:
    ///   - spacing: 图片和文字之间的间距，默认为 0
    /// - Note: 需要先设置好 imageView 和 titleLabel 的内容（setImage 和 setTitle）
    func imageUpTitleDown(spacing: CGFloat = 0) {
        if #available(iOS 15.0, *) {
            // iOS 15+ 使用 UIButtonConfiguration
            configureWithImageUpTitleDowniOS15(spacing: spacing)
        } else {
            // 旧版本 iOS 使用 imageEdgeInsets 和 titleEdgeInsets
            configureWithImageUpTitleDownLegacy(spacing: spacing)
        }
    }
    
    /// iOS 15+ 上图下文布局实现（使用 UIButtonConfiguration）
    @available(iOS 15.0, *)
    private func configureWithImageUpTitleDowniOS15(spacing: CGFloat) {
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero

        // 设置图片和文字的布局
        configuration.imagePlacement = .top
        configuration.imagePadding = spacing

        // 使用 transformer 来设置字体
        if let currentFont = titleLabel?.font {
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = currentFont
                return outgoing
            }
        }
        // 应用配置
        self.configuration = configuration
    }
    
    /// 旧版本 iOS 上图下文布局实现（使用 imageEdgeInsets 和 titleEdgeInsets）
    private func configureWithImageUpTitleDownLegacy(spacing: CGFloat) {
        guard let imageView = imageView, let titleLabel = titleLabel else {
            return
        }
        
        guard let imageSize = imageView.image?.size else {
            return
        }
        
        // 明确使用 .normal 或 .selected 状态
        let targetState: UIControl.State = isSelected ? .selected : .normal
        guard let currentTitle = title(for: targetState) else {
            return
        }
        
        let btnTitleWidth = (currentTitle as NSString).size(withAttributes: [
            .font: titleLabel.font!
        ]).width
        
        imageEdgeInsets = UIEdgeInsets(
            top: -(imageSize.height + spacing),
            left: 0,
            bottom: 0,
            right: -btnTitleWidth
        )
        
        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: -imageSize.width,
            bottom: -(imageSize.height + spacing),
            right: 0
        )
    }
}
