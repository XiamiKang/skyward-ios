//
//  MeasureBottomView.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import UIKit
import SWTheme

/// 底部按钮栏视图配置项
struct BottomButtonBarConfig {
    /// 按钮图片名称数组
    let buttonImageNames: [String]
    /// 按钮间距
    let spacing: CGFloat
    /// 按钮大小
    let buttonSize: CGFloat
    
    /// 默认配置
    static let `default` = BottomButtonBarConfig(buttonImageNames: [], spacing: 48, buttonSize: swAdaptedValue(40))
}

/// 通用底部按钮栏视图
class BottomButtonBarView: UIStackView {
    
    /// 按钮数组
    var buttons: [UIButton] = []
    
    /// 配置
    private let config: BottomButtonBarConfig
    
    /// 初始化方法
    /// - Parameter config: 配置项
    init(config: BottomButtonBarConfig = .default) {
        self.config = config
        super.init(frame: .zero)
        
        setupUI()
        createButtons()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置UI
    private func setupUI() {
        axis = .horizontal
        spacing = config.spacing
        distribution = .equalSpacing
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    /// 创建按钮
    private func createButtons() {
        for imageName in config.buttonImageNames {
            let button = createButton(imageName: imageName)
            buttons.append(button)
            addArrangedSubview(button)
        }
    }
    
    /// 创建单个按钮
    /// - Parameter imageName: 图片名称
    /// - Returns: 按钮实例
    private func createButton(imageName: String) -> UIButton {
        let button = UIButton()
        let image = MapModule.image(named: imageName)
        button.setImage(image, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: config.buttonSize),
            button.heightAnchor.constraint(equalToConstant: config.buttonSize)
        ])
        
        return button
    }
    
    /// 获取指定索引的按钮
    /// - Parameter index: 索引
    /// - Returns: 按钮实例（可选）
    func button(at index: Int) -> UIButton? {
        guard index >= 0 && index < buttons.count else {
            return nil
        }
        return buttons[index]
    }
}

/// 测量模式底部按钮栏（基于通用底部按钮栏）
class MeasureBottomView: BottomButtonBarView {
    
    // 便捷访问按钮
    var revocationButton: UIButton { buttons[0] }
    var deleteButton: UIButton { buttons[1] }
    var exitButton: UIButton { buttons[2] }
    
    init() {
        let config = BottomButtonBarConfig(
            buttonImageNames: ["measure_revocation", "measure_delete", "measure_exit"],
            spacing: 48,
            buttonSize: swAdaptedValue(40)
        )
        super.init(config: config)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 路线模式底部按钮栏（基于通用底部按钮栏）
class RouteBottomView: BottomButtonBarView {
    
    // 便捷访问按钮
    var revocationButton: UIButton { buttons[0] }
    var confirmButton: UIButton { buttons[1] }
    var exitButton: UIButton { buttons[2] }
    
    init() {
        let config = BottomButtonBarConfig(
            buttonImageNames: ["measure_revocation", "route_confirm", "measure_exit"],
            spacing: 48,
            buttonSize: swAdaptedValue(40)
        )
        super.init(config: config)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
