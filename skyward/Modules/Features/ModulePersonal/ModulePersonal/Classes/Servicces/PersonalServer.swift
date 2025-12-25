//
//  PersonalServer.swift
//  Pods
//
//  Created by TXTS on 2025/12/17.
//

import Foundation
import SWNetwork
import Moya
import Combine

// MARK: - 个人
public class PersonalServer {
    
    private let provider: NetworkProvider<PersonalAPI>
    
    public init() {
        self.provider = NetworkProvider<PersonalAPI>()
    }
    
    // MARK: - 获取设备列表
    @available(iOS 13.0, *)
    public func getDeviceList(_ model: BaseModel) async throws -> Response {
        return try await provider.request(.getDeviceList(model))
    }
    
    public func getDeviceList(_ model: BaseModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getDeviceList(model), completion: completion)
    }
    
    // MARK: - 取消绑定设备
    @available(iOS 13.0, *)
    public func unBingMiniDevice(_ model: UnBindModel) async throws -> Response {
        return try await provider.request(.unBingMiniDevice(model))
    }
    
    public func unBingMiniDevice(_ model: UnBindModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.unBingMiniDevice(model), completion: completion)
    }
    
    // MARK: - 修改头像
    @available(iOS 13.0, *)
    public func updateUserAvatar(avatarUrl: String) async throws -> Response {
        return try await provider.request(.updateUserAvatar(avatarUrl))
    }
    
    public func updateUserAvatar(avatarUrl: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserAvatar(avatarUrl), completion: completion)
    }
    
    // MARK: - 修改昵称
    @available(iOS 13.0, *)
    public func updateUserNickname(nickname: String) async throws -> Response {
        return try await provider.request(.updateUserNickname(nickname))
    }
    
    public func updateUserNickname(nickname: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserNickname(nickname), completion: completion)
    }
    
    // MARK: - 修改城市
    @available(iOS 13.0, *)
    public func updateUserCity(city: String, cityCode: String) async throws -> Response {
        return try await provider.request(.updateUserCity(city, cityCode: cityCode))
    }
    
    public func updateUserCity(city: String, cityCode: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserCity(city, cityCode: cityCode), completion: completion)
    }

    // MARK: - 修改性别   1-男 2-女
    @available(iOS 13.0, *)
    public func updateUserSex(sex: Int) async throws -> Response {
        return try await provider.request(.updateUserSex(sex))
    }
    
    public func updateUserSex(sex: Int, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserSex(sex), completion: completion)
    }
    
    // MARK: - 修改签名
    @available(iOS 13.0, *)
    public func updateUserSign(personalitySign: String) async throws -> Response {
        return try await provider.request(.updateUserSign(personalitySign))
    }
    
    public func updateUserSign(personalitySign: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserSign(personalitySign), completion: completion)
    }
    
    // MARK: - 修改密码
    @available(iOS 13.0, *)
    public func updateUserPassword(_ model: NewPasswrodModel) async throws -> Response {
        return try await provider.request(.updateUserPassword(model))
    }
    
    public func updateUserPassword(_ model: NewPasswrodModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserPassword(model), completion: completion)
    }
    
    // MARK: - 用户退出
    @available(iOS 13.0, *)
    public func userLogout() async throws -> Response {
        return try await provider.request(.userLogout)
    }
    
    public func userLogout(_ completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.userLogout, completion: completion)
    }
    
    // MARK: - 注销用户
    @available(iOS 13.0, *)
    public func cancellationUser() async throws -> Response {
        return try await provider.request(.cancellationUser)
    }
    
    public func cancellationUser(_ completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.cancellationUser, completion: completion)
    }
    
    // MARK: - 新增紧急联系人（也是修改紧急联系人的接口，后台会自动覆盖）
    @available(iOS 13.0, *)
    public func addEmergencyContact(_ model: EmergencyContactModel) async throws -> Response {
        return try await provider.request(.addEmergencyContact(model))
    }
    
    public func addEmergencyContact(_ model: EmergencyContactModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.addEmergencyContact(model), completion: completion)
    }
    
    // MARK: - 获取设备固件信息
    @available(iOS 13.0, *)
    public func getDeviceFirmware(_ model: DeviceFirmwareModel) async throws -> Response {
        return try await provider.request(.getDeviceFirmware(model))
    }
    
    public func getDeviceFirmware(_ model: DeviceFirmwareModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getDeviceFirmware(model), completion: completion)
    }
    
    // MARK: - 获取紧急联系人
    @available(iOS 13.0, *)
    public func getEmergencyContact() async throws -> Response {
        return try await provider.request(.getEmergencyContact)
    }
    
    public func getEmergencyContact(_ completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getEmergencyContact, completion: completion)
    }
    
    // MARK: - 获取用户信息
    @available(iOS 13.0, *)
    public func getUserInfo() async throws -> Response {
        return try await provider.request(.getUserInfo)
    }
    
    public func getUserInfo(_ completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getUserInfo, completion: completion)
    }
}
