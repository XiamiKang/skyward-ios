//
//  ForwardStatusResponse.swift
//  Pods
//
//  Created by TXTS on 2026/2/10.
//

import Foundation

// 前向链路状态模型
struct ForwardStatusResponse: Codable {
    let code: Int
    let uptime: Int
    let u8FwdIsLock: Int
    let u32CurrentSrate: Int
    let s32CurrentPower: Int
    let u8FwdModcode: Int
    let s32FwdSnr: Int
    let s32FwdSnrMax: Int
    let u32CurrentFreq: Int
    let u32CurrentBer: Int
    let txSnr: Int
    let satelliteNameNow: String
    let beamIdNow: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case uptime
        case u8FwdIsLock = "u8_fwd_is_lock"
        case u32CurrentSrate = "u32_current_srate"
        case s32CurrentPower = "s32_current_power"
        case u8FwdModcode = "u8_fwd_modcode"
        case s32FwdSnr = "s32_fwd_snr"
        case s32FwdSnrMax = "s32_fwd_snr_max"
        case u32CurrentFreq = "u32_current_freg"
        case u32CurrentBer = "u32_current_ber"
        case txSnr = "tx_snr"
        case satelliteNameNow = "satellite_name_now"
        case beamIdNow = "beamid_now"
    }
}

// VSAT状态模型
struct VSATStatusResponse: Codable {
    let code: String
    let rcstVersionType: String
    let x509AuthStatus: String
    let zdVersion: String
    let u32TimuCount: String
    let u32TimbCount: String
    let u32DownUnicastIpCount: String
    let u32DownMulcastIpCount: String
    let u32DownLosskeyCount: String
    let u32DownFpgaSyncLoss: String
    let u32FpgaGseCount: String
    let u32FpgaBbframeCount: String
    let rcstCurrentStatus: String
    let u32UpSigRate: String
    let u32UpTrfRate: String
    let u32UpSigPower: String
    let u32UpTrfPower: String
    let u32UpSigModcod: String
    let u32UpTrfModcod: String
    let u8UpSigSnr: String
    let u8UpTrfSnr: String
    let u32LbSendCount: String
    let u32CbSendCount: String
    let u32TrfSendCount: String
    let u32TotalRemainedPacketCount: String
    let u32FpgaReceivePacket: String
    let u32FpgaSendPacket: String
    
    // 初始化映射
    enum CodingKeys: String, CodingKey {
        case code
        case rcstVersionType = "rcst_version_type"
        case x509AuthStatus = "x509_auth_status"
        case zdVersion = "zd_version"
        case u32TimuCount = "u32_timu_count"
        case u32TimbCount = "u32_timb_count"
        case u32DownUnicastIpCount = "u32_down_unicast_ip_count"
        case u32DownMulcastIpCount = "u32_down_mulcast_ip_count"
        case u32DownLosskeyCount = "u32_down_losskey_count"
        case u32DownFpgaSyncLoss = "u32_down_fpga_sync_loss"
        case u32FpgaGseCount = "u32_fpga_gse_count"
        case u32FpgaBbframeCount = "u32_fpga_bbframe_count"
        case rcstCurrentStatus = "rcst_current_status"
        case u32UpSigRate = "u32_up_sig_rate"
        case u32UpTrfRate = "u32_up_trf_rate"
        case u32UpSigPower = "u32_up_sig_power"
        case u32UpTrfPower = "u32_up_trf_power"
        case u32UpSigModcod = "u32_up_sig_modcod"
        case u32UpTrfModcod = "u32_up_trf_modcod"
        case u8UpSigSnr = "u8_up_sig_snr"
        case u8UpTrfSnr = "u8_up_trf_snr"
        case u32LbSendCount = "u32_lb_send_count"
        case u32CbSendCount = "u32_cb_send_count"
        case u32TrfSendCount = "u32_trf_send_count"
        case u32TotalRemainedPacketCount = "u32_total_remained_packet_count"
        case u32FpgaReceivePacket = "u32_fpga_receive_packet"
        case u32FpgaSendPacket = "u32_fpga_send_packet"
    }
}

