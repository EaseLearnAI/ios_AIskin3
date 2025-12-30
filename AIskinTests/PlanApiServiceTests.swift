//
//  PlanApiServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin

/// PlanApiService集成测试
/// 测试护肤方案相关的API服务与后端连接
class PlanApiServiceTests: XCTestCase {
    
    var planApiService: PlanApiService!
    var userApiService: UserApiService!
    var testToken: String!
    
    override func setUp() {
        super.setUp()
        planApiService = PlanApiService.shared
        userApiService = UserApiService.shared
        
        // 创建测试用户并获取token
        Task {
            await setupTestUser()
        }
        
        print("✅ PlanApiService测试环境已设置")
    }
    
    override func tearDown() {
        planApiService = nil
        userApiService = nil
        testToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
        print("✅ PlanApiService测试环境已清理")
    }
    
    /// 设置测试用户
    private func setupTestUser() async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email = "plan_test_\(timestamp)@example.com"
        let password = "TestPassword123"
        let name = "方案测试用户_\(timestamp)"
        
        do {
            let (token, _) = try await userApiService.register(
                name: name,
                email: email,
                password: password
            )
            testToken = token
            UserDefaults.standard.set(token, forKey: "authToken")
            print("✅ 测试用户已创建")
        } catch {
            print("⚠️ 无法创建测试用户: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 创建方案测试
    
    /// 测试创建个性化护肤方案
    func testCreatePlan() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "创建护肤方案测试")
        
        // Act: 创建方案
        do {
            let plan = try await planApiService.createPlan(
                requirement: "美白保湿",
                userAge: 25,
                skinConcerns: ["美白", "保湿"]
            )
            
            // Assert: 验证方案创建结果
            XCTAssertFalse(plan.id.isEmpty, "方案ID不应该为空")
            XCTAssertFalse(plan.name.isEmpty, "方案名称不应该为空")
            XCTAssertNotNil(plan.morning, "应该有早晨步骤")
            XCTAssertNotNil(plan.evening, "应该有晚间步骤")
            
            print("✅ 创建护肤方案成功")
            print("   - 方案ID: \(plan.id)")
            print("   - 方案名称: \(plan.name)")
            print("   - 早晨步骤数: \(plan.morning.count)")
            print("   - 晚间步骤数: \(plan.evening.count)")
            print("   - 推荐建议数: \(plan.recommendations.count)")
            
            expectation.fulfill()
        } catch {
            XCTFail("创建护肤方案失败: \(error.localizedDescription)")
            print("❌ 创建方案错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 30.0) // AI生成可能需要时间
    }
    
    /// 测试获取用户所有方案
    func testGetUserPlans() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "获取用户方案列表测试")
        
        // Act: 获取方案列表
        do {
            let plans = try await planApiService.getUserPlans()
            
            // Assert: 验证结果
            XCTAssertNotNil(plans, "应该返回方案列表")
            print("✅ 获取用户方案列表成功")
            print("   - 方案数量: \(plans.count)")
            
            for plan in plans {
                print("     • \(plan.name) (ID: \(plan.id))")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取方案列表失败: \(error.localizedDescription)")
            print("❌ 获取方案列表错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取方案详情
    func testGetPlanDetail() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先创建一个方案
        var planId: String!
        do {
            let plan = try await planApiService.createPlan(requirement: "测试方案")
            planId = plan.id
        } catch {
            XCTFail("创建方案失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取方案详情测试")
        
        // Act: 获取方案详情
        do {
            let plan = try await planApiService.getPlan(planId: planId)
            
            // Assert: 验证结果
            XCTAssertEqual(plan.id, planId, "方案ID应该匹配")
            XCTAssertFalse(plan.name.isEmpty, "方案名称不应该为空")
            
            print("✅ 获取方案详情成功")
            print("   - 方案ID: \(plan.id)")
            print("   - 方案名称: \(plan.name)")
            
            expectation.fulfill()
        } catch {
            XCTFail("获取方案详情失败: \(error.localizedDescription)")
            print("❌ 获取方案详情错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试创建自定义方案
    func testCreateCustomPlan() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "创建自定义方案测试")
        
        // Arrange: 准备自定义方案数据
        let morningSteps = [
            RoutineItem(product: "洁面产品", reason: "清洁", completed: false),
            RoutineItem(product: "精华", reason: "滋养", completed: false)
        ]
        let eveningSteps = [
            RoutineItem(product: "洁面产品", reason: "清洁", completed: false),
            RoutineItem(product: "面霜", reason: "保湿", completed: false)
        ]
        
        // Act: 创建自定义方案
        do {
            let plan = try await planApiService.createCustomPlan(
                name: "自定义测试方案_\(Int(Date().timeIntervalSince1970))",
                morning: morningSteps,
                evening: eveningSteps,
                recommendations: ["建议1", "建议2"],
                tags: ["测试", "自定义"]
            )
            
            // Assert: 验证结果
            XCTAssertFalse(plan.id.isEmpty, "方案ID不应该为空")
            XCTAssertEqual(plan.morning.count, morningSteps.count, "早晨步骤数应该匹配")
            XCTAssertEqual(plan.evening.count, eveningSteps.count, "晚间步骤数应该匹配")
            
            print("✅ 创建自定义方案成功")
            print("   - 方案ID: \(plan.id)")
            print("   - 方案名称: \(plan.name)")
            
            expectation.fulfill()
        } catch {
            XCTFail("创建自定义方案失败: \(error.localizedDescription)")
            print("❌ 创建自定义方案错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试删除方案
    func testDeletePlan() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先创建一个方案
        var planId: String!
        do {
            let plan = try await planApiService.createPlan(requirement: "删除测试方案")
            planId = plan.id
        } catch {
            XCTFail("创建方案失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "删除方案测试")
        
        // Act: 删除方案
        do {
            try await planApiService.deletePlan(planId: planId)
            
            // Assert: 验证删除成功
            print("✅ 删除方案成功")
            print("   - 方案ID: \(planId!)")
            
            expectation.fulfill()
        } catch {
            XCTFail("删除方案失败: \(error.localizedDescription)")
            print("❌ 删除方案错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}




