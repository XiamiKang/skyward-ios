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
    case sos = "SOS"
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
        
        guard UserManager.shared.userInfo?.isSetEmergency == true else {
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
                            UIWindow.topWindow?.sw_showSuccessToast("发送成功")
                        }
                    case .failure(let error):
                        UIWindow.topWindow?.sw_showWarningToast("发送失败: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let tips = type == .sos ? "当前无网络连接，通过Mini设备发送SOS?" : "当前无网络连接，通过Mini设备上报平安？"
            SWAlertView.showAlert(title: nil, message: tips) {
                if let _ = BluetoothManager.shared.connectedPeripheral {
                    var alarmData = Data()
                    if type == .sos {
                        alarmData.append(0x00) // SOS报警
                    } else {
                        alarmData.append(0x01) // 报平安
                    }
                    BluetoothManager.shared.sendCommand(.appTriggerAlarm, messageContent: alarmData)
                }else {
                    UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
                }
            }
        }
    }
}

enum ReportAPI {
    case userReport([String : Any])
}

extension ReportAPI: NetworkAPI {
    
    var path: String {
        switch self {
        case .userReport:
            return "/txts-user-center-app/api/v1/user-reports"
        }
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Moya.Task {
        switch self {
        case .userReport(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
}
