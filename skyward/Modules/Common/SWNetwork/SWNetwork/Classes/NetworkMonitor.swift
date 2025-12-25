//
//  NetworkMonitor.swift
//  Pods
//
//  Created by TXTS on 2025/12/19.
//


import Network

public class NetworkMonitor {
    public static let shared = NetworkMonitor()
    public let monitor: NWPathMonitor
    public let queue = DispatchQueue.global(qos: .background)
    
    public var isConnected: Bool = false
    public var isMonitoring: Bool = false
    
    public init() {
        self.monitor = NWPathMonitor()
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            self?.isConnected = isConnected
            print("网络状态变化: \(isConnected ? "有网络" : "无网络")")
        }
        
        monitor.start(queue: queue)
        isMonitoring = true
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }
    
    deinit {
        stopMonitoring()
    }
}
