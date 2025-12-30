//
//  RealImageTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin
import UIKit

/// 真实图片集成测试
/// 使用实际图片测试皮肤分析和成分提取功能
class RealImageTests: XCTestCase {
    
    var skinAnalysisApiService: SkinAnalysisApiService!
    var productApiService: ProductApiService!
    var ingredientAnalysisApiService: IngredientAnalysisApiService!
    var userApiService: UserApiService!
    var testToken: String!
    
    override func setUp() {
        super.setUp()
        skinAnalysisApiService = SkinAnalysisApiService.shared
        productApiService = ProductApiService.shared
        ingredientAnalysisApiService = IngredientAnalysisApiService.shared
        userApiService = UserApiService.shared
        
        // 创建测试用户并获取token
        Task {
            await setupTestUser()
        }
        
        print("✅ 真实图片测试环境已设置")
    }
    
    override func tearDown() {
        skinAnalysisApiService = nil
        productApiService = nil
        ingredientAnalysisApiService = nil
        userApiService = nil
        testToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
        print("✅ 真实图片测试环境已清理")
    }
    
    /// 设置测试用户
    private func setupTestUser() async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email = "real_image_test_\(timestamp)@example.com"
        let password = "TestPassword123"
        let name = "真实图片测试用户_\(timestamp)"
        
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
    
    /// 从Bundle加载图片
    private func loadImageFromBundle(named: String) -> UIImage? {
        // 在测试bundle中查找图片
        let testBundle = Bundle(for: type(of: self))
        
        // 方法1: 尝试从bundle资源中加载
        if let imagePath = testBundle.path(forResource: named, ofType: nil) {
            if let image = UIImage(contentsOfFile: imagePath) {
                print("✅ 从Bundle资源加载图片: \(imagePath)")
                return image
            }
        }
        
        // 方法2: 尝试去掉扩展名
        let nameWithoutExt = (named as NSString).deletingPathExtension
        let ext = (named as NSString).pathExtension
        
        if let imagePath = testBundle.path(forResource: nameWithoutExt, ofType: ext.isEmpty ? "jpg" : ext) {
            if let image = UIImage(contentsOfFile: imagePath) {
                print("✅ 从Bundle资源加载图片（分离扩展名）: \(imagePath)")
                return image
            }
        }
        
        // 方法3: 尝试在测试bundle目录中查找
        let testBundlePath = testBundle.bundlePath
        let imagePath = (testBundlePath as NSString).appendingPathComponent(named)
        
        if FileManager.default.fileExists(atPath: imagePath) {
            if let image = UIImage(contentsOfFile: imagePath) {
                print("✅ 从Bundle目录加载图片: \(imagePath)")
                return image
            }
        }
        
        // 方法4: 尝试在项目目录中查找（AIskinTests目录）
        let projectPath = (testBundlePath as NSString).deletingLastPathComponent
        let imagePath2 = (projectPath as NSString).appendingPathComponent(named)
        
        if FileManager.default.fileExists(atPath: imagePath2) {
            if let image = UIImage(contentsOfFile: imagePath2) {
                print("✅ 从项目目录加载图片: \(imagePath2)")
                return image
            }
        }
        
        // 方法5: 尝试使用绝对路径（AIskinTests目录）
        let absolutePath = "/Users/terry/Desktop/coding/projiect/skin/skintest/AIskin/AIskinTests/\(named)"
        if FileManager.default.fileExists(atPath: absolutePath) {
            if let image = UIImage(contentsOfFile: absolutePath) {
                print("✅ 从绝对路径加载图片: \(absolutePath)")
                return image
            }
        }
        
        print("⚠️ 无法找到图片: \(named)")
        print("   已尝试的路径:")
        print("   - Bundle资源: \(testBundle.path(forResource: named, ofType: nil) ?? "未找到")")
        print("   - Bundle目录: \(imagePath)")
        print("   - 项目目录: \(imagePath2)")
        print("   - 绝对路径: \(absolutePath)")
        print("   - Bundle路径: \(testBundlePath)")
        
        return nil
    }
    
    // MARK: - 皮肤分析测试（使用真实图片）
    
    /// 测试使用真实图片进行皮肤分析
    func testSkinAnalysisWithRealImage() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        print("🎯 开始真实图片皮肤分析测试")
        print("📷 图片文件: 1924903380_1761459787694.jpg")
        
        // Arrange: 加载真实图片
        guard let skinImage = loadImageFromBundle(named: "1924903380_1761459787694.jpg") else {
            XCTFail("无法加载皮肤分析图片")
            return
        }
        
        print("✅ 图片加载成功")
        print("   - 图片尺寸: \(skinImage.size.width)x\(skinImage.size.height)")
        print("   - 图片大小: \(String(format: "%.2f", Double(skinImage.pngData()?.count ?? 0) / 1024.0)) KB")
        
        let expectation = XCTestExpectation(description: "真实图片皮肤分析测试")
        
