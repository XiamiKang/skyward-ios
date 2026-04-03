//
//  ImageManager.swift
//  Pods
//
//  Created by TXTS on 2026/3/5.
//


import UIKit
import Foundation

/// 图片管理类 - 负责图片的保存、获取和删除
public class ImageManager {
    
    // MARK: - 单例
    public static let shared = ImageManager()
    
    private init() {
        createBaseDirectory()
    }
    
    // MARK: - 目录结构
    private let baseDirectoryName = "AppImages"
    private let imagesDirectoryName = "Images"
    private let thumbnailsDirectoryName = "Thumbnails"
    private let tempDirectoryName = "Temp"
    
    // MARK: - 路径计算属性
    private var baseDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(baseDirectoryName)
    }
    
    private var imagesDirectory: URL {
        return baseDirectory.appendingPathComponent(imagesDirectoryName)
    }
    
    private var thumbnailsDirectory: URL {
        return baseDirectory.appendingPathComponent(thumbnailsDirectoryName)
    }
    
    private var tempDirectory: URL {
        return baseDirectory.appendingPathComponent(tempDirectoryName)
    }
    
    // MARK: - 文件管理器
    private let fileManager = FileManager.default
    private let ioQueue = DispatchQueue(label: "com.imagemanager.io", attributes: .concurrent)
    
    // MARK: - 初始化
    private func createBaseDirectory() {
        ioQueue.sync(flags: .barrier) {
            do {
                // 创建基础目录
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            } catch {
                print("创建目录失败: \(error)")
            }
        }
    }
    
    // MARK: - 公共方法
    
    /// 保存图片
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - name: 图片名称（可选，如果不提供将自动生成）
    ///   - quality: 图片质量（0-1，仅对JPEG有效）
    ///   - completion: 完成回调，返回保存路径
    public func saveImage(
        _ image: UIImage,
        name: String? = nil,
        quality: CGFloat = 0.8,
        completion: @escaping (Result<String, ImageError>) -> Void
    ) {
        ioQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                // 生成文件名
                let fileName = self.generateFileName(name)
                
                // 获取图片数据
                guard let imageData = self.getImageData(image, quality: quality) else {
                    completion(.failure(.dataConversionFailed))
                    return
                }
                
                // 生成文件路径
                let fileURL = self.imagesDirectory.appendingPathComponent(fileName)
                
                // 检查是否已存在
                if self.fileManager.fileExists(atPath: fileURL.path) {
                    completion(.failure(.fileAlreadyExists))
                    return
                }
                
                // 写入文件
                try imageData.write(to: fileURL)
                
                // 生成缩略图并保存
                self.createAndSaveThumbnail(from: image, fileName: fileName)
                
                completion(.success(fileURL.path))
                
            } catch {
                completion(.failure(.saveFailed(error)))
            }
        }
    }
    
    /// 根据路径获取图片
    /// - Parameters:
    ///   - path: 图片路径
    ///   - useThumbnail: 是否使用缩略图
    /// - Returns: UIImage?
    public func getImage(from path: String, useThumbnail: Bool = false) -> UIImage? {
        var image: UIImage?
        
        ioQueue.sync {
            // 检查文件是否存在
            guard fileManager.fileExists(atPath: path) else {
                return
            }
            
            // 如果要使用缩略图，尝试获取缩略图路径
            if useThumbnail {
                let fileName = (path as NSString).lastPathComponent
                let thumbnailPath = thumbnailsDirectory.appendingPathComponent(fileName).path
                
                if fileManager.fileExists(atPath: thumbnailPath) {
                    image = UIImage(contentsOfFile: thumbnailPath)
                    return
                }
            }
            
            // 加载原图
            image = UIImage(contentsOfFile: path)
        }
        
        return image
    }
    
    /// 异步获取图片
    func getImageAsync(
        from path: String,
        useThumbnail: Bool = false,
        completion: @escaping (UIImage?) -> Void
    ) {
        ioQueue.async { [weak self] in
            let image = self?.getImage(from: path, useThumbnail: useThumbnail)
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    /// 根据路径删除图片
    /// - Parameter path: 图片路径
    /// - Returns: 删除结果
    @discardableResult
    public func deleteImage(at path: String) -> Result<Void, ImageError> {
        var result: Result<Void, ImageError> = .success(())
        
        ioQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 检查文件是否存在
            guard self.fileManager.fileExists(atPath: path) else {
                result = .failure(.fileNotFound)
                return
            }
            
            do {
                // 删除原图
                try self.fileManager.removeItem(atPath: path)
                
                // 删除对应的缩略图
                let fileName = (path as NSString).lastPathComponent
                let thumbnailPath = self.thumbnailsDirectory.appendingPathComponent(fileName).path
                
                if self.fileManager.fileExists(atPath: thumbnailPath) {
                    try self.fileManager.removeItem(atPath: thumbnailPath)
                }
                
                result = .success(())
                
            } catch {
                result = .failure(.deleteFailed(error))
            }
        }
        
        return result
    }
    
    /// 批量删除图片
    func deleteImages(at paths: [String], completion: @escaping (Result<[String], ImageError>) -> Void) {
        ioQueue.async(flags: .barrier) { [weak self] in
            var failedPaths: [String] = []
            
            for path in paths {
                if case .failure = self?.deleteImage(at: path) {
                    failedPaths.append(path)
                }
            }
            
            DispatchQueue.main.async {
                if failedPaths.isEmpty {
                    completion(.success(paths))
                } else {
                    completion(.failure(.batchDeleteFailed(failedPaths)))
                }
            }
        }
    }
    
    /// 获取所有保存的图片路径
    func getAllImagePaths() -> [String] {
        var paths: [String] = []
        
        ioQueue.sync {
            do {
                let fileNames = try fileManager.contentsOfDirectory(atPath: imagesDirectory.path)
                paths = fileNames.map { imagesDirectory.appendingPathComponent($0).path }
            } catch {
                print("获取图片列表失败: \(error)")
            }
        }
        
        return paths
    }
    
    /// 获取图片信息
    func getImageInfo(at path: String) -> ImageInfo? {
        var info: ImageInfo?
        
        ioQueue.sync {
            guard fileManager.fileExists(atPath: path),
                  let attributes = try? fileManager.attributesOfItem(atPath: path),
                  let image = UIImage(contentsOfFile: path) else {
                return
            }
            
            let fileName = (path as NSString).lastPathComponent
            let fileSize = attributes[.size] as? Int64 ?? 0
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            
            info = ImageInfo(
                path: path,
                fileName: fileName,
                fileSize: fileSize,
                creationDate: creationDate,
                imageSize: image.size
            )
        }
        
        return info
    }
    
    /// 移动/重命名图片
    func moveImage(from sourcePath: String, to newName: String) -> Result<String, ImageError> {
        var result: Result<String, ImageError> = .failure(.fileNotFound)
        
        ioQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            guard self.fileManager.fileExists(atPath: sourcePath) else {
                result = .failure(.fileNotFound)
                return
            }
            
            let fileName = (sourcePath as NSString).lastPathComponent
            let fileExtension = (fileName as NSString).pathExtension
            let newFileName = "\(newName).\(fileExtension)"
            let newPath = self.imagesDirectory.appendingPathComponent(newFileName).path
            
            guard !self.fileManager.fileExists(atPath: newPath) else {
                result = .failure(.fileAlreadyExists)
                return
            }
            
            do {
                try self.fileManager.moveItem(atPath: sourcePath, toPath: newPath)
                result = .success(newPath)
            } catch {
                result = .failure(.moveFailed(error))
            }
        }
        
        return result
    }
    
    /// 清理临时文件
    func cleanTempDirectory() {
        ioQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                let tempFiles = try self.fileManager.contentsOfDirectory(atPath: self.tempDirectory.path)
                for file in tempFiles {
                    let filePath = self.tempDirectory.appendingPathComponent(file).path
                    try self.fileManager.removeItem(atPath: filePath)
                }
            } catch {
                print("清理临时文件失败: \(error)")
            }
        }
    }
    
    // MARK: - 私有辅助方法
    
    /// 生成文件名
    private func generateFileName(_ name: String?) -> String {
        if let name = name, !name.isEmpty {
            return name
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        return "IMG_\(timestamp)_\(uuid).jpg"
    }
    
    /// 获取图片数据
    private func getImageData(_ image: UIImage, quality: CGFloat) -> Data? {
        if quality < 1.0 {
            return image.jpegData(compressionQuality: quality)
        } else {
            return image.pngData()
        }
    }
    
    /// 创建并保存缩略图
    private func createAndSaveThumbnail(from image: UIImage, fileName: String) {
        let thumbnailSize = CGSize(width: 200, height: 200)
        
        // 创建缩略图
        UIGraphicsBeginImageContext(thumbnailSize)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 保存缩略图
        if let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6) {
            let thumbnailURL = thumbnailsDirectory.appendingPathComponent(fileName)
            try? thumbnailData.write(to: thumbnailURL)
        }
    }
}

