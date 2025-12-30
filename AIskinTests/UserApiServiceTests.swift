//
//  UserApiServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin

/// UserApiService单元测试
/// 测试用户相关的API服务功能
class UserApiServiceTests: XCTestCase {
    
    var userApiService: UserApiService!
    var testEmail: String!
    var testPassword: String!
    var testName: String!
    
    override func setUp() {
        super.setUp()
        userApiService = UserApiService.shared
        
        // 生成测试用的唯一邮箱和用户名
        let timestamp = Int(Date().timeIntervalSince1970)
        testEmail = "test_\(timestamp)@example.com"
        testPassword = "TestPassword123"
        testName = "测试用户_\(timestamp)"
        
        print("✅ UserApiService测试环境已设置")
        print("📧 测试邮箱: \(testEmail!)")
    }
    
    override func tearDown() {
        userApiService = nil
        testEmail = nil
        testPassword = nil
        testName = nil
        super.tearDown()
        print("✅ UserApiService测试环境已清理")
    }
    
    // MARK: - 用户注册测试
    
    /// 测试用户注册功能
    func testUserRegistration() async {
        // Arrange: 准备测试数据
        let expectation = XCTestExpectation(description: "用户注册测试")
        
        // Act: 执行注册
        do {
            let (token, user) = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            
            // Assert: 验证注册结果
            XCTAssertNotNil(token, "应该返回token")
            XCTAssertFalse(token.isEmpty, "token不应该为空")
            XCTAssertEqual(user.email, testEmail, "用户邮箱应该匹配")
            XCTAssertEqual(user.name, testName, "用户名称应该匹配")
            XCTAssertFalse(user.id.isEmpty, "用户ID不应该为空")
            
            print("✅ 用户注册成功")
            print("   - 用户ID: \(user.id)")
            print("   - Token已获取: \(token.prefix(20))...")
            
            expectation.fulfill()
        } catch {
            XCTFail("用户注册失败: \(error.localizedDescription)")
            print("❌ 注册错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试重复注册（应该失败）
    func testDuplicateRegistration() async {
        // Arrange: 先注册一个用户
        do {
            let _ = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("首次注册应该成功: \(error.localizedDescription)")
            return
        }
        
        // Act: 尝试用相同邮箱再次注册
        do {
            let _ = try await userApiService.register(
                name: "另一个用户",
                email: testEmail, // 相同邮箱
                password: "AnotherPassword123"
            )
            
            // Assert: 应该失败
            XCTFail("重复注册应该失败")
        } catch {
            // Assert: 验证错误类型
            print("✅ 重复注册正确被拒绝")
            XCTAssertTrue(error.localizedDescription.contains("已被注册") || 
                         error.localizedDescription.contains("已存在"),
                         "应该返回邮箱已存在的错误")
        }
    }
    
    // MARK: - 用户登录测试
    
    /// 测试用户登录功能
    func testUserLogin() async {
        // Arrange: 先注册用户
        do {
            let _ = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败，无法继续登录测试: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "用户登录测试")
        
        // Act: 执行登录
        do {
            let (token, user) = try await userApiService.login(
                email: testEmail,
                password: testPassword
            )
            
            // Assert: 验证登录结果
            XCTAssertNotNil(token, "应该返回token")
            XCTAssertFalse(token.isEmpty, "token不应该为空")
            XCTAssertEqual(user.email, testEmail, "用户邮箱应该匹配")
            XCTAssertEqual(user.name, testName, "用户名称应该匹配")
            
            print("✅ 用户登录成功")
            print("   - 用户ID: \(user.id)")
            print("   - Token已获取")
            
            expectation.fulfill()
        } catch {
            XCTFail("用户登录失败: \(error.localizedDescription)")
            print("❌ 登录错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试错误密码登录（应该失败）
    func testLoginWithWrongPassword() async {
        // Arrange: 先注册用户
        do {
            let _ = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        // Act: 使用错误密码登录
        do {
            let _ = try await userApiService.login(
                email: testEmail,
                password: "WrongPassword123"
            )
            
            // Assert: 应该失败
            XCTFail("使用错误密码登录应该失败")
        } catch {
            // Assert: 验证错误
            print("✅ 错误密码登录正确被拒绝")
            XCTAssertTrue(error.localizedDescription.contains("密码") || 
                         error.localizedDescription.contains("不正确"),
                         "应该返回密码错误")
        }
    }
    
    // MARK: - 获取用户信息测试
    
    /// 测试获取当前用户信息
    func testGetCurrentUser() async {
        // Arrange: 先注册并登录
        var token: String!
        do {
            let (t, _) = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            token = t
            // 保存token到UserDefaults以便APIClient使用
            UserDefaults.standard.set(token, forKey: "authToken")
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "获取用户信息测试")
        
        // Act: 获取用户信息
        do {
            let user = try await userApiService.getCurrentUser()
            
            // Assert: 验证用户信息
            XCTAssertEqual(user.email, testEmail, "用户邮箱应该匹配")
            XCTAssertEqual(user.name, testName, "用户名称应该匹配")
            XCTAssertFalse(user.id.isEmpty, "用户ID不应该为空")
            
            print("✅ 获取用户信息成功")
            print("   - 用户ID: \(user.id)")
            print("   - 用户名: \(user.name)")
            
            expectation.fulfill()
        } catch {
            XCTFail("获取用户信息失败: \(error.localizedDescription)")
            print("❌ 获取用户信息错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // 清理
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    // MARK: - 更新用户信息测试
    
    /// 测试更新用户名
    func testUpdateUsername() async {
        // Arrange: 先注册并登录
        var token: String!
        do {
            let (t, _) = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            token = t
            UserDefaults.standard.set(token, forKey: "authToken")
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let newName = "新用户名_\(Int(Date().timeIntervalSince1970))"
        let expectation = XCTestExpectation(description: "更新用户名测试")
        
        // Act: 更新用户名
        do {
            let updatedUser = try await userApiService.updateUsername(name: newName)
            
            // Assert: 验证更新结果
            XCTAssertEqual(updatedUser.name, newName, "用户名应该已更新")
            XCTAssertEqual(updatedUser.email, testEmail, "邮箱不应该改变")
            
            print("✅ 更新用户名成功")
            print("   - 新用户名: \(updatedUser.name)")
            
            expectation.fulfill()
        } catch {
            XCTFail("更新用户名失败: \(error.localizedDescription)")
            print("❌ 更新用户名错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // 清理
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
    
    /// 测试更新性别
    func testUpdateGender() async {
        // Arrange: 先注册并登录
        var token: String!
        do {
            let (t, _) = try await userApiService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            token = t
            UserDefaults.standard.set(token, forKey: "authToken")
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "更新性别测试")
        
        // Act: 更新性别
        do {
            let updatedUser = try await userApiService.updateGender(gender: "female")
            
            // Assert: 验证更新结果
            XCTAssertEqual(updatedUser.gender, "female", "性别应该已更新")
            
            print("✅ 更新性别成功")
            print("   - 新性别: \(updatedUser.gender ?? "未设置")")
            
            expectation.fulfill()
        } catch {
            XCTFail("更新性别失败: \(error.localizedDescription)")
            print("❌ 更新性别错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // 清理
        UserDefaults.standard.removeObject(forKey: "authToken")
    }
}




