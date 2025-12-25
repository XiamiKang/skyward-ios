//
//  AppInfo.swift
//  gy
//
//  Created by wanghui20 on 2018/4/17.
//  Copyright © 2018年 Longfor. All rights reserved.
//

import Foundation

public class AppInfo: NSObject {
    
    /// App名称，CFBundleDisplayName、CFBundleName，value,e.g. 龙湖
    public static var appName: String? {
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return appName
        } else if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return appName
        } else {
            return nil
        }
    }
        
    /// App main version, `CFBundleShortVersionString` value, e.g. 1.0
    public static var appVersion: String? {
        if let info = Bundle.main.infoDictionary {
            return info["CFBundleShortVersionString"] as? String
        }
        return nil
    }
    
    /// App build number, `CFBundleVersion` value, e.g. 1100
    public static var buildNumber: String? {
        if let info = Bundle.main.infoDictionary {
            return info["CFBundleVersion"] as? String
        }
        return nil
    }
    
    /// iPhone platform value is `iPhone`
    public static var platform: String = "iPhone"
    
    /// Bundle Id
    public static var bundleId: String? = Bundle.main.bundleIdentifier
    
}
