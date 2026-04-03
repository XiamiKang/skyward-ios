//
//  RouteManager.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/18.
//

import Foundation
import CoreLocation
import SWKit
import SWNetwork

class RouteManager: NSObject {
    private let dataManager = RouteDataManager()
    
    
    // MARK: - Initializer
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidTermination),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startRecord() {
        dataManager.startRecord(type: .route)
    }
    
    func endRecord() {
        dataManager.endRecord()
    }
    
    // MARK: - 增删改查
    
    func writePoint(_ point: CLLocationCoordinate2D) {
        let point = RecordPoint(latitude: point.latitude, longitude: point.longitude)
        dataManager.writePointToSessionTxtFile(point)
    }
    
    func revocation() -> Bool {
        return dataManager.sessionRouteRemoveLastPoint()
    }
    
    func clear() -> Bool {
        return dataManager.sessionRouteRemoveAllPoint()
    }
    
    // MARK: 保存轨迹相关
    
    func isValidSessionRoute() -> Bool {
        guard let route = dataManager.sessionRoute else {
            return false
        }
        return route.endLatitude != nil && route.endLongitude != nil
    }
    
    func assembleSessionRoute(completion: @escaping (Route?) ->Void) {
        dataManager.assembleSessionRoute { [weak self] in
            completion(self?.dataManager.sessionRoute)
        }
    }

    func saveSessionRoute(newName: String?, desc: String?, coverImage: UIImage?, completion: @escaping (Bool) -> Void) {
        if let newName = newName, !newName.isEmpty {
            dataManager.sessionRoute?.routeName = newName
        }
        
        if let desc = desc {
            dataManager.sessionRoute?.description = desc
        }
        
        guard let route = dataManager.sessionRoute else {
            completion(false)
            return
        }
        
        if NetworkMonitor.shared.isConnected {
            dataManager.checkSensitiveWords(newName) { [weak self] success in
                if success {
                    self?.dataManager.saveRouteToServer(route, coverImage: coverImage, completion: completion)
                }
            }
        } else {
            RouteDataManager.saveRouteCoverToLocal(coverImage, routeId: route.id)
            completion(dataManager.saveSessionRouteToLocal())
        }
    }
    
    //MARK: - Notification
    
    @objc func appDidTermination() {
        // 如果正在记录，杀程序需要endRecord
        endRecord()
    }
}
