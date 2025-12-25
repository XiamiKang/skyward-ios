//
//  ModuleType.swift
//  skyward
//
//  Created by 赵波 on 2025/11/11.
//

import Foundation
import UIKit
import TXRouterKit

public protocol ModuleType {
    static var name: String { get }
    static var bundle: Bundle { get }
    
    /// 配置当前模块的路由集合
    var routeSettings: [RoutableType.Type] { get }
    
    /// 安装模块
    /// 运行在didFinishLaunching中，应用启动后，所有必须的前置逻辑，例如APM初始化，各种key的配置等
    func moduleSetup()
    
    /// 图片加载
    static func image(named name: String) -> UIImage?
}

extension ModuleType {
    
    /// 获取当前模块的资源包
    public static var bundle: Bundle {
//        if let path = Bundle.main.path(forResource: Self.name, ofType: "bundle"), let bundle = Bundle(path: path) {
//            return bundle
//        }
        
    
        let bundlePath = Bundle(for: Self.self as! AnyClass).resourceURL?.appendingPathComponent(Self.name + ".bundle")
        if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
            return bundle
        }
        
        return Bundle(for: FakeClass.self)
    }
    
    public var routeSettings: [RoutableType.Type] { return [] }
    
    public func moduleSetup() {}
    
    static public func image(named name: String) -> UIImage? {
        return UIImage(named: name, in: Self.bundle, compatibleWith: nil)
    }
}

fileprivate class FakeClass {}
