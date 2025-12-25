//
//  Device.swift
//  
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024年 Longfor. All rights reserved.
//

import Foundation
import UIKit

public final class Device {
    
    private let deviceIdKey = "X-SA-DeviceID"

    private var keychain: Keychain!
    
    public var deviceID: String!

    required public init(group: String, service: String) {
        self.keychain = Keychain(service: service, group: group)
        deviceID = self.getDeviceID()
    }
    
    public static let defaults = Device(group: "sa-group", service: "sa-uuid")
    
    private func getDeviceID() -> String {
        if let id = self.keychain.string(forKey: deviceIdKey) {
            return id
        }
        
        let uuid = UUID().uuidString
        self.keychain.set(uuid, forKey: deviceIdKey)
        return uuid
    }

    @discardableResult
    public func removeDeviceID() -> Bool {
        return self.keychain.removeObject(forKey: deviceIdKey)
    }
   
    
    /// Returns whether the device is an iPhone (real or simulator)
    public static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Returns whether the device is an iPad (real or simulator)
    public static var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// The name identifying the device (e.g. "Dennis' iPhone").
    public static var name: String {
        return UIDevice.current.name
    }
    
    /// The name of the operating system running on the device represented by the receiver (e.g. "iOS" or "tvOS").
    public static var systemName: String {
        return UIDevice.current.systemName
    }
    
    /// The current version of the operating system (e.g. 8.4 or 9.2).
    public static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    /// The model of the device (e.g. "iPhone" or "iPod Touch").
    public static var model: String {
        return UIDevice.current.model
    }
    
    /// The model of the device as a localized string.
    public static var localizedModel: String {
        return UIDevice.current.localizedModel
    }
    
    /// True when a Guided Access session is currently active; otherwise, false.
    public static var isGuidedAccessSessionActive: Bool {
        return UIAccessibility.isGuidedAccessEnabled
    }
    
    /// The brightness level of the screen.
    public static var screenBrightness: Int {
        return Int(UIScreen.main.brightness * 100)
    }
    
    /// Gets the identifier from the system, such as "iPhone7,1".
    public static var identifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

}

// MARK: - Battery
extension Device {
    /**
     This enum describes the state of the battery.
     
     - Full:      The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
     - Charging:  The device is plugged into power and the battery is less than 100% charged.
     - Unplugged: The device is not plugged into power; the battery is discharging.
     */
    public enum BatteryState: CustomStringConvertible, Equatable {
        /// The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
        case full
        /// The device is plugged into power and the battery is less than 100% charged.
        /// The associated value is in percent (0-100).
        case charging(Int)
        /// The device is not plugged into power; the battery is discharging.
        /// The associated value is in percent (0-100).
        case unplugged(Int)
        
        fileprivate init() {
            let wasBatteryMonitoringEnabled = UIDevice.current.isBatteryMonitoringEnabled
            UIDevice.current.isBatteryMonitoringEnabled = true
            let batteryLevel = Int(round(UIDevice.current.batteryLevel * 100)) // round() is actually not needed anymore since -[batteryLevel] seems to always return a two-digit precision number
            // but maybe that changes in the future.
            switch UIDevice.current.batteryState {
            case .charging: self = .charging(batteryLevel)
            case .full: self = .full
            case .unplugged:self = .unplugged(batteryLevel)
            case .unknown: self = .full // Should never happen since `batteryMonitoring` is enabled.
            }
            UIDevice.current.isBatteryMonitoringEnabled = wasBatteryMonitoringEnabled
        }
        
        /// The user enabled Low Power mode
        public var lowPowerMode: Bool {
            if #available(iOS 9.0, *) {
                return ProcessInfo.processInfo.isLowPowerModeEnabled
            } else {
                return false
            }
        }
        
        /// Provides a textual representation of the battery state.
        /// Examples:
        /// ```
        /// Battery level: 90%, device is plugged in.
        /// Battery level: 100 % (Full), device is plugged in.
        /// Battery level: \(batteryLevel)%, device is unplugged.
        /// ```
        public var description: String {
            switch self {
            case .charging(let batteryLevel): return "Battery level: \(batteryLevel)%, device is plugged in."
            case .full: return "Battery level: 100 % (Full), device is plugged in."
            case .unplugged(let batteryLevel): return "Battery level: \(batteryLevel)%, device is unplugged."
            }
        }
        
    }
    
    /// The state of the battery
    public var batteryState: BatteryState {
        return BatteryState()
    }
    
    /// Battery level ranges from 0 (fully discharged) to 100 (100% charged).
    public var batteryLevel: Int {
        switch BatteryState() {
        case .charging(let value): return value
        case .full: return 100
        case .unplugged(let value): return value
        }
    }
    
}

