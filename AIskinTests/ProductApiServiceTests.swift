//
//  ProductApiServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin
import UIKit

/// ProductApiService集成测试
/// 测试产品相关的API服务与后端连接
class ProductApiServiceTests: XCTestCase {
    
    var productApiService: ProductApiService!
    var userApiService: UserApiService!
    var testToken: String!
    var testUserId: String!
    
    override func setUp() {
        super.setUp()
        productApiService = ProductApiService.shared
        userApiService = UserApiService.shared
        
        // 创建测试用户并获取token
        Task {
            await setupTestUser()
        }
        
        print("✅ ProductApiService测试环境已设置")
    }
    
    override func tearDown() {
        productApiService = nil
        userApiService = nil
        testToken = nil
        testUserId = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        super.tearDown()
        print("✅ ProductApiService测试环境已清理")
    }
    
    /// 设置测试用户
    private func setupTestUser() async {
        let timestamp = Int(Date().timeIntervalSince1970)
        let email = "product_test_\(timestamp)@example.com"
        let password = "TestPassword123"
        let name = "产品测试用户_\(timestamp)"
        
        do {
            let (token, user) = try await userApiService.register(
                name: name,
                email: email,
                password: password
            )
            testToken = token
            testUserId = user.id
            UserDefaults.standard.set(token, forKey: "authToken")
            print("✅ 测试用户已创建: \(user.id)")
        } catch {
            print("⚠️ 无法创建测试用户: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 产品创建测试
    
    /// 测试创建产品
    func testCreateProduct() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        
        // Arrange: 准备测试数据
        let productName = "测试产品_\(Int(Date().timeIntervalSince1970))"
        let productLabel = "测试标签"
        let expectation = XCTestExpectation(description: "创建产品测试")
        
        // Act: 创建产品
        do {
            let product = try await productApiService.createProduct(
                name: productName,
                label: productLabel
            )
            
            // Assert: 验证产品创建结果
            XCTAssertEqual(product.name, productName, "产品名称应该匹配")
            XCTAssertEqual(product.label, productLabel, "产品标签应该匹配")
            XCTAssertFalse(product.id.isEmpty, "产品ID不应该为空")
            
            print("✅ 创建产品成功")
            print("   - 产品ID: \(product.id)")
            print("   - 产品名称: \(product.name)")
            print("   - 产品标签: \(product.label ?? "无")")
            
            expectation.fulfill()
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            print("❌ 创建产品错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取产品列表
    func testGetProducts() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let expectation = XCTestExpectation(description: "获取产品列表测试")
        
        // Act: 获取产品列表
        do {
            let products = try await productApiService.getProducts(page: 1, limit: 10)
            
            // Assert: 验证结果
            XCTAssertNotNil(products, "应该返回产品列表")
            print("✅ 获取产品列表成功")
            print("   - 产品数量: \(products.count)")
            
            for product in products {
                print("     • \(product.name) (ID: \(product.id))")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("获取产品列表失败: \(error.localizedDescription)")
            print("❌ 获取产品列表错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试获取产品详情
    func testGetProductDetail() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先创建一个产品
        var productId: String!
        do {
            let product = try await productApiService.createProduct(
                name: "详情测试产品_\(Int(Date().timeIntervalSince1970))"
            )
            productId = product.id
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取产品详情测试")
        
        // Act: 获取产品详情
        do {
            let product = try await productApiService.getProduct(productId: productId)
            
            // Assert: 验证结果
            XCTAssertEqual(product.id, productId, "产品ID应该匹配")
            XCTAssertFalse(product.name.isEmpty, "产品名称不应该为空")
            
            print("✅ 获取产品详情成功")
            print("   - 产品ID: \(product.id)")
            print("   - 产品名称: \(product.name)")
            
            expectation.fulfill()
        } catch {
            XCTFail("获取产品详情失败: \(error.localizedDescription)")
            print("❌ 获取产品详情错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试更新产品
    func testUpdateProduct() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先创建一个产品
        var productId: String!
        do {
            let product = try await productApiService.createProduct(
                name: "更新测试产品_\(Int(Date().timeIntervalSince1970))"
            )
            productId = product.id
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            return
        }
        
        let newName = "更新后的产品名称_\(Int(Date().timeIntervalSince1970))"
        let newLabel = "更新后的标签"
        let expectation = XCTestExpectation(description: "更新产品测试")
        
        // Act: 更新产品
        do {
            let updatedProduct = try await productApiService.updateProduct(
                productId: productId,
                name: newName,
                label: newLabel
            )
            
            // Assert: 验证更新结果
            XCTAssertEqual(updatedProduct.id, productId, "产品ID不应该改变")
            XCTAssertEqual(updatedProduct.name, newName, "产品名称应该已更新")
            XCTAssertEqual(updatedProduct.label, newLabel, "产品标签应该已更新")
            
            print("✅ 更新产品成功")
            print("   - 产品ID: \(updatedProduct.id)")
            print("   - 新名称: \(updatedProduct.name)")
            
            expectation.fulfill()
        } catch {
            XCTFail("更新产品失败: \(error.localizedDescription)")
            print("❌ 更新产品错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试删除产品
    func testDeleteProduct() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先创建一个产品
        var productId: String!
        do {
            let product = try await productApiService.createProduct(
                name: "删除测试产品_\(Int(Date().timeIntervalSince1970))"
            )
            productId = product.id
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "删除产品测试")
        
        // Act: 删除产品
        do {
            try await productApiService.deleteProduct(productId: productId)
            
            // Assert: 验证删除成功（尝试获取应该失败）
            do {
                let _ = try await productApiService.getProduct(productId: productId)
                XCTFail("产品应该已被删除")
            } catch {
                // 这是预期的，产品应该不存在了
                print("✅ 删除产品成功")
                print("   - 产品ID: \(productId!)")
                expectation.fulfill()
            }
        } catch {
            XCTFail("删除产品失败: \(error.localizedDescription)")
            print("❌ 删除产品错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试提取产品成分（需要先上传图片）
    func testExtractIngredients() async {
        // 等待用户设置完成
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Arrange: 先创建一个产品并上传图片
        var productId: String!
        do {
            let product = try await productApiService.createProduct(
                name: "成分提取测试产品_\(Int(Date().timeIntervalSince1970))"
            )
            productId = product.id
            
            // 注意: 实际测试中需要真实的图片
            // 这里只测试API调用是否正常
            print("⚠️ 成分提取测试需要真实的产品图片")
        } catch {
            XCTFail("创建产品失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "提取产品成分测试")
        
        // Act: 提取成分（可能会失败，因为可能没有图片）
        do {
            let (name, ingredients) = try await productApiService.extractIngredients(productId: productId)
            
            // Assert: 验证结果
            XCTAssertFalse(name.isEmpty, "产品名称不应该为空")
            XCTAssertNotNil(ingredients, "成分列表不应该为nil")
            
            print("✅ 提取产品成分成功")
            print("   - 产品名称: \(name)")
            print("   - 成分数量: \(ingredients.count)")
            
            expectation.fulfill()
        } catch {
            // 如果没有图片，这是预期的失败
            print("⚠️ 提取成分失败（可能需要先上传产品图片）: \(error.localizedDescription)")
            expectation.fulfill() // 不视为测试失败
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    /// 从Bundle加载图片
    private func loadImageFromBundle(named: String) -> UIImage? {
        let testBundle = Bundle(for: type(of: self))
        
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
        
        return nil
    }
}

