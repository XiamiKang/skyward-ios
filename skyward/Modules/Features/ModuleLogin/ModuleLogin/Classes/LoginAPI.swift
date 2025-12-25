//
//  LoginAPI.swift
//  ModuleLogin
//
//  Created by TXTS on 2025/11/26.
//

import Foundation
import SWNetwork
import Moya
import Combine

// MARK: - 登录相关 API 枚举
public enum LoginAPI {
    case sendSmsCode(_ model: SmsCodeModel)
    case register(_ model: RegisterModel)
    case passwordLogin(_ model: PasswordLoginModel)
    case verificationCodeLogin(_ model: VerificationCodeLoginModel)
    case forgotPassword(_ model: ForgotPasswrodModel)
    case logout
    case refreshToken(refreshToken: String)
}

// MARK: - TargetType 实现
extension LoginAPI: NetworkAPI {

    public var path: String {
        switch self {
        case .sendSmsCode:
            return "/txts-auth/api/v1/auth/sms_code"
        case .register:
            return "/txts-user-center-app/api/v1/user/app-user/register"
        case .passwordLogin, .verificationCodeLogin:
            return "/txts-auth/oauth2/token"
        case .forgotPassword:
            return "/txts-user-center-app/api/v1/user/app-user/forgot/password"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/txts-auth/oauth2/token"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .sendSmsCode, .register, .passwordLogin,
             .verificationCodeLogin, .refreshToken:
            return .post
        case .forgotPassword:
            return .put
        case .logout:
            return .delete
        }
    }
    
    public var task: Task {
        switch self {
        case .sendSmsCode(let model):
            return .requestParameters(
                parameters: [
                    "mobile": model.mobile,
                    "codeType": model.codeType.rawValue
                ],
                encoding: URLEncoding.httpBody  // 关键修改
            )
            
        case .register(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
            
        case .passwordLogin(let model):
            let parameters = model.toDictionary()
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.httpBody
            )
            
        case .verificationCodeLogin(let model):
            let parameters = model.toDictionary()
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.httpBody
            )
            
        case .forgotPassword(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
            
        case .logout:
            return .requestPlain
            
        case .refreshToken(_):
            let parameters: [String: Any] = [
                "lang": "zh",
                "location": "101010100",
            ]
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.httpBody
            )
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        switch self {
        case .passwordLogin, .verificationCodeLogin, .refreshToken:
            // Basic Auth 认证
            let username = "txts-app"
            let password = "txts@app!"
            let loginString = "\(username):\(password)"
            guard let loginData = loginString.data(using: .utf8) else {
                return headers
            }
            let base64LoginString = loginData.base64EncodedString()
            headers["Authorization"] = "Basic \(base64LoginString)"
            // OAuth 接口通常需要 application/x-www-form-urlencoded
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        case .sendSmsCode:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        case .logout:
            // 登出接口需要携带认证token
            if let token = TokenManager.shared.accessToken {
                headers["Authorization"] = "Bearer \(token)"
            }
        default:
            break
        }
        
        return headers
    }
    
    // 可选：为测试提供示例数据
    public var sampleData: Data {
        switch self {
        case .sendSmsCode:
            return """
            {
                "success": true,
                "message": "验证码发送成功"
            }
            """.data(using: .utf8)!
            
        case .register:
            return """
            {
                "success": true,
                "data": {
                    "userId": "123",
                    "token": "jwt_token_here"
                }
            }
            """.data(using: .utf8)!
            
        case .passwordLogin, .verificationCodeLogin:
            return """
            {
                "access_token": "access_token_here",
                "refresh_token": "refresh_token_here",
                "token_type": "bearer",
                "expires_in": 3600
            }
            """.data(using: .utf8)!
            
        default:
            return "{\"success\": true}".data(using: .utf8)!
        }
    }
}

// MARK: - 登录服务
public class LoginService {
    private let provider: NetworkProvider<LoginAPI>
    
    public init() {
        self.provider = NetworkProvider<LoginAPI>()
    }
    
    // MARK: - 发送验证码
    @available(iOS 13.0, *)
    public func sendSmsCode(_ model: SmsCodeModel) async throws -> Response {
        return try await provider.request(.sendSmsCode(model))
    }
    
    public func sendSmsCode(_ model: SmsCodeModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.sendSmsCode(model), completion: completion)
    }
    
    @available(iOS 13.0, *)
    public func sendSmsCode(_ model: SmsCodeModel) -> AnyPublisher<Response, MoyaError> {
        return provider.request(.sendSmsCode(model))
    }
    
    // MARK: - 用户注册
    @available(iOS 13.0, *)
    public func register(_ model: RegisterModel) async throws -> Response {
        return try await provider.request(.register(model))
    }
    
    public func register(_ model: RegisterModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.register(model), completion: completion)
    }
    
    // MARK: - 密码登录
    @available(iOS 13.0, *)
    public func passwordLogin(_ model: PasswordLoginModel) async throws -> Response {
        return try await provider.request(.passwordLogin(model))
    }
    
    public func passwordLogin(_ model: PasswordLoginModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.passwordLogin(model), completion: completion)
    }
    
    // MARK: - 验证码登录
    @available(iOS 13.0, *)
    public func verificationCodeLogin(_ model: VerificationCodeLoginModel) async throws -> Response {
        return try await provider.request(.verificationCodeLogin(model))
    }
    
    public func verificationCodeLogin(_ model: VerificationCodeLoginModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.verificationCodeLogin(model), completion: completion)
    }
    
    // MARK: - 忘记密码
    @available(iOS 13.0, *)
    public func forgotPassword(_ model: ForgotPasswrodModel) async throws -> Response {
        return try await provider.request(.forgotPassword(model))
    }
    
    public func forgotPassword(_ model: ForgotPasswrodModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.forgotPassword(model), completion: completion)
    }
    
    // MARK: - 退出登录
    @available(iOS 13.0, *)
    public func logout() async throws -> Response {
        return try await provider.request(.logout)
    }
    
    public func logout(completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.logout, completion: completion)
    }
    
    // MARK: - 刷新Token
    @available(iOS 13.0, *)
    public func refreshToken(_ refreshToken: String) async throws -> Response {
        return try await provider.request(.refreshToken(refreshToken: refreshToken))
    }
    
    public func refreshToken(_ refreshToken: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.refreshToken(refreshToken: refreshToken), completion: completion)
    }
}

// MARK: - 响应模型
public struct SmsCodeResponse: Codable {
    public let code: String?
    public let data: String?
    public let msg: String?
}

public struct CommonResponse: Codable {
    public let success: Bool
    public let message: String?
    public let data: [String: String]?
}
