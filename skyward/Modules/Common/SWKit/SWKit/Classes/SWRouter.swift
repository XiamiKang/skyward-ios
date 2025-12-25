//
//  SWRouter.swift
//  skyward
//
//  Created by 赵波 on 2025/11/13.
//

import TXRouterKit

open class SWRouter {
    private static let needLoginKey = "needLogin"
    
    // MARK: - Public
    public static func handle(_ url: any URLConvertible,
                              parameters: [String : String]? = nil, // 路由参数
                              isNeedLogin:Bool = false, // 是否必须登录
                              configuration: ((any RoutableType) -> Void)? = nil,
                              callback:((Any?) -> Void)? = nil) {
    
        /// 1、所有路由执行前都要进行隐私检测
//        if checkPrivacy {
//            return
//        }
         
        /// 2、隐私检测通过后，需要检测参数中是否有需要登录的情况
        if SWRouter.handleLogin(url,parameters: parameters, isNeedLogin: isNeedLogin, callback: callback) {
            return
        }
        
        /// 3、接着执行真正路由
        Router.default.handle(url, params: parameters, configuration: configuration, callback: callback)
    }
    
    /// 通过Push或Present的方式来打开一个VC
    /// - Parameters:
    ///   - viewController: 待打开的VC
    ///   - animated: 是否使用动画，默认true
    ///   - isPush: 是否使用push，默认true
    public static func show(_ viewController: UIViewController, animated: Bool = true, isPush: Bool = true) {
        let topVC = UIWindow.topViewController()
        if isPush {
            topVC?.navigationController?.pushViewController(viewController, animated: animated)
        } else {
            topVC?.present(viewController, animated: animated)
        }
    }
    
    // MARK: - Private
    
    /// 路由跳转登录状态拦截
    /// - Parameters:
    ///   - url: 路由地址,如果出现  needLogin=1 则需要登录
    ///   - parameters: 路由参数,如果出现 parameters["needLogin"] = 1 则需要登录
    ///   - isNeedLogin: 如果值为true 则需要登录
    ///   - configuration: 路由回调
    private static func handleLogin(_ url:any URLConvertible,
                                    parameters: [String : String]? = nil,
                                    isNeedLogin:Bool = false,
                                    configuration: ((any RoutableType) -> Void)? = nil,
                                    callback:((Any?) -> Void)? = nil) -> Bool {
//        if xxx.isLogin {
//            return false
//        }
        
        if isNeedLogin {
            openLogin(url, parameters,configuration,callback)
            return true
        }
        
        if parameters?[needLoginKey] == "1" {
            openLogin(url, parameters,configuration,callback)
            return true
        }
        
        let params = url.urlValue?.queryAndFragmentParameters
        if params?[needLoginKey] == "1" {
            openLogin(url, parameters,configuration,callback)
            return true
        }
        
        return false
    }
    
    private static func openLogin(_ url:any URLConvertible,
                                  _ parameters: [String : String]? = nil,
                                  _ configuration: ((any RoutableType) -> Void)? = nil,
                                  _ callback:((Any?) -> Void)? = nil) {
        Router.default.handle(RouteTable.loginPageUrl, callback:  { result in
            
            if let loginResult = result as? [String: String], loginResult["data"] == "1" {
                DispatchQueue.mp_asyncAfter(0.4) {
                    SWRouter.handle(url,parameters: parameters,configuration: configuration, callback: callback)
                }
            }
        })
    }
}