// MARK: - Device.Batterystate: Comparable
extension Device.BatteryState: Comparable {
    /// Tells if two battery states are equal.
    ///
    /// - parameter lhs: A battery state.
    /// - parameter rhs: Another battery state.
    ///
    /// - returns: `true` iff they are equal, otherwise `false`
    public static func == (lhs: Device.BatteryState, rhs: Device.BatteryState) -> Bool {
        return lhs.description == rhs.description
    }
    
    /// Compares two battery states.
    ///
    /// - parameter lhs: A battery state.
    /// - parameter rhs: Another battery state.
    ///
    /// - returns: `true` if rhs is `.Full`, `false` when lhs is `.Full` otherwise their battery level is compared.
    public static func < (lhs: Device.BatteryState, rhs: Device.BatteryState) -> Bool {
        switch (lhs, rhs) {
        case (.full, _): return false // return false (even if both are `.Full` -> they are equal)
        case (_, .full): return true // lhs is *not* `.Full`, rhs is
        case (.charging(let lhsLevel), .charging(let rhsLevel)): return lhsLevel < rhsLevel
        case (.charging(let lhsLevel), .unplugged(let rhsLevel)): return lhsLevel < rhsLevel
        case (.unplugged(let lhsLevel), .charging(let rhsLevel)): return lhsLevel < rhsLevel
        case (.unplugged(let lhsLevel), .unplugged(let rhsLevel)): return lhsLevel < rhsLevel
        default: return false // compiler won't compile without it, though it cannot happen
        }
    }
}


// MARK: - Orientation
extension Device {
    public static var orientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }
}

// MARK: - DiskSpace
@available(iOS 11.0, *)
extension Device {
    
    /// Return the root url
    ///
    /// - returns: the "/" url
    private static var rootURL = {
        return URL(fileURLWithPath: "/")
    }()
    
    /// The volume’s total capacity in bytes.
    public static var volumeTotalCapacity: Int? {
        do {
            let values = try Device.rootURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            return values.volumeTotalCapacity
        } catch {
            return nil
        }
    }
    
    /// The volume’s available capacity in bytes.
    public static var volumeAvailableCapacity: Int? {
        do {
            let values = try rootURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return values.volumeAvailableCapacity
        } catch {
            return nil
        }
    }
    
    /// The volume’s available capacity in bytes for storing important resources.
    public static var volumeAvailableCapacityForImportantUsage: Int64? {
        do {
            let values = try rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage
        } catch {
            return nil
        }
    }
    
    /// The volume’s available capacity in bytes for storing nonessential resources.
    public static var volumeAvailableCapacityForOpportunisticUsage: Int64? { //swiftlint:disable:this identifier_name
        do {
            let values = try rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey])
            return values.volumeAvailableCapacityForOpportunisticUsage
        } catch {
            return nil
        }
    }
    
    /// All volumes capacity information in bytes.
    public static var volumes: [URLResourceKey: Int64]? {
        do {
            let values = try rootURL.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForOpportunisticUsageKey,
                .volumeTotalCapacityKey
                ])
            return values.allValues.mapValues {
                if let int = $0 as? Int64 {
                    return int
                }
                if let int = $0 as? Int {
                    return Int64(int)
                }
                return 0
            }
        } catch {
            return nil
        }
    }
    
}

// MARK: - JailBreak
extension Device {
    
    public func isJailBreak() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #endif
        // Check 1 : existence of files that are common for jailbroken devices
        if FileManager.default.fileExists(atPath: "/Applications/Cydia.app")
            || FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib")
            || FileManager.default.fileExists(atPath: "/bin/bash")
            || FileManager.default.fileExists(atPath: "/usr/sbin/sshd")
            || FileManager.default.fileExists(atPath: "/etc/apt")
            || FileManager.default.fileExists(atPath: "/private/var/lib/apt/")
            || UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!) {
            return true
        }
        // Check 2 : Reading and writing in system directories (sandbox violation)
        let stringToWrite = "Jailbreak Test"
        do {
            try stringToWrite.write(toFile: "/private/JailbreakTest.txt", atomically: true, encoding: String.Encoding.utf8)
            // Device is jailbroken
            return true
        } catch {
            return false
        }
    }
    
    public func isUsedProxy() -> Bool {
        guard let proxy = CFNetworkCopySystemProxySettings()?.takeUnretainedValue() else { return false }
        guard let dict = proxy as? [String: Any] else { return false }
        guard let HTTPProxy = dict["HTTPProxy"] as? String else { return false }
        return HTTPProxy.count > 0
    }
    
}
