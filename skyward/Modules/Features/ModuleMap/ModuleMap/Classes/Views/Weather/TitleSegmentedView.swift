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
    private var underlineViews: [UIView] = []
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var underlineContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var underlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .orange
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var selectedIndex: Int = 0 {
        didSet {
            updateUI()
        }
    }
    
    var onSelect: ((Int) -> Void)?
    
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
        addSubview(underlineContainer)
        underlineContainer.addSubview(underlineView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            underlineContainer.topAnchor.constraint(equalTo: stackView.bottomAnchor),
            underlineContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            underlineContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            underlineContainer.heightAnchor.constraint(equalToConstant: 2),
            
            underlineView.topAnchor.constraint(equalTo: underlineContainer.topAnchor),
            underlineView.bottomAnchor.constraint(equalTo: underlineContainer.bottomAnchor),
            underlineView.heightAnchor.constraint(equalToConstant: 2),
        ])
    }
    
    private func setupTitles() {
        buttons.removeAll()
        underlineViews.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, title) in titles.enumerated() {
            let button = createButton(title: title, tag: index)
            buttons.append(button)
            stackView.addArrangedSubview(button)
            
            // 创建每个标题下的下划线占位视图
            let underline = createUnderlineView()
            underlineViews.append(underline)
        }
        
        // 设置默认选中第一个
        selectedIndex = 0
        updateUnderlinePosition(animated: false)
    }
    
    private func createButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.tag = tag
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.orange, for: .selected)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func createUnderlineView() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    // MARK: - Actions
    @objc private func buttonTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        onSelect?(selectedIndex)
        updateUnderlinePosition(animated: true)
    }
    
    // MARK: - UI Update
    private func updateUI() {
        for (index, button) in buttons.enumerated() {
            button.isSelected = (index == selectedIndex)
            button.titleLabel?.font = (index == selectedIndex)
                ? UIFont.systemFont(ofSize: 16, weight: .semibold)
                : UIFont.systemFont(ofSize: 16, weight: .medium)
        }
    }
    
    private func updateUnderlinePosition(animated: Bool) {
        guard selectedIndex < buttons.count else { return }
        
        let selectedButton = buttons[selectedIndex]
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.underlineView.frame = CGRect(
                    x: selectedButton.frame.origin.x,
                    y: 0,
                    width: selectedButton.frame.width,
                    height: 2
                )
            })
        } else {
            underlineView.frame = CGRect(
                x: selectedButton.frame.origin.x,
                y: 0,
                width: selectedButton.frame.width,
                height: 2
            )
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
        updateUnderlinePosition(animated: animated)
    }
    
    func getSelectedIndex() -> Int {
        return selectedIndex
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUnderlinePosition(animated: false)
    }
}
