//
//  SkinAnalysisApiServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin
import UIKit

/// SkinAnalysisApiService集成测试
/// 测试皮肤分析相关的API服务与后端连接
class SkinAnalysisApiServiceTests: XCTestCase {
    
    var skinAnalysisApiService: SkinAnalysisApiService!
    var userApiService: UserApiService!
    var testToken: String!
    
    override func setUp() {
        super.setUp()
        skinAnalysisApiService = SkinAnalysisApiService.shared
        userApiService = UserApiService.shared
        
        // 创建测试用户并获取token
        Task {
            await setupTestUser()
        }
        
        print("✅ SkinAnalysisApiService测试环境已设置")
    }
    
    override func tearDown() {
        skinAnalysisApiService = nil
        userApiService = nil
        testToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
        print("✅ SkinAnalysisApiService测试环境已清理")
    }
    
    /// 设置测试用户
    private func setupTestUser() async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email = "skin_test_\(timestamp)@example.com"
        let password = "TestPassword123"
        let name = "皮肤分析测试用户_\(timestamp)"
        
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
    
    // MARK: - 皮肤分析测试
    
    /// 测试上传并分析皮肤图片
    func testAnalyzeSkin() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 创建一个测试图片
        // 注意: 实际测试中需要真实的皮肤图片
        let testImage = createTestImage()
        
        let expectation = XCTestExpectation(description: "皮肤分析测试")
        
        // Act: 分析皮肤
        do {
            let analysis = try await skinAnalysisApiService.analyzeSkin(image: testImage)
            
            // Assert: 验证分析结果
            XCTAssertFalse(analysis.id.isEmpty, "分析ID不应该为空")
            XCTAssertNotNil(analysis.overallAssessment, "应该有整体评估")
            XCTAssertGreaterThanOrEqual(analysis.overallAssessment.healthScore, 0, "健康评分应该在0-100之间")
            XCTAssertLessThanOrEqual(analysis.overallAssessment.healthScore, 100, "健康评分应该在0-100之间")
            XCTAssertNotNil(analysis.skinType, "应该有皮肤类型")
            
            print("✅ 皮肤分析成功")
            print("   - 分析ID: \(analysis.id)")
            print("   - 健康评分: \(analysis.overallAssessment.healthScore)")
            print("   - 皮肤类型: \(analysis.skinType.type)")
            print("   - 皮肤状况: \(analysis.overallAssessment.skinCondition)")
            
            expectation.fulfill()
        } catch {
            XCTFail("皮肤分析失败: \(error.localizedDescription)")
            print("❌ 皮肤分析错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 60.0) // 分析可能需要较长时间
    }
    
    /// 测试获取分析历史
    func testGetAnalysisHistory() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "获取分析历史测试")
        
        // Act: 获取分析历史
        do {
            let (analyses, pagination) = try await skinAnalysisApiService.getAnalysisHistory(page: 1, limit: 10)
            
            // Assert: 验证结果
            XCTAssertNotNil(analyses, "应该返回分析列表")
            print("✅ 获取分析历史成功")
            print("   - 分析数量: \(analyses.count)")
            if let pagination = pagination {
                print("   - 总数: \(pagination.total)")
                print("   - 当前页: \(pagination.page)")
            }
            
            for analysis in analyses {
                print("     • 分析ID: \(analysis.id), 健康评分: \(analysis.overallAssessment.healthScore)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取分析历史失败: \(error.localizedDescription)")
            print("❌ 获取分析历史错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取分析详情
    func testGetAnalysisDetail() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先进行一次分析
        let testImage = createTestImage()
        var analysisId: String!
        
        do {
            let analysis = try await skinAnalysisApiService.analyzeSkin(image: testImage)
            analysisId = analysis.id
        } catch {
            XCTFail("创建分析失败，无法继续详情测试: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取分析详情测试")
        
        // Act: 获取分析详情
        do {
            let analysis = try await skinAnalysisApiService.getAnalysisDetail(analysisId: analysisId)
            
            // Assert: 验证结果
            XCTAssertEqual(analysis.id, analysisId, "分析ID应该匹配")
            XCTAssertNotNil(analysis.overallAssessment, "应该有整体评估")
            XCTAssertNotNil(analysis.skinType, "应该有皮肤类型")
            
            print("✅ 获取分析详情成功")
            print("   - 分析ID: \(analysis.id)")
            print("   - 健康评分: \(analysis.overallAssessment.healthScore)")
            print("   - 皮肤类型: \(analysis.skinType.type)")
            if let moisture = analysis.moisture {
                print("   - 水分: \(moisture)")
            }
            if let glossiness = analysis.glossiness {
                print("   - 光泽度: \(glossiness)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取分析详情失败: \(error.localizedDescription)")
            print("❌ 获取分析详情错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取最新分析
    func testGetLatestAnalysis() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "获取最新分析测试")
        
        // Act: 获取最新分析
        do {
            let analysis = try await skinAnalysisApiService.getLatestAnalysis()
            
            // Assert: 验证结果
            if let analysis = analysis {
                XCTAssertFalse(analysis.id.isEmpty, "分析ID不应该为空")
                print("✅ 获取最新分析成功")
                print("   - 分析ID: \(analysis.id)")
                print("   - 健康评分: \(analysis.overallAssessment.healthScore)")
                print("   - 创建时间: \(analysis.createdAt?.description ?? "未知")")
            } else {
                print("⚠️ 暂无分析记录")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取最新分析失败: \(error.localizedDescription)")
            print("❌ 获取最新分析错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取统计数据
    func testGetAnalysisStats() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "获取统计数据测试")
        
        // Act: 获取统计数据
        do {
            let stats = try await skinAnalysisApiService.getAnalysisStats()
            
            // Assert: 验证结果
            XCTAssertGreaterThanOrEqual(stats.totalAnalyses, 0, "总分析次数应该>=0")
            
            print("✅ 获取统计数据成功")
            print("   - 总分析次数: \(stats.totalAnalyses)")
            if let avgScore = stats.averageHealthScore {
                print("   - 平均健康评分: \(avgScore)")
            }
            if let latestCondition = stats.latestSkinCondition {
                print("   - 最新皮肤状况: \(latestCondition)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取统计数据失败: \(error.localizedDescription)")
            print("❌ 获取统计数据错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 创建测试图片
    private func createTestImage() -> UIImage {
        // 创建一个简单的测试图片
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// 从Bundle加载图片
    private func loadImageFromBundle(named: String) -> UIImage? {
        let testBundle = Bundle(for: type(of: self))
        
        // 尝试多种路径
        if let imagePath = testBundle.path(forResource: named, ofType: nil) {
            return UIImage(contentsOfFile: imagePath)
        }
        
        let nameWithoutExt = (named as NSString).deletingPathExtension
        let ext = (named as NSString).pathExtension
        
        if let imagePath = testBundle.path(forResource: nameWithoutExt, ofType: ext.isEmpty ? "jpg" : ext) {
            return UIImage(contentsOfFile: imagePath)
        }
        
        let testBundlePath = testBundle.bundlePath
        let imagePath = (testBundlePath as NSString).appendingPathComponent(named)
        
        if FileManager.default.fileExists(atPath: imagePath) {
            return UIImage(contentsOfFile: imagePath)
        }
        
        let projectPath = (testBundlePath as NSString).deletingLastPathComponent
        let imagePath2 = (projectPath as NSString).appendingPathComponent(named)
        
        if FileManager.default.fileExists(atPath: imagePath2) {
            return UIImage(contentsOfFile: imagePath2)
        }
        
        return nil
    }
}

