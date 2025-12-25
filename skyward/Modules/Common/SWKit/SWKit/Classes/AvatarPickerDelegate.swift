//
//  AvatarPickerDelegate.swift
//  Pods
//
//  Created by TXTS on 2025/12/19.
//


import UIKit
import Photos
import MobileCoreServices

public protocol AvatarPickerDelegate: AnyObject {
    func avatarPickerDidSelectImage(_ image: UIImage)
    func avatarPickerDidCancel()
    func avatarPickerDidFailWithError(_ error: String)
}

public class AvatarPickerManager: NSObject {
    
    public static let shared = AvatarPickerManager()
    
    public weak var delegate: AvatarPickerDelegate?
    public weak var presentingViewController: UIViewController?
    
    public override init() {}
    
    /// 显示头像选择弹窗
    func showAvatarPicker(in viewController: UIViewController) {
        self.presentingViewController = viewController
        
        let alertController = UIAlertController(
            title: "更换头像",
            message: "请选择图片来源",
            preferredStyle: .actionSheet
        )
        
        // 拍照
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "拍照", style: .default) { [weak self] _ in
                self?.checkCameraPermission()
            }
            cameraAction.setValue(UIImage(systemName: "camera"), forKey: "image")
            alertController.addAction(cameraAction)
        }
        
        // 从相册选择
        let albumAction = UIAlertAction(title: "从相册选择", style: .default) { [weak self] _ in
            self?.checkPhotoLibraryPermission()
        }
        albumAction.setValue(UIImage(systemName: "photo.on.rectangle"), forKey: "image")
        alertController.addAction(albumAction)
        
        // 取消
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.delegate?.avatarPickerDidCancel()
        }
        alertController.addAction(cancelAction)
        
        // 适配 iPad
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX, 
                                                y: viewController.view.bounds.midY, 
                                                width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        viewController.present(alertController, animated: true)
    }
    
    // MARK: - 权限检查
    
    public func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            openCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.openCamera()
                    } else {
                        self?.showPermissionAlert(type: "相机")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(type: "相机")
        @unknown default:
            break
        }
    }
    
    public func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            openPhotoLibrary()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self?.openPhotoLibrary()
                    } else {
                        self?.showPermissionAlert(type: "相册")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert(type: "相册")
        @unknown default:
            break
        }
    }
    
    public func showPermissionAlert(type: String) {
        let alert = UIAlertController(
            title: "权限被拒绝",
            message: "请在设置中允许访问\(type)",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let settingsAction = UIAlertAction(title: "去设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(settingsAction)
        
        presentingViewController?.present(alert, animated: true)
    }
    
    // MARK: - 打开相机/相册
    
    private func openCamera() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraDevice = .front // 默认使用前置摄像头
        picker.allowsEditing = true // 允许编辑（裁剪）
        picker.mediaTypes = [kUTTypeImage as String]
        picker.cameraCaptureMode = .photo
        
        presentingViewController?.present(picker, animated: true)
    }
    
    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true // 允许编辑（裁剪）
        picker.mediaTypes = [kUTTypeImage as String]
        
        // iOS 14+ 支持 limited 模式
        if #available(iOS 14, *) {
            picker.mediaTypes = ["public.image"]
        }
        
        presentingViewController?.present(picker, animated: true)
    }
    
    // MARK: - 图片处理
    
    /// 压缩图片
    private func compressImage(_ image: UIImage, maxSize: Int = 1024 * 1024) -> Data? {
        var compression: CGFloat = 1.0
        let maxCompression: CGFloat = 0.1
        var imageData = image.jpegData(compressionQuality: compression)
        
        // 如果图片大于最大尺寸，逐步压缩
        while let data = imageData, data.count > maxSize && compression > maxCompression {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
    
    /// 调整图片方向
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
    
    /// 裁剪图片为正方形
    private func cropToSquare(_ image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let length = min(originalWidth, originalHeight)
        
        let x = (originalWidth - length) / 2.0
        let y = (originalHeight - length) / 2.0
        let cropRect = CGRect(x: x, y: y, width: length, height: length)
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AvatarPickerManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // 获取编辑后的图片
            let editedImage = info[.editedImage] as? UIImage
            let originalImage = info[.originalImage] as? UIImage
            
            guard let selectedImage = editedImage ?? originalImage else {
                self.delegate?.avatarPickerDidFailWithError("无法获取图片")
                return
            }
            
            // 处理图片
            let fixedImage = self.fixImageOrientation(selectedImage)
            let croppedImage = self.cropToSquare(fixedImage)
            
            // 通知代理
            self.delegate?.avatarPickerDidSelectImage(croppedImage)
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.delegate?.avatarPickerDidCancel()
        }
    }
}
