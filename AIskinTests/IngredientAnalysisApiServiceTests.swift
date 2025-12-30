//
//  IngredientAnalysisApiServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin

/// IngredientAnalysisApiService集成测试
/// 测试成分分析相关的API服务与后端连接
class IngredientAnalysisApiServiceTests: XCTestCase {
    
    var ingredientAnalysisApiService: IngredientAnalysisApiService!
    var productApiService: ProductApiService!
    var userApiService: UserApiService!
    var testToken: String!
    var testProductId: String!
    
    override func setUp() {
        super.setUp()
        ingredientAnalysisApiService = IngredientAnalysisApiService.shared
        productApiService = ProductApiService.shared
        userApiService = UserApiService.shared
        
        // 创建测试用户和产品
        Task {
            await setupTestData()
        }
        
        print("✅ IngredientAnalysisApiService测试环境已设置")
    }
    
    override func tearDown() {
        ingredientAnalysisApiService = nil
        productApiService = nil
        userApiService = nil
        testToken = nil
        testProductId = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
        print("✅ IngredientAnalysisApiService测试环境已清理")
    }
    
    /// 设置测试数据
    private func setupTestData() async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email = "ingredient_test_\(timestamp)@example.com"
        let password = "TestPassword123"
        let name = "成分分析测试用户_\(timestamp)"
        
        do {
            let (token, _) = try await userApiService.register(
                name: name,
                email: email,
                password: password
            )
            testToken = token
            UserDefaults.standard.set(token, forKey: "authToken")
            
            // 创建测试产品
            let product = try await productApiService.createProduct(
                name: "成分分析测试产品_\(timestamp)"
            )
            testProductId = product.id
            
            print("✅ 测试用户和产品已创建")
            print("   - 产品ID: \(testProductId!)")
        } catch {
            print("⚠️ 无法创建测试数据: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 成分分析测试
    
    /// 测试分析产品成分
    func testAnalyzeIngredients() async {
        // 等待数据设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let productId = testProductId else {
            XCTFail("测试产品未创建")
            return
        }
        
        let expectation = XCTestExpectation(description: "分析产品成分测试")
        
        // Act: 分析成分
        do {
            let analysis = try await ingredientAnalysisApiService.analyzeIngredients(productId: productId)
            
            // Assert: 验证分析结果
            XCTAssertGreaterThanOrEqual(analysis.safetyIndex, 0, "安全性指数应该在0-100之间")
            XCTAssertLessThanOrEqual(analysis.safetyIndex, 100, "安全性指数应该在0-100之间")
            XCTAssertGreaterThanOrEqual(analysis.efficacyScore, 0, "功效评分应该在0-5之间")
            XCTAssertLessThanOrEqual(analysis.efficacyScore, 5, "功效评分应该在0-5之间")
            XCTAssertGreaterThanOrEqual(analysis.activeIngredients, 0, "活性成分数应该>=0")
            
            print("✅ 成分分析成功")
            print("   - 安全性指数: \(analysis.safetyIndex)")
            print("   - 功效评分: \(analysis.efficacyScore)")
            print("   - 活性成分数: \(analysis.activeIngredients)")
            print("   - 整体评级: \(analysis.overallRating)")
            print("   - 痘痘风险: \(analysis.acneRisk.level) (\(analysis.acneRisk.percentage)%)")
            print("   - 刺激风险: \(analysis.irritationRisk.level) (\(analysis.irritationRisk.percentage)%)")
            print("   - 过敏风险: \(analysis.allergyRisk.level) (\(analysis.allergyRisk.percentage)%)")
            
            expectation.fulfill()
        } catch {
            XCTFail("成分分析失败: \(error.localizedDescription)")
            print("❌ 成分分析错误: \(error.localizedDescription)")
            print("⚠️ 注意: 成分分析可能需要产品有成分信息")
        }
        
        await fulfillment(of: [expectation], timeout: 30.0) // AI分析可能需要时间
    }
    
    /// 测试获取成分分析结果
    func testGetIngredientAnalysis() async {
        // 等待数据设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let productId = testProductId else {
            XCTFail("测试产品未创建")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取成分分析结果测试")
        
        // Act: 获取成分分析结果
        do {
            let (product, analysis) = try await ingredientAnalysisApiService.getIngredientAnalysis(productId: productId)
            
            // Assert: 验证结果
            XCTAssertEqual(product.id, productId, "产品ID应该匹配")
            XCTAssertGreaterThanOrEqual(analysis.safetyIndex, 0, "安全性指数应该在0-100之间")
            XCTAssertLessThanOrEqual(analysis.safetyIndex, 100, "安全性指数应该在0-100之间")
            
            print("✅ 获取成分分析结果成功")
            print("   - 产品名称: \(product.name)")
            print("   - 成分数量: \(product.ingredients.count)")
            print("   - 安全性指数: \(analysis.safetyIndex)")
            print("   - 功效评分: \(analysis.efficacyScore)")
            
            expectation.fulfill()
        } catch {
            XCTFail("获取成分分析结果失败: \(error.localizedDescription)")
            print("❌ 获取成分分析结果错误: \(error.localizedDescription)")
            print("⚠️ 注意: 可能需要先进行成分分析")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}




