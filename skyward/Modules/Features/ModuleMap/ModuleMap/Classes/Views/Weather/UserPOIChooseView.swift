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

//// MARK: - 使用示例代码（放在你的ViewController中）
//class ViewController: UIViewController {
//    
//    private var titleSegmentedView: TitleSegmentedView!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupTitleSegmentedView()
//    }
//    
//    private func setupTitleSegmentedView() {
//        // 创建标题选择视图
//        titleSegmentedView = TitleSegmentedView(titles: ["全部", "进行中", "已完成", "已取消"])
//        
//        // 设置位置和大小
//        titleSegmentedView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(titleSegmentedView)
//        
//        NSLayoutConstraint.activate([
//            titleSegmentedView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            titleSegmentedView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
//            titleSegmentedView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
//            titleSegmentedView.heightAnchor.constraint(equalToConstant: 44)
//        ])
//        
//        // 设置选中回调
//        titleSegmentedView.onSelect = { [weak self] index in
//            self?.handleSelection(index: index)
//        }
//        
//        // 设置初始选中（可选，默认第一个）
//        // titleSegmentedView.selectIndex(1, animated: false)
//    }
//    
//    private func handleSelection(index: Int) {
//        print("选中了第 \(index) 个标题: \(["全部", "进行中", "已完成", "已取消"][index])")
//        
//        // 根据选中的索引执行相应操作
//        switch index {
//        case 0:
//            // 全部
//            break
//        case 1:
//            // 进行中
//            break
//        case 2:
//            // 已完成
//            break
//        case 3:
//            // 已取消
//            break
//        default:
//            break
//        }
//    }
//}
//
