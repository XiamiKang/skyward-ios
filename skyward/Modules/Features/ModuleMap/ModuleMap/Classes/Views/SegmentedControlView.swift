//
//  SegmentedControlView.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/9.
//

import UIKit
import SnapKit
import SWTheme

/// 通用分段控制器
class SegmentedControlView: UIView {

    // MARK: - Callbacks

    /// 选中变化回调，返回选中的索引
    var onSelectedIndexChanged: ((Int) -> Void)?

    // MARK: - UI Components

    private var buttons: [UIButton] = []
    private var titles: [String] = []

    private lazy var indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeManager.current.mainColor
        view.cornerRadius = 1.5
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()

    // MARK: - Properties

    private(set) var selectedIndex: Int = 0 {
        didSet {
            updateButtonsAppearance()
            moveIndicator(to: selectedIndex, animated: true)
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(stackView)
        addSubview(indicatorView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        indicatorView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(3)
            make.width.equalTo(30)
        }
    }

    // MARK: - Public Methods

    /// 配置分段控制器
    /// - Parameters:
    ///   - titles: 标题数组
    ///   - defaultIndex: 默认选中的索引，默认为 0
    func configure(titles: [String], defaultIndex: Int = 0) {
        self.titles = titles

        // 移除旧的按钮
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        // 创建新按钮
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .custom)
            button.setTitle(title, for: .normal)
            button.setTitleColor(ThemeManager.current.mainColor, for: .selected)
            button.setTitleColor(ThemeManager.current.titleColor, for: .normal)
            button.titleLabel?.font = .pingFangFontMedium(ofSize: 16)
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        // 设置默认选中
        selectedIndex = defaultIndex
        updateButtonsAppearance()
        moveIndicator(to: defaultIndex, animated: false)
    }

    /// 更新指定索引的标题
    /// - Parameters:
    ///   - index: 索引
    ///   - title: 新标题
    func updateTitle(at index: Int, title: String) {
        guard index < titles.count else { return }
        titles[index] = title
        buttons[index].setTitle(title, for: .normal)
        buttons[index].setTitle(title, for: .selected)
    }

    /// 设置当前选中的索引
    func setSelectedIndex(_ index: Int, animated: Bool = true) {
        guard index < buttons.count else { return }
        selectedIndex = index
        moveIndicator(to: index, animated: animated)
    }

    /// 获取当前选中的索引
    func getSelectedIndex() -> Int {
        return selectedIndex
    }

    // MARK: - Actions

    @objc private func buttonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index != selectedIndex else { return }
        selectedIndex = index
        onSelectedIndexChanged?(index)
    }

    // MARK: - Private Methods

    private func updateButtonsAppearance() {
        for (index, button) in buttons.enumerated() {
            button.isSelected = (index == selectedIndex)
        }
    }

    private func moveIndicator(to index: Int, animated: Bool) {
        guard index < buttons.count else { return }
        let button = buttons[index]

        let updateConstraints = {
            self.indicatorView.snp.remakeConstraints { make in
                make.bottom.equalToSuperview()
                make.height.equalTo(3)
                make.width.equalTo(30)
                make.centerX.equalTo(button)
            }
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                updateConstraints()
                self.layoutIfNeeded()
            }
        } else {
            updateConstraints()
            layoutIfNeeded()
        }
    }
}
