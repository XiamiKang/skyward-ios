//
//  SmsCodeModel.swift
//  ModuleLogin
//
//  Created by TXTS on 2025/11/26.
//

import Foundation

public enum SmsCodeType: String {
    /// APP注册
    case appRegister = "APP_REGISTER"
    /// APP登录
    case appLogin = "APP_LOGIN"
    /// 更新密码
    case updatePassword = "UPDATE_PASSWORD"
    /// 忘记密码
    case forgetPassword = "FORGET_PASSWORD"
    /// 绑定手机号
    case bindPhone = "BIND_PHONE"
}

public struct SmsCodeModel {
    let mobile: String
    let codeType: SmsCodeType
    
    func toDictionary() -> [String: Any] {
        return [
            "mobile": mobile,
            "codeType": codeType.rawValue
            ]
    }
}

public struct RegisterModel {
    let nickname: String
    let avatar: String
    let phone: String
    let gender: Int  // 0:男,1:女
    let smsCode: String
    let password: String
    
    func toDictionary() -> [String: Any] {
        return [
            "nickname": nickname,
            "avatar": avatar,
            "phone": phone,
            "gender": gender,
            "smsCode": smsCode,
            "password": password
            ]
    }
}

public struct PasswordLoginModel {
    let username: String // 手机号
    let grant_type: String = "app_password"
    let password: String
    
    func toDictionary() -> [String: Any] {
        return [
            "username": username,
            "grant_type": grant_type,
            "password": password
            ]
    }
}

public struct VerificationCodeLoginModel {
    let mobile: String // 手机号
    let grant_type: String = "sms_code"
    let code: String
    
    func toDictionary() -> [String: Any] {
        return [
            "mobile": mobile,
            "grant_type": grant_type,
            "code": code
            ]
    }
}

public struct ForgotPasswrodModel {
    let phone: String // 手机号
    let smsCode: String
    let newPassword: String
    
    func toDictionary() -> [String: Any] {
        return [
            "phone": phone,
            "smsCode": smsCode,
            "newPassword": newPassword
            ]
    }
}

public struct BaseResponse<T: Codable>: Codable {
    let code: String
    let data: T?
    let msg: String
    
    var success: Bool {
        return code == "00000"  // 根据你的成功码调整
    }
}

// 空数据模型
struct EmptyData: Codable {}

// 空数据模型
struct TokenData: Codable {
    let accessToken: String?
    let refreshToken: String?
    let thirdAuthKey: String?
    let tokenType: String?
    let expiresIn: TimeInterval?
    let clientId: String?
    let password: String?
    let username: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case thirdAuthKey = "thirdAuthKey"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case clientId = "client_id"
        case password = "password"
        case username = "username"
    }
}
