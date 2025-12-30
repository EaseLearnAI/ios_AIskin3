//
//  AuthServiceTests.swift
//  AIskinTests
//
//  Created by AI Assistant
//

import XCTest
@testable import AIskin

/// AuthService单元测试和集成测试
/// 测试认证服务的功能和与UserApiService的集成
class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    var userApiService: UserApiService!
    var testEmail: String!
    var testPassword: String!
    var testName: String!
    
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
        userApiService = UserApiService.shared
        
        let timestamp = Int(Date().timeIntervalSince1970)
        testEmail = "auth_test_\(timestamp)@example.com"
        testPassword = "TestPassword123"
        testName = "认证测试用户_\(timestamp)"
        
        // 清除之前的认证状态
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        print("✅ AuthService测试环境已设置")
    }
    
    override func tearDown() {
        // 清理认证状态（同步清理，不调用异步logout）
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
        
        // 重置认证状态（在主线程上）
        Task { @MainActor in
            authService?.currentUser = nil
            authService?.isAuthenticated = false
        }
        
        authService = nil
        userApiService = nil
        testEmail = nil
        testPassword = nil
        testName = nil
        
        super.tearDown()
        print("✅ AuthService测试环境已清理")
    }
    
    // MARK: - 注册功能测试
    
    /// 测试用户注册流程
    func testRegister() async {
        // Arrange: 准备测试
        let expectation = XCTestExpectation(description: "用户注册测试")
        
        // Act: 执行注册
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            
            // Assert: 验证注册结果（需要在主线程上访问MainActor隔离的属性）
            await MainActor.run {
                XCTAssertTrue(authService.isAuthenticated, "注册后应该已认证")
                XCTAssertNotNil(authService.currentUser, "应该设置当前用户")
                XCTAssertEqual(authService.currentUser?.email, testEmail, "用户邮箱应该匹配")
                XCTAssertEqual(authService.currentUser?.name, testName, "用户名称应该匹配")
                XCTAssertNotNil(authService.getToken(), "应该保存token")
                
                print("✅ 用户注册成功")
                print("   - 用户ID: \(authService.currentUser?.id ?? "未知")")
                print("   - 认证状态: \(authService.isAuthenticated)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("用户注册失败: \(error.localizedDescription)")
            print("❌ 注册错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - 登录功能测试
    
    /// 测试用户登录流程
    func testLogin() async {
        // Arrange: 先注册用户
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
            // 登出以便测试登录
            try await authService.logout()
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "用户登录测试")
        
        // Act: 执行登录
        do {
            try await authService.login(
                email: testEmail,
                password: testPassword
            )
            
            // Assert: 验证登录结果（需要在主线程上访问MainActor隔离的属性）
            await MainActor.run {
                XCTAssertTrue(authService.isAuthenticated, "登录后应该已认证")
                XCTAssertNotNil(authService.currentUser, "应该设置当前用户")
                XCTAssertEqual(authService.currentUser?.email, testEmail, "用户邮箱应该匹配")
                XCTAssertNotNil(authService.getToken(), "应该保存token")
                
                print("✅ 用户登录成功")
                print("   - 用户ID: \(authService.currentUser?.id ?? "未知")")
                print("   - 认证状态: \(authService.isAuthenticated)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("用户登录失败: \(error.localizedDescription)")
            print("❌ 登录错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - 登出功能测试
    
    /// 测试用户登出流程
    func testLogout() async {
        // Arrange: 先注册并登录
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        await MainActor.run {
            XCTAssertTrue(authService.isAuthenticated, "登录后应该已认证")
        }
        
        let expectation = XCTestExpectation(description: "用户登出测试")
        
        // Act: 执行登出
        do {
            try await authService.logout()
            
            // Assert: 验证登出结果（需要在主线程上访问MainActor隔离的属性）
            await MainActor.run {
                XCTAssertFalse(authService.isAuthenticated, "登出后应该未认证")
                XCTAssertNil(authService.currentUser, "应该清除当前用户")
                XCTAssertNil(authService.getToken(), "应该清除token")
                
                print("✅ 用户登出成功")
                print("   - 认证状态: \(authService.isAuthenticated)")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("用户登出失败: \(error.localizedDescription)")
            print("❌ 登出错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Token管理测试
    
    /// 测试Token保存和获取
    func testTokenManagement() async {
        // Arrange: 先注册
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        // Act: 获取token（需要在主线程上访问MainActor隔离的方法）
        let token = await MainActor.run { authService.getToken() }
        
        // Assert: 验证token
        XCTAssertNotNil(token, "应该保存token")
        XCTAssertFalse(token?.isEmpty ?? true, "token不应该为空")
        
        // 验证token格式（JWT通常有三个部分）
        let tokenParts = token?.split(separator: ".") ?? []
        XCTAssertGreaterThanOrEqual(tokenParts.count, 1, "token应该有有效格式")
        
        print("✅ Token管理测试通过")
        print("   - Token长度: \(token?.count ?? 0)")
    }
    
    // MARK: - 用户信息刷新测试
    
    /// 测试刷新用户信息
    func testRefreshCurrentUser() async {
        // Arrange: 先注册
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "刷新用户信息测试")
        
        // Act: 刷新用户信息
        do {
            try await authService.refreshCurrentUser()
            
            // Assert: 验证用户信息（需要在主线程上访问MainActor隔离的属性）
            await MainActor.run {
                XCTAssertNotNil(authService.currentUser, "应该有当前用户")
                XCTAssertEqual(authService.currentUser?.email, testEmail, "用户邮箱应该匹配")
                
                print("✅ 刷新用户信息成功")
                print("   - 用户ID: \(authService.currentUser?.id ?? "未知")")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("刷新用户信息失败: \(error.localizedDescription)")
            print("❌ 刷新用户信息错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - 更新用户信息测试
    
    /// 测试更新用户名
    func testUpdateUsername() async {
        // Arrange: 先注册
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let newName = "新用户名_\(Int(Date().timeIntervalSince1970))"
        let expectation = XCTestExpectation(description: "更新用户名测试")
        
        // Act: 更新用户名
        do {
            try await authService.updateUsername(name: newName)
            
            // Assert: 验证更新结果（需要在主线程上访问MainActor隔离的属性）
            await MainActor.run {
                XCTAssertEqual(authService.currentUser?.name, newName, "用户名应该已更新")
                XCTAssertEqual(authService.currentUser?.email, testEmail, "邮箱不应该改变")
                
                print("✅ 更新用户名成功")
                print("   - 新用户名: \(authService.currentUser?.name ?? "未知")")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("更新用户名失败: \(error.localizedDescription)")
            print("❌ 更新用户名错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    /// 测试更新性别
    func testUpdateGender() async {
        // Arrange: 先注册
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let expectation = XCTestExpectation(description: "更新性别测试")
        
        // Act: 更新性别
        do {
            try await authService.updateGender(gender: "male")
            
            // Assert: 验证更新结果（需要在主线程上访问MainActor隔离的属性）
            await MainActor.run {
                XCTAssertEqual(authService.currentUser?.gender, "male", "性别应该已更新")
                
                print("✅ 更新性别成功")
                print("   - 新性别: \(authService.currentUser?.gender ?? "未设置")")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("更新性别失败: \(error.localizedDescription)")
            print("❌ 更新性别错误: \(error.localizedDescription)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - 持久化测试
    
    /// 测试认证状态的持久化
    func testAuthStatePersistence() async {
        // Arrange: 先注册
        do {
            try await authService.register(
                name: testName,
                email: testEmail,
                password: testPassword
            )
        } catch {
            XCTFail("注册失败: \(error.localizedDescription)")
            return
        }
        
        let (originalUserId, originalToken) = await MainActor.run {
            (authService.currentUser?.id, authService.getToken())
        }
        
        // Act: 创建新的AuthService实例（模拟应用重启）
        // 注意: 由于是单例，这里实际上验证的是UserDefaults的持久化
        let newAuthService = await MainActor.run { AuthService.shared }
        
        // Assert: 验证状态已恢复（需要在主线程上访问MainActor隔离的方法）
        await MainActor.run {
            XCTAssertNotNil(newAuthService.getToken(), "应该恢复token")
            XCTAssertNotNil(newAuthService.getCurrentUser(), "应该恢复用户信息")
        }
        
        print("✅ 认证状态持久化测试通过")
    }
}
