//
//  ResponseModels.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/17.
//

import Foundation
import SWKit

public struct EmergencyInfoData: Codable {
    public let id: String?                        // id
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

public struct HomeStatusData: Codable {
    public let num_string: String?                //
    public let rcst_current_status: Int?          // 运行状态
    public let rf_rx_is_locked: Int?              //
    public let rf_rx_snr: Int?                    // 接收信噪比
    public let rf_tx_snr: Int?                    // 发送信噪比
    public let x509_auth_status: Int?             //
    public let zd_version: Int?                   //
    
    
    // 计算属性：获取卫星链路状态
    var satelliteLinkStatus: SatelliteLinkStatus {
        return SatelliteLinkStatus(rawValue: rcst_current_status ?? -1) ?? .STATUS_OFF
    }
}

public struct AppVersionData: Codable {
    public let id: String?                        // ID
    public let versionCode: Int?                  // 版本号
    public let versionName: String?               // 版本名称
    public let platform: String?                  // 平台
    public let upgradeType: Int?               // 升级类型(0:无需升级 1:建议升级 2:强制升级)
    public let releaseTime: String?               // 发布时间
    public let fileUrl: String?                   // 安装包下载地址
    public let releaseNotes: String?              // 升级提示
}
