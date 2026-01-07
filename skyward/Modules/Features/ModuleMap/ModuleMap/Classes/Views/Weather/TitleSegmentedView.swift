//
//  UserPOIChooseView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/17.
//

import UIKit

class TitleSegmentedView: UIView {
    
    // MARK: - Properties
    private var titles: [String] = []
    private var buttons: [UIButton] = []
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .orange
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 1
        return view
    }()
    
    private var underlineWidthConstraint: NSLayoutConstraint?
    private var underlineCenterXConstraint: NSLayoutConstraint?
    
    private var selectedIndex: Int = 0 {
        didSet {
            updateUI()
            updateUnderlinePosition(animated: true)
        }
    }
    
    var onSelect: ((Int) -> Void)?
    
    // MARK: - Configuration
    var underlineHeight: CGFloat = 2 {
        didSet {
            underlineView.heightAnchor.constraint(equalToConstant: underlineHeight).isActive = true
        }
    }
    
    var underlineColor: UIColor = .orange {
        didSet {
            underlineView.backgroundColor = underlineColor
        }
    }
    
    var normalColor: UIColor = .black {
        didSet {
            updateButtonColors()
        }
    }
    
    var selectedColor: UIColor = .orange {
        didSet {
            updateButtonColors()
        }
    }
    
    var normalFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium) {
        didSet {
            updateButtonFonts()
        }
    }
    
    var selectedFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .semibold) {
        didSet {
            updateButtonFonts()
        }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(titles: [String]) {
        self.init(frame: .zero)
        self.titles = titles
        setupTitles()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(stackView)
        addSubview(underlineView)
        
        // StackView 约束
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 下划线约束
        underlineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        underlineView.heightAnchor.constraint(equalToConstant: underlineHeight).isActive = true
        
        // 初始宽度和居中约束（稍后更新）
        underlineWidthConstraint = underlineView.widthAnchor.constraint(equalToConstant: 0)
        underlineWidthConstraint?.isActive = true
        
        underlineCenterXConstraint = underlineView.centerXAnchor.constraint(equalTo: leadingAnchor)
        underlineCenterXConstraint?.isActive = true
    }
    
    private func setupTitles() {
        buttons.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, title) in titles.enumerated() {
            let button = createButton(title: title, tag: index)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        // 设置默认选中第一个
        selectedIndex = 0
        updateUI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.updateUnderlinePosition(animated: false)
        }
    }
    
    private func createButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = normalFont
        button.setTitleColor(normalColor, for: .normal)
        button.setTitleColor(selectedColor, for: .selected)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    @objc private func buttonTapped(_ sender: UIButton) {
        let newIndex = sender.tag
        guard newIndex != selectedIndex else { return }
        
        selectedIndex = newIndex
        onSelect?(selectedIndex)
    }
    
    // MARK: - UI Update
    private func updateUI() {
        for (index, button) in buttons.enumerated() {
            button.isSelected = (index == selectedIndex)
            button.titleLabel?.font = (index == selectedIndex) ? selectedFont : normalFont
        }
    }
    
    private func updateButtonColors() {
        for button in buttons {
            button.setTitleColor(normalColor, for: .normal)
            button.setTitleColor(selectedColor, for: .selected)
        }
        updateUI()
    }
    
    private func updateButtonFonts() {
        for button in buttons {
            button.titleLabel?.font = normalFont
        }
        updateUI()
    }
    
    private func updateUnderlinePosition(animated: Bool) {
        guard selectedIndex < buttons.count else { return }
        
        let selectedButton = buttons[selectedIndex]
        
        // 计算下划线的宽度（可以根据按钮标题宽度调整）
        let titleWidth = selectedButton.titleLabel?.intrinsicContentSize.width ?? selectedButton.bounds.width
        let underlineWidth = min(titleWidth + 20, selectedButton.bounds.width - 20)
        
        // 更新约束
        underlineWidthConstraint?.constant = underlineWidth/1.5
        underlineCenterXConstraint?.isActive = false
        
        // 新的居中约束
        underlineCenterXConstraint = underlineView.centerXAnchor.constraint(equalTo: selectedButton.centerXAnchor)
        underlineCenterXConstraint?.isActive = true
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.layoutIfNeeded()
            })
        } else {
            layoutIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    func setTitles(_ titles: [String]) {
        self.titles = titles
        setupTitles()
    }
    
    func selectIndex(_ index: Int, animated: Bool = true) {
        guard index >= 0 && index < buttons.count else { return }
        selectedIndex = index
        if !animated {
            updateUnderlinePosition(animated: false)
        }
    }
    
    func getSelectedIndex() -> Int {
        return selectedIndex
    }
    
    func getSelectedTitle() -> String? {
        guard selectedIndex < titles.count else { return nil }
        return titles[selectedIndex]
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保在布局完成后更新下划线位置
        if buttons.count > 0 && underlineWidthConstraint?.constant == 0 {
            updateUnderlinePosition(animated: false)
        }
    }
}
