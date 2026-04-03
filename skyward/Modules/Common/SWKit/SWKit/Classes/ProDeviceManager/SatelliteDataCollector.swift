//
//  HomeStatusResponse.swift
//  Pods
//
//  Created by TXTS on 2026/2/12.
//

import Foundation

// MARK: - 新增 RcstTypeGet 响应模型
struct RcstTypeResponse: Codable {
    let transceiverType: String?
    let rcst_type: String?
    let zd_version: String?
    let network_mode: String?
    let vlanmode: String?
    let item_type: String?
    let freqType: String?
    let rf_tx_type: String?
    let ACM_or_CCM: String?
    let installType: String?
    let locked: String?
    let beamaccsss_map_isnot_dbs_flag: String?
    let space0_or_weitong1: String?
    let langtype: String?
    let anovo_sys: String?
    let rcst_xph_type: String?      // 终端类型
    let wanMac: String?
}

// MARK: - 卫星接口响应模型
public struct HomeStatusResponse: Codable {
    public let num_string: String?
    public let rcst_current_status: Int?
    public let rf_rx_is_locked: Int?
    public let rf_rx_snr: Int?
    public let rf_tx_snr: Int?
    public let x509_auth_status: Int?
    public let zd_version: Int?
    
    // 计算属性：获取卫星链路状态
    public var satelliteLinkStatus: SatelliteLinkStatus {
        return SatelliteLinkStatus(rawValue: rcst_current_status ?? -1) ?? .STATUS_OFF
    }
}

public struct SysTrafficResponse: Codable {
    public let code: String
    public let sysTraffic: String
    
    public var receiveBandwidth: Double {
        let values = sysTraffic.split(separator: " ").compactMap { Double($0) }
        return values.count >= 3 ? values[2] : 0
    }
    
    public var transmitBandwidth: Double {
        let values = sysTraffic.split(separator: " ").compactMap { Double($0) }
        return values.count >= 4 ? values[3] : 0
    }
}

enum BeamSearchStatus: String {
    case idle = "0"              // 空闲
    case querying = "1"          // 查询中
    case success = "2"           // 查询成功
    case noBeamFile = "3"        // 无波束文件
    case noBeamCheck = "4"       // 无可用波束
    case queryFailed = "5"       // 查询失败
    case timeout = "6"           // 超时
    
    var isSuccess: Bool {
        return self == .success
    }
    
    var isQuerying: Bool {
        return self == .querying
    }
    
    var isFailed: Bool {
        return self == .noBeamFile || self == .noBeamCheck || self == .queryFailed || self == .timeout
    }
}

struct BeamSearchStatusResponse: Codable {
    let code: String
    
    var status: BeamSearchStatus {
        return BeamSearchStatus(rawValue: code) ?? .idle
    }
}

struct BeamSearchResponse: Codable {
    let code: String
    let beam_count: String
    let info: [BeamInfo]
}

struct BeamInfo: Codable {
    let discribe: String
    let nsid: String
    let beamid: String
    let downlinkPolarization: String
    let lbLinkType: String
    let frequency: String
    let symbol: String
    let sate_longitude: String
    let enable: String
}

struct OduDivideResponse: Codable {
    let code: String
    let rx_freq_main: String
    let rx_freq_back: String
    let tx_freq_main: String
    let tx_freq_back: String
    let mainback_flag: String
    let satellite_name_main: String
    let antenna_name_main: String
    let satellite_name_back: String
    let antenna_name_back: String
    let lock_freq_main: String
    let rx_symbol_main: String
    let lock_freq_back: String
    let rx_symbol_back: String
    let mainback_switch: String
}

struct OduTransmitResponse: Codable {
    let code: String
    let tx_power: String
    let tx_max_power: String
    let tx_p2p_freq: String
    let tx_p2p_symbol: String
    let tx_p2p_modulation: String
    let tx_p2p_frame: String
    let p2p_network_type: String
    let tx_power_mesh: String
}

struct OduLocationResponse: Codable {
    let code: String
    let long_type: String
    let long_value: String
    let lat_type: String
    let lat_value: String
    let u8_location_id: String
}

struct FwdStatusResponse: Codable {
    let code: String
    let uptime: String
    let u8_fwd_is_lock: String
    let u32_current_srate: String
    let s32_current_power: String
    let u8_fwd_modcode: String
    let s32_fwd_snr: String
    let s32_fwd_snr_max: String
    let u32_current_freq: String
    let u32_current_ber: String
    let tx_snr: String
    let satellite_name_now: String
    let beamid_now: String
}

