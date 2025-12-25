//
//  BaseResponse.swift
//  Pods
//
//  Created by TXTS on 2025/12/3.
//

import Foundation

// 基础响应模型
public struct BaseResponse<T: Codable>: Codable {
    public let code: String
    public let data: T?
    public let msg: String
    
    public var success: Bool {
        return code == "00000"
    }
}

// 通用响应模型
public struct CommonResponse: Codable {
    public let success: Bool
    public let message: String?
    public let data: [String: String]?
}

public struct SmsCodeResponse: Codable {
    public let code: String?
    public let data: String?
    public let msg: String?
}
