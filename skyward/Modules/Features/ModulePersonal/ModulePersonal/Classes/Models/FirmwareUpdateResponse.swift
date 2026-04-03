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


