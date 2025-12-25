# ModuleHome - 首页模块

首页模块是 Skyward 应用的核心功能模块，提供了用户进入应用后的主要界面和交互功能。

## 📁 文件结构

```
ModuleHome/
├── Classes/
│   ├── ViewControllers/
│   │   ├── HomeViewController.swift          # 主首页控制器
│   │   └── HomeDemoViewController.swift      # 演示控制器
│   ├── Views/
│   │   ├── HomeQuickActionsView.swift        # 快捷操作视图
│   │   ├── HomeSectionHeaderView.swift       # 分组标题视图
│   │   └── HomeStatsView.swift               # 统计信息视图
│   ├── Models/
│   │   └── HomeModel.swift                   # 数据模型定义
│   ├── Utils/
│   │   ├── HomeConstants.swift               # 常量定义
│   │   └── HomeCacheManager.swift            # 缓存管理器
│   └── HomeViewModel.swift                   # 首页视图模型
└── README.md
```

## 🎯 功能特性

### 1. 模块化UI组件
- **HomeQuickActionsView**: 快捷操作按钮网格
- **HomeSectionHeaderView**: 分组标题，支持查看更多
- **HomeStatsView**: 统计信息卡片展示

### 2. 数据管理
- **HomeViewModel**: 业务逻辑和数据处理
- **HomeCacheManager**: 智能缓存机制，支持过期时间
- **数据模型**: 结构化的数据定义

### 3. 交互功能
- 快捷操作点击事件
- 查看更多功能
- 下拉刷新支持
- 错误处理和提示

### 4. 主题支持
- 完全支持 SWTheme 主题系统
- 动态颜色适配
- 字体和样式统一

## 🚀 使用方法

### 基础使用

```swift
// 在 App 中使用主首页
let homeVC = HomeViewController()
navigationController?.pushViewController(homeVC, animated: true)

// 使用演示控制器
let demoVC = HomeDemoViewController()
navigationController?.pushViewController(demoVC, animated: true)
```

### 自定义快捷操作

```swift
// 在 ViewModel 中自定义快捷操作
let customActions = [
    HomeItem(title: "自定义", icon: "star", type: .custom),
    HomeItem(title: "设置", icon: "gear", type: .settings)
]

viewModel.quickActions = customActions
```

### 监听事件

```swift
// 监听快捷操作点击
NotificationCenter.default.addObserver(
    forName: .homeQuickActionTapped,
    object: nil,
    queue: .main
) { notification in
    if let action = notification.userInfo?["action"] as? HomeItem {
        print("点击了: \(action.title)")
    }
}

// 监听查看更多
NotificationCenter.default.addObserver(
    forName: .homeSectionMoreButtonTapped,
    object: nil,
    queue: .main
) { notification in
    if let title = notification.userInfo?["title"] as? String {
        print("查看更多: \(title)")
    }
}
```

## 📊 数据模型

### HomeItem - 快捷操作项
```swift
public struct HomeItem {
    public let title: String
    public let icon: String?  // SF Symbols 名称
    public let type: HomeItemType
}
```

### HomeStats - 统计信息
```swift
public struct HomeStats {
    public let title: String
    public let value: String
}
```

### HomeData - 首页数据
```swift
public struct HomeData {
    public let quickActions: [HomeItem]
    public let totalTasks: String
    public let completedTasks: String
    public let inProgressTasks: String
}
```

## 🎨 主题定制

所有组件都支持 SWTheme 主题系统，支持以下属性：

- **背景颜色**: `ThemeManager.current.backgroundColor`
- **主色调**: `ThemeManager.current.mainColor`
- **文字颜色**: `ThemeManager.current.textColor`
- **次要文字**: `ThemeManager.current.secondaryTextColor`
- **边框颜色**: `ThemeManager.current.borderColor`

## 💾 缓存机制

首页模块实现了智能缓存系统：

- **缓存有效期**: 5分钟 (可配置)
- **自动清理**: 过期缓存自动清除
- **内存优化**: 支持缓存数据序列化
- **网络优化**: 优先使用缓存，后台更新

```swift
// 手动清除缓存
HomeCacheManager.shared.clearAllCache()

// 检查缓存有效性
let isValid = HomeCacheManager.shared.isCacheValid(for: HomeConstants.homeDataCacheKey)
```

## 🔧 扩展开发

### 添加新的快捷操作类型

```swift
public enum HomeItemType: String, CaseIterable {
    case task = "task"
    case profile = "profile"
    case settings = "settings"
    case custom = "custom"
    // 添加新类型
    case newFeature = "newFeature"
}
```

### 自定义统计信息

```swift
// 扩展 HomeStatsView
public func addCustomStat(title: String, value: String) {
    let stats = HomeStats(title: title, value: value)
    // 添加到现有统计信息中
}
```

## 📝 注意事项

1. **图标资源**: 当前使用 SF Symbols，后续需要替换为实际图标
2. **网络请求**: 目前使用模拟数据，需要接入实际 API
3. **错误处理**: 已添加基础错误处理，可根据需求扩展
4. **性能优化**: 支持懒加载和内存管理

## 🔮 后续优化

- [ ] 添加实际网络请求
- [ ] 集成真实图标资源
- [ ] 支持下拉刷新
- [ ] 添加动画效果
- [ ] 支持深色模式
- [ ] 添加搜索功能
- [ ] 支持个性化配置

## 📞 支持

如有问题或建议，请联系开发团队。