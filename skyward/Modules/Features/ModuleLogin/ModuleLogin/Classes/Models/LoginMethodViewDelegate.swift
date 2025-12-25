//
//  LoginMethodViewDelegate.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//


import UIKit

// MARK: - 协议
protocol LoginMethodViewDelegate: AnyObject {
    func loginMethodView(_ view: LoginMethodView, didSelectMethod method: String, at index: Int)
}

// MARK: - 登录方式选择视图
class LoginMethodView: UIView {
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 32
        stackView.distribution = .fill
        return stackView
    }()
    
    private let underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .orange
        view.layer.cornerRadius = 1
        return view
    }()
    
    // MARK: - Properties
    weak var delegate: LoginMethodViewDelegate?
    private var buttons: [UIButton] = []
    private var methodTitles: [String] = []
    var selectedIndex: Int = 0
    
    // 配置属性
    var normalColor: UIColor = defaultBlackColor
    var selectedColor: UIColor = defaultOrangeColor
    var underlineHeight: CGFloat = 3
    var buttonFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.addSubview(underlineView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func configure(with methods: [String], defaultSelectedIndex: Int = 0) {
        // 清除现有的按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        methodTitles.removeAll()
        
        methodTitles = methods
        selectedIndex = defaultSelectedIndex
        
        // 创建按钮
        for (index, method) in methods.enumerated() {
            let button = createButton(title: method, index: index)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }
        
        // 更新选中状态
        updateSelection()
        
        // 布局完成后更新下划线位置
        DispatchQueue.main.async {
            self.updateUnderlinePosition(animated: false)
        }
    }
    
    func addMethod(_ method: String) {
        methodTitles.append(method)
        let button = createButton(title: method, index: methodTitles.count - 1)
        stackView.addArrangedSubview(button)
        buttons.append(button)
    }
    
    func selectMethod(at index: Int) {
        guard index >= 0 && index < buttons.count else { return }
        selectedIndex = index
        updateSelection()
        updateUnderlinePosition(animated: true)
    }
    
    // MARK: - Private Methods
    private func createButton(title: String, index: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = buttonFont
        button.tag = index
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? selectedColor : normalColor, for: .normal)
            button.titleLabel?.font = isSelected ? 
                UIFont.systemFont(ofSize: buttonFont.pointSize, weight: .semibold) : buttonFont
        }
    }
    
    private func updateUnderlinePosition(animated: Bool) {
        guard selectedIndex < buttons.count else { return }
        
        let selectedButton = buttons[selectedIndex]
        let buttonFrame = selectedButton.frame
        
        let underlineFrame = CGRect(
            x: buttonFrame.origin.x,
            y: scrollView.bounds.height - underlineHeight,
            width: buttonFrame.width,
            height: underlineHeight
        )
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.underlineView.frame = underlineFrame
            }
        } else {
            underlineView.frame = underlineFrame
        }
        
        // 确保选中的按钮在可视区域内
        scrollView.scrollRectToVisible(selectedButton.frame, animated: animated)
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        selectMethod(at: index)
        delegate?.loginMethodView(self, didSelectMethod: methodTitles[index], at: index)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUnderlinePosition(animated: false)
    }
}
