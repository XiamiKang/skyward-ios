//
//  BaseViewController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import UIKit
import Combine

open class BaseViewController: UIViewController, DataLoadControllerDelegate {
        
    public var cancellables = Set<AnyCancellable>()
    
    /// 是否正在显示中
    public var isShowing: Bool = false
    
    private lazy var loadViewModel: BaseViewModel = {
        return loadStatusViewModel()
    }()
    
    // Custom LifeCycle Flags
    private var _firstWillAppear: Bool = true
    private var _firstDidAppear: Bool  = true
    private var _sourceHasNarBar: Bool = false
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if let navController = self.navigationController {
            _sourceHasNarBar = !navController.isNavigationBarHidden
        }
        
        // 约束Controller初始化逻辑
        configureBeforeSetupViews()
        setupViews()
        setupConstraints()
        configureAfterSetupViews()
        bindViewModel()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.autoDetectNavigationBar, let navController = self.navigationController {
            _sourceHasNarBar = !navController.isNavigationBarHidden
            
            let hideAnimated = _shouldHideNavBarAnimated()
            if self.hasNavBar {
                if !_sourceHasNarBar {
                    self.navigationController?.setNavigationBarHidden(false, animated: hideAnimated)
                }
            } else {
                if _sourceHasNarBar {
                    self.navigationController?.setNavigationBarHidden(true, animated: hideAnimated)
                }
            }
        }
        
        if _firstWillAppear {
            _firstWillAppear = false
            viewWillAppearForTheFirstTime(animated)
        } else {
            viewWillAppearForOtherTimes(animated)
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isShowing = true
        if _firstDidAppear {
            _firstDidAppear = false
            viewDidAppearForTheFirstTime(animated)
        } else {
            viewDidAppearForOtherTimes(animated)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShowing = false
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    open func loadStatusViewModel() -> BaseViewModel {
        return BaseViewModel()
    }
    
    open func dataLoadPlugin() -> DataLoadType {
        return DefaultDataLoad()
    }
    
    // MARK: - DataLoadControllerDelegate
    open func dataLoadContainerView() -> UIView {
        return self.view
    }
    
    open func dataLoadConstraintsView() -> UIView? {
        return nil
    }
    
    open func networkErrorActionInDataLoadController() {
        loadViewModel.loadStatus = .loading(shouldShowLoading: true, message: nil)
    }
    
    open func emptyDataActionInDataLoadController() {
        loadViewModel.loadStatus = .loading(shouldShowLoading: true, message: nil)
    }
    
    // MARK: - View Controller Init Logic
    open func configureBeforeSetupViews() {}
    open func setupViews() {}
    open func setupConstraints() {}
    open func configureAfterSetupViews() {}
    open func bindViewModel() {
        bindPublisher(loadViewModel.$loadStatus.eraseToAnyPublisher()) { [weak self] value in
            self?.loadStatusChanged(value)
        }
    }
    
    // MARK: - Life Cycle
    open func viewWillAppearForTheFirstTime(_ animated: Bool) {}
    open func viewWillAppearForOtherTimes(_ animated: Bool) {}
    open func viewDidAppearForTheFirstTime(_ animated: Bool) {}
    open func viewDidAppearForOtherTimes(_ animated: Bool) {}
    
    // MARK: - Navigation Bar Detect
    open var autoDetectNavigationBar: Bool = {
        return true
    }()
    
    open var hasNavBar: Bool {
        return true
    }
    
    open var hideNavBarAnimated: Bool = {
        return true
    }()
    
    // 获取状态栏和导航栏总高度
    open var naviBarHeight: CGFloat {
        var height = 20.0
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            height = window.safeAreaInsets.top
        }
        return height + 44
    }
    
    open func loadStatusChanged(_ loadStatus: DataLoadStatus) {
        dataLoadController.hideEmptyDataView()
        dataLoadController.hideNetworkErrorView()
        switch loadStatus {
        case .loading(let shouldShowLoading, _):
            if shouldShowLoading {
                let loadMessage = loadViewModel.loadingMessage(loadStatus)
                dataLoadController.showLoadingView(true, message: loadMessage)
            }
        case .finished:
            dataLoadController.hideLoadingView()
        case .emptyData:
            dataLoadController.hideLoadingView()
            let emptyMsg = loadViewModel.emptyDataMessage(loadStatus)
            dataLoadController.showEmptyDataView(emptyMsg)
        case .networkError(let isToast, _):
            dataLoadController.hideLoadingView()
            let errorrMsg = loadViewModel.networkMessage(loadStatus)
            if isToast {
//                dataLoadContainerView().makeToast(errorrMsg)
            } else {
                dataLoadController.hideLoadingView()
                dataLoadController.showNetworkErrorView(errorrMsg)
            }
        }
    }
    
    public func bindPublisher<T>(_ publisher: AnyPublisher<T, Never>,
                                 onRecievedValue: @escaping ((T)->Void)) {
        publisher.dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { value in
                onRecievedValue(value)
            }
            .store(in: &cancellables)
    }
    
    public func bindPublisherNoDropFirst<T>(_ publisher: AnyPublisher<T, Never>,
                                            onRecievedValue: @escaping ((T)->Void)) {
        publisher.receive(on: DispatchQueue.main)
            .sink { value in
                onRecievedValue(value)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func _shouldHideNavBarAnimated() -> Bool {
        
        let animated = self.hideNavBarAnimated
        guard let tabController = self.navigationController?.topViewController as? UITabBarController else {
            return animated
        }
        
        guard let controllers = tabController.viewControllers, controllers.contains(self) else {
            return animated
        }
        
        guard tabController.selectedViewController != self else {
            return animated
        }
        
        return false
    }
    
    // MARK: - Lazy properties
    public lazy var dataLoadController: DataLoadController = {
        return DataLoadController(delegate: self, dataLoadType: dataLoadPlugin())
    }()
}
