//
//  TokenManager.swift
//  SWNetwork
//
//  Created by 赵波 on 2025/11/21.
//

import Foundation
import Moya

// MARK: - Token管理器
public class TokenManager {
    
    /// 单例实例
    public static let shared = TokenManager()
    
    // Token存储的键名
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let accessTokenExpiryKey = "expires_in"
    
    // 存储工具
    private let storage = UserDefaults.standard
    
    // Token刷新回调队列
    private var refreshCallbacks: [(Result<String, Error>) -> Void] = []
    private var isRefreshing = false
    private let lock = NSRecursiveLock()
    
    // MARK: - Access Token
    
    /// 获取当前的Access Token
    public var accessToken: String?{
        return storage.string(forKey: accessTokenKey)
    }
    
    /// 保存Access Token
    public func saveAccessToken(_ token: String) {
        storage.set(token, forKey: accessTokenKey)
    }
    
    /// 保存Access Token及其过期时间
    public func saveAccessToken(_ token: String, expiresIn seconds: TimeInterval) {
        let expiryDate = Date().addingTimeInterval(seconds - 60) // 提前60秒过期，避免边界情况
        storage.set(token, forKey: accessTokenKey)
        storage.set(expiryDate.timeIntervalSince1970, forKey: accessTokenExpiryKey)
    }
    
    // MARK: - Refresh Token
    
    /// 获取当前的Refresh Token
    public var refreshToken: String? {
        return storage.string(forKey: refreshTokenKey)
    }
    
    /// 保存Refresh Token
    public func saveRefreshToken(_ token: String) {
        storage.set(token, forKey: refreshTokenKey)
    }
    
    // MARK: - Access Token 过期时间
    
    /// 获取Access Token过期时间
    public var accessTokenExpiry: Date? {
        let timestamp = storage.double(forKey: accessTokenExpiryKey)
        if timestamp == 0 {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - 清除Token
    
    /// 清除所有Token
    public func clearTokens() {
        storage.removeObject(forKey: accessTokenKey)
        storage.removeObject(forKey: refreshTokenKey)
        storage.removeObject(forKey: accessTokenExpiryKey)
        
        // 清空回调队列
        lock.lock()
        refreshCallbacks.removeAll()
        isRefreshing = false
        lock.unlock()
    }
    
    // MARK: - Token有效性检查
    
    /// 检查token是否有效
    public var isTokenValid: Bool {
        guard let accessToken = accessToken, !accessToken.isEmpty else {
            return false
        }
        
        // 如果设置了过期时间，检查是否过期
        if let expiryDate = accessTokenExpiry {
            return Date() < expiryDate
        }
        
        return true
    }
    
    /// Token是否即将过期（6小时）
    public var isTokenNearlyExpired: Bool {
        guard let expiryDate = accessTokenExpiry else {
            return false
        }
        let fiveMinutesLater = Date().addingTimeInterval(6 * 60 * 60)
        return Date() < expiryDate && fiveMinutesLater > expiryDate
    }
    
    // MARK: - Token刷新协调（避免并发刷新）
    
    /// 请求刷新AccessToken
    /// - Parameter callback: 刷新完成后的回调
    public func requestRefreshAccessToken(_ callback: @escaping (Result<String, Error>) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        // 将回调添加到队列
        refreshCallbacks.append(callback)
        
        // 如果当前没有刷新正在进行，立即触发刷新
        if !isRefreshing {
            isRefreshing = true
            performTokenRefresh()
        }
    }
    
    /// 处理Token刷新结果
    /// - Parameter result: 刷新结果
    public func handleRefreshResult(_ result: Result<String, Error>) {
        lock.lock()
        let callbacks = refreshCallbacks
        refreshCallbacks.removeAll()
        isRefreshing = false
        lock.unlock()
        
        // 通知所有等待的回调
        callbacks.forEach { $0(result) }
    }
    
    /// 主动刷新Token
    /// - Parameter completion: 刷新完成后的回调
    public func proactivelyRefreshToken(completion: ((Result<String, Error>) -> Void)? = nil) {
        // 检查是否有有效的refresh token且token即将过期
        guard let _ = refreshToken, isTokenNearlyExpired else {
            // 如果不需要刷新，直接返回当前access token
            if let accessToken = accessToken {
                completion?(.success(accessToken))
            } else {
                completion?(.failure(NSError(
                    domain: "com.skyward.auth",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "Access Token不存在"]
                )))
            }
            return
        }
        
        requestRefreshAccessToken { result in
            // 调用传入的完成回调
            completion?(result)
        }
    }
    
    /// 执行Token刷新的具体操作
    private func performTokenRefresh() {
        // 1. 从TokenManager获取refreshToken
        guard let refreshToken = self.refreshToken else {
            handleRefreshResult(.failure(NSError(
                domain: "com.skyward.auth",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Refresh Token不存在"]
            )))
            return
        }
        
        // 2. 使用不带认证的提供者请求刷新Token
        let refreshProvider = MoyaProvider<TokenAPI>()
        refreshProvider.request(.refreshToken(refreshToken)) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                do {
                    // 3. 解析刷新Token响应
                    let decoder = JSONDecoder()
                    let tokenResponse = try decoder.decode(TokenRefreshResponse.self, from: response.data)
                    
                    // 4. 更新Token
                    self.saveAccessToken(tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn)
                    self.saveRefreshToken(tokenResponse.refreshToken)
                    
                    // 5. 通知完成
                    self.handleRefreshResult(.success(tokenResponse.accessToken))
                    
                } catch {
                    // 解析错误
                    self.handleRefreshResult(.failure(error))
                }
                
            case .failure(let error):
                // 请求错误
                self.handleRefreshResult(.failure(error))
            }
        }
    }
    
    public func getAccessTokenPlugin() -> NetworkAuthPlugin {
        // 返回简化版的NetworkAuthPlugin，只提供token获取功能
        return NetworkAuthPlugin(tokenClosure: { TokenManager.shared.accessToken })
    }
}


// Token刷新响应模型
enum TokenRefreshResponse: Decodable {
    case success(accessToken: String, refreshToken: String, expiresIn: TimeInterval)
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let accessToken = try container.decode(String.self, forKey: .accessToken)
        let refreshToken = try container.decode(String.self, forKey: .refreshToken)
        let expiresIn = try container.decode(TimeInterval.self, forKey: .expiresIn)
        
        self = .success(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
    }
    
    var accessToken: String {
        switch self {
        case .success(let accessToken, _, _):
            return accessToken
        }
    }
    
    var refreshToken: String {
        switch self {
        case .success(_, let refreshToken, _):
            return refreshToken
        }
    }
    
    var expiresIn: TimeInterval {
        switch self {
        case .success(_, _, let expiresIn):
            return expiresIn
        }
    }
}

enum TokenAPI {
    case refreshToken(_ refreshToken: String)
}

extension TokenAPI: NetworkAPI {
    
    public var path: String {
        return "/txts-auth/oauth2/token"
    }
    
    public var method: Moya.Method {
        return .post
    }
    
    public var task: Moya.Task {
        switch self {
        case .refreshToken(let refreshToken):
            return .requestParameters(parameters: [
                "refresh_token": refreshToken,
                "grant_type": "refresh_token"
            ], encoding: URLEncoding.httpBody)
        }
    }
}