// MARK: - 错误定义
public enum ImageError: Error {
    case dataConversionFailed
    case fileAlreadyExists
    case fileNotFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case batchDeleteFailed([String])
    case moveFailed(Error)
    
    public var localizedDescription: String {
        switch self {
        case .dataConversionFailed:
            return "图片数据转换失败"
        case .fileAlreadyExists:
            return "文件已存在"
        case .fileNotFound:
            return "文件不存在"
        case .saveFailed(let error):
            return "保存失败: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "删除失败: \(error.localizedDescription)"
        case .batchDeleteFailed(let paths):
            return "批量删除失败: \(paths.joined(separator: ", "))"
        case .moveFailed(let error):
            return "移动失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - 图片信息模型
public struct ImageInfo {
    let path: String
    let fileName: String
    let fileSize: Int64
    let creationDate: Date
    let imageSize: CGSize
    
    var fileSizeString: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var creationDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

// MARK: - 使用示例
extension ImageManager {
    func demo() {
        let manager = ImageManager.shared
        
        // 1. 保存图片
        if let image = UIImage(named: "example") {
            manager.saveImage(image, name: "myPhoto") { result in
                switch result {
                case .success(let path):
                    print("图片保存成功: \(path)")
                    
                    // 2. 获取图片
                    if let savedImage = manager.getImage(from: path) {
                        print("图片获取成功，尺寸: \(savedImage.size)")
                    }
                    
                    // 3. 获取图片信息
                    if let info = manager.getImageInfo(at: path) {
                        print("图片信息: \(info)")
                    }
                    
                    // 4. 删除图片
                    let deleteResult = manager.deleteImage(at: path)
                    switch deleteResult {
                    case .success:
                        print("图片删除成功")
                    case .failure(let error):
                        print("图片删除失败: \(error)")
                    }
                    
                case .failure(let error):
                    print("图片保存失败: \(error)")
                }
            }
        }
        
        // 5. 获取所有图片
        let allImages = manager.getAllImagePaths()
        print("所有图片: \(allImages)")
        
        // 6. 清理临时文件
        manager.cleanTempDirectory()
    }
}
