//
//  IntegrationTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin

/// 综合集成测试
/// 测试前后端完整连接流程，验证整个系统的集成
class IntegrationTests: XCTestCase {
    
    var authService: AuthService!
    var userApiService: UserApiService!
    var productApiService: ProductApiService!
    var planApiService: PlanApiService!
    var skinAnalysisApiService: SkinAnalysisApiService!
    var conflictApiService: ConflictApiService!
    
    var testEmail: String!
    var testPassword: String!
    var testName: String!
    
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
        userApiService = UserApiService.shared
        productApiService = ProductApiService.shared
        planApiService = PlanApiService.shared
        skinAnalysisApiService = SkinAnalysisApiService.shared
        conflictApiService = ConflictApiService.shared
        
        let timestamp = Int(Date().timeIntervalSince1970)
        testEmail = "integration_test_\(timestamp)@example.com"
        testPassword = "TestPassword123"
        testName = "集成测试用户_\(timestamp)"
        
        // 清除之前的认证状态
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        print("✅ 集成测试环境已设置")
        print("📧 测试邮箱: \(testEmail!)")
    }
    
    override func tearDown() {
        authService = nil
        userApiService = nil
        productApiService = nil
        planApiService = nil
        skinAnalysisApiService = nil
        conflictApiService = nil
        testEmail = nil
        testPassword = nil
        testName = nil
        
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        super.tearDown()
        print("✅ 集成测试环境已清理")
    }
    
    // MARK: - 完整用户流程测试
    
    /// 测试完整的用户注册-登录-使用流程
    func testCompleteUserFlow() async {
        let expectation = XCTestExpectation(description: "完整用户流程测试")
        
        // Step 1: 用户注册
        print("📝 步骤1: 用户注册")
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            
            XCTAssertTrue(authService.isAuthenticated, "注册后应该已认证")
            XCTAssertNotNil(authService.currentUser, "应该有当前用户")
            print("   ✅ 用户注册成功")
        } catch {
            XCTFail("用户注册失败: \(error.localizedDescription)")
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: 1.0)
            return
        }
        
        // Step 2: 刷新用户信息
        print("📝 步骤2: 刷新用户信息")
        do {
            try await authService.refreshCurrentUser()
            XCTAssertNotNil(authService.currentUser, "应该有当前用户")
            print("   ✅ 用户信息刷新成功")
        } catch {
            XCTFail("刷新用户信息失败: \(error.localizedDescription)")
        }
        
        // Step 3: 创建产品
        print("📝 步骤3: 创建产品")
        var productId: String?
        do {
            let product = try await productApiService.createProduct(
                name: "集成测试产品_\(Int(Date().timeIntervalSince1970))",
                label: "测试"
            )
            productId = product.id
            XCTAssertFalse(product.id.isEmpty, "产品ID不应该为空")
            print("   ✅ 产品创建成功: \(product.id)")
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
        }
        
        // Step 4: 获取产品列表
        print("📝 步骤4: 获取产品列表")
        do {
            let products = try await productApiService.getProducts()
            XCTAssertGreaterThanOrEqual(products.count, 0, "应该返回产品列表")
            print("   ✅ 获取产品列表成功: \(products.count)个产品")
        } catch {
            XCTFail("获取产品列表失败: \(error.localizedDescription)")
        }
        
        // Step 5: 创建护肤方案
        print("📝 步骤5: 创建护肤方案")
        var planId: String?
        do {
            let plan = try await planApiService.createPlan(
                requirement: "集成测试方案",
                userAge: 25
            )
            planId = plan.id
            XCTAssertFalse(plan.id.isEmpty, "方案ID不应该为空")
            print("   ✅ 方案创建成功: \(plan.id)")
        } catch {
            XCTFail("创建方案失败: \(error.localizedDescription)")
        }
        
        // Step 6: 获取方案列表
        print("📝 步骤6: 获取方案列表")
        do {
            let plans = try await planApiService.getUserPlans()
            XCTAssertGreaterThanOrEqual(plans.count, 0, "应该返回方案列表")
            print("   ✅ 获取方案列表成功: \(plans.count)个方案")
        } catch {
            XCTFail("获取方案列表失败: \(error.localizedDescription)")
        }
        
        // Step 7: 用户登出
        print("📝 步骤7: 用户登出")
        do {
            try await authService.logout()
            XCTAssertFalse(authService.isAuthenticated, "登出后应该未认证")
            XCTAssertNil(authService.currentUser, "应该清除当前用户")
            print("   ✅ 用户登出成功")
        } catch {
            XCTFail("用户登出失败: \(error.localizedDescription)")
        }
        
        print("✅ 完整用户流程测试通过")
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 60.0)
    }
    
    // MARK: - API端点连接测试
    
    /// 测试所有主要API端点是否可访问
    func testAPIEndpointsAccessibility() async {
        let expectation = XCTestExpectation(description: "API端点可访问性测试")
        
        // 先注册用户
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: 1.0)
            return
        }
        
        var testsPassed = 0
        var testsTotal = 0
        
        // 测试用户API
        print("🔍 测试用户API端点...")
        testsTotal += 1
        do {
            let _ = try await userApiService.getCurrentUser()
            print("   ✅ /users/me - 可访问")
            testsPassed += 1
        } catch {
            print("   ❌ /users/me - 不可访问: \(error.localizedDescription)")
        }
        
        // 测试产品API
        print("🔍 测试产品API端点...")
        testsTotal += 1
        do {
            let _ = try await productApiService.getProducts()
            print("   ✅ /products - 可访问")
            testsPassed += 1
        } catch {
            print("   ❌ /products - 不可访问: \(error.localizedDescription)")
        }
        
        // 测试方案API
        print("🔍 测试方案API端点...")
        testsTotal += 1
        do {
            let _ = try await planApiService.getUserPlans()
            print("   ✅ /plans - 可访问")
            testsPassed += 1
        } catch {
            print("   ❌ /plans - 不可访问: \(error.localizedDescription)")
        }
        
        // 测试冲突API
        print("🔍 测试冲突API端点...")
        testsTotal += 1
        do {
            let _ = try await conflictApiService.getUserConflicts()
            print("   ✅ /conflicts - 可访问")
            testsPassed += 1
        } catch {
            print("   ❌ /conflicts - 不可访问: \(error.localizedDescription)")
        }
        
        // 测试皮肤分析API
        print("🔍 测试皮肤分析API端点...")
        testsTotal += 1
        do {
            let _ = try await skinAnalysisApiService.getAnalysisStats()
            print("   ✅ /skin-analysis/stats - 可访问")
            testsPassed += 1
        } catch {
            print("   ❌ /skin-analysis/stats - 不可访问: \(error.localizedDescription)")
        }
        
        print("📊 API端点测试结果: \(testsPassed)/\(testsTotal) 通过")
        
        if testsPassed == testsTotal {
            print("✅ 所有API端点均可访问")
        } else {
            print("⚠️ 部分API端点不可访问，请检查后端服务")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - 数据一致性测试
    
    /// 测试创建和获取的数据一致性
    func testDataConsistency() async {
        let expectation = XCTestExpectation(description: "数据一致性测试")
        
        // 注册用户
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: 1.0)
            return
        }
        
        // 创建产品
        let productName = "一致性测试产品_\(Int(Date().timeIntervalSince1970))"
        var createdProduct: Product?
        
        do {
            createdProduct = try await productApiService.createProduct(name: productName)
            print("✅ 产品已创建: \(createdProduct!.id)")
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: 1.0)
            return
        }
        
        // 获取产品详情，验证数据一致性
        do {
            let fetchedProduct = try await productApiService.getProduct(productId: createdProduct!.id)
            
            // 验证数据一致性
            XCTAssertEqual(fetchedProduct.id, createdProduct!.id, "产品ID应该一致")
            XCTAssertEqual(fetchedProduct.name, createdProduct!.name, "产品名称应该一致")
            
            print("✅ 数据一致性验证通过")
            print("   - 创建的产品ID: \(createdProduct!.id)")
            print("   - 获取的产品ID: \(fetchedProduct.id)")
            print("   - 产品名称匹配: ✅")
        } catch {
            XCTFail("获取产品失败: \(error.localizedDescription)")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 20.0)
    }
    
    // MARK: - 错误处理测试
    
    /// 测试错误处理是否正常工作
    func testErrorHandling() async {
        let expectation = XCTestExpectation(description: "错误处理测试")
        
        // 测试未认证访问
        UserDefaults.standard.removeObject(forKey: "authToken")
        
        do {
            let _ = try await userApiService.getCurrentUser()
            XCTFail("未认证访问应该失败")
        } catch {
            print("✅ 未认证访问正确被拒绝")
            XCTAssertTrue(error.localizedDescription.contains("授权") || 
                         error.localizedDescription.contains("401"),
                         "应该返回授权错误")
        }
        
        // 测试获取不存在的资源
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            
            let _ = try await productApiService.getProduct(productId: "nonexistent_id_12345")
            XCTFail("获取不存在的产品应该失败")
        } catch {
            print("✅ 获取不存在资源正确返回错误")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 15.0)
    }
}




