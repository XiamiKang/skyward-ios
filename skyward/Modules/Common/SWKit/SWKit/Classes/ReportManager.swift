//
//  ReportManager.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/28.
//

import SWNetwork
import Moya
import Alamofire
import CoreLocation
import TXKit

public enum ReportType: String {
    case safety = "SAFE"
    case openSOS = "SOS"
    case closeSOS = "CloseSOS"
}

public struct ReportManager {
    
    /// 自定义错误类型
    private enum ReportError: Error {
        case locationFailed(String)
        
        var localizedDescription: String {
            switch self {
            case .locationFailed(let message):
                return "获取定位失败: \(message)"
            }
        }
    }
    
    public static func report(_ type: ReportType) {
        let hasNetwork = NetworkMonitor.shared.isConnected
        
        // SOS上报时，如果是自动定时上报，跳过紧急联系人检查（因为开启SOS时已经检查过了）
        var shouldCheckEmergency = true
        if type == .openSOS {
            // 检查是否是从定时器触发的上报
            // 可以通过调用栈或其他方式判断，这里简单判断SOS状态是否已开启
            if SOSManager.shared.checkUserSOSState() {
                shouldCheckEmergency = false
            }
        }
        
        guard shouldCheckEmergency == false || UserManager.shared.userInfo?.isSetEmergency == true else {
            let emergencyContactView = EmergencyContactPopupView()
            SWAlertView.showCustomAlert(title: "请绑定紧急联系人", customView: emergencyContactView, confirmTitle: "保存", cancelTitle: "取消", confirmHandler: {
                if let name = emergencyContactView.nickname, let phoneNumber = emergencyContactView.phoneNumber {
                    if hasNetwork {
                        UIWindow.topWindow?.sw_showLoading()
                        UserManager.shared.bindEmergencyContact(name: name, phone: phoneNumber) { success in
                            UIWindow.topWindow?.sw_hideLoading()
                            if success {
                                report(type)
                            }
                        }
                    } else {
                        SWAlertView.showAlert(title: nil, message: "当前无网络连接，通过Mini设备绑定紧急联系人？") {
                            if let _ = BluetoothManager.shared.connectedPeripheral {
                                if let data = MessageGenerator.generateBindEmergencyContact(userId: UserManager.shared.userId,
                                                                                            phone: phoneNumber,
                                                                                            name: name) {
                                    BluetoothManager.shared.sendAppCustomData(data)
                                }
                            } else {
                                UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
                            }
                        }
                    }
                }
            })
            return
        }
        
        if hasNetwork {
            UIWindow.topWindow?.sw_showLoading()
            if type == .closeSOS {
                NetworkProvider<ReportAPI>().request(.closeUserSOS) { result in
                    switch result {
                    case .success(let rsp):
                        UIWindow.topWindow?.sw_hideLoading()
                        if rsp.statusCode == 200 {
                            UIWindow.topWindow?.sw_showSuccessToast("关闭SOS成功")
                            SOSManager.shared.closeSOSState()
                        }
                    case .failure(let error):
                        UIWindow.topWindow?.sw_hideLoading()
                        UIWindow.topWindow?.sw_showWarningToast("发送失败: \(error.localizedDescription)")
                    }
                }
                BluetoothManager.shared.closeSOS()
            }else {
                LocationManager().getCurrentLocation { location, error in
                    guard let latitude = location?.coordinate.latitude, let longitude = location?.coordinate.longitude else {
                        UIWindow.topWindow?.sw_hideLoading()
                        UIWindow.topWindow?.sw_showWarningToast("获取定位失败: 定位信息无效")
                        return
                    }
                    var params = [String : Any]()
                    params["type"] = type.rawValue
                    params["latitude"] = String(latitude)
                    params["longitude"] = String(longitude)
                    params["userId"] = UserManager.shared.userId
                    let dateFormatter = DateFormatter.fullPretty
                    let localTimeString = dateFormatter.string(from: Date())
                    params["reportsTime"] = localTimeString
                    NetworkProvider<ReportAPI>().request(.userReport(params)) { result in
                        UIWindow.topWindow?.sw_hideLoading()
                        switch result {
                        case .success(let rsp):
                            if rsp.statusCode == 200 {
                                // 只在非自动上报时显示成功提示
                                if shouldCheckEmergency {
                                    UIWindow.topWindow?.sw_showSuccessToast("发送成功")
                                }
                                if type == .openSOS {
                                    SOSManager.shared.openSOSState()
                                }
                            }
                        case .failure(let error):
                            UIWindow.topWindow?.sw_showWarningToast("发送失败: \(error.localizedDescription)")
                        }
                    }
                }
                if type == .openSOS {
                    var alarmData = Data()
                    alarmData.append(0x00) // SOS报警
                    BluetoothManager.shared.sendCommand(.appTriggerAlarm, messageContent: alarmData)
                }
            }
        } else {
            var tips = ""
            switch type {
            case .safety:
                tips = "当前无网络连接，通过Mini设备上报平安？"
            case .openSOS:
                tips = "当前无网络连接，通过Mini设备打开SOS?"
            case .closeSOS:
                tips = "当前无网络连接，通过Mini设备关闭SOS?"
            }
            SWAlertView.showAlert(title: nil, message: tips) {
                if let _ = BluetoothManager.shared.connectedPeripheral {
                    if type == .closeSOS {
                        BluetoothManager.shared.closeSOS()
                        return
                    }
                    var alarmData = Data()
                    if type == .openSOS {
                        alarmData.append(0x00) // SOS报警
                    } else if type == .safety {
                        alarmData.append(0x01) // 报平安
                    }
                    BluetoothManager.shared.sendCommand(.appTriggerAlarm, messageContent: alarmData)
                }else {
                    UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
                }
            } cancelHandler: {
                if type == .openSOS {
                    SOSManager.shared.hideSOSIndicator()
                }
                if type == .closeSOS {
                    SOSManager.shared.showSOSIndicator()
                }
            }
        }
    }
}


enum ReportAPI {
    case userReport([String : Any])
    case closeUserSOS
}

extension ReportAPI: NetworkAPI {
    
    var path: String {
        switch self {
        case .userReport:
            return "/txts-user-center-app/api/v1/user-reports"
        case .closeUserSOS:
            return "/txts-user-center-app/api/v1/my-center/close/urgentState"
        }
        
    }
    
    var method: Moya.Method {
        switch self {
        case .userReport:
            return .post
        case .closeUserSOS:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .userReport(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .closeUserSOS:
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}
