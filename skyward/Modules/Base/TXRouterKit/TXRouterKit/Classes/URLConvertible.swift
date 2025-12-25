//
//  URLConvertible.swift
//  skyward
//
//  Created by 赵波 on 2025/11/11.
//

import Foundation

public protocol URLConvertible {
    var urlValue: URL? { get }
    var urlStringValue: String { get }
}

extension String: URLConvertible {
    
    public var urlValue: URL? {
        if let url = URL(string: self) {
            return url
        }
        var set = CharacterSet()
        set.formUnion(.urlHostAllowed)
        set.formUnion(.urlPathAllowed)
        set.formUnion(.urlQueryAllowed)
        set.formUnion(.urlFragmentAllowed)
        return self.addingPercentEncoding(withAllowedCharacters: set).flatMap {
            URL(string: $0)
        }
    }
    
    public var urlStringValue: String {
        return self
    }
}

extension String {
    public func httpUrlStringAppendParam(str:String) -> String {
        if str.count == 0  || !self.hasPrefix("http") {
            return self
        }
        
        guard let url = URL(string: self) else {
            return self
        }
        
        var hasParam = url.queryParameters.count > 0

        var newStr = self
        if hasParam {
            newStr = "\(self)&\(str)"
        } else {
            newStr = "\(self)?\(str)"
        }
        return newStr
    }
}

extension URL: URLConvertible {
    public var urlValue: URL? {
        return self
    }
    
    public var urlStringValue: String {
        return self.absoluteString
    }
}

extension URL {
    public var queryParameters: [String: String] {
        var parameters = [String: String]()
        let urlComponent = URLComponents(url: self, resolvingAgainstBaseURL: false)
        guard let queryItems = urlComponent?.queryItems else { return parameters }
        queryItems.forEach { parameters[$0.name] = $0.value }
        return parameters
    }
    
    public var queryAndFragmentParameters: [String: String] {
        var parameters = [String: String]()
        guard let url = URL(string: self.urlStringValue) else {
            return parameters
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // 解析查询参数
        if let queryItems = components?.queryItems {
            queryItems.forEach { parameters[$0.name] = $0.value }
        }
        // 解析片段参数
        if let fragment = components?.fragment {
            let fragmentComponents = fragment.components(separatedBy: "?").last
            guard let fragmentParams = fragmentComponents?.components(separatedBy: "&") else {
                return parameters
            }
            for fragmentParam in fragmentParams {
                let keyValue = fragmentParam.components(separatedBy: "=")
                if keyValue.count == 2 {
                    parameters[keyValue[0]] = keyValue[1]
                }
            }
        }
        return parameters
    }
}