class VSATStatusViewModel: ObservableObject {
    @Published var forwardStatus: ForwardStatusResponse?
    @Published var vsatStatus: VSATStatusResponse?
    @Published var isLoading = false
    @Published var lastUpdateTime = Date()
    
    // MARK: - 计算属性（合并两个接口的数据）
    
    // 1. 信号强度 (dBm)
    var signalStrength: String {
        guard let power = forwardStatus?.s32CurrentPower else { return "-" }
        let powerInDb = Double(power) / 1000.0
        return String(format: "%.1f dBm", powerInDb)
    }
    
    // 2. 调制方式 (前向链路)
    var forwardModulation: String {
        guard let modcode = forwardStatus?.u8FwdModcode else { return "-" }
        return forwardModulationType(modcode)
    }
    
    // 3. 信噪比 (前向链路)
    var forwardSNR: String {
        guard let snr = forwardStatus?.s32FwdSnr else { return "-" }
        let snrValue = Double(snr) / 10.0
        return String(format: "%.1f dB", snrValue)
    }
    
    // 4. 信令功率
    var signalingPower: String {
        guard let powerStr = vsatStatus?.u32UpSigPower else { return "-" }
        return transmitPowerNew(powerStr)
    }
    
    // 5. 业务功率
    var trafficPower: String {
        guard let powerStr = vsatStatus?.u32UpTrfPower else { return "-" }
        return transmitPowerNew(powerStr)
    }
    
    // 6. 信令调制方式
    var signalingModulation: String {
        guard let modcod = vsatStatus?.u32UpSigModcod else { return "-" }
        return vsatModulationType(modcod)
    }
    
    // 7. 业务调制方式
    var trafficModulation: String {
        guard let modcod = vsatStatus?.u32UpTrfModcod else { return "-" }
        return vsatModulationType(modcod)
    }
    
    // 8. 信令信噪比
    var signalingSNR: String {
        guard let sigSnrStr = vsatStatus?.u8UpSigSnr,
              let sigSnr = Int(sigSnrStr) else { return "-" }
        let snrValue = Double(sigSnr - 120) / 5.0
        return String(format: "%.1f dB", snrValue)
    }
    
    // 9. 业务信噪比
    var trafficSNR: String {
        guard let trfSnrStr = vsatStatus?.u8UpTrfSnr,
              let trfSnr = Int(trfSnrStr) else { return "-" }
        let snrValue = Double(trfSnr - 120) / 5.0
        return String(format: "%.1f dB", snrValue)
    }
    
    // 10. 符号速率
    var symbolRate: String {
        guard let srate = forwardStatus?.u32CurrentSrate else { return "-" }
        let srateInMsps = Double(srate) / 1000000.0
        return String(format: "%.3f Msps", srateInMsps)
    }
    
    // 11. 锁定状态
    var lockStatus: String {
        guard let isLock = forwardStatus?.u8FwdIsLock else { return "未知" }
        return isLock == 1 ? "已锁定" : "未锁定"
    }
    
    // 12. 频率
    var frequency: String {
        guard let freq = forwardStatus?.u32CurrentFreq else { return "-" }
        let freqInKHz = Double(freq)
        return formatNumber(freqInKHz) + " KHz"
    }
    
    // 13. 卫星名称
    var satelliteName: String {
        forwardStatus?.satelliteNameNow ?? "-"
    }
    
    // 14. 波束ID
    var beamId: String {
        forwardStatus?.beamIdNow.description ?? "-"
    }
    
    // 15. 设备状态
    var deviceStatus: String {
        guard let statusCode = vsatStatus?.rcstCurrentStatus,
              let code = Int(statusCode) else {
            return "未知"
        }
        
        switch code {
        case 0: return "保持待机"
        case 1: return "离线待机"
        case 2: return "准备登录"
        case 3: return "准备同步"
        case 4: return "TDMA同步"
        case 5: return "NCR恢复"
        case -1: return "状态关闭"
        default: return "未知状态"
        }
    }
    
