//
//  SOSManager.swift
//  Pods
//
//  Created by TXTS on 2026/3/22.
//


import UIKit
import SWNetwork

public extension Notification.Name {
    static let SOSStateDidOpen = Notification.Name("SOSStateDidOpen")
    static let SOSStateDidClose = Notification.Name("SOSStateDidClose")
    static let SOSReportFrequencyDidChange = Notification.Name("SOSReportFrequencyDidChange")
}


public class SOSManager {
    
    public static let shared = SOSManager()
    
    private let sosStateKey = "UserSOSState"
    private let sosReportFrequencyKey = "UserSOSReportFrequency"
    private var emergencyView: EmergencyView?
    private var vibrationTimer: Timer?
    private var reportTimer: Timer?  // 定时上报定时器
    private var isShowing = false
    
    // 默认上报频率为3分钟（180秒）
    private let defaultReportFrequency: Int = 180
    
    private init() {}
    
    /// 开启SOS状态
    public func openSOSState() {
        UserDefaults.standard.setValue(true, forKey: sosStateKey)
        UserDefaults.standard.synchronize()
        
        if checkUserSOSState() {
            showSOSIndicator()
            startAutoReport()  // 开启自动上报
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .SOSStateDidOpen, object: nil)
            }
        }
    }
    
    /// 检查SOS状态
    public func checkUserSOSState() -> Bool {
        return UserDefaults.standard.bool(forKey: sosStateKey)
    }
    
    /// 关闭SOS状态
    public func closeSOSState() {
        UserDefaults.standard.setValue(false, forKey: sosStateKey)
        UserDefaults.standard.synchronize()
        
        hideSOSIndicator()
        stopAutoReport()  // 停止自动上报
        
        // 发送关闭通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SOSStateDidClose, object: nil)
        }
    }
    
    /// 显示SOS指示器（红色闪烁边框）
    public func showSOSIndicator() {
        DispatchQueue.main.async {
            // 避免重复添加
            guard !self.isShowing else { return }
            
            // 获取当前活动的window
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                return
            }
            
            // 创建EmergencyView
            let emergencyView = EmergencyView(frame: window.bounds)
            emergencyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(emergencyView)
            
            // 开始闪烁动画
            emergencyView.startFlashing()
            
            // 保存引用
            self.emergencyView = emergencyView
            self.isShowing = true
        }
    }
    
    /// 隐藏SOS指示器
    public func hideSOSIndicator() {
        DispatchQueue.main.async {
            self.vibrationTimer?.invalidate()
            self.vibrationTimer = nil
            
            self.emergencyView?.stopFlashing()
            self.emergencyView?.removeFromSuperview()
            self.emergencyView = nil
            self.isShowing = false
        }
    }
    
    // MARK: - SOS上报频率管理
    
    /// 设置SOS上报频率（秒）
    public func setSOSReportFrequency(_ frequency: Int) {
        let validFrequency = max(60, frequency) // 最小60秒
        UserDefaults.standard.setValue(validFrequency, forKey: sosReportFrequencyKey)
        UserDefaults.standard.synchronize()
        
        // 如果SOS状态是开启的，重新启动定时器以使用新的频率
        if checkUserSOSState() {
            restartAutoReport()
        }
        
        // 发送频率变更通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SOSReportFrequencyDidChange, object: validFrequency)
        }
    }
    
    /// 获取SOS上报频率（秒）
    public func getSOSReportFrequency() -> Int {
        let frequency = UserDefaults.standard.integer(forKey: sosReportFrequencyKey)
        if frequency <= 0 {
            return defaultReportFrequency
        }
        return frequency
    }
    
    /// 获取SOS上报频率（格式化字符串）
    public func getSOSReportFrequencyString() -> String {
        let frequency = getSOSReportFrequency()
        return SOSReportHelper.reportString(from: frequency)
    }
    
    /// 设置SOS上报频率（通过字符串）
    public func setSOSReportFrequency(with string: String) {
        let frequency = SOSReportHelper.reportValue(from: string)
        setSOSReportFrequency(frequency)
    }
    
    /// 重置上报频率为默认值
    public func resetSOSReportFrequency() {
        setSOSReportFrequency(defaultReportFrequency)
    }
    
    // MARK: - 自动上报管理
    
    /// 开始自动上报
    private func startAutoReport() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 停止已有的定时器
            self.stopAutoReport()
            
            let frequency = self.getSOSReportFrequency()
            print("开始SOS自动上报，频率：\(frequency)秒")
            
            // 立即上报一次
            self.performReport()
            
            // 设置定时器
            self.reportTimer = Timer.scheduledTimer(
                timeInterval: TimeInterval(frequency),
                target: self,
                selector: #selector(self.performReport),
                userInfo: nil,
                repeats: true
            )
            
            // 添加到RunLoop确保定时器在滚动时也能运行
            RunLoop.current.add(self.reportTimer!, forMode: .common)
        }
    }
    
    /// 停止自动上报
    private func stopAutoReport() {
        reportTimer?.invalidate()
        reportTimer = nil
        print("停止SOS自动上报")
    }
    
    /// 重启自动上报（用于频率变更后）
    private func restartAutoReport() {
        if checkUserSOSState() {
            startAutoReport()
        }
    }
    
    /// 执行上报
    @objc private func performReport() {
        // 检查SOS状态是否还在开启中
        guard checkUserSOSState() else {
            // 如果SOS已关闭，停止自动上报
            stopAutoReport()
            return
        }
        
        print("执行SOS自动上报，时间：\(Date())")
        
        reportSOSState()
    }
    
    private func reportSOSState() {
        LocationManager().getCurrentLocation { location, error in
            guard let latitude = location?.coordinate.latitude, let longitude = location?.coordinate.longitude else {
                UIWindow.topWindow?.sw_hideLoading()
                UIWindow.topWindow?.sw_showWarningToast("获取定位失败: 定位信息无效")
                return
            }
            var params = [String : Any]()
            params["type"] = "SOS"
            params["latitude"] = String(latitude)
            params["longitude"] = String(longitude)
            params["userId"] = UserManager.shared.userId
            let dateFormatter = DateFormatter.fullPretty
            let localTimeString = dateFormatter.string(from: Date())
            params["reportsTime"] = localTimeString
            NetworkProvider<ReportAPI>().request(.userReport(params)) { result in
                UIWindow.topWindow?.sw_hideLoading()
            }
        }
    }
}


