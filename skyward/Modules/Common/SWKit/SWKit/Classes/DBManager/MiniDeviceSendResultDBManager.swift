//
//  MiniDeviceDBManager.swift
//  SWKit
//
//  Created by TXTS on 2026/1/4.
//

import Foundation
import WCDBSwift

public class MiniDeviceSendResultDBManager: NSObject {
    
    public static let shared = MiniDeviceSendResultDBManager.init()
    
    override init() {
        super.init()
    }
    
    //  MARK: - 窄带设备
    
    /// 添加当前收发记录
    public func insertFromMiniDeviceSendResultList(_ object: [MiniDeviceSendResultData]) {
        DBManager.shared.insertToDb(objects: object, intoTable: DBTableName.miniDeviceSendResult.rawValue)
    }
    
    /// 查询整个表
    public func qureyAllData() -> [MiniDeviceSendResultData]? {
        let query = MiniDeviceSendResultData.Properties.all.count
        if let dbData = DBManager.shared.queryFromDb(fromTable: DBTableName.miniDeviceSendResult.rawValue, cls: MiniDeviceSendResultData.self, where: query) {
            return dbData
        }
        return nil
    }
    
    /// 根据imei查询
    public func qureyFromSendResultWithIMEI(_ imei: String) -> [MiniDeviceSendResultData]? {
        let query = MiniDeviceSendResultData.Properties.imeiNum == imei
        if let dbData = DBManager.shared.queryFromDb(fromTable: DBTableName.miniDeviceSendResult.rawValue, cls: MiniDeviceSendResultData.self, where: query) {
            return dbData
        }
        return nil
    }
    
    /// 删除整个表
    public func deleteAllMiniDeviceTable() {
        let query = MiniDeviceSendResultData.Properties.all.count
        DBManager.shared.deleteFromDb(fromTable: DBTableName.miniDeviceSendResult.rawValue, where: query)
    }
    
    /// 删除窄带设备通过IMEI
    public func deleteSendResultWithIMEI(imei: String) {
        let query = MiniDeviceSendResultData.Properties.imeiNum == imei
        DBManager.shared.deleteFromDb(fromTable: DBTableName.miniDeviceSendResult.rawValue, where: query)
    }
}



