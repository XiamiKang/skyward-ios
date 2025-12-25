//
//  TabBarView.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import UIKit
import SWTheme
import SWKit

class TabBarView: UIView {
    // MARK: - Properties
    private var tabs: [String] = []
    private var buttons: [UIButton] = []
    private var underlineView: UIView!
    private var selectedTabIndex: Int = 0
    var onTabSelected: ((Int) -> Void)?
    
    // MARK: - Initialization
    init(tabs: [String]) {
        self.tabs = tabs
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .white
        
        // 创建下划线
        underlineView = UIView()
        underlineView.backgroundColor = ThemeManager.current.mainColor
        underlineView.frame = CGRect(x: 0, y: 40, width: 0, height: 3)
        addSubview(underlineView)
        
        // 创建按钮
        createButtons()
    }
    
    private func createButtons() {
        let buttonHeight: CGFloat = swAdaptedValue(22)
        let buttonSpacing: CGFloat = 24.0
        var buttonX: CGFloat = 0.0
        
        for (index, title) in tabs.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.black, for: .normal)
            button.setTitleColor(ThemeManager.current.mainColor, for: .selected)
            button.tag = index
            button.isSelected = index == 0
            
            // 根据选中状态设置字体并计算宽度
            updateButtonFontAndWidth(button, title: title, isSelected: index == 0)
            
            // 设置按钮位置
            button.frame = CGRect(x: buttonX, y: 11, width: button.frame.size.width, height: buttonHeight)
            buttonX += button.frame.size.width + buttonSpacing
            
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
        
        // 初始化指示器
        updateUnderlineView()
    }
    
    private func updateButtonFontAndWidth(_ button: UIButton, title: String, isSelected: Bool) {
        // 设置字体
        button.titleLabel?.font = isSelected ? ThemeManager.bold16Font : ThemeManager.regular16Font
        
        // 根据当前字体重新计算宽度
        let font = isSelected ? ThemeManager.bold16Font : ThemeManager.regular16Font
        let buttonWidth = textWidth(text: title, font: font)
        button.frame.size.width = buttonWidth
    }
    
    private func updateUnderlineView() {
        guard !buttons.isEmpty, let selectedButton = buttons.first(where: { $0.isSelected }) else { return }
        
        // 设置指示器宽度为选中按钮的宽度
        underlineView.frame.size.width = selectedButton.frame.size.width
        underlineView.center.x = selectedButton.center.x
    }
    
    // MARK: - Actions
    @objc private func tabTapped(_ sender: UIButton) {
        let index = sender.tag
        selectTab(at: index)
    }
    
    // MARK: - Public Methods
    func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count && index != selectedTabIndex else { return }
        
        // 更新选中状态和字体
        for button in buttons {
            let isSelected = button.tag == index
            button.isSelected = isSelected
            
            // 更新按钮字体和宽度（考虑字体变粗时宽度变化）
            updateButtonFontAndWidth(button, title: button.title(for: .normal) ?? "", isSelected: isSelected)
        }
        
        // 重新布局所有按钮位置
        updateButtonsLayout()
        
        // 动画移动下划线
        UIView.animate(withDuration: 0.3) {
            let button = self.buttons[index]
            self.underlineView.frame.size.width = button.frame.size.width
            self.underlineView.center.x = button.center.x
        }
        
        // 更新选中索引并回调
        selectedTabIndex = index
        onTabSelected?(index)
    }
    
    private func updateButtonsLayout() {
        var buttonX: CGFloat = 0.0
        let buttonSpacing: CGFloat = 24.0
        
        for button in buttons {
            button.frame.origin.x = buttonX
            buttonX += button.frame.size.width + buttonSpacing
        }
    }
    
    func textWidth(text: String, font: UIFont) -> CGFloat {
        let textWidth = text.boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil).size.width
        return CGFloat(ceilf(Float(textWidth)))
    }
}
