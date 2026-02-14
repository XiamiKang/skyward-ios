//
//  ACUDeviceData.swift
//  Pods
//
//  Created by TXTS on 2026/2/12.
//


import Foundation

// MARK: - ACU设备数据结构
public struct ACUDeviceData: Codable {
    // REQLOC 终端状态 (7个)
    var lockStatus: Int = 0          // 锁定状态
    var antennaStatus: Int = 0       // 收藏状态
    var altitude: Double = 0         // 海拔
    var longitude: Int = 0          // 经度 ×100000
    var latitude: Int = 0           // 纬度 ×100000
    var powerSavingMode: Int = 0    // 低功耗
    var mode: Int = 0              // 当前模式
    
    // REQENV 环境信息 (2个)
    var temperature: String = "0.00"     // 温度
    var humidity: String = "0.00"        // 湿度
    
    // DEV_WARING 故障码 (5个)
    var imuFault: Int = 0          // 惯导故障码
    var beidouFault: Int = 0       // 北斗故障码
    var beaconFault: Int = 0       // 信标机故障
    var lnbFault: Int = 0          // LNB故障码
    var bucFault: Int = 0          // BUC故障码
    
    // REQDEV_INFO 设备信息 (4个)
    var firmwareVersion: String = "" // 固件版本号
    var deviceSN: String = ""       // 设备SN
    var catMAC: String = ""         // 猫的Mac
    var catSN: String = ""          // 猫的SN
}

// MARK: - 卫星设备数据结构
public struct SatelliteDeviceData: Codable {
    // /action/homestatus (3个)
    var rcstCurrentStatus: Int = 0      // 运行状态
    var rfRxSnr: Int = 0              // 接收信噪比
    var rfTxSnr: Int = 0             // 发送信噪比
    
    // /action/sysTrafficGet (2个)
    var rxBwAvg: Double = 0           // 流量接收速率
    var txBwAvg: Double = 0           // 流量发送速率
    
    // /action/searchBeamListGet
    var beamList: [BeamData] = []    // 候选波束
    
    // /action/oduDivideGet (3个)
    var satelliteName: String = ""     // 卫星资源
    var antennaName: String = ""       // 天线射频
    var rxFreq: String = ""           // 接收本振
    
    // /action/oduTransmitGet (2个)
    var txPower: String = ""          // 初始发射功率
    var txMaxPower: String = ""       // 最大发射功率
    
    // /action/oduLocationGet (4个)
    var longType: String = ""         // 经度方位 E/W
    var longValue: Int = 0           // 经度数据 ×100000
    var latType: String = ""          // 纬度方位 N/S
    var latValue: Int = 0           // 纬度数据 ×100000
    
    // /action/fwdStatusGet (9个)
    var fwdIsLock: String = ""        // 锁定状态
    var fwdSrate: String = ""         // 符号速率
    var fwdFreq: String = ""          // 锁定频率
    var fwdPower: String = ""         // 信号强度
    var fwdMode: String = "DVB-S2/S2X" // 接收模式
    var fwdModcode: String = ""       // 调制方式
    var fwdSnr: String = ""           // 信噪比
    var fwdBer: String = ""           // 误码率
    var fwdBeamId: String = ""        // 当前波速ID
    
    // /action/vsatStatusGetNew (9个)
    var authStatus: String = ""       // 认证状态
    var upSigRate: String = ""        // 信令速率
    var upTrfRate: String = ""        // 业务速率
    var upSigPower: String = ""       // 信令功率
    var upTrfPower: String = ""       // 业务功率
    var upSigModcod: String = ""      // 信令调制方式
    var upTrfModcod: String = ""      // 业务调制方式
    var upSigSnr: String = ""         // 信令信噪比
    var upTrfSnr: String = ""         // 业务信噪比
    
    // /action/RcstTypeGet (新增1个)
    var rcstXphType: String = ""      // 终端类型
}

public struct BeamData: Codable {
    var beamDescription: String = ""    // 波束描述
    var beamNSID: String = ""          // NSID
    var beamID: String = ""           // BeamID
    var beamPolarization: String = ""  // 极化方式
    var beamLBLinkType: String = ""    // LB链路类型
    var beamFrequency: String = ""     // 频率
    var beamSymbol: String = ""        // 符号速率
    var beamSatLongitude: Int = 0     // 卫星经度 ×100000
    
    mutating func form(with beamInfo: BeamInfo) {
        self.beamDescription = beamInfo.discribe
        self.beamNSID = beamInfo.nsid
        self.beamID = beamInfo.beamid
        self.beamPolarization = beamInfo.downlinkPolarization
        self.beamLBLinkType = beamInfo.lbLinkType
        self.beamFrequency = beamInfo.frequency
        self.beamSymbol = beamInfo.symbol
        self.beamSatLongitude = Int((Double(beamInfo.sate_longitude) ?? 0)*100000)
    }
}

// MARK: - 完整采集数据
public struct CollectedDeviceData: Codable {
    public var acuData: ACUDeviceData
    public var satelliteData: SatelliteDeviceData
    public var collectTime: TimeInterval
    public var deviceId: String
    
    public init(acuData: ACUDeviceData, satelliteData: SatelliteDeviceData) {
        self.acuData = acuData
        self.satelliteData = satelliteData
        self.collectTime = Date().timeIntervalSince1970
        self.deviceId = acuData.deviceSN.isEmpty ? "unknown" : acuData.deviceSN
    }
}
