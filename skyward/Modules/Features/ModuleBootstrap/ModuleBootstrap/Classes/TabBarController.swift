//
//  TabBarController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import TXKit
import SWTheme
import ModuleHome
import ModuleMessage
import ModulePersonal
import ModuleMap

class TabBarController: UITabBarController {
    
    public init(_ defaultTag: Int = 0) {
        super.init(nibName: nil, bundle: nil)
        
        self.tabBar.backgroundImage = nil
        self.tabBar.shadowImage = nil
        self.tabBar.isTranslucent = false
        self.tabBar.barTintColor = .white

    
        // 更新外观设置
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = .white
        tabBarAppearance.shadowColor = .black.withAlphaComponent(0.1)
        tabBarAppearance.shadowImage = nil
        tabBarAppearance.backgroundImage = nil
        
        // 设置标题颜色
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 12)
        ]
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: ThemeManager.current.mainColor,
            .font: UIFont.systemFont(ofSize: 12)
        ]
        
        // 确保列表项和内联项也使用相同的颜色设置
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes
        
        self.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            self.tabBar.scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.viewControllers = [homeVC, mapVC, mineVC]
        self.selectedIndex = 0
    }
    
    // MARK: - Lazy Properties
    private lazy var homeVC: HomeViewController = {
        let vc = HomeViewController()
        let normalImage = BootstrapModule.image(named: "tabbar_home_normal")
        let selectedImage = BootstrapModule.image(named: "tabbar_home_select")?.withRenderingMode(.alwaysOriginal)
        vc.tabBarItem = UITabBarItem(title: "首页", image: normalImage, selectedImage: selectedImage)
        vc.tabBarItem.tag = 1000
        return vc
    }()
    
    private lazy var mapVC: MapViewController = {
        let vc = MapViewController()
        let normalImage = BootstrapModule.image(named: "tabbar_map_normal")
        let selectedImage = BootstrapModule.image(named: "tabbar_map_select")?.withRenderingMode(.alwaysOriginal)
        vc.tabBarItem = UITabBarItem(title: "地图", image: normalImage, selectedImage: selectedImage)
        vc.tabBarItem.tag = 1001
        return vc
    }()
    
    private lazy var messageVC: MessageViewController = {
        let vc = MessageViewController()
        let normalImage = BootstrapModule.image(named: "tabbar_message_normal")
        let selectedImage = BootstrapModule.image(named: "tabbar_message_select")?.withRenderingMode(.alwaysOriginal)
        vc.tabBarItem = UITabBarItem(title: "消息", image: normalImage, selectedImage: selectedImage)
        vc.tabBarItem.tag = 1002
        return vc
    }()
    
    private lazy var mineVC: PersonalViewController = {
        let vc = PersonalViewController()
        let normalImage = BootstrapModule.image(named: "tabbar_mine_normal")
        let selectedImage = BootstrapModule.image(named: "tabbar_mine_select")?.withRenderingMode(.alwaysOriginal)
        vc.tabBarItem = UITabBarItem(title: "我的", image: normalImage, selectedImage: selectedImage)
        vc.tabBarItem.tag = 1003
        return vc
    }()
}
