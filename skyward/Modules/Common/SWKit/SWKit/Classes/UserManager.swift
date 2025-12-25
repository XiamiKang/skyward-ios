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
    
    public var emergencyContact: EmergencyContact? {
        didSet {
            if emergencyContact != nil {
                self.userInfo?.isSetEmergency = true
            }
        }
    }
    
    init() {
        readUserInfo()
    }
    
    // MARK: - Public
    
    public func login(_ params: [String : Any]) {
        
    }
    
    public func logout() {
        cleanUserInfo()
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
    public func getEmergencyContact(_ completion: @escaping (EmergencyContact?) -> Void) {
        if let emergencyContact = emergencyContact {
            completion(emergencyContact)
        } else {
            requestEmergencyContact(completion)
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
                        self.requestEmergencyContact { contact in
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
    func requestEmergencyContact(_ completion: @escaping (EmergencyContact?) -> Void) { 
        NetworkProvider<UserAPI>().request(.getEmergencyContact) { result in
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<EmergencyContact>.self)
                    self.emergencyContact = networkResponse.data
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
    public func bindMiniDevice(serialNum: String, macAddress: String, _ completion: @escaping (Bool) -> Void) {
        NetworkProvider<UserAPI>().retryRequest(.bindMiniDevice(userId: userId, serialNum: serialNum, macAddress: macAddress)) { result in
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<Bool>.self)
                    if networkResponse.isSuccess {
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
                
            case .failure(let error):
                completion(false)
            }
        }
    }
    
    /// 清空用户信息
    private func cleanUserInfo() {
        UserDefaults.standard.removeObject(forKey: storageUserId())
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


