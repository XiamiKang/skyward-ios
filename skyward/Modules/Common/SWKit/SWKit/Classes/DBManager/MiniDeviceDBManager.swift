//
//  MiniDeviceDBManager.swift
//  SWKit
//
//  Created by TXTS on 2026/1/4.
//

import Foundation
import WCDBSwift

public class MiniDeviceDBManager: NSObject {
    
    public static let shared = MiniDeviceDBManager.init()
    
    override init() {
        super.init()
    }
    
    //  MARK: - 窄带设备
    
    /// 添加当前设备
    public func insertFromMiniDeviceList(_ object: [MiniDeviceData]) {
        var miniDevices = [MiniDeviceData]()
        for device in object {
            if isImeiExists(imei: device.imeiNum ?? "") {
                return
            }
            miniDevices.append(device)
        }
        DBManager.shared.insertToDb(objects: miniDevices, intoTable: DBTableName.miniDevice.rawValue)
    }
    
    /// 查询整个表
    public func qureyFromMiniDeviceDataAllData() -> [MiniDeviceData]? {
        let query = MiniDeviceData.Properties.all.count
        if let dbData = DBManager.shared.queryFromDb(fromTable: DBTableName.miniDevice.rawValue, cls: MiniDeviceData.self, where: query) {
            return dbData
        }
        return nil
    }
    
    /// 根据imei查询
    public func qureyFromMiniDeviceWithIMEI(_ imei: String) -> [MiniDeviceData]? {
        let query = MiniDeviceData.Properties.imeiNum == imei
        if let dbData = DBManager.shared.queryFromDb(fromTable: DBTableName.miniDevice.rawValue, cls: MiniDeviceData.self, where: query) {
            return dbData
        }
        return nil
    }
    
    /// 查询该设备是否存在
    func isImeiExists(imei: String) -> Bool {
        // 创建查询条件：WHERE imei = '指定的imei'
        let condition = MiniDeviceData.Properties.imeiNum == imei
        
        // 查询数据库
        if let results: [MiniDeviceData] = DBManager.shared.queryFromDb(fromTable: DBTableName.miniDevice.rawValue,
                                                     cls: MiniDeviceData.self,
                                                     where: condition) {
            // 如果查询结果不为空，则表示存在
            return !results.isEmpty
        }
        
        // 查询失败或结果为空
        return false
    }
    
    /// 删除整个表
    public func deleteAllMiniDeviceTable() {
        let query = MiniDeviceData.Properties.all.count
        DBManager.shared.deleteFromDb(fromTable: DBTableName.miniDevice.rawValue, where: query)
    }
    
    /// 删除窄带设备通过IMEI
    public func deleteMiniDeviceWithIMEI(imei: String) {
        let query = MiniDeviceData.Properties.imeiNum == imei
        DBManager.shared.deleteFromDb(fromTable: DBTableName.miniDevice.rawValue, where: query)
    }
    
    /// 更新设备
    public func updateMiniDeviceWithIMEI(_ miniDeviceData: MiniDeviceData, imei: String) {
        let query = MiniDeviceData.Properties.imeiNum == imei
        DBManager.shared.updateToDb(table: DBTableName.miniDevice.rawValue, on: MiniDeviceData.Properties.all, with: miniDeviceData, where: query)
    }
}



