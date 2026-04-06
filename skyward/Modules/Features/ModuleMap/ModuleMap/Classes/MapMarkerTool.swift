//
//  MapMarkerTool.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/24.
//

import Foundation
import TangramMap

class MapMarkerTool {
    
    class func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        return startLocation.distance(from: endLocation)
    }
    
    class func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.1fm", distance)
        } else {
            return String(format: "%.2fkm", distance / 1000)
        }
    }
    
    class func getSWAndNE(_ coordinates: [CLLocationCoordinate2D]) ->(CLLocationCoordinate2D, CLLocationCoordinate2D)? {
        guard coordinates.count > 1 else {
            return nil
        }

        // 计算所有点的边界
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let sw = CLLocationCoordinate2D(latitude: minLat, longitude: minLon)
        let ne = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon)
        
        return (sw, ne)
    }
    
    /// 调整相机位置以显示所有规划的路线点
    /// - Parameters:
    ///   - animated: 是否使用动画
    ///   - completion: 完成回调
    class func cameraPositionFitAllCoordinates(mapView: TGMapView, bounds: (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D), animated: Bool = false, completion: (() -> Void)? = nil) {
        
        let tgBounds = TGCoordinateBounds(sw: bounds.sw, ne: bounds.ne)
        
        // 统一使用 60 的边距
        let padding = UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60)
        var cameraPosition = mapView.cameraThatFitsBounds(tgBounds, withPadding: padding)
        
        // 先临时设置相机位置，以便计算屏幕上的实际尺寸
        mapView.cameraPosition = cameraPosition

        // 计算在屏幕上的实际矩形区域
        let routeRect = getRouteBoundsRect(mapView: mapView, bounds: bounds)
        let width = routeRect.width
        let height = routeRect.height
        
        // 如果高度大于宽度，需要缩小（减小 zoom）让高度降低
        if height > width {
            // 计算需要缩小的比例
            let scale = width / height  // 例如: 300/400 = 0.75
            
            // 通过调整 zoom 来实现缩放
            // zoom 越小，显示区域越大（图像越小）
            // 需要让图像变小，所以 zoom 要减小
            let currentZoom = mapView.zoom
            // zoom 是对数刻度，每增加 1 显示区域缩小一半
            // 缩小 scale 倍对应的 zoom 调整：log2(1/scale)
            let zoomAdjustment = log2(1.0 / scale)
            let newZoom = currentZoom - CGFloat(zoomAdjustment)
            
            // 创建新的相机位置，使用调整后的 zoom
            if let adjustedPosition = TGCameraPosition(center: cameraPosition.center,
                                                       zoom: newZoom,
                                                       bearing: cameraPosition.bearing,
                                                       pitch: cameraPosition.pitch) {
                cameraPosition = adjustedPosition
            }
        }
        
        if animated {
            mapView.setCameraPosition(cameraPosition, withDuration: 0.5, easeType: .linear) { _ in
                completion?()
            }
        } else {
            mapView.cameraPosition = cameraPosition
            completion?()
        }
    }

    // 辅助函数：计算 log2
    class private func log2(_ x: Double) -> Double {
        return log(x) / log(2)
    }

    /// 获取包含所有路线点的屏幕矩形区域
    /// - Parameters:
    ///   - mapView: 地图视图
    ///   - bounds: 边界坐标 (sw: 西南角, ne: 东北角)
    /// - Returns: 包含所有点的 CGRect（相对于 mapView）
    class func getRouteBoundsRect(mapView: TGMapView, bounds: (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D)) -> CGRect {
        // 转换为屏幕坐标
        let swPoint = mapView.viewPosition(from: bounds.sw, clipToViewport: false)
        let nePoint = mapView.viewPosition(from: bounds.ne, clipToViewport: false)

        // 计算实际占据的矩形（不含边距）
        let minX = min(swPoint.x, nePoint.x)
        let maxX = max(swPoint.x, nePoint.x)
        let minY = min(swPoint.y, nePoint.y)
        let maxY = max(swPoint.y, nePoint.y)

        let actualWidth = maxX - minX
        let actualHeight = maxY - minY

        // 返回实际占据的矩形，用于判断是否需要调整 zoom
        return CGRect(x: minX, y: minY, width: actualWidth, height: actualHeight)
    }

    /// 获取裁剪区域的正方形
    /// - Parameters:
    ///   - mapView: 地图视图
    ///   - bounds: 边界坐标 (sw: 西南角, ne: 东北角)
    /// - Returns: 裁剪区域的 CGRect（相对于 mapView）
    class func getCropRouteBoundsRect(mapView: TGMapView, bounds: (sw: CLLocationCoordinate2D, ne: CLLocationCoordinate2D)) -> CGRect {
        let boundsRect = MapMarkerTool.getRouteBoundsRect(mapView: mapView, bounds: bounds)
        //获取正方形，宽高是boundsRect最大值， 然后需要加20的外边距
        let maxSide = max(boundsRect.width, boundsRect.height) + 20
        let centerX = boundsRect.midX
        let centerY = boundsRect.midY
        let cropRect = CGRect(x: centerX - maxSide / 2, y: centerY - maxSide / 2, width: maxSide, height: maxSide)
        return cropRect
    }
}
