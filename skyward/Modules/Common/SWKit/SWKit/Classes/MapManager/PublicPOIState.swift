//
//  PublicPOIState.swift
//  ModuleMap
//
//  Created by TXTS on 2026/2/26.
//

import Foundation

// MARK: - 下载状态
public enum DownloadState: String, Codable {
    case notDownloaded = "notDownloaded"      // 未下载
    case downloading = "downloading"           // 下载中
    case downloaded = "downloaded"             // 已下载
}

// MARK: - 导入状态
public enum ImportState: String, Codable {
    case notImported = "notImported"           // 未导入
    case importing = "importing"               // 导入中
    case imported = "imported"                  // 导入完成
}

// MARK: - 下载任务信息
struct DownloadTaskInfo: Codable {
    var fileUrl: String
    var fileMd5: String
    var version: String
    var fileName: String                           // 只保存文件名
    var downloadStartTime: Date                    // 下载开始时间
    var downloadEndTime: Date?                     // 下载结束时间
    
    // 计算属性：动态获取本地文件路径
    var localFilePath: String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return (documentsPath as NSString).appendingPathComponent(fileName)
    }
}

// MARK: - 导入任务信息
struct ImportTaskInfo: Codable {
    var fileName: String                         // 要导入的文件路径
    var fileMd5: String                          // 文件MD5
    var version: String                          // 版本号
    var totalCount: Int = 0                      // 总记录数
    var importedCount: Int = 0                   // 已导入记录数
    var lastImportedId: String?                  // 最后导入的ID（用于断点续导）
    var importStartTime: Date                    // 导入开始时间
    var importEndTime: Date?                     // 导入结束时间
    var batchSize: Int = 10000                   // 每批导入数量
    var currentBatch: Int = 0                    // 当前批次
    
    // 计算属性：动态获取完整路径
    var filePath: String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return (documentsPath as NSString).appendingPathComponent(fileName)
    }
}
