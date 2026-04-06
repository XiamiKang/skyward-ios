//
//  UIImage+Extensions.swift
//  SWKit
//
//  Created by zhaobo on 2026/2/12.
//

import Foundation

public extension UIImage {
    
    // 裁剪图片到指定区域
    func cropImage(to rect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }

        // 确保裁剪区域在图片范围内
        let scaleFactor = cgImage.width / Int(self.size.width)
        let scaledRect = CGRect(
            x: rect.origin.x * CGFloat(scaleFactor),
            y: rect.origin.y * CGFloat(scaleFactor),
            width: rect.width * CGFloat(scaleFactor),
            height: rect.height * CGFloat(scaleFactor)
        )

        // 确保裁剪区域不超出图片边界
        let maxX = CGFloat(cgImage.width) - scaledRect.origin.x
        let maxY = CGFloat(cgImage.height) - scaledRect.origin.y
        let clampedRect = CGRect(
            x: scaledRect.origin.x,
            y: scaledRect.origin.y,
            width: min(scaledRect.width, maxX),
            height: min(scaledRect.height, maxY)
        )

        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            // 如果 cropping 方法不可用，使用传统方法
            let width = cgImage.width
            let height = cgImage.height
            guard let _ = cgImage.dataProvider?.data,
                  let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
                return nil
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            guard let newCGImage = context.makeImage() else { return nil }
            return UIImage(cgImage: newCGImage, scale: self.scale, orientation: self.imageOrientation)
        }

        return UIImage(cgImage: croppedCGImage, scale: self.scale, orientation: self.imageOrientation)
    }

}
