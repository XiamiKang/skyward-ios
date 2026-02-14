//
//  FirmwareError.swift
//  Pods
//
//  Created by TXTS on 2026/1/13.
//

import Foundation

// MARK: - 错误类型
enum FirmwareError: Error, LocalizedError {
    case invalidURL
    case noData
    case downloadFailed
    case checksumMismatch
    case fileSaveFailed
    case deviceNotConnected
    case invalidResponse
    case apiError(code: String, message: String)
    case noNewVersion
    case versionParseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有收到数据"
        case .downloadFailed:
            return "下载失败"
        case .checksumMismatch:
            return "文件校验失败"
        case .fileSaveFailed:
            return "文件保存失败"
        case .deviceNotConnected:
            return "设备未连接"
        case .invalidResponse:
            return "无效的响应"
        case .apiError(let code, let message):
            return "API错误 [\(code)]: \(message)"
        case .noNewVersion:
            return "当前已是最新版本"
        case .versionParseError:
            return "版本号解析失败"
        }
    }
}

// 您的PersonalError扩展
extension PersonalError {
    var asFirmwareError: FirmwareError {
        switch self {
        case .networkError(let message):
            return .apiError(code: "NETWORK_ERROR", message: message)
        case .parseError(let message):
            return .apiError(code: "PARSE_ERROR", message: message)
        case .businessError(let message, let code):
            return .apiError(code: code, message: message)
        }
    }
}