// SOS上报频率工具类
public class SOSReportHelper {
    public static func reportString(from value: Int) -> String {
        switch value {
        case 180: return "3分钟"
        case 900: return "15分钟"
        case 1800: return "30分钟"
        case 3600: return "1小时"
        default:
            let minutes = value / 60
            if minutes >= 60 {
                let hours = minutes / 60
                return hours >= 24 ? "\(hours/24)天" : "\(hours)小时"
            }
            return "\(minutes)分钟"
        }
    }
    
    public static func reportValue(from string: String) -> Int {
        switch string {
        case "3分钟": return 180
        case "15分钟": return 900
        case "30分钟": return 1800
        case "1小时": return 3600
        default:
            // 处理其他格式，如 "5分钟"、"2小时" 等
            if string.contains("分钟") {
                let minutesStr = string.replacingOccurrences(of: "分钟", with: "")
                if let minutes = Int(minutesStr) {
                    return minutes * 60
                }
            } else if string.contains("小时") {
                let hoursStr = string.replacingOccurrences(of: "小时", with: "")
                if let hours = Int(hoursStr) {
                    return hours * 3600
                }
            }
            return 180 // 默认返回3分钟
        }
    }
    
    public static var allOptions: [String] {
        return ["3分钟", "15分钟", "30分钟", "1小时"]
    }
}
