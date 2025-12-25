//
//  ResponseModels.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/17.
//

import Foundation

public struct MiniDeviceData: Codable {
    public let name: String?                      // 设备名称
    public let serialNum: String?                 // 设备序列号
    public let imeiNum: String?                   // 设备IMEI
    public let forthGenCardNum: String?           // 设备4G卡号
    public let typeCode: String?                  // 窄带：NARROW_BAND, 宽带：BROAD_BAND
    public let state: Int?                        //  0 有效 1删除
    public let macAddress: String?                // 设备MAC地址
    public let model: String?                     // 设备型号   窄带：TXTS-NB-01
}

public struct FirmwareData: Codable {
    public let versionCode: Int?                  // 设备版本号
    public let versionName: String?               // 设备版本名称
    public let firmwareUrl: String?               // 设备固件地址
    public let forceUpdate: Bool?                 // 是否强制更新
    public let hardwareModel: String?             // 设备型号
}

public struct EmergencyInfoData: Codable {
    public let name: String?                      // 名称
    public let phone: String?                     // 手机号
}

public struct ResponseUserInfoData: Codable {
    public let userInfo: UserInfoData?             // 用户信息
    public let travelDistance: Int?                // 行程距离
    public let favoritesCount: Int?                // 收藏数量
    public let carCount: Int?                      // 车辆数量
    public let realNameAuthStatus: Int?            // 实名状态: 0-未实名, 1-已实名
    public let emergencyContactName: String?       // 紧急联系人
}

public struct UserInfoData: Codable {
    public let id: String?                        // 用户ID
    public let userNumber: String?                // 用户编号
    public let phone: String?                     // 手机号
    public let nickname: String?                  // 昵称
    public let avatar: String?                    // 头像
    public let gender: Int?                       // 性别
    public let city: String?                      // 城市
    public let cityCode: String?                  // 城市码
    public let personalitySign: String?           // 签名
}


