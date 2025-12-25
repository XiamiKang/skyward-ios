//
//  NetworkProvider.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

/// 二次封装的网络提供者

import Foundation
import Moya
import Combine

public class NetworkProvider<T: TargetType> {
    
    private let provider: MoyaProvider<T>
    private let config: NetworkConfigProtocol
    
    public init(
        config: NetworkConfigProtocol = NetworkConfigurationManager.shared.getConfig(),
        plugins: [PluginType] = NetworkDefaultPlugins.createDefaultMoyaPlugins(),
        stubClosure: @escaping (T) -> StubBehavior = MoyaProvider.neverStub,
        callbackQueue: DispatchQueue? = nil
    ) {
        self.config = config
        
        // 查找token刷新插件
        var updatedPlugins = plugins
        if !plugins.contains(where: { $0 is NetworkAuthPlugin }) {
            updatedPlugins.append(TokenManager.shared.getAccessTokenPlugin())
        }
        
        // 创建自定义endpoint closure
        let endpointClosure = { (target: T) -> Endpoint in
            let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
            
            // 添加公共headers
            let headers = target.headers ?? [:]
//            config.commonHeaders.forEach { headers[$0.key] = $0.value }
            
            // 处理参数：只有当任务类型支持参数时才添加公共参数
            var finalTask = target.task
            if case .requestParameters(var parameters, let encoding) = target.task {
                // 添加公共参数
                config.commonParameters.forEach { parameters[$0.key] = $0.value }
                finalTask = .requestParameters(parameters: parameters, encoding: encoding)
            } else if case .requestPlain = target.task {
                // 对于Plain请求，如果有公共参数，转换为参数请求
                if !config.commonParameters.isEmpty {
                    finalTask = .requestParameters(parameters: config.commonParameters, encoding: URLEncoding.default)
                }
            }
            
            return defaultEndpoint
                .adding(newHTTPHeaderFields: headers)
                .replacing(task: finalTask)
        }
        
        // 创建自定义request closure
        let requestClosure = { (endpoint: Endpoint, closure: @escaping (Result<URLRequest, MoyaError>) -> Void) in
            do {
                var request = try endpoint.urlRequest()
                request.timeoutInterval = config.timeoutInterval
                closure(.success(request))
            } catch {
                closure(.failure(MoyaError.underlying(error, nil)))
            }
        }
        
        self.provider = MoyaProvider<T>(
            endpointClosure: endpointClosure,
            requestClosure: requestClosure,
            stubClosure: stubClosure,
            callbackQueue: callbackQueue,
            plugins: updatedPlugins,
            trackInflights: false
        )
    }
    
