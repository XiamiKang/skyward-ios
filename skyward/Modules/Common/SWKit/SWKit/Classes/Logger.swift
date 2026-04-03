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



//6. 路线规划沿线地图下载完成
//解析路线，提取起点、终点、途经点
//
//沿路线向两侧扩展缓冲区，确定覆盖区域
//
//将区域映射到地图瓦片网格，生成待下载数据单元
//
//检查本地已有数据，去重并增量下载
//
//预估数据量并提示用户
//
//支持自动触发（需授权）或手动确认后下载
//
//支持下载队列管理、断点续传
//
//支持网络策略（仅Wi-Fi/允许移动网络）
//
//下载前检查存储空间，不足时提示
//
//实时展示下载进度与剩余时间
//
//下载完成后通过通知栏/弹窗反馈
//
//支持失败重试与部分失败项单独重试
//
//路线变更时提示原数据可能不完整，建议补充下载
//
//地图版本更新时提示需更新沿线数据
//
//支持过期数据清理，与普通离线地图复用数据避免重复下载
//
//7. 离线地图特定区域下载
//支持按行政区划（国家/省/市/区县）选择下载区域
//
//支持矩形框选、多边形/自由绘制选择区域
//
//支持当前位置周边（预设半径）快速下载
//
//支持收藏常用区域，方便再次下载或更新
//
//支持选择地图缩放级别范围，控制数据精度与大小
//
//支持选择数据类型（底图、兴趣点、3D、导航路网等）
//
//仅下载边界内数据，进行区域裁剪
//
//支持多任务并行/串行下载，可调整优先级
//
//支持暂停、继续、取消单个或全部任务
//
//下载前检测存储空间，不足时提示降级选项
//
//提供区域详情页（名称、范围预览、大小、状态、进度）
//
//提供已下载区域列表，支持更新、删除、排序
//
//地图上以半透明蒙层可视化已下载区域
//
//支持增量更新，仅下载变更部分
//
//支持自动更新提醒与定期更新策略
//
//支持自动清理过期未使用的离线地图
//
//离线状态下支持区域内地点搜索与离线导航
