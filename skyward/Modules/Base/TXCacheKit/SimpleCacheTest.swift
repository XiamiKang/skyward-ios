import Foundation

// 简化版本的 SWCache 测试，不依赖 UIKit
class SimpleCacheTest {
    
    static func runTest() {
        print("=== SWCache 功能测试 ===")
        
        do {
            // 创建测试用的缓存实例
            let cache = try createTestCache()
            print("✅ 缓存实例创建成功")
            
            // 测试数据存储和获取
            testBasicOperations(cache: cache)
            
        } catch {
            print("❌ 测试失败: \(error)")
        }
    }
    
    static func createTestCache() throws -> SWCache {
        // 创建临时目录用于测试
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TestCache")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        return try SWCache(name: "TestCache", directoryURL: tempDir)
    }
    
    static func testBasicOperations(cache: SWCache) {
        let testKey = "test_key"
        let testData = "Hello, SWCache! 测试数据".data(using: .utf8)!
        
        print("\n--- 存储测试 ---")
        
        // 存储数据
        cache.setValue(testData, forKey: testKey, toDisk: true) { result in
            print("存储结果:")
            print("内存: \(result.memoryCacheResult)")
            print("磁盘: \(result.diskCacheResult)")
            
            // 立即测试获取
            testRetrieval(cache: cache, key: testKey, expectedData: testData)
        }
    }
    
    static func testRetrieval(cache: SWCache, key: String, expectedData: Data) {
        print("\n--- 获取测试 ---")
        
        // 从内存获取
        if let memoryData = cache.valueInMemory(forKey: key) {
            print("内存数据: \(String(data: memoryData, encoding: .utf8) ?? "无法解码")")
            print(memoryData == expectedData ? "✅ 内存数据正确" : "❌ 内存数据错误")
        } else {
            print("⚠️ 内存中无数据")
        }
        
        // 从磁盘获取
        cache.valueInDisk(forKey: key) { result in
            switch result {
            case .success(let data):
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    print("磁盘数据: \(string)")
                    print(data == expectedData ? "✅ 磁盘数据正确" : "❌ 磁盘数据错误")
                } else {
                    print("⚠️ 磁盘中无数据")
                }
            case .failure(let error):
                print("❌ 磁盘获取失败: \(error)")
            }
            
            testCleanup(cache: cache, key: key)
        }
    }
    
    static func testCleanup(cache: SWCache, key: String) {
        print("\n--- 清理测试 ---")
        
        // 清理内存
        cache.clearMemoryCache()
        print("✅ 内存已清理")
        
        // 验证内存清理
        if cache.valueInMemory(forKey: key) == nil {
            print("✅ 内存数据已清除")
        } else {
            print("❌ 内存数据仍存在")
        }
        
        // 清理磁盘
        cache.cleanDiskCache {
            print("✅ 磁盘已清理")
            
            // 验证磁盘清理
            cache.valueInDisk(forKey: key) { result in
                switch result {
                case .success(let data):
                    print(data == nil ? "✅ 磁盘数据已清除" : "❌ 磁盘数据仍存在")
                case .failure:
                    print("✅ 磁盘数据已清除（获取失败表示不存在）")
                }
                
                print("\n=== 测试完成 ===")
            }
        }
    }
}

// 运行测试
SimpleCacheTest.runTest()