        // Act: 分析皮肤
        do {
            print("📡 开始上传并分析皮肤图片...")
            let startTime = Date()
            
            let analysis = try await skinAnalysisApiService.analyzeSkin(image: skinImage)
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Assert: 验证分析结果
            XCTAssertFalse(analysis.id.isEmpty, "分析ID不应该为空")
            XCTAssertNotNil(analysis.overallAssessment, "应该有整体评估")
            XCTAssertGreaterThanOrEqual(analysis.overallAssessment.healthScore, 0, "健康评分应该在0-100之间")
            XCTAssertLessThanOrEqual(analysis.overallAssessment.healthScore, 100, "健康评分应该在0-100之间")
            XCTAssertNotNil(analysis.skinType, "应该有皮肤类型")
            
            print("")
            print(String(repeating: "=", count: 60))
            print("✅ 皮肤分析成功！")
            print(String(repeating: "=", count: 60))
            print("📊 分析结果:")
            print("   - 分析ID: \(analysis.id)")
            print("   - 处理时间: \(String(format: "%.2f", duration))秒")
            print("   - 健康评分: \(analysis.overallAssessment.healthScore)/100")
            print("   - 皮肤类型: \(analysis.skinType.type)")
            if let subtype = analysis.skinType.subtype {
                print("   - 子类型: \(subtype)")
            }
            print("   - 皮肤状况: \(analysis.overallAssessment.skinCondition)")
            print("   - 总结: \(analysis.overallAssessment.summary)")
            
            if let moisture = analysis.moisture {
                print("   - 水分: \(String(format: "%.1f", moisture))%")
            }
            if let glossiness = analysis.glossiness {
                print("   - 光泽度: \(String(format: "%.1f", glossiness))%")
            }
            if let elasticity = analysis.elasticity {
                print("   - 弹性: \(String(format: "%.1f", elasticity))%")
            }
            
            // 打印皮肤问题详情
            if let blackheads = analysis.blackheads {
                print("   - 黑头: \(blackheads.severity)")
            }
            if let acne = analysis.acne {
                print("   - 痘痘: \(acne.count)")
            }
            if let pores = analysis.pores {
                print("   - 毛孔: \(pores.severity)")
            }
            
            // 打印建议
            if let recommendations = analysis.overallAssessment.recommendations, !recommendations.isEmpty {
                print("")
                print("💡 护肤建议:")
                for (index, recommendation) in recommendations.enumerated() {
                    print("   \(index + 1). \(recommendation)")
                }
            }
            
            print(String(repeating: "=", count: 60))
            print("")
            
            expectation.fulfill()
        } catch {
            XCTFail("皮肤分析失败: \(error.localizedDescription)")
            print("❌ 皮肤分析错误: \(error.localizedDescription)")
            print("")
            print("💡 可能的原因:")
            print("   1. 后端AI服务未配置")
            print("   2. 图片格式不支持")
            print("   3. 网络连接问题")
        }
        
