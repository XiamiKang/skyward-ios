//
//  PersonalViewModel.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//

// MARK: - 首页ViewModel
import UIKit
import Moya
import SWNetwork

public class LoginViewModel {
    
    private let loginService = LoginService()
    
    // MARK: - 类型别名
    typealias LoginResult = Result<TokenData, LoginError>
    typealias LoginCompletion = (LoginResult) -> Void
    
    typealias CommonResult = Result<EmptyData, LoginError>
    typealias CommonCompletion = (CommonResult) -> Void
    
    typealias SmsCodeResult = Result<Response, LoginError>
    typealias SmsCodeCompletion = (SmsCodeResult) -> Void
    
    // MARK: - 登录错误枚举
    enum LoginError: Error {
        case networkError(String)
        case parseError(String)
        case businessError(message: String, code: String)
        case tokenDataMissing
        
        var errorMessage: String {
            switch self {
            case .networkError(let message):
                return message
            case .parseError(let message):
                return message
            case .businessError(let message, _):
                return message
            case .tokenDataMissing:
                return "登录信息不完整"
            }
        }
        
        var errorCode: String {
            switch self {
            case .businessError(_, let code):
                return code
            default:
                return "-1"
            }
        }
    }
    
    // MARK: - 密码登录
    func passwordLogin(username: String, password: String, completion: @escaping LoginCompletion) {
        let model = PasswordLoginModel(username: username, password: password)
        
        loginService.passwordLogin(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ 密码登录网络请求成功：Status Code: \(response.statusCode)")
                    
                    do {
                        let baseResponse = try JSONDecoder().decode(BaseResponse<TokenData>.self, from: response.data)
                        
                        if baseResponse.success {
                            if let tokenData = baseResponse.data {
                                print("🎉 密码登录成功: \(baseResponse.msg)")
                                completion(.success(tokenData))
                            } else {
                                print("❌ Token 数据为空")
                                completion(.failure(.tokenDataMissing))
                            }
                        } else {
                            print("❌ 密码登录业务失败: \(baseResponse.msg), 错误码: \(baseResponse.code)")
                            completion(.failure(.businessError(message: baseResponse.msg, code: baseResponse.code)))
                        }
                        
                    } catch {
                        print("❌ 响应解析失败: \(error)")
                        completion(.failure(.parseError("数据解析失败")))
                    }
                    
                case .failure(let error):
                    print("❌ 密码登录网络失败：\(error)")
                    completion(.failure(.networkError("网络请求失败")))
                }
            }
        }
    }
    
    // MARK: - 验证码登录（预留）
    func verificationCodeLogin(phone: String, code: String, completion: @escaping LoginCompletion) {
        let model = VerificationCodeLoginModel(mobile: phone, code: code)
        
        loginService.verificationCodeLogin(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ 密码登录网络请求成功：Status Code: \(response.statusCode)")
                    
                    do {
                        let baseResponse = try JSONDecoder().decode(BaseResponse<TokenData>.self, from: response.data)
                        
                        if baseResponse.success {
                            if let tokenData = baseResponse.data {
                                print("🎉 密码登录成功: \(baseResponse.msg)")
                                completion(.success(tokenData))
                            } else {
                                print("❌ Token 数据为空")
                                completion(.failure(.tokenDataMissing))
                            }
                        } else {
                            print("❌ 密码登录业务失败: \(baseResponse.msg), 错误码: \(baseResponse.code)")
                            completion(.failure(.businessError(message: baseResponse.msg, code: baseResponse.code)))
                        }
                        
                    } catch {
                        print("❌ 响应解析失败: \(error)")
                        completion(.failure(.parseError("数据解析失败")))
                    }
                    
                case .failure(let error):
                    print("❌ 密码登录网络失败：\(error)")
                    completion(.failure(.networkError("网络请求失败")))
                }
            }
        }
    }
    
    // MARK: - 注册
    func register(nickname: String, phone: String, smsCode: String, password: String, completion: @escaping CommonCompletion) {
        let model = RegisterModel(nickname: nickname, avatar: "", phone: phone, gender: 0, smsCode: smsCode, password: password)
        
        loginService.register(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ 注册网络请求成功：Status Code: \(response.statusCode)")
                    
                    do {
                        let baseResponse = try JSONDecoder().decode(BaseResponse<EmptyData>.self, from: response.data)
                        
                        if baseResponse.success {
                            print("🎉 注册成功: \(baseResponse.msg)")
                            completion(.success(EmptyData()))
                        } else {
                            print("❌ 注册业务失败: \(baseResponse.msg), 错误码: \(baseResponse.code)")
                            completion(.failure(.businessError(message: baseResponse.msg, code: baseResponse.code)))
                        }
                        
                    } catch {
                        print("❌ 响应解析失败: \(error)")
                        completion(.failure(.parseError("数据解析失败")))
                    }
                    
                case .failure(let error):
                    print("❌ 注册网络失败：\(error)")
                    completion(.failure(.networkError("网络请求失败")))
                }
            }
        }
    }
    
    // MARK: - 忘记密码
    func forgotPassword(phone: String, smsCode: String, newPassword: String, completion: @escaping CommonCompletion) {
        let model = ForgotPasswrodModel(phone: phone, smsCode: smsCode, newPassword: newPassword)
        
        loginService.forgotPassword(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ 重置密码网络请求成功：Status Code: \(response.statusCode)")
                    
                    do {
                        let baseResponse = try JSONDecoder().decode(BaseResponse<EmptyData>.self, from: response.data)
                        
                        if baseResponse.success {
                            print("🎉 重置密码成功: \(baseResponse.msg)")
                            completion(.success(EmptyData()))
                        } else {
                            print("❌ 重置密码业务失败: \(baseResponse.msg), 错误码: \(baseResponse.code)")
                            completion(.failure(.businessError(message: baseResponse.msg, code: baseResponse.code)))
                        }
                        
                    } catch {
                        print("❌ 响应解析失败: \(error)")
                        completion(.failure(.parseError("数据解析失败")))
                    }
                    
                case .failure(let error):
                    print("❌ 重置密码网络失败：\(error)")
                    completion(.failure(.networkError("网络请求失败")))
                }
            }
        }
    }
    
    // MARK: - 发送验证码
    func sendSmsCode(phone: String, type: SmsCodeType, completion: @escaping SmsCodeCompletion) {
        let model = SmsCodeModel(mobile: phone, codeType: type)
        
        loginService.sendSmsCode(model) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("✅ 验证码发送成功：\(response)")
                    completion(.success(response))
                    
                case .failure(let error):
                    print("❌ 验证码发送失败：\(error)")
                    completion(.failure(.networkError("验证码发送失败")))
                }
            }
        }
    }
}
