//
//  AuthService.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    private let tokenKey = "authToken"
    private let userKey = "currentUser"
    private let userApiService = UserApiService.shared
    
    private init() {
        loadAuthState()
    }
    
    /// 用户注册（使用邮箱）
    func register(name: String, email: String, password: String) async throws {
        print("🎯 开始用户注册流程")
        let (token, user) = try await userApiService.register(name: name, email: email, password: password)
        login(token: token, user: user)
    }
    
    /// 用户注册（使用手机号）
    func register(name: String, phone: String, password: String, gender: String?) async throws {
        print("🎯 开始用户注册流程（手机号）")
        let (token, user) = try await userApiService.register(name: name, phone: phone, password: password, gender: gender)
        login(token: token, user: user)
    }
    
    /// 用户登录（使用邮箱）
    func login(email: String, password: String) async throws {
        print("🎯 开始用户登录流程")
        let (token, user) = try await userApiService.login(email: email, password: password)
        login(token: token, user: user)
    }
    
    /// 用户登录（使用手机号）
    func login(phone: String, password: String) async throws {
        print("🎯 开始用户登录流程（手机号）")
        let (token, user) = try await userApiService.login(phone: phone, password: password)
        login(token: token, user: user)
    }
    
    /// 内部登录方法（设置token和user）
    func login(token: String, user: User) {
        print("🔐 保存认证信息")
        UserDefaults.standard.set(token, forKey: tokenKey)
        saveUser(user)
        self.currentUser = user
        self.isAuthenticated = true
        print("✅ 认证信息已保存")
    }
    
    /// 用户登出
    func logout() async throws {
        print("🎯 开始用户登出流程")
        do {
            try await userApiService.logout()
        } catch {
            print("⚠️ 服务器登出失败，继续本地登出: \(error.localizedDescription)")
        }
        
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        self.currentUser = nil
        self.isAuthenticated = false
        print("✅ 登出成功")
    }
    
    /// 注销账号（永久删除账号及所有数据）
    func deleteAccount() async throws {
        print("🎯 开始账号注销流程")
        print("⚠️ 警告: 此操作将永久删除账号及所有相关数据，不可恢复")
        
        do {
            try await userApiService.deleteAccount()
        } catch {
            print("❌ 注销账号失败: \(error.localizedDescription)")
            throw error
        }
        
        // 清除本地数据
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        self.currentUser = nil
        self.isAuthenticated = false
        print("✅ 账号注销成功，本地数据已清除")
    }
    
    /// 获取当前用户信息（从服务器刷新）
    func refreshCurrentUser() async throws {
        print("🎯 刷新当前用户信息")
        let user = try await userApiService.getCurrentUser()
        self.currentUser = user
        saveUser(user)
        print("✅ 用户信息已刷新")
    }
    
    /// 更新用户名
    func updateUsername(name: String) async throws {
        print("🎯 更新用户名")
        let user = try await userApiService.updateUsername(name: name)
        self.currentUser = user
        saveUser(user)
        print("✅ 用户名已更新")
    }
    
    /// 更新性别
    func updateGender(gender: String) async throws {
        print("🎯 更新性别")
        let user = try await userApiService.updateGender(gender: gender)
        self.currentUser = user
        saveUser(user)
        print("✅ 性别已更新")
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }
    
    func getCurrentUser() -> User? {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            return user
        }
        return nil
    }
    
    private func loadAuthState() {
        if let token = getToken(), !token.isEmpty {
            self.isAuthenticated = true
            self.currentUser = getCurrentUser()
            print("✅ 已加载保存的认证状态")
        }
    }
}