    // MARK: - 转换函数
    
    // 前向链路调制方式转换
    private func forwardModulationType(_ modcode: Int) -> String {
        switch modcode {
        case 0: return "DUMMY"
        case 1: return "QPSK 1/4"
        case 2: return "QPSK 1/3"
        case 3: return "QPSK 2/5"
        case 4: return "QPSK 1/2"
        case 5: return "QPSK 3/5"
        case 6: return "QPSK 2/3"
        case 7: return "QPSK 3/4"
        case 8: return "QPSK 4/5"
        case 9: return "QPSK 5/6"
        case 10: return "QPSK 8/9"
        case 11: return "QPSK 9/10"
        case 12: return "8PSK 3/5"
        case 13: return "8PSK 2/3"
        case 14: return "8PSK 3/4"
        case 15: return "8PSK 5/6"
        case 16: return "8PSK 8/9"
        case 17: return "8PSK 9/10"
        case 18: return "16APSK 2/3"
        case 19: return "16APSK 3/4"
        case 20: return "16APSK 4/5"
        case 21: return "16APSK 5/6"
        case 22: return "16APSK 8/9"
        case 23: return "16APSK 9/10"
        case 24: return "32APSK 3/4"
        case 25: return "32APSK 4/5"
        case 26: return "32APSK 5/6"
        case 27: return "32APSK 8/9"
        case 28: return "32APSK 9/10"
        default:
            return "未知调制 (\(modcode))"
        }
    }
    
    // VSAT回传调制方式转换
    private func vsatModulationType(_ modcod: String) -> String {
        guard let code = Int(modcod) else { return "-" }
        
        switch code {
        case 1, 2, 3, 13:
            return "QPSK1/3"
        case 4:
            return "QPSK1/2"
        case 5:
            return "QPSK2/3"
        case 6:
            return "QPSK3/4"
        case 7:
            return "QPSK5/6"
        case 8:
            return "8QPSK2/3"
        case 9:
            return "8QPSK3/4"
        case 10:
            return "8QPSK5/6"
        case 11:
            return "16QPSK3/4"
        case 12:
            return "16PSK5/6"
        case 14:
            return "QPSK1/2"
        case 15:
            return "QPSK2/3"
        case 16:
            return "QPSK3/4"
        case 17:
            return "QPSK5/6"
        case 18:
            return "8PSK2/3"
        case 19:
            return "8PSK3/4"
        case 20:
            return "8PSK5/6"
        case 21:
            return "16QAM3/4"
        case 22:
            return "16QAM5/6"
        default:
            return "-"
        }
    }
    
    private func transmitPowerNew(_ power: String) -> String {
        return "\(power) dBm"
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // MARK: - 数据获取
    
    func fetchAllStatus(completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        let group = DispatchGroup()
        var forwardSuccess = false
        var vsatSuccess = false
        
        // 获取前向链路状态
        group.enter()
        fetchForwardStatus { success in
            forwardSuccess = success
            group.leave()
        }
        
        // 获取VSAT状态
        group.enter()
        fetchVSATStatus { success in
            vsatSuccess = success
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            self.lastUpdateTime = Date()
            completion(forwardSuccess || vsatSuccess)
        }
    }
    
    private func fetchForwardStatus(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://192.168.251.1/action/fwdStatusGet") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ForwardStatusResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.forwardStatus = response
                    completion(true)
                }
            } catch {
                print("前向链路JSON解析错误: \(error)")
                completion(false)
            }
        }.resume()
    }
    
    private func fetchVSATStatus(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://192.168.251.1/action/vsatStatusGetNew") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                completion(false)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(VSATStatusResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.vsatStatus = response
                    completion(true)
                }
            } catch {
                print("VSAT JSON解析错误: \(error)")
                completion(false)
            }
        }.resume()
    }
}
