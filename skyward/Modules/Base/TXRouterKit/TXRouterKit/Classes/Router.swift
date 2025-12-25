//
//  Router.swift
//  skyward
//
//  Created by 赵波 on 2025/11/11.
//

import UIKit

enum RouterError: Error {
    case invalidPattern
    case schemeNotRecognized
    case noMatchRoute
}

extension RouterError: CustomStringConvertible, CustomDebugStringConvertible {
    
    var description: String {
        switch self {
        case .invalidPattern:
            return "invalidPattern"
        case .schemeNotRecognized:
            return "schemeNotRecognized"
        case .noMatchRoute:
            return "noMatchRoute"
        }
    }
    
    var debugDescription: String {
        return description
    }
}

public enum RouterPriority {
    case low
    case normal
    case high
}

/// Router for registe a routable type and handle url
open class Router {
    
    /// This dictionary is a mapping from URL to RoutableType.
    /// The key is URL, value is the corresponding RoutableType.
    private(set) var lowRouteMap = [String: RoutableType.Type]()
    private(set) var normalRouteMap = [String: RoutableType.Type]()
    private(set) var highRouteMap = [String: RoutableType.Type]()
    
    /// Matcher for url and routable type
    public let matcher = URLMatcher()
    
    open weak var delegate: RouterDelegate?
    
    /// Default instance
    public static var `default`: Router = Router()
    
    private var tabRouteCache: [String: RoutableType.Type] = [:]
    
    // MARK: - Registe
    
    /// Registe single RoutableType
    open func registe(_ routableType: RoutableType.Type) {
        for pattern in routableType.patterns {
            guard !pattern.isEmpty else {
                fatalError(RouterError.invalidPattern.description)
            }
            switch routableType.priority {
            case .low:
                self.lowRouteMap[pattern] = routableType
            case .normal:
                self.normalRouteMap[pattern] = routableType
            case .high:
                self.highRouteMap[pattern] = routableType
            }
        }
    }
    
    /// Registe multiple RoutableType
    open func registe(_ routableTypes: [RoutableType.Type]) {
        for routableType in routableTypes {
            self.registe(routableType)
        }
    }
    
    // MARK: - Handle
    @discardableResult
    open func handle(_ url: URLConvertible,
                     params: [String: String]? = nil,
                     configuration: ((RoutableType) -> Void)? = nil,
                     callback:((Any?) -> Void)? = nil) -> Bool {
        guard let routableType = matcher.routableType(for: url,
                                                      lowRouteMap: lowRouteMap,
                                                      normalRouteMap: normalRouteMap,
                                                      highRouteMap: highRouteMap) else {
            // 路由表中找不到该路由，直接不处理，返回false
            return false
        }
        
        /// 只处理RoutableActionType类型的路由
        guard let routableType = routableType as? RoutableActionType.Type else {
            return false
        }
        
        var newURL: URLConvertible = url
        if let parameters = params, var urlComponents = URLComponents(string: url.urlStringValue) {
            var items: [URLQueryItem] = urlComponents.queryItems ?? []
            items.append(contentsOf: parameters.map { URLQueryItem(name: $0, value: $1) })
            urlComponents.queryItems = items
            if let u = urlComponents.url {
                newURL = u
            }
        }
        
        return routableType.handle(newURL, callback)
    }
    
    /// Show
    private func showViewController(_ controller: UIViewController,
                                    fromViewController: UIViewController,
                                    segueKind: SegueKind) {
        
        let showColsure: (_ controller: UIViewController,
                          _ from: UIViewController,
                          _ segueKind: SegueKind,
                          _ completion: @escaping () -> Void) -> Void = { controller, from, segueKind, completion in
            if let routableController = controller as? ControllerType {
                routableController.show(fromViewController) {
                    completion()
                }
            }
        }
        
        if self.delegate != nil {
            self.delegate?.shouldShowController(controller,
                                                fromViewController: fromViewController,
                                                segueKind: segueKind) { shouldShow in
                if shouldShow != false {
                    self.delegate?.willShowController(controller,
                                                      fromViewController: fromViewController,
                                                      segueKind: segueKind)
                    
                    showColsure(controller, fromViewController, segueKind) {
                        self.delegate?.didShownController(controller,
                                                          fromViewController: fromViewController,
                                                          segueKind: segueKind)
                    }
                }
            }
        } else {
            showColsure(controller, fromViewController, segueKind) { }
        }
    }
}


extension UIWindow {
    
    /// Returns the top most controller
    class func topMostViewController() -> UIViewController? {
        let window = UIApplication.shared.delegate?.window
        let rootViewController = window??.rootViewController
        return top(of: rootViewController)
    }
    
    /// Returns the top most view controller from given view controller's stack.
    class func top(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.top(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.top(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.top(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.top(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.top(of: childViewController)
            }
        }
        return viewController
    }
}