        await fulfillment(of: [expectation], timeout: 120.0) // AI分析可能需要较长时间
    }
    
    // MARK: - 产品成分提取和分析测试（使用真实图片）
    
    /// 测试使用真实图片提取产品成分并分析
    func testProductIngredientExtractionAndAnalysis() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        print("🎯 开始真实图片产品成分提取和分析测试")
        print("📷 图片文件: images.jpeg")
        
        // Arrange: 加载真实图片
        guard let productImage = loadImageFromBundle(named: "images.jpeg") else {
            XCTFail("无法加载产品图片")
            return
        }
        
        print("✅ 图片加载成功")
        print("   - 图片尺寸: \(productImage.size.width)x\(productImage.size.height)")
        print("   - 图片大小: \(String(format: "%.2f", Double(productImage.pngData()?.count ?? 0) / 1024.0)) KB")
        
        let expectation = XCTestExpectation(description: "产品成分提取和分析测试")
        
        // Step 1: 创建产品
        var productId: String!
        do {
            print("")
            print("📝 步骤1: 创建产品...")
            let product = try await productApiService.createProduct(
                name: "Cloris Land 毛孔焕净趣玩泡泡泥膜",
                label: "清洁"
            )
            productId = product.id
            print("   ✅ 产品创建成功: \(product.id)")
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: 1.0)
            return
        }
        
        // Step 2: 上传产品图片
        do {
            print("")
            print("📝 步骤2: 上传产品图片...")
            let imageUrl = try await productApiService.uploadProductImage(
                productId: productId,
                image: productImage
            )
            print("   ✅ 图片上传成功")
            print("   - 图片URL: \(imageUrl)")
        } catch {
            XCTFail("上传产品图片失败: \(error.localizedDescription)")
            print("   ❌ 上传错误: \(error.localizedDescription)")
        }
        
        // Step 3: 提取产品成分（OCR）
        do {
            print("")
            print("📝 步骤3: 提取产品成分（OCR识别）...")
            print("   ⏳ 这可能需要一些时间...")
            
            let (name, ingredients) = try await productApiService.extractIngredients(productId: productId)
            
            print("   ✅ 成分提取成功")
            print("   - 识别产品名称: \(name)")
            print("   - 提取的成分数量: \(ingredients.count)")
            print("")
            print("   📋 提取的成分列表:")
            for (index, ingredient) in ingredients.prefix(20).enumerated() {
                print("      \(index + 1). \(ingredient)")
            }
            if ingredients.count > 20 {
                print("      ... 还有 \(ingredients.count - 20) 个成分")
            }
        } catch {
            XCTFail("提取产品成分失败: \(error.localizedDescription)")
            print("   ❌ 提取错误: \(error.localizedDescription)")
            print("   💡 可能的原因:")
            print("      1. OCR服务未配置")
            print("      2. 图片质量不够清晰")
            print("      3. 图片中不包含成分信息")
        }
        
        // Step 4: 分析产品成分
        do {
            print("")
            print("📝 步骤4: 分析产品成分（AI分析）...")
            print("   ⏳ 这可能需要较长时间...")
            
            let startTime = Date()
            let analysis = try await ingredientAnalysisApiService.analyzeIngredients(productId: productId)
            let duration = Date().timeIntervalSince(startTime)
            
            print("")
            print(String(repeating: "=", count: 60))
            print("✅ 成分分析成功！")
            print(String(repeating: "=", count: 60))
            print("📊 分析结果:")
            print("   - 分析耗时: \(String(format: "%.2f", duration))秒")
            print("   - 安全性指数: \(analysis.safetyIndex)/100")
            print("   - 功效评分: \(analysis.efficacyScore)/5.0")
            print("   - 活性成分数: \(analysis.activeIngredients)")
            print("   - 整体评级: \(analysis.overallRating)/5.0")
            print("")
            print("⚠️ 风险分析:")
            print("   - 痘痘风险: \(analysis.acneRisk.level) (\(String(format: "%.1f", analysis.acneRisk.percentage))%)")
            print("   - 刺激风险: \(analysis.irritationRisk.level) (\(String(format: "%.1f", analysis.irritationRisk.percentage))%)")
            print("   - 过敏风险: \(analysis.allergyRisk.level) (\(String(format: "%.1f", analysis.allergyRisk.percentage))%)")
            print("")
            
            if !analysis.efficacyAnalysis.isEmpty {
                print("💡 功效分析:")
                for (index, efficacy) in analysis.efficacyAnalysis.enumerated() {
                    print("   \(index + 1). \(efficacy)")
                }
            }
            
            if !analysis.potentialRisks.isEmpty {
                print("")
                print("⚠️ 潜在风险:")
                for (index, risk) in analysis.potentialRisks.enumerated() {
                    print("   \(index + 1). \(risk)")
                }
            }
            
            if !analysis.recommendations.isEmpty {
                print("")
                print("💡 使用建议:")
                for (index, recommendation) in analysis.recommendations.enumerated() {
                    print("   \(index + 1). \(recommendation)")
                }
            }
            
            print("")
            print("📝 总结:")
            print("   \(analysis.summary)")
            print(String(repeating: "=", count: 60))
            print("")
            
        } catch {
            XCTFail("分析产品成分失败: \(error.localizedDescription)")
            print("   ❌ 分析错误: \(error.localizedDescription)")
            print("   💡 可能的原因:")
            print("      1. AI服务未配置")
            print("      2. 产品没有成分信息")
            print("      3. 网络连接问题")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 180.0) // OCR和AI分析需要较长时间
    }
    
    /// 获取完整的产品成分分析（包含产品信息）
    func testGetCompleteIngredientAnalysis() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 先执行完整流程创建产品并分析
        guard let productImage = loadImageFromBundle(named: "images.jpeg") else {
            XCTFail("无法加载产品图片")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取完整成分分析测试")
        
        // 创建产品
        var productId: String!
        do {
            let product = try await productApiService.createProduct(
                name: "测试产品_\(Int(Date().timeIntervalSince1970))",
                label: "测试"
            )
            productId = product.id
            
            // 上传图片
            let _ = try await productApiService.uploadProductImage(
                productId: productId,
                image: productImage
            )
            
            // 提取成分
            let _ = try await productApiService.extractIngredients(productId: productId)
            
            // 分析成分
            let _ = try await ingredientAnalysisApiService.analyzeIngredients(productId: productId)
            
        } catch {
            print("⚠️ 设置测试数据失败: \(error.localizedDescription)")
            expectation.fulfill()
            await fulfillment(of: [expectation], timeout: 1.0)
            return
        }
        
        // 获取完整分析结果
        do {
            print("")
            print("📝 获取完整成分分析结果...")
            
            let (product, analysis) = try await ingredientAnalysisApiService.getIngredientAnalysis(productId: productId)
            
            print("✅ 获取完整分析成功")
            print("")
            print("📦 产品信息:")
            print("   - 产品ID: \(product.id)")
            print("   - 产品名称: \(product.name)")
            print("   - 产品标签: \(product.label ?? "无")")
            print("   - 成分数量: \(product.ingredients.count)")
            
            print("")
            print("🔬 成分分析:")
            print("   - 安全性指数: \(analysis.safetyIndex)")
            print("   - 功效评分: \(analysis.efficacyScore)")
            print("   - 整体评级: \(analysis.overallRating)")
            
            expectation.fulfill()
        } catch {
            XCTFail("获取完整分析失败: \(error.localizedDescription)")
            print("❌ 获取错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
}

