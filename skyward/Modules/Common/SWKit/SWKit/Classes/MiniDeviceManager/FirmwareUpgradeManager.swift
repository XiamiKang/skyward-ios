//
//  FirmwareUpgradeManager.swift
//  test11
//
//  Created by yifan kang on 2025/11/13.
//

import Foundation
import CryptoKit

public protocol FirmwareUpgradeDelegate: AnyObject {
    func firmwareUpgradeProgress(_ progress: Int)
    func firmwareUpgradeCompleted(_ success: Bool, error: String?)
}

public class FirmwareUpgradeManager {
    
    // MARK: - 常量定义
    private enum Constants {
        static let FILE_CHUNK_SIZE: Int = 512      // 大包大小（和安卓一致）
        static let MTU_OVERHEAD: Int = 14          // 协议开销
        static let MAX_RETRIES: Int = 2            // 最大重试次数
        static let RETRY_DELAY: TimeInterval = 0.3 // 重试延迟
    }
    
    // MARK: - 属性
    private(set) var firmwareData: Data?
    private(set) var totalChunks: Int = 0
    private(set) var currentChunkIndex: Int = 0
    private(set) var version: String = ""
    private(set) var isUpgrading: Bool = false
    
    private var retryCount: Int = 0
    private var lastSendTime: Date?
    
    public weak var delegate: FirmwareUpgradeDelegate?
    
    // MARK: - 公共方法
    
    /// 准备固件升级
    public func prepareFirmware(version: String, firmwareData: Data) {
        self.version = version
        self.firmwareData = firmwareData
        self.totalChunks = Int(ceil(Double(firmwareData.count) / Double(Constants.FILE_CHUNK_SIZE)))
        self.currentChunkIndex = 0
        self.retryCount = 0
        self.isUpgrading = false
        
        print("✅ 固件准备完成")
        print("   版本: \(version)")
        print("   大小: \(firmwareData.count) 字节")
        print("   总包数: \(totalChunks)")
    }
    
    /// 开始升级
    public func startUpgrade() {
        guard let firmwareData = firmwareData else {
            delegate?.firmwareUpgradeCompleted(false, error: "固件数据为空")
            return
        }
        
        isUpgrading = true
        currentChunkIndex = 0
        retryCount = 0
        
        // 计算MD5（和安卓一致）
        let md5 = calculateMD5(firmwareData)
        print("📦 固件MD5: \(md5)")
        
        // 发送开始升级命令（通过BluetoothManager）
        BluetoothManager.shared.startFirmwareUpgrade(version: version, firmwareData: firmwareData)
        
        // 更新初始进度
        updateProgress(0)
    }
    
    /// 获取下一个数据块
    public func getNextChunk() -> (index: Int, data: Data)? {
        guard let firmwareData = firmwareData,
              currentChunkIndex < totalChunks else {
            return nil
        }
        
        let start = currentChunkIndex * Constants.FILE_CHUNK_SIZE
        let end = min(start + Constants.FILE_CHUNK_SIZE, firmwareData.count)
        let chunkData = firmwareData.subdata(in: start..<end)
        
        return (currentChunkIndex, chunkData)
    }
    
    /// 移动到下一个数据块
    public func moveToNextChunk() {
        currentChunkIndex += 1
        retryCount = 0
        
        if currentChunkIndex < totalChunks {
            // 更新进度
            let progress = Int((Double(currentChunkIndex) / Double(totalChunks)) * 90) + 10
            updateProgress(progress)
        } else {
            // 所有数据块发送完成
            updateProgress(100)
        }
    }
    
    /// 处理数据块发送失败
    public func handleChunkSendFailure() -> Bool {
        retryCount += 1
        
        if retryCount <= Constants.MAX_RETRIES {
            print("🔄 重试数据块 \(currentChunkIndex)，第 \(retryCount) 次重试")
            return true // 继续重试
        } else {
            print("❌ 数据块 \(currentChunkIndex) 发送失败，达到最大重试次数")
            isUpgrading = false
            delegate?.firmwareUpgradeCompleted(false, error: "数据传输失败")
            return false // 停止升级
        }
    }
    
    /// 完成升级
    public func completeUpgrade(success: Bool) {
        isUpgrading = false
        if success {
            print("🎉 固件升级完成")
        } else {
            print("❌ 固件升级失败")
        }
    }
    
    /// 重置升级状态
    public func reset() {
        firmwareData = nil
        totalChunks = 0
        currentChunkIndex = 0
        retryCount = 0
        isUpgrading = false
    }
    
    // MARK: - 私有方法
    
    private func updateProgress(_ progress: Int) {
        DispatchQueue.main.async {
            self.delegate?.firmwareUpgradeProgress(progress)
        }
    }
    
    private func calculateMD5(_ data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
