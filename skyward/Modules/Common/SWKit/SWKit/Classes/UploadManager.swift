//
//  UploadManager.swift
//  Pods
//
//  Created by TXTS on 2025/12/16.
//

import Moya
import SWNetwork

public class UploadManager {
    
    public let provider: MoyaProvider<UploadAPI>
    
    public init() {
        // 配置上传的超时时间（文件上传需要更长的时间）
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60  // 请求超时时间
        configuration.timeoutIntervalForResource = 60 * 10  // 资源超时时间（10分钟）
        
        provider = MoyaProvider<UploadAPI>(
            session: Session(configuration: configuration),
            plugins: [
                NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
            ]
        )
    }
    
    // MARK: - 上传文件方法
    
    /// 上传文件（Data格式）
    public func uploadFile(
        fileData: Data,
        fileName: String,
        mimeType: String,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadResponse, UploadError>) -> Void
    ) {
        provider.request(
            .uploadFile(fileData: fileData, fileName: fileName, mimeType: mimeType),
            callbackQueue: .main,
            progress: { progress in
                DispatchQueue.main.async {
                    progressHandler?(progress.progress)
                }
            }
        ) { result in
            switch result {
            case .success(let response):
                self.handleResponse(response, completion: completion)
            case .failure(let error):
                completion(.failure(.moyaError(error)))
            }
        }
    }
    
    /// 上传图片（UIImage格式）
    public func uploadImage(
        _ image: UIImage,
        fileName: String? = nil,
        compressionQuality: CGFloat = 0.8,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadResponse, UploadError>) -> Void
    ) {
        provider.request(
            .uploadImage(image: image, compressionQuality: compressionQuality, fileName: fileName),
            callbackQueue: .main,
            progress: { progress in
                DispatchQueue.main.async {
                    progressHandler?(progress.progress)
                }
            }
        ) { result in
            switch result {
            case .success(let response):
                self.handleResponse(response, completion: completion)
            case .failure(let error):
                completion(.failure(.moyaError(error)))
            }
        }
    }
    
    /// 上传本地文件（通过URL）
    public func uploadFileFromURL(
        fileURL: URL,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadResponse, UploadError>) -> Void
    ) {
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let fileExtension = fileURL.pathExtension
            let mimeType = getMimeType(for: fileExtension)
            
            uploadFile(
                fileData: fileData,
                fileName: fileName,
                mimeType: mimeType,
                progressHandler: progressHandler,
                completion: completion
            )
        } catch {
            completion(.failure(.fileReadError))
        }
    }
    
    /// 上传视频文件
    public func uploadVideo(
        videoURL: URL,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadResponse, UploadError>) -> Void
    ) {
        uploadFileFromURL(
            fileURL: videoURL,
            progressHandler: progressHandler,
            completion: completion
        )
    }
    
    /// 上传PDF文档
    public func uploadPDF(
        pdfURL: URL,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<UploadResponse, UploadError>) -> Void
    ) {
        uploadFileFromURL(
            fileURL: pdfURL,
            progressHandler: progressHandler,
            completion: completion
        )
    }
    
    // MARK: - 私有方法
    
    private func handleResponse(_ response: Response, completion: @escaping (Result<UploadResponse, UploadError>) -> Void) {
        do {
            // 尝试解析响应
            let decoder = JSONDecoder()
            let uploadResponse = try decoder.decode(UploadResponse.self, from: response.data)
            
            // 检查HTTP状态码
            if (200...299).contains(response.statusCode) {
                completion(.success(uploadResponse))
            } else {
                completion(.failure(.serverError(uploadResponse.msg ?? "上传失败")))
            }
        } catch {
            // 如果解析失败，尝试获取错误信息
            if let errorString = String(data: response.data, encoding: .utf8) {
                completion(.failure(.decodingError("解析失败: \(errorString)")))
            } else {
                completion(.failure(.decodingError("响应解析失败")))
            }
        }
    }
    
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "doc", "docx":
            return "application/msword"
        case "xls", "xlsx":
            return "application/vnd.ms-excel"
        case "ppt", "pptx":
            return "application/vnd.ms-powerpoint"
        case "txt":
            return "text/plain"
        case "mp4", "m4v":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        default:
            return "application/octet-stream"
        }
    }
}

public struct UploadResponse: Codable {
    public let code: String?
    public let msg: String?
    public let data: UploadData?
    public let requestId: String?
    
    public var isSuccess: Bool {
        return code == "200" || code == "00000"
    }
}

public struct UploadData: Codable {
    public let fileId: String?
    public let fileName: String?
    public let fileUrl: String?
    public let fileKey: String?
    public let fileSize: Int?
    public let fileType: String?
    public let fileMd5: String?
    public let saveMode: Int?
}

// MARK: - 错误类型

public enum UploadError: Error, LocalizedError {
    case moyaError(MoyaError)
    case serverError(String)
    case decodingError(String)
    case fileReadError
    case imageConversionFailed
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .moyaError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .decodingError(let message):
            return "数据解析失败: \(message)"
        case .fileReadError:
            return "文件读取失败"
        case .imageConversionFailed:
            return "图片转换失败"
        case .networkError:
            return "网络连接失败"
        }
    }
}


/**
 
 func uploadImage(image: UIImage) {
     uploadService.uploadImage(
         image,
         fileName: "my_photo.jpg",
         compressionQuality: 0.8,
         progressHandler: { [weak self] progress in
             let percentage = Int(progress * 100)
             print("上传进度: \(percentage)%")
         },
         completion: { [weak self] result in
             DispatchQueue.main.async {
                 switch result {
                 case .success(let response):
                     if response.isSuccess, let fileUrl = response.data?.fileUrl {
                         print("上传成功！文件URL: \(fileUrl)")
                     } else {
                         print("上传失败: \(response.msg ?? "未知错误")")
                     }
                 case .failure(let error):
                     print("上传错误: \(error.localizedDescription)")
                 }
             }
         }
     )
 }
 
 */
