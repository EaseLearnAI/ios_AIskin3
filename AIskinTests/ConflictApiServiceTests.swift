//
//  ConflictApiServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin

/// ConflictApiService集成测试
/// 测试产品冲突检测相关的API服务与后端连接
class ConflictApiServiceTests: XCTestCase {
    
    var conflictApiService: ConflictApiService!
    var productApiService: ProductApiService!
    var userApiService: UserApiService!
    var testToken: String!
    var productIds: [String] = []
    
    override func setUp() {
        super.setUp()
        conflictApiService = ConflictApiService.shared
        productApiService = ProductApiService.shared
        userApiService = UserApiService.shared
        
        // 创建测试用户并获取token
        Task {
            await setupTestUser()
        }
        
        print("✅ ConflictApiService测试环境已设置")
    }
    
    override func tearDown() {
        conflictApiService = nil
        productApiService = nil
        userApiService = nil
        testToken = nil
        productIds = []
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
        print("✅ ConflictApiService测试环境已清理")
    }
    
    /// 设置测试用户和产品
    private func setupTestUser() async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email = "conflict_test_\(timestamp)@example.com"
        let password = "TestPassword123"
        let name = "冲突测试用户_\(timestamp)"
        
        do {
            let (token, _) = try await userApiService.register(
                name: name,
                email: email,
                password: password
            )
            testToken = token
            UserDefaults.standard.set(token, forKey: "authToken")
            
            // 创建测试产品
            let product1 = try await productApiService.createProduct(name: "测试产品1_\(timestamp)")
            let product2 = try await productApiService.createProduct(name: "测试产品2_\(timestamp)")
            
            // 获取产品ID
            productIds = [product1.id, product2.id]
            
            print("✅ 测试用户和产品已创建")
            print("   - 产品1 ID: \(product1.id)")
            print("   - 产品2 ID: \(product2.id)")
        } catch {
            print("⚠️ 无法创建测试数据: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 冲突分析测试
    
    /// 测试分析产品冲突
    func testAnalyzeConflict() async {
        // 等待数据设置完成
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        guard !productIds.isEmpty else {
            XCTFail("测试产品未创建")
            return
        }
        
        let expectation = XCTestExpectation(description: "分析产品冲突测试")
        
        // Act: 分析冲突
        do {
            let result = try await conflictApiService.analyzeConflict(productIds: productIds)
            
            // Assert: 验证分析结果
            XCTAssertNotNil(result, "应该返回分析结果")
            
            print("✅ 产品冲突分析成功")
            print("   - 冲突记录ID: \(result.conflictId ?? "未知")")
            print("   - 发现冲突数: \(result.conflicts?.count ?? 0)")
            print("   - 安全组合数: \(result.safeCombo?.count ?? 0)")
            
            if let conflicts = result.conflicts {
                for conflict in conflicts {
                    print("     • 冲突成分: \(conflict.components.joined(separator: ", "))")
                    print("       严重程度: \(conflict.severity)")
                }
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("产品冲突分析失败: \(error.localizedDescription)")
            print("❌ 冲突分析错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 30.0) // AI分析可能需要时间
    }
    
    /// 测试获取用户所有冲突记录
    func testGetUserConflicts() async {
        // 等待数据设置完成
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let expectation = XCTestExpectation(description: "获取用户冲突记录测试")
        
        // Act: 获取冲突记录
        do {
            let conflicts = try await conflictApiService.getUserConflicts()
            
            // Assert: 验证结果
            XCTAssertNotNil(conflicts, "应该返回冲突记录列表")
            print("✅ 获取用户冲突记录成功")
            print("   - 记录数量: \(conflicts.count)")
            
            for conflict in conflicts {
                print("     • 记录ID: \(conflict.id ?? "未知")")
                print("       冲突数: \(conflict.conflicts?.count ?? 0)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取冲突记录失败: \(error.localizedDescription)")
            print("❌ 获取冲突记录错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取冲突详情
    func testGetConflictDetail() async {
        // 等待数据设置完成
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Arrange: 先进行一次冲突分析
        guard !productIds.isEmpty else {
            XCTFail("测试产品未创建")
            return
        }
        
        var conflictId: String?
        do {
            let result = try await conflictApiService.analyzeConflict(productIds: productIds)
            conflictId = result.conflictId
        } catch {
            XCTFail("创建冲突分析失败: \(error.localizedDescription)")
            return
        }
        
        guard let conflictId = conflictId else {
            XCTFail("未获取到冲突记录ID")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取冲突详情测试")
        
        // Act: 获取冲突详情
        do {
            let conflict = try await conflictApiService.getConflict(conflictId: conflictId)
            
            // Assert: 验证结果
            XCTAssertEqual(conflict.id, conflictId, "冲突记录ID应该匹配")
            XCTAssertNotNil(conflict.conflicts, "应该有冲突信息")
            
            print("✅ 获取冲突详情成功")
            print("   - 冲突记录ID: \(conflict.id ?? "未知")")
            print("   - 涉及产品数: \(conflict.products?.count ?? 0)")
            print("   - 冲突数量: \(conflict.conflicts?.count ?? 0)")
            
            expectation.fulfill()
        } catch {
            XCTFail("获取冲突详情失败: \(error.localizedDescription)")
            print("❌ 获取冲突详情错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}
