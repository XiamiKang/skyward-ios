//
//  UserInfo.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/26.
//

import Foundation

public struct UserInfo: Codable {
    public let id: String?
    public let realName: String?
    public let nickname: String?
    public let avatar: String?
    public let email: String?
    public var isSetEmergency: Bool?
    public let createTime: String?
}

/// 紧急联系人信息模型
public struct EmergencyContact: Codable {
    public let id: String?
    public let name: String?
    public let phone: String?
    public let userId: String?
    public let isNoticeInsurance: Int?
    public let insuranceCode: String?
    public let isNoticeLtRescueTeam: Int?
}

