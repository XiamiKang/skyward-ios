//
//  SandBox.swift
//
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024年 Longfor. All rights reserved.
//

import UIKit

/**
    homePath:                       |AppData
    docPath:                        |---- Documents
    libPath:                        |---- Library
    libPreferencePath:              |-------- Preferences
    libCachePath:                   |-------- Caches
    tmpPath:                        |---- tmp
 */

public class SandBox: NSObject {

    public static var homePath: String {
        return NSHomeDirectory()
    }
    
    public static var appPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return paths.first!
    }
    
    public static var docPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return paths.first!
    }
    
    public static var docmentsURL: URL? {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    public static var libPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return paths.first!
    }
    public static var libPreferencePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return paths.first!.appending("/Preference")
    }
    
    public static var libCachePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        return paths.first!
    }
    
    public static var tmpPath: String {
        return NSHomeDirectory().appending("/tmp")
    }
    
}
