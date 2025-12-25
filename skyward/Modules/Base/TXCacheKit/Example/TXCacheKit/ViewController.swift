//
//  ViewController.swift
//  TXCacheKit
//
//  Created by 赵波 on 11/14/2025.
//  Copyright (c) 2025 赵波. All rights reserved.
//

import UIKit
import TXCacheKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        
        // 测试 SWCache 的存储和获取数据功能 - 调用10次
//        for i in 1...10 {
//            print("\n🔄 第 \(i) 次测试开始")
            testSWCacheStorage()
//        }
    }
    
    func testSWCacheStorage() {
        
        do {
            // 创建 SWCache 实例 - 使用直接导入的方式
            let cache = try SWCache(dirName: CacheModuleName.message.module)
            print("✅ SWCache 实例创建成功")
            
            // 测试数据 - 每次使用不同的key和数据
            let testKey = "test_key_123"
            let testData = "Hello, SWCache! 这是测试数据HAHHAH".data(using: .utf8)!
            
            print("\n--- 存储数据测试 ---")
            
            // 存储数据到内存和磁盘
            cache.setValue(testData, forKey: testKey, toDisk: true) { result in
                switch result.memoryCacheResult {
                case .success:
                    print("✅ 内存存储成功")
                case .failure(let error):
                    print("❌ 内存存储失败: \(error)")
                }
                
                switch result.diskCacheResult {
                case .success:
                    print("✅ 磁盘存储成功")
                case .failure(let error):
                    print("❌ 磁盘存储失败: \(error)")
                }
                
                // 存储完成后立即测试获取
                self.testRetrieveData(cache: cache, key: testKey, expectedData: testData)
            }
            
        } catch {
            print("❌ SWCache 创建失败: \(error)")
            print("错误详情: \(error.localizedDescription)")
        }
    }
    
    func testRetrieveData(cache: SWCache, key: String, expectedData: Data) {
        print("\n--- 获取数据测试 ---")
        print("📋 测试参数: key='\(key)', expectedData长度=\(expectedData.count) bytes")
        print("📊 期望数据内容: \(String(data: expectedData, encoding: .utf8) ?? "无法解码为字符串")")
        
        // 测试从内存获取
        if let memoryData = cache.valueInMemory(forKey: key) {
            print("💾 内存中获取到的原始数据: \(String(data: memoryData, encoding: .utf8) ?? "无法解码为字符串") (长度: \(memoryData.count) bytes)")
            if memoryData == expectedData {
                print("✅ 内存数据获取成功，数据正确")
            } else {
                print("❌ 内存数据获取成功，但数据不匹配")
                print("🔍 内存数据与期望数据差异: 内存[\(memoryData)], 期望[\(expectedData)]")
            }
        } else {
            print("⚠️ 内存中未找到数据")
        }
        
        // 测试通过 value 方法获取（会优先检查内存，然后磁盘）
        cache.value(forKey: key) { result in
            switch result {
            case .success(let cacheResult):
                switch cacheResult {
                case .memory(let data):
                    print("💾 通过 value() 方法从内存获取的原始数据: \(String(data: data, encoding: .utf8) ?? "无法解码为字符串") (长度: \(data.count) bytes)")
                    if data == expectedData {
                        print("✅ 通过 value() 方法从内存获取数据成功，数据正确")
                    } else {
                        print("❌ 通过 value() 方法从内存获取数据成功，但数据不匹配")
                        print("🔍 获取数据与期望数据差异: 获取[\(data)], 期望[\(expectedData)]")
                    }
                case .disk(let data):
                    print("💽 通过 value() 方法从磁盘获取的原始数据: \(String(data: data, encoding: .utf8) ?? "无法解码为字符串") (长度: \(data.count) bytes)")
                    if data == expectedData {
                        print("✅ 通过 value() 方法从磁盘获取数据成功，数据正确")
                    } else {
                        print("❌ 通过 value() 方法从磁盘获取数据成功，但数据不匹配")
                        print("🔍 获取数据与期望数据差异: 获取[\(data)], 期望[\(expectedData)]")
                    }
                case .none:
                    print("⚠️ 通过 value() 方法未找到数据")
                }
            case .failure(let error):
                print("❌ 通过 value() 方法获取数据失败: \(error)")
            }
            
            // 测试从磁盘获取
            self.testDiskRetrieve(cache: cache, key: key, expectedData: expectedData)
        }
    }
    
    func testDiskRetrieve(cache: SWCache, key: String, expectedData: Data) {
        print("\n--- 磁盘数据获取测试 ---")
        print("📋 磁盘测试参数: key='\(key)', expectedData长度=\(expectedData.count) bytes")
        print("📊 期望数据内容: \(String(data: expectedData, encoding: .utf8) ?? "无法解码为字符串")")
        
        cache.valueInDisk(forKey: key) { result in
            switch result {
            case .success(let data):
                if let data = data {
                    print("💽 磁盘获取到的原始数据: \(String(data: data, encoding: .utf8) ?? "无法解码为字符串") (长度: \(data.count) bytes)")
                    if data == expectedData {
                        print("✅ 磁盘数据获取成功，数据正确")
                    } else {
                        print("❌ 磁盘数据获取成功，但数据不匹配")
                        print("🔍 磁盘数据与期望数据差异:")
                        print("   磁盘数据: [\(data)]")
                        print("   期望数据: [\(expectedData)]")
                        print("   磁盘数据(base64): [\(data.base64EncodedString())]")
                        print("   期望数据(base64): [\(expectedData.base64EncodedString())]")
                    }
                } else {
                    print("⚠️ 磁盘中未找到数据 (返回nil)")
                }
            case .failure(let error):
                print("❌ 磁盘数据获取失败: \(error)")
                print("🔍 错误详情: \(String(describing: error))")
            }
        }
    }
    
    func testCacheCleaning(cache: SWCache, key: String) {
        print("\n--- 缓存清理测试 (最终测试) ---")
        
        // 清理内存缓存
        cache.clearMemoryCache()
        print("✅ 内存缓存已清理")
        
        // 验证内存中是否还有数据
        if cache.valueInMemory(forKey: key) == nil {
            print("✅ 内存数据已正确清理")
        } else {
            print("❌ 内存数据清理失败")
        }
        
        // 清理磁盘缓存
        cache.cleanDiskCache {
            print("✅ 磁盘缓存已清理")
            
            // 验证磁盘中是否还有数据
            cache.valueInDisk(forKey: key) { result in
                switch result {
                case .success(let data):
                    if data == nil {
                        print("✅ 磁盘数据已正确清理")
                    } else {
                        print("❌ 磁盘数据清理失败")
                    }
                case .failure:
                    print("✅ 磁盘数据已正确清理（返回失败表示数据不存在）")
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("⚠️ 收到内存警告，内存缓存将被自动清理")
    }
}

