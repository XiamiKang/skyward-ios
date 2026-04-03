//
//  User.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/26.
//

import Foundation
import SWNetwork
import TXKit

public class UserManager {
    
    public static let shared = UserManager()
    
    public var userId : String {
        get {
            return userInfo?.id ?? ""
        }
    }
    
    /// 是否是游客模式
    public var isVisitor: Bool = false
    
    /// 是否登录
    public var isLogin: Bool {
        return TokenManager.shared.isTokenValid
    }
    
    public var userInfo: UserInfo?
    
    public var emergencyContact: [EmergencyContact]? {
        didSet {
            if emergencyContact?.count != 0 {
                self.userInfo?.isSetEmergency = true
            }
        }
    }
    
    public var realNameAuthStatus: Bool = false
    
    init() {
        readUserInfo()
    }
    
    // MARK: - Public
    
    public func login(_ params: [String : Any]) {
        
    }
    
    public func logout() {
        cleanUserInfo()
        TokenManager.shared.clearTokens()
        SWRouter.handle(RouteTable.loginPageUrl)
        // 发送登出成功通知
        NotificationCenter.default.post(name: .logoutSuccess, object: nil)
    }
    
    /// 获取用户信息
    public func requestUserInfo() async {
        do {
            let rsp = try await NetworkProvider<UserAPI>().request(.getUserInfo)
            let networkResponse = try rsp.map(NetworkResponse<UserInfo>.self)
            userInfo = networkResponse.data
            
            if let userId = userInfo?.id, !userId.isEmpty {
                saveUserInfo()
            }
            
        } catch {
            print("❌ 获取用户信息失败: \(error)")
        }
    }
    
    /// 获取紧急联系人信息
    public func getEmergencyContactList(_ completion: @escaping ([EmergencyContact]?) -> Void) {
        if let emergencyContact = emergencyContact {
            completion(emergencyContact)
        } else {
            requestEmergencyContactList(completion)
        }
    }
    /// 绑定紧急联系人信息
    public func bindEmergencyContact(name: String, phone: String, _ completion: @escaping (Bool) -> Void) {
        NetworkProvider<UserAPI>().request(.bindEmergencyContact(name: name, phone: phone)) { result in
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<Bool>.self)
                    if networkResponse.isSuccess {
                        self.requestEmergencyContactList { contact in
                            completion( contact != nil)
                        }
                    } else {
                        UIWindow.topWindow?.sw_showWarningToast(networkResponse.msg ?? "")
                    }
                } catch {
                    completion(false)
                }
                
            case .failure(let error):
                UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                completion(false)
            }
        }
    }

    /// 请求紧急联系人信息
    public func requestEmergencyContactList(_ completion: @escaping ([EmergencyContact]?) -> Void) {
        NetworkProvider<UserAPI>().request(.getEmergencyContactList) { result in
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<[EmergencyContact]>.self)
                    self.emergencyContact = networkResponse.data
                    self.userInfo?.isSetEmergency = true
                    completion(self.emergencyContact)
                } catch {
                    completion(nil)
                }
            case .failure(let error):
                UIWindow.topWindow?.sw_showWarningToast(error.localizedDescription)
                completion(nil)
            }
        }
    }
    
    /// 绑定Mini设备
    public func bindDevice(serialNum: String, macAddress: String) {
        NetworkProvider<UserAPI>().retryRequest(.bindMiniDevice(userId: userId, serialNum: serialNum, macAddress: macAddress)) { result in
            
        }
    }
    
    /// 清空用户信息
    public func cleanUserInfo() {
        UserDefaults.standard.removeObject(forKey: storageUserId())
        userInfo = nil
        emergencyContact = nil
        TokenManager.shared.clearTokens()
    }
    
    public func cleanEmergencyContact() {
        userInfo?.isSetEmergency = false
        emergencyContact = nil
    }
    
    /// 保存用户信息
    private func saveUserInfo() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(userInfo)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.setValue(jsonString, forKey: storageUserId())
            }
        } catch {
            print("Failed to encode struct to JSON: \(error)")
        }
    }
    /// 读取用户信息
    private func readUserInfo() {
        let jsonString = UserDefaults.standard.value(forKey: storageUserId()) as? String
        guard let _jsonString = jsonString,
              !_jsonString.isEmpty else {
            return
        }
        if let data = _jsonString.data(using: .utf8) {
            do {
                userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
            } catch {
                print("Error decoding JSON: \(error)")
            }
        }
    }
    
    private func storageUserId() -> String {
        return "user-info"
//        return "user_info_\(userId)"
    }
    
    
}


