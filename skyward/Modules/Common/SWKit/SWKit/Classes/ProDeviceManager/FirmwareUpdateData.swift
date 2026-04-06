//
//  FirmwareFileAttribute.swift
//  Pods
//
//  Created by TXTS on 2026/3/30.
//

import Foundation

// MARK: - 固件文件信息
public struct FirmwareFileAttribute: Codable {
    public let firmwareUrl: String
    public let firmwareSize: Int
    public let firmwareMd5: String
    public let firmwareType: Int // 1: 验证固件, 2: 正式固件
    
    public init(firmwareUrl: String, firmwareSize: Int, firmwareMd5: String, firmwareType: Int) {
        self.firmwareUrl = firmwareUrl
        self.firmwareSize = firmwareSize
        self.firmwareMd5 = firmwareMd5
        self.firmwareType = firmwareType
    }
    
    public var isValidationFirmware: Bool {
        return firmwareType == 1
    }
    
    public var isOfficialFirmware: Bool {
        return firmwareType == 2
    }
}

// MARK: - 固件更新数据（兼容新旧接口）
public struct FirmwareUpdateData: Codable {
    public let versionCode: Int
    public let versionName: String
    public let firmwareUrl: String?                // 改为可选（新接口可能为空）
    public let description: String?
    public let forceUpdate: Bool
    public let releaseTime: String
    public let hardwareModel: String?
    public let deviceType: Int
    public let firmwareFileAttributeList: [FirmwareFileAttribute]? // 新增：固件文件列表
    
    enum CodingKeys: String, CodingKey {
        case versionCode
        case versionName
        case firmwareUrl
        case description
        case forceUpdate
        case releaseTime
        case hardwareModel
        case deviceType
        case firmwareFileAttributeList
    }
    
    public init(versionCode: Int, versionName: String, firmwareUrl: String?, description: String?, forceUpdate: Bool, releaseTime: String, hardwareModel: String?, deviceType: Int, firmwareFileAttributeList: [FirmwareFileAttribute]?) {
        self.versionCode = versionCode
        self.versionName = versionName
        self.firmwareUrl = firmwareUrl
        self.description = description
        self.forceUpdate = forceUpdate
        self.releaseTime = releaseTime
        self.hardwareModel = hardwareModel
        self.deviceType = deviceType
        self.firmwareFileAttributeList = firmwareFileAttributeList
    }
    
    // MARK: - 兼容性方法
    
    /// 判断是否为新接口格式
    public var isNewApiFormat: Bool {
        return firmwareFileAttributeList?.isEmpty == false
    }
    
    /// 判断是否为旧接口格式
    public var isOldApiFormat: Bool {
        return firmwareUrl?.isEmpty == false && firmwareFileAttributeList == nil
    }
    
    /// 获取所有可用的固件URL
    public var allAvailableFirmwareUrls: [(url: String, type: Int?, size: Int?, md5: String?)] {
        var result: [(url: String, type: Int?, size: Int?, md5: String?)] = []
        
        if let list = firmwareFileAttributeList {
            for firmware in list {
                result.append((firmware.firmwareUrl, firmware.firmwareType, firmware.firmwareSize, firmware.firmwareMd5))
            }
        } else if let url = firmwareUrl, !url.isEmpty {
            result.append((url, nil, nil, nil))
        }
        
        return result
    }
    
    /// 获取默认固件（优先使用正式固件，没有则用验证固件，最后回退到旧接口）
    public var defaultFirmware: (url: String, type: Int?, size: Int?, md5: String?)? {
        if let list = firmwareFileAttributeList {
            // 优先返回正式固件
            if let official = list.first(where: { $0.firmwareType == 2 }) {
                return (official.firmwareUrl, official.firmwareType, official.firmwareSize, official.firmwareMd5)
            }
            // 返回验证固件
            if let validation = list.first(where: { $0.firmwareType == 1 }) {
                return (validation.firmwareUrl, validation.firmwareType, validation.firmwareSize, validation.firmwareMd5)
            }
        }
        
        // 回退到旧接口
        if let url = firmwareUrl, !url.isEmpty {
            return (url, nil, nil, nil)
        }
        
        return nil
    }
    
    /// 获取验证固件
    public var validationFirmware: FirmwareFileAttribute? {
        return firmwareFileAttributeList?.first(where: { $0.firmwareType == 1 })
    }
    
    /// 获取正式固件
    public var officialFirmware: FirmwareFileAttribute? {
        return firmwareFileAttributeList?.first(where: { $0.firmwareType == 2 })
    }
    
    /// 获取有效的固件URL（兼容新旧接口）
    public var effectiveFirmwareUrl: String? {
        return defaultFirmware?.url
    }
    
    /// 获取固件文件名称
    public func getFirmwareFileName(firmwareType: Int? = nil) -> String {
        guard let hardwareModel = hardwareModel else {
            return "firmware_\(versionCode).bin"
        }
        
        let typeSuffix: String
        if let type = firmwareType {
            typeSuffix = type == 1 ? "_validation" : (type == 2 ? "" : "_\(type)")
        } else {
            typeSuffix = ""
        }
        
        return "\(hardwareModel)_\(versionCode)\(typeSuffix).bin"
    }
}


public struct LocalFirmwareInfo: Codable {
    public let versionName: String
    public let downloadURL: String
    public let forceUpdate: Bool
    public let filePath: String
    public let downloadDate: Date
    public let fileSize: Int
    public let deviceType: Int
    public let firmwareId: String
    public let firmwareType: Int?          // 新增：固件类型（1:验证,2:正式）
    public let hardwareModel: String?      // 新增：硬件型号
    public let versionCode: Int?           // 新增：版本号
    public let firmwareMd5: String?        // 新增：MD5校验值
    public let isNewApiFormat: Bool        // 新增：是否新接口格式
    
    // 旧接口初始化方法
    public init(versionName: String,
                downloadURL: String,
                forceUpdate: Bool,
                filePath: String,
                downloadDate: Date,
                fileSize: Int,
                deviceType: Int,
                firmwareId: String) {
        self.versionName = versionName
        self.downloadURL = downloadURL
        self.forceUpdate = forceUpdate
        self.filePath = filePath
        self.downloadDate = downloadDate
        self.fileSize = fileSize
        self.deviceType = deviceType
        self.firmwareId = firmwareId
        self.firmwareType = nil
        self.hardwareModel = nil
        self.versionCode = nil
        self.firmwareMd5 = nil
        self.isNewApiFormat = false
    }
    
    // 新接口初始化方法
    public init(versionName: String,
                downloadURL: String,
                forceUpdate: Bool,
                filePath: String,
                downloadDate: Date,
                fileSize: Int,
                deviceType: Int,
                firmwareId: String,
                firmwareType: Int?,
                hardwareModel: String?,
                versionCode: Int?,
                firmwareMd5: String?,
                isNewApiFormat: Bool) {
        self.versionName = versionName
        self.downloadURL = downloadURL
        self.forceUpdate = forceUpdate
        self.filePath = filePath
        self.downloadDate = downloadDate
        self.fileSize = fileSize
        self.deviceType = deviceType
        self.firmwareId = firmwareId
        self.firmwareType = firmwareType
        self.hardwareModel = hardwareModel
        self.versionCode = versionCode
        self.firmwareMd5 = firmwareMd5
        self.isNewApiFormat = isNewApiFormat
    }
}
