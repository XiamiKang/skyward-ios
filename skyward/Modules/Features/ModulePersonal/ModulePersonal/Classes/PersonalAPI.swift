//
//  PersonalAPI.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/17.
//

import Foundation
import SWNetwork
import Moya
import Combine

public enum PersonalAPI {
    case getDeviceList(_ model: BaseModel)                         // 获取设备列表
    case unBingMiniDevice(_ model: UnBindModel)                    // 取消绑定设备
    case updateUserAvatar(_ avatarUrl: String)                     // 修改头像
    case updateUserNickname(_ nickname: String)                    // 修改昵称
    case updateUserCity(_ city: String, cityCode: String)          // 修改城市
    case updateUserSex(_ sex: Int)                                 // 修改性别   1-男 2-女
    case updateUserSign(_ personalitySign: String)                 // 修改签名
    case updateUserPassword(_ model: NewPasswrodModel)             // 修改密码
    case userLogout                                                // 用户退出
    case cancellationUser                                          // 注销用户
    case addEmergencyContact(_ model: EmergencyContactModel)       // 新增紧急联系人（也是修改紧急联系人的接口，后台会自动覆盖）
    case getDeviceFirmware(_ model: DeviceFirmwareModel)           // 获取设备的固件信息
    case getEmergencyContact                                       // 获取紧急联系人
    case getUserInfo                                               // 获取用户信息
}

// MARK: - TargetType 实现
extension PersonalAPI: NetworkAPI {

    public var path: String {
        switch self {
        case .getDeviceList:
            return "/txts-user-center-app/api/v1/user/device/list"
        case .unBingMiniDevice:
            return "/txts-user-center-app/api/v1/user/device/unbindDevice"
        case .updateUserAvatar:
            return "/txts-user-center-app/api/v1/my-center/avatar"
        case .updateUserNickname:
            return "/txts-user-center-app/api/v1/my-center/nickname"
        case .updateUserCity:
            return "/txts-user-center-app/api/v1/my-center/city"
        case .updateUserSex:
            return "/txts-user-center-app/api/v1/my-center/sex"
        case .updateUserSign:
            return "/txts-user-center-app/api/v1/my-center/personality-sign"
        case .updateUserPassword:
            return "/txts-user-center-app/api/v1/my-center/password"
        case .userLogout:
            return "/txts-user-center-app/api/v1/user/app-user/logout"
        case .cancellationUser:
            return "/txts-user-center-app/api/v1/my-center/cancellation"
        case .addEmergencyContact:
            return "/txts-user-center-app/api/v1/emergency-contact"
        case .getDeviceFirmware:
            return "/txts-system/api/v1/firmware-version/check/newVersion"
        case .getEmergencyContact:
            return "/txts-user-center-app/api/v1/emergency-contact/info"
        case .getUserInfo:
            return "/txts-user-center-app/api/v1/my-center/info"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case    .getDeviceList,
                .userLogout,
                .getDeviceFirmware,
                .getEmergencyContact,
                .getUserInfo:
            return .get
        case    .addEmergencyContact:
            return .post
        case    .unBingMiniDevice:
            return .delete
        case    .updateUserAvatar,
                .updateUserNickname,
                .updateUserCity,
                .updateUserSex,
                .updateUserSign,
                .updateUserPassword,
                .cancellationUser:
            return .put
        }
    }
    
    public var task: Task {
        switch self {
        case .getDeviceList(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: URLEncoding.default
            )
        case .unBingMiniDevice(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .updateUserAvatar(let avatarUrl):
            return .requestParameters(
                parameters: ["avatarUrl": avatarUrl],
                encoding: URLEncoding.httpBody
            )
        case .updateUserNickname(let nickname):
            return .requestParameters(
                parameters: ["nickname": nickname],
                encoding: URLEncoding.httpBody
            )
        case .updateUserCity(let city, let cityCode):
            return .requestParameters(
                parameters: ["city": city, "cityCode": cityCode],
                encoding: JSONEncoding.default
            )
        case .updateUserSex(let sex):
            return .requestParameters(
                parameters: ["sex": sex],
                encoding: URLEncoding.httpBody
            )
        case .updateUserSign(let personalitySign):
            return .requestParameters(
                parameters: ["personalitySign": personalitySign],
                encoding: URLEncoding.httpBody
            )
        case .updateUserPassword(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .userLogout:
            return .requestPlain
        case .cancellationUser:
            return .requestPlain
        case .addEmergencyContact(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .getDeviceFirmware(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: URLEncoding.default
            )
        case .getEmergencyContact:
            return .requestPlain
        case .getUserInfo:
            return .requestPlain
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        switch self {
        case .updateUserAvatar,
                .updateUserNickname,
                .updateUserSex,
                .updateUserSign:
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        default:
            headers["Content-Type"] = "application/json"
        }
        
        return headers
    }
    
}

public struct BaseResponse<T: Codable>: Codable {
    public let code: String
    public let data: T?
    public let msg: String
    
    public var success: Bool {
        return code == "00000"
    }
}

public enum PersonalError: Error {
    case networkError(String)
    case parseError(String)
    case businessError(message: String, code: String)
    
    public var errorMessage: String {
        switch self {
        case .networkError(let message):
            return message
        case .parseError(let message):
            return message
        case .businessError(let message, _):
            return message
        }
    }
    
    public var errorCode: String {
        switch self {
        case .businessError(_, let code):
            return code
        default:
            return "-1"
        }
    }
}

public struct BaseModel {
    public let pageNum: Int
    public let pageSize: Int
    
    func toDictionary() -> [String: Any] {
        return [
            "pageNum": pageNum,
            "pageSize": pageSize
            ]
    }
}

public struct UnBindModel {
    public let userId: Int
    public let serialNum: String
    public let macAddress: String
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "serialNum": serialNum,
            "macAddress": macAddress
            ]
    }
}

public struct EmergencyContactModel {
    public let name: String
    public let phone: String
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "phone": phone
            ]
    }
}

public struct NewPasswrodModel {
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

public struct DeviceFirmwareModel {
    let deviceType: Int // 设备类型（1-窄带 2-宽带）
    let versionCode: String
    let hardwareModel: String
    
    func toDictionary() -> [String: Any] {
        return [
            "deviceType": deviceType,
            "versionCode": versionCode,
            "hardwareModel": hardwareModel
        ]
    }
}
