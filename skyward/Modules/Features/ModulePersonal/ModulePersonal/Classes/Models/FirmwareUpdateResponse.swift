//
//  FirmwareUpdateResponse.swift
//  Pods
//
//  Created by TXTS on 2026/1/13.
//


import Foundation
import Combine

// MARK: - 数据模型
struct FirmwareUpdateResponse: Codable {
    let code: String
    let data: FirmwareUpdateData?
    let msg: String
    let requestId: String?
}

struct FirmwareUpdateData: Codable {
    let versionCode: Int
    let versionName: String
    let firmwareUrl: String
    let description: String?
    let forceUpdate: Bool
    let releaseTime: String
    let hardwareModel: String?
    let deviceType: Int
    
    enum CodingKeys: String, CodingKey {
        case versionCode
        case versionName
        case firmwareUrl
        case description
        case forceUpdate
        case releaseTime
        case hardwareModel
        case deviceType
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
}

// MARK: - 常量定义
struct FirmwareConstants {
    // 固定设备类型
    static let fixedDeviceType = 2
    
    // UserDefaults Key（简化版，只有一个版本）
    static let currentVersionKey = "firmware_current_version"     // 本地存储的版本号
    static let firmwareDownloadedKey = "firmware_downloaded_info" // 已下载固件信息
    static let firmwareFilePathKey = "firmware_file_path"         // 固件文件路径
    static let hardwareModelKey = "firmware_hardware_model"       // 硬件型号
    static let firmwareDirectory = "Firmware"                     // 固件存储目录
    static let defaultVersion = "1.0.0.0"                         // 默认版本
    static let defaultHardwareModel = "TX035"                     // 默认硬件型号
}
