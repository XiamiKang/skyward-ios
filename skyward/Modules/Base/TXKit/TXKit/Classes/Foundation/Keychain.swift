//
//  Keychain.swift
//
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024年 Longfor. All rights reserved.
//

import Foundation

/**
 *  This class is used to operate keychain item.
 *  It has the add, delete, update, find mehtods like operation a collection.
 *  The key is the keychain item attribute `kSecAttrAccount`.
 *  The object is keychain item attribute `kSecValueData`.
 *  Also, it provide a util method, used to get bundle seed id from keychain.
 *
 */

public class Keychain {
    
    var service: String!
    var group: String?
    
    /**
     *  Initialization a operable keychain item instance with servie and group, the two params used to operate keychain item.
     *
     *  @param service_  service is the keychain item attribute `kSecAttrService`, can't be nil.
     *  @param group_   group is the keychain item attribute `kSecAttrAccessGroup`, can be nil.
     *
     *  @return a keychain operated instance.
     */
    public init(service: String!, group: String?) {
        self.service = service
        self.group = group
    }
    
    // MARK: - public set methods
    public func set(_ value: Data?, forKey key: String) {
        if let _ = data(forKey: key) {
            self.update(value, forKey: key)
        } else {
            var dict: [String: Any] = self.prepare(forkey: key)
            dict[kSecValueData as String] = value
            print("prepard dict is : \n \(dict)")
            var result: AnyObject?
            let status: OSStatus = SecItemAdd(dict as CFDictionary, &result)
            if status != errSecSuccess {
                //                print(result)
                print("add failed \(status)")
            }
        }
    }
    
    public func set(_ value: String?, forKey key: String) {
        guard let data = value?.data(using: .utf8, allowLossyConversion: false) else {
            print("failed to convert string to data")
            return
        }
        set(data, forKey: key)
    }
    
    public func set(_ value: [String: Any]?, forKey key: String) {
        if let value = value  {
            let data: Data = NSKeyedArchiver.archivedData(withRootObject: value)
            set(data, forKey: key)
        } else {
            print("failed to convert dictionary to data")
        }
    }
    
    public func set(_ value: [Any]?, forKey key: String) {
        if let value = value  {
            let data: Data = NSKeyedArchiver.archivedData(withRootObject: value)
            set(data, forKey: key)
        } else {
            print("failed to convert array to data")
        }
    }
    
    
    
    // MARK: - public get methods
    public func data(forKey key: String) -> Data? {
        var dict: [String: Any] = self.prepare(forkey: key)
        dict[kSecMatchLimit as String] = kSecMatchLimitOne as String
        dict[kSecReturnData as String] = kCFBooleanTrue
        var result: AnyObject?
        let status: OSStatus = SecItemCopyMatching(dict as CFDictionary, &result)
        
        guard
            errSecSuccess == status,
            let data = result as? Data
            else {
                return nil
        }
        return data
    }
    
    public func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            print("failed to convert data to string")
            return nil
        }
        return string
    }
    
    public func dictionary(forKey key: String) -> [String: Any]? {
        guard let data = data(forKey: key) else {
            return nil
        }
        guard let dic = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] else {
            return nil
        }
        return dic
    }
    
    public func array(forKey key: String) -> [Any]? {
        guard let data = data(forKey: key) else {
            return nil
        }
        guard let array = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Any] else {
            return nil
        }
        return array
    }
    
    // MARK: - public get methods
    @discardableResult
    public func removeObject(forKey key: String) -> Bool {
        let dict: [String: Any] = self.prepare(forkey: key)
        let status: OSStatus = SecItemDelete(dict as CFDictionary)
        return errSecSuccess == status
    }
    
    
    
    // MARK: - private methods
    
    private func update(_ value: Data?, forKey key: String) {
        let preparedDict = self.prepare(forkey: key)
        var updateDict: [String: Any]! = [:]
        updateDict[kSecValueData as String] = value
        
        let status: OSStatus = SecItemUpdate(preparedDict as CFDictionary, updateDict as CFDictionary)
        if status != errSecSuccess {
//            print("update failed \(status)")
        }
    }
    
    /// prepare data for add, remove, update, get item methods
    private func prepare(forkey key: String) -> [String: Any] {
        var dict = [String: Any]()
        /**
         kSecClass -> type of item which is kSecClassGenericPassword
         kSecAttrGeneric -> Generic attribute key.
         kSecAttrAccount -> Account attribute key
         kSecAttrService -> Name of the service.
         kSecAttrAccessible -> Specifies when data is accessible.
         kSecAttrAccessGroup : Keychain access group name. This should be same to share the data across apps.
         */
        dict[kSecClass as String] = kSecClassGenericPassword
        let encodedKey = key.data(using: .utf8)
        dict[kSecAttrGeneric as String] = encodedKey
        dict[kSecAttrAccount as String] = encodedKey
        dict[kSecAttrService as String] = self.service
        dict[kSecAttrAccessible as String] = kSecAttrAccessibleAlwaysThisDeviceOnly
        
        if let group = self.group, let bundleSeedID = Keychain.bundleSeedID() {
            let g = "\(bundleSeedID).\(group)"
            dict[kSecAttrAccessGroup as String] = g
        }
        return dict
    }
    
    /// Get bundle seed id from keychain.
    /// Use to make of keychain group.
    private static func bundleSeedID() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: "bundleSeedID",
                                    kSecAttrService as String: "",
                                    kSecReturnAttributes as String: kCFBooleanTrue]
        
        var result: AnyObject?
        var status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, &result)
        }
        if status != errSecSuccess {
            return nil
        }
        
        // accessGroup like : "GB7HXXXXXX.com.xxxxxx.Example"
        guard let res = result as? [String: Any] else { return nil }
        guard let accessGroup = res[kSecAttrAccessGroup as String] as? String else { return nil }
        
        let components: [String] = accessGroup.components(separatedBy: ".")
        return components.first
    }
}