struct VsatStatusResponse: Codable {
    let code: String
    let rcst_version_type: String
    let x509_auth_status: String
    let zd_version: String
    let u32_timu_count: String
    let u32_timb_count: String
    let u32_down_unicast_ip_count: String
    let u32_down_mulcast_ip_count: String
    let u32_down_losskey_count: String
    let u32_down_fpga_sync_loss: String
    let u32_fpga_gse_count: String
    let u32_fpga_bbframe_count: String
    let rcst_current_status: String
    let u32_up_sig_rate: String
    let u32_up_trf_rate: String
    let u32_up_sig_power: String
    let u32_up_trf_power: String
    let u32_up_sig_modcod: String
    let u32_up_trf_modcod: String
    let u8_up_sig_snr: String
    let u8_up_trf_snr: String
    let u32_lb_send_count: String
    let u32_cb_send_count: String
    let u32_trf_send_count: String
    let u32_total_remained_packet_count: String
    let u32_fpga_receive_packet: String
    let u32_fpga_send_packet: String
}

// MARK: - 卫星数据采集器
public class SatelliteDataCollector {
    
    public static let shared = SatelliteDataCollector()
    private let baseURL = "https://192.168.0.8"
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
//        self.session = URLSession(configuration: configuration)
        
        self.session = URLSession(configuration: configuration, delegate: InsecureCertificateDelegate(), delegateQueue: nil)
        print("📡 SatelliteDataCollector 初始化完成")
    }
    
    // 采集所有卫星数据
    func collectAllData(completion: @escaping (SatelliteDeviceData?) -> Void) {
        var satelliteData = SatelliteDeviceData()
        let group = DispatchGroup()
        var hasError = false
        
        // 1. homestatus
        group.enter()
        getHomestatus { result in
            switch result {
            case .success(let data):
                satelliteData.rcstCurrentStatus = data.rcst_current_status ?? 0
                satelliteData.rfRxSnr = data.rf_rx_snr ?? 0
                satelliteData.rfTxSnr = data.rf_tx_snr ?? 0
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 2. sysTraffic
        group.enter()
        getSysTraffic { result in
            switch result {
            case .success(let data):
                satelliteData.rxBwAvg = data.receiveBandwidth
                satelliteData.txBwAvg = data.transmitBandwidth
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 3. 🔧 修复：先获取波束状态，成功后获取波束列表
        group.enter()
        waitForBeamStatus(timeout: 30) { [weak self] result in
            guard let self = self else {
                hasError = true
                group.leave()
                return
            }
            
            switch result {
            case .success:
                // 状态成功，获取波束列表
                self.getBeamList { beamResult in
                    switch beamResult {
                    case .success(let data):
                        var beamList: [BeamData] = []
                        for beamInfo in data.info {
                            var beamData = BeamData()
                            beamData.form(with: beamInfo)
                            beamList.append(beamData)
                        }
                        satelliteData.beamList = beamList
                        print("  ✅ 波束列表采集成功: \(beamList.count)个波束")
                    case .failure(let error):
                        print("  ❌ 波束列表采集失败: \(error)")
//                        hasError = true
                    }
                    group.leave()
                }
                
            case .failure(let error):
                print("  ❌ 波束状态等待失败: \(error)")
//                hasError = true
                group.leave()
            }
        }
        
        // 4. oduDivide
        group.enter()
        getOduDivide { result in
            switch result {
            case .success(let data):
                satelliteData.satelliteName = data.satellite_name_main
                satelliteData.antennaName = data.antenna_name_main
                satelliteData.rxFreq = data.rx_freq_main
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 5. oduTransmit
        group.enter()
        getOduTransmit { result in
            switch result {
            case .success(let data):
                satelliteData.txPower = data.tx_power
                satelliteData.txMaxPower = data.tx_max_power
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 6. oduLocation
        group.enter()
        getOduLocation { result in
            switch result {
            case .success(let data):
                satelliteData.longType = data.long_type
                satelliteData.longValue = Int((Double(data.long_value) ?? 0) * 100000)
                satelliteData.latType = data.lat_type
                satelliteData.latValue = Int((Double(data.lat_value) ?? 0) * 100000)
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 7. fwdStatus
        group.enter()
        getFwdStatus { result in
            switch result {
            case .success(let data):
                satelliteData.fwdIsLock = data.u8_fwd_is_lock
                satelliteData.fwdSrate = data.u32_current_srate
                satelliteData.fwdFreq = data.u32_current_freq
                satelliteData.fwdPower = data.s32_current_power
                satelliteData.fwdModcode = data.u8_fwd_modcode
                satelliteData.fwdSnr = data.s32_fwd_snr
                satelliteData.fwdBer = data.u32_current_ber
                satelliteData.fwdBeamId = data.beamid_now
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 8. vsatStatus
        group.enter()
        getVsatStatus { result in
            switch result {
            case .success(let data):
                satelliteData.authStatus = data.x509_auth_status
                satelliteData.upSigRate = data.u32_up_sig_rate
                satelliteData.upTrfRate = data.u32_up_trf_rate
                satelliteData.upSigPower = data.u32_up_sig_power
                satelliteData.upTrfPower = data.u32_up_trf_power
                satelliteData.upSigModcod = data.u32_up_sig_modcod
                satelliteData.upTrfModcod = data.u32_up_trf_modcod
                satelliteData.upSigSnr = data.u8_up_sig_snr
                satelliteData.upTrfSnr = data.u8_up_trf_snr
            case .failure:
                hasError = true
            }
            group.leave()
        }
        
        // 9. RcstTypeGet (新增终端类型)
        group.enter()
        getRcstType { result in
            switch result {
            case .success(let data):
                satelliteData.rcstXphType = data.rcst_xph_type ?? "0"
            case .failure:
                hasError = true
            }
            group.leave()
        }
                
        group.notify(queue: .main) {
            completion(hasError ? nil : satelliteData)
        }
    }
    
    // MARK: - 🔧 新增：等待波束状态直到成功或超时
    private func waitForBeamStatus(timeout: TimeInterval, completion: @escaping (Result<Void, Error>) -> Void) {
        let startTime = Date()
        _ = Int(timeout / 1.0) // 每秒检查一次
        var currentRetry = 0
        
        func checkStatus() {
            currentRetry += 1
            let elapsedTime = Date().timeIntervalSince(startTime)
            
            // 检查是否超时
            if elapsedTime > timeout {
                completion(.failure(NSError(domain: "波束状态查询超时", code: -1, userInfo: nil)))
                return
            }
            
            // 获取波束状态
            getBeamStatus { result in
                switch result {
                case .success(let response):
                    let status = response.status
                    print("  ⏳ 波束状态查询[\(currentRetry)]: \(status.rawValue) - \(elapsedTime.rounded())秒")
                    
                    if status.isQuerying {
                        // 还在查询中，继续等待
                        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                            checkStatus()
                        }
                    } else if status.isFailed {
                        // 状态失败，直接返回失败
                        completion(.failure(NSError(domain: "波束状态失败: \(status.rawValue)", code: -2, userInfo: nil)))
                    } else {
                        // 状态成功，返回成功
                        completion(.success(()))
                    }
                    
                case .failure(let error):
                    print("  ❌ 波束状态请求失败: \(error)")
                    // 请求失败，重试
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                        checkStatus()
                    }
                }
            }
        }
        
        // 开始第一次检查
        checkStatus()
    }
    
    // MARK: - 私有请求方法
    public func getHomestatus(completion: @escaping (Result<HomeStatusResponse, Error>) -> Void) {
        request("/action/homestatus", completion: completion)
    }
    
    public func getSysTraffic(completion: @escaping (Result<SysTrafficResponse, Error>) -> Void) {
        request("/action/sysTrafficGet", completion: completion)
    }
    
    private func getBeamStatus(completion: @escaping (Result<BeamSearchStatusResponse, Error>) -> Void) {
        request("/action/searchBeamStatusGet", completion: completion)
    }
    
    private func getBeamList(completion: @escaping (Result<BeamSearchResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/action/searchBeamListGet") else {
            completion(.failure(NSError(domain: "无效URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "pageNum=1".data(using: .utf8)
        
        let task = session.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "无数据", code: -2)))
                return
            }
            do {
                let result = try JSONDecoder().decode(BeamSearchResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    private func getOduDivide(completion: @escaping (Result<OduDivideResponse, Error>) -> Void) {
        request("/action/oduDivideGet", completion: completion)
    }
    
    private func getOduTransmit(completion: @escaping (Result<OduTransmitResponse, Error>) -> Void) {
        request("/action/oduTransmitGet", completion: completion)
    }
    
    private func getOduLocation(completion: @escaping (Result<OduLocationResponse, Error>) -> Void) {
        request("/action/oduLocationGet", completion: completion)
    }
    
    private func getFwdStatus(completion: @escaping (Result<FwdStatusResponse, Error>) -> Void) {
        request("/action/fwdStatusGet", completion: completion)
    }
    
    private func getVsatStatus(completion: @escaping (Result<VsatStatusResponse, Error>) -> Void) {
        request("/action/vsatStatusGetNew", completion: completion)
    }
    
    private func getRcstType(completion: @escaping (Result<RcstTypeResponse, Error>) -> Void) {
        request("/action/RcstTypeGet", completion: completion)
    }
    
    private func request<T: Decodable>(_ path: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(NSError(domain: "无效URL", code: -1)))
            return
        }
        
        let task = session.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "无数据", code: -2)))
                return
            }
            do {
                let result = try JSONDecoder().decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

public class InsecureCertificateDelegate: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        print("🔐 处理证书验证请求: \(challenge.protectionSpace.host)")
        
        // 只对192.168.0.8的证书验证做特殊处理
        if challenge.protectionSpace.host == "192.168.0.8" {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    // 接受该服务器的所有证书
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    print("✅ 接受自签名证书: 192.168.0.8")
                    return
                }
            }
        }
        
        // 其他请求使用默认处理
        completionHandler(.performDefaultHandling, nil)
    }
}

