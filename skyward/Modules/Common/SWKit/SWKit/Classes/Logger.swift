//
//  Logger.swift
//  SWKit
//
//  Created by zhaobo on 2026/1/26.
//

import Foundation
import CocoaLumberjack

/// 枚举，为每条日志消息添加适当的前缀符号
///
/// - error: 错误日志类型
/// - info: 信息日志类型
/// - debug: 调试日志类型
/// - verbose: 详细日志类型
/// - warning: 警告日志类型
/// - severe: 严重日志类型
public enum LogLevel: String {
    case error = "❌[ERROR]"
    case warning = "⚠️[WARNING]"
    case info = "ℹ️[INFO]"
    case debug = "🐞[DEBUG]"
    case verbose = "🔬[VERBOSE]"
}

/// 构建或归档环境
public enum EnvType {
    case prod
    case other
}

/// 在 DEBUG 标志下包装 Swift.print()
///
/// - Note: *print()* 可能会导致[安全漏洞](https://codifiedsecurity.com/mobile-app-security-testing-checklist-ios/)
///
/// - Parameter object: 需要记录的对象
///
public func print(_ object: Any) {
    #if DEBUG
//    Swift.print(object)
    Logger.debug(object)
    #endif
}

public func debugPrint(_ object: Any) {
    #if DEBUG
    Logger.debug(object)
    #endif
}

public class Logger {

    private static var fileLogger = DDFileLogger()

    public static func registe(with env: EnvType) {

        /// 文件日志
        fileLogger.rollingFrequency = TimeInterval(60*60*24) // 每天创建新日志文件
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7 // 保留7天日志
        fileLogger.logFileManager.logFilesDiskQuota = 1024 * 1024 * 50 // 50MB 磁盘配额

        if env == .prod {
            DDLog.add(fileLogger, with: .info)
        } else {
            /// 系统日志（包含 Xcode 控制台）
            DDLog.add(DDOSLogger.sharedInstance, with: .all)
            DDLog.add(fileLogger, with: .all)
        }
    }

    // MARK: - Loging methods

    public class func error( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        DDLogError("\(LogLevel.error.rawValue) [\((filename as NSString).lastPathComponent)]:\(line) \(funcName) -> \(object)")
    }

    public class func warning( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        DDLogWarn("\(LogLevel.warning.rawValue) [\((filename as NSString).lastPathComponent)]:\(line) \(funcName) -> \(object)")
    }

    public class func info( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        DDLogInfo("\(LogLevel.info.rawValue) [\((filename as NSString).lastPathComponent)]:\(line) \(funcName) -> \(object)")
    }

    public class func debug( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        DDLogDebug("\(LogLevel.debug.rawValue) [\((filename as NSString).lastPathComponent)]:\(line) \(funcName) -> \(object)")
    }

    public class func verbose( _ object: Any, filename: String = #file, line: Int = #line, funcName: String = #function) {
        DDLogVerbose("\(LogLevel.verbose.rawValue) [\((filename as NSString).lastPathComponent)]:\(line) \(funcName) -> \(object)")
    }

    // MARK: - File Management

    /// 获取所有日志文件的路径集合
    /// - Returns: 日志文件 URL 数组
    public class func getLogFiles() -> [URL] {
        let logFileURLs = fileLogger.logFileManager.sortedLogFilePaths.map { URL(fileURLWithPath: $0)}
        return logFileURLs
    }

    /// 删除所有本地日志文件
    /// - Returns: 是否删除成功
    @discardableResult
    public class func deleteAllLogs() -> Bool {
        let logFileURLs = getLogFiles()

        var deleteSuccess = true
        for fileURL in logFileURLs {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                deleteSuccess = false
                print("删除日志文件失败: \(fileURL.path), 错误: \(error.localizedDescription)")
            }
        }

        return deleteSuccess
    }
}
