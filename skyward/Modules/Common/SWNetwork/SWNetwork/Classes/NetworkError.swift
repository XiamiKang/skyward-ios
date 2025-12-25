//
//  NetworkError.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

/// 错误处理

import Foundation
import Moya

/// 网络错误枚举
public enum NetworkError: Error, LocalizedError {
    case networkConnection
    case timeout
    case serverError(statusCode: Int, message: String?)
    case parsingError(underlying: Error)
    case authenticationFailed
    case invalidURL
    case parameterEncodingFailed
    case cancelled
    case unknown(Error)
    
    /// 错误描述
    public var errorDescription: String? {
        switch self {
        case .networkConnection:
            return "网络连接失败，请检查网络设置"
        case .timeout:
            return "请求超时，请稍后重试"
        case .serverError(let statusCode, let message):
            return message ?? "服务器错误 (状态码: \(statusCode))"
        case .parsingError:
            return "数据解析失败"
        case .authenticationFailed:
            return "认证失败，请重新登录"
        case .invalidURL:
            return "无效的URL"
        case .parameterEncodingFailed:
            return "参数编码失败"
        case .cancelled:
            return "请求已取消"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}

/// 网络错误处理工具类
public struct NetworkErrorHandler {
    
    /// 转换Moya错误为Network错误
    public static func convertMoyaError(_ error: MoyaError) -> NetworkError {
        switch error {
        case .underlying(let nsError as NSError, _):
            return convertNSError(nsError)
        case .jsonMapping, .objectMapping, .encodableMapping:
            return .parsingError(underlying: error)
        case .statusCode(let response):
            return .serverError(statusCode: response.statusCode, message: nil)
        case .requestMapping, .parameterEncoding:
            return .parameterEncodingFailed
        default:
            return .unknown(error)
        }
    }
    
    /// 转换NSError为Network错误
    public static func convertNSError(_ error: NSError) -> NetworkError {
        switch error.code {
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
            return .networkConnection
        case NSURLErrorCancelled:
            return .cancelled
        default:
            return .unknown(error)
        }
    }
}

