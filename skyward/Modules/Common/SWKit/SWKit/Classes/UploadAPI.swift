//
//  YourUploadTarget.swift
//  Pods
//
//  Created by TXTS on 2025/12/16.
//

import Foundation
import SWNetwork
import Moya
import Combine

public enum UploadAPI {
    case uploadFile(fileData: Data, fileName: String, mimeType: String)
    case uploadImage(image: UIImage, compressionQuality: CGFloat, fileName: String?)
}

extension UploadAPI: NetworkAPI {
    
    public var headers: [String: String]? {
        // 为所有请求添加默认的Accept头
        var defaultHeaders: [String: String] = [
            "Accept": "application/json"
        ]
        guard let token = TokenManager.shared.accessToken else {
            return defaultHeaders
        }
        defaultHeaders["Authorization"] = "Bearer \(token)"
        
        return defaultHeaders
    }
    
    public var path: String {
        switch self {
        case .uploadFile, .uploadImage:
            return "/txts-file/file/api/v1/files"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .uploadFile, .uploadImage:
            return .post
        }
    }
    
    public var task: Task {
        switch self {
        case .uploadFile(let fileData, let fileName, let mimeType):
            return createMultipartTask(fileData: fileData, fileName: fileName, mimeType: mimeType)
            
        case .uploadImage(let image, let compressionQuality, let fileName):
            guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
                return .requestPlain
            }
            
            let finalFileName = fileName ?? "image_\(Date().timeIntervalSince1970).jpg"
            return createMultipartTask(fileData: imageData, fileName: finalFileName, mimeType: "image/jpeg")
        }
    }
    
    private func createMultipartTask(fileData: Data, fileName: String, mimeType: String) -> Task {
        var multipartData: [MultipartFormData] = []
        
        // 1. 添加 folderType 参数 0-业务_私有 1-业务_公共 2-APP上传 3-路线/轨迹
        if let folderTypeData = "2".data(using: .utf8) {
            multipartData.append(
                MultipartFormData(
                    provider: .data(folderTypeData),
                    name: "folderType"
                )
            )
        }
    
        
        // 2. 添加 file 参数
        multipartData.append(
            MultipartFormData(
                provider: .data(fileData),
                name: "file",
                fileName: fileName,
                mimeType: mimeType
            )
        )
        
        return .uploadMultipart(multipartData)
    }
    
    // 辅助方法：根据文件扩展名获取 MIME 类型
    private func mimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "mp4":
            return "video/mp4"
        default:
            return "application/octet-stream"
        }
    }
}
