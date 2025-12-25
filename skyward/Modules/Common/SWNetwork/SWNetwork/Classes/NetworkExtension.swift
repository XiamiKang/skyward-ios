//
//  NetworkExtension.swift
//  SWNetworkKit
//
//  Created by 赵波 on 2025/11/16.
//

import Foundation
import Moya

public extension Task {
    /// 获取参数
    var parameters: [String: Any]? {
        switch self {
        case .requestPlain:
            return nil
        case .requestParameters(let parameters, _):
            return parameters
        case .requestCompositeData(let bodyData, let urlParameters):
            var params = urlParameters
            if let bodyDict = try? JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any] {
                params.merge(bodyDict) { _, new in new }
            }
            return params
        case .requestCompositeParameters(let bodyParameters, _, let urlParameters):
            var params = urlParameters
            params.merge(bodyParameters) { _, new in new }
            return params
        case .requestJSONEncodable(let encodable):
            return try? encodable.asDictionary()
        case .requestCustomJSONEncodable(let encodable, _):
            return try? encodable.asDictionary()
        default:
            return nil
        }
    }
    
    /// 获取编码方式
    var encoding: ParameterEncoding {
        switch self {
        case .requestParameters(_, let encoding):
            return encoding
        case .requestCompositeParameters(_, let encoding, _):
            return encoding
        case .requestCustomJSONEncodable(_, _):
//            return JSONEncoding(encoder: encoder)
            return JSONEncoding.default
        default:
            return JSONEncoding.default
        }
    }
}

// MARK: - Encodable Extension
public extension Encodable {
    
    /// 转换为字典
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dictionary ?? [:]
    }
}

// MARK: - Response扩展
public extension Response {
    
    /// 响应扩展 - 支持Codable解析

    /// 直接解析为目标数据模型（自动处理NetworkResponse包装）
    func map<T: Codable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        do {
            // 首先尝试直接解析为目标类型（适用于非包装格式）
            return try decoder.decode(type, from: data)
        } catch {
            // 如果直接解析失败，尝试解析为NetworkResponse包装格式
            do {
                let networkResponse = try decoder.decode(NetworkResponse<T>.self, from: data)
                
                // 检查业务状态码
                guard networkResponse.isSuccess else {
                    throw NetworkError.serverError(statusCode: Int(networkResponse.code ?? "0") ?? 0, message: networkResponse.msg)
                }
                
                // 检查数据是否存在
                guard let data = networkResponse.data else {
                    throw NetworkError.parsingError(underlying: NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应数据为空"]))
                }
                
                return data
            } catch {
                throw MoyaError.jsonMapping(self)
            }
        }
    }
}

// MARK: - String扩展
public extension String {
    
    /// 转换为URL
    var asURL: URL? {
        return URL(string: self)
    }
    
    /// URL编码
    var urlEncoded: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    /// URL解码
    var urlDecoded: String? {
        return removingPercentEncoding
    }
    
    func asJSONObject() -> [String: Any]? {
        if let jsonData = data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
            return jsonObject
        }
        return nil
    }
}

// MARK: - Dictionary扩展
public extension Dictionary where Key == String, Value == Any {
    
    /// 转换为URL查询字符串
    var queryString: String {
        return compactMap { key, value in
            "\(key)=\("\(value)".urlEncoded ?? "")"
        }.joined(separator: "&")
    }
    
    /// 转换为JSON数据
    func toJSONData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
    /// 转换为JSON字符串
    func asString() -> String? {
        if let jsonData = try? toJSONData(),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return nil
    }
}

// MARK: - Data扩展
public extension Data {
    
    /// 转换为JSON字符串
    var jsonString: String? {
        return String(data: self, encoding: .utf8)
    }
    
    /// 安全地转换为JSON对象
    var jsonObject: Any? {
        return try? JSONSerialization.jsonObject(with: self, options: .allowFragments)
    }
}
