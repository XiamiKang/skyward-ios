//
//  MessageViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme
import SnapKit

public class MessageViewController: BaseViewController {
    private var convListVC: ConvListViewController!
    private var contactsVC: ContactViewController!
    
    private var contentView: UIView!
    private var scrollView: UIScrollView!
    private var tabBarView: TabBarView!
    
    private var addButton: UIButton!
    
    private var selectedTab = 0 // 0: 聊天, 1: 通讯录
    
    // MARK: - Override
    override public var hasNavBar: Bool {
        return false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeManager.current.backgroundColor
        setupUI()
    }
    
    private func setupUI() {
        // 设置顶部TabBar
        setupTabBarView()
        
        // 设置内容视图
        setupContentView()
        
        // 添加右上角 +
        setupAddButton()
    }
    
    private func setupTabBarView() {
        let tabs = ["聊天", "通讯录"]
        tabBarView = TabBarView(tabs: tabs)
        tabBarView.onTabSelected = { [weak self] index in
            self?.switchToTab(index)
        }
        tabBarView.frame = CGRect(x: Layout.hMargin, y: ScreenUtil.statusBarHeight, width: swAdaptedValue(104), height: 44)
        view.addSubview(tabBarView)
    }
    
    private func setupAddButton() {
        addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .black
        addButton.frame = CGRect(x: view.bounds.width - 40, y: ScreenUtil.statusBarHeight, width: 30, height: 30)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        view.addSubview(addButton)
    }
    
    private func setupContentView() {
        let top = ScreenUtil.navigationBarHeight
        
        contentView = UIView()
        contentView.backgroundColor = .white
        contentView.frame = CGRect(x: 0, y: top, width: view.bounds.width, height: view.bounds.height - top)
        view.addSubview(contentView)
        
        // 创建 ScrollView
        scrollView = UIScrollView()
        scrollView.frame = contentView.bounds
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: view.bounds.width * 2, height: contentView.bounds.height)
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        contentView.addSubview(scrollView)
        
        // 初始化子控制器
        convListVC = ConvListViewController()
        contactsVC = ContactViewController()
        
        // 添加到 scrollView
        addChild(convListVC)
        convListVC.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: contentView.bounds.height)
        scrollView.addSubview(convListVC.view)
        convListVC.didMove(toParent: self)
        
        addChild(contactsVC)
        contactsVC.view.frame = CGRect(x: view.bounds.width, y: 0, width: view.bounds.width, height: contentView.bounds.height)
        scrollView.addSubview(contactsVC.view)
        contactsVC.didMove(toParent: self)
    }
    
    @objc private func addTapped() {
        print("点击 + 按钮")
    }
    
    private func switchToTab(_ index: Int) {
        guard index != selectedTab else { return }
        
        // 滚动到对应页面
        let offsetX = CGFloat(index) * view.bounds.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension MessageViewController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        if index != selectedTab {
            selectedTab = index
            tabBarView.selectTab(at: index)
        }
    }
}