    /// 发送请求（使用async/await）
    @available(iOS 13.0, *)
    public func request(_ target: T) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            self.requestWithTokenRefresh(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// 发送请求（使用Combine）
    @available(iOS 13.0, *)
    public func request(_ target: T) -> AnyPublisher<Response, MoyaError> {
        return Future<Response, MoyaError> { promise in
            self.requestWithTokenRefresh(target) { result in
                switch result {
                case .success(let response):
                    promise(.success(response))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 发送请求（传统回调方式）
    public func request(_ target: T,
                       callbackQueue: DispatchQueue? = .main,
                       progress: ProgressBlock? = nil,
                       completion: @escaping (Result<Response, MoyaError>) -> Void) {
        requestWithTokenRefresh(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }
    
    ///带Token刷新的请求方法（核心实现）
    private func requestWithTokenRefresh(_ target: T,
                                        callbackQueue: DispatchQueue? = .main,
                                        progress: ProgressBlock? = nil,
                                        completion: @escaping (Result<Response, MoyaError>) -> Void) {
        // 直接请求，如果是401错误会被插件捕获处理
        provider.request(target, callbackQueue: callbackQueue, progress: progress) { [weak self] result in
            
            // 检查是否需要处理token刷新
            if case .failure(let error) = result,
               case .underlying(let nsError as NSError, _) = error,
               nsError.code == 401, nsError.domain == "com.skyward.auth" {
                
                // 触发token刷新
                TokenManager.shared.requestRefreshAccessToken { [weak self] _ in
                    // token刷新成功后重试请求
                    self?.provider.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
                }
                
            } else {
                // 不是401错误，直接返回原结果
                completion(result)
            }
        }
    }
    
    /// 发送请求（退避请求）
    public func retryRequest(_ target: T,
                        callbackQueue: DispatchQueue? = .main,
                        progress: ProgressBlock? = nil,
                        completion: @escaping (Result<Response, MoyaError>) -> Void) {
        requestWithTokenRefresh(target,
                                callbackQueue: callbackQueue,
                                progress: progress,
                                maxRetryCount: 3,
                                currentRetry: 0,
                                completion: completion)
    }
    
    /// 带Token刷新的请求方法（核心实现）增加退避重试机制
    private func requestWithTokenRefresh(_ target: T,
                                         callbackQueue: DispatchQueue? = .main,
                                         progress: ProgressBlock? = nil,
                                         maxRetryCount: Int = 3,
                                         currentRetry: Int = 0,
                                         completion: @escaping (Result<Response, MoyaError>) -> Void) {
        
        provider.request(target, callbackQueue: callbackQueue, progress: progress) { [weak self] result in
            
            // 检查是否需要处理token刷新
            if case .failure(let error) = result,
               case .underlying(let nsError as NSError, _) = error,
               nsError.code == 401, nsError.domain == "com.skyward.auth" {
                
                // 如果已经超过最大重试次数，直接返回错误
                guard currentRetry < maxRetryCount else {
                    completion(result)
                    return
                }
                
                // 触发token刷新
                TokenManager.shared.requestRefreshAccessToken { refreshResult in
                    switch refreshResult {
                    case .success:
                        // token刷新成功后，使用指数退避延迟重试
                        let delay = self?.calculateExponentialBackoffDelay(retryCount: currentRetry) ?? 0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                            self?.requestWithTokenRefresh(target,
                                                          callbackQueue: callbackQueue,
                                                          progress: progress,
                                                          maxRetryCount: maxRetryCount,
                                                          currentRetry: currentRetry + 1,
                                                          completion: completion)
                        }
                        
                    case .failure:
                        // token刷新失败，直接返回原错误
                        completion(result)
                    }
                }
                
            } else {
                // 不是401错误，直接返回原结果
                completion(result)
            }
        }
    }
    
    /// 计算指数退避延迟时间
    private func calculateExponentialBackoffDelay(retryCount: Int,
                                                  baseDelay: TimeInterval = 1.0,
                                                  maxDelay: TimeInterval = 30.0,
                                                  jitter: Bool = true) -> TimeInterval {
        
        // 指数退避公式: baseDelay * (2^retryCount)
        let exponent = pow(2, Double(retryCount))
        var delay = baseDelay * exponent
        
        // 添加随机抖动以避免惊群效应
        if jitter {
            let jitterFactor = Double.random(in: 0.5...1.5)
            delay *= jitterFactor
        }
        
        // 限制最大延迟时间
        return min(delay, maxDelay)
    }
    
    // MARK: - 高级重试方法
    
    /// 带重试机制的请求（公开方法）
    public func requestWithRetry(_ target: T,
                                 maxRetries: Int = 3,
                                 callbackQueue: DispatchQueue? = .main,
                                 progress: ProgressBlock? = nil,
                                 completion: @escaping (Result<Response, MoyaError>) -> Void) {
        
        requestWithTokenRefresh(target,
                                callbackQueue: callbackQueue,
                                progress: progress,
                                maxRetryCount: maxRetries,
                                currentRetry: 0,
                                completion: completion)
    }
    
    /// 仅重试指定错误类型
    public func requestWithSelectiveRetry(_ target: T,
                                          retryableErrors: [Int] = [401, 408, 500, 502, 503, 504],
                                          maxRetries: Int = 3,
                                          callbackQueue: DispatchQueue? = .main,
                                          progress: ProgressBlock? = nil,
                                          completion: @escaping (Result<Response, MoyaError>) -> Void) {
        
        var currentRetry = 0
        
        func attemptRequest() {
            provider.request(target, callbackQueue: callbackQueue, progress: progress) { [weak self] result in
                guard let self = self else { return }
                
                if case .failure(let error) = result,
                   case .statusCode(let response) = error,
                   retryableErrors.contains(response.statusCode),
                   currentRetry < maxRetries {
                    
                    currentRetry += 1
                    let delay = self.calculateExponentialBackoffDelay(retryCount: currentRetry - 1)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        attemptRequest()
                    }
                } else {
                    completion(result)
                }
            }
        }
        
        attemptRequest()
    }
}

