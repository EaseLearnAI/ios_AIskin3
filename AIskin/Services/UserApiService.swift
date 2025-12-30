//
//  UserApiService.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation
import Combine

/// 用户API响应数据结构
struct UserResponse: Codable {
    var success: Bool
    var message: String?
    var token: String?
    var data: UserData?
}

struct UserData: Codable {
    var user: User
}

/// 用户注册请求
struct RegisterRequest: Codable {
    var name: String
    var email: String?
    var phone: String?
    var password: String
    var gender: String?
}

/// 用户登录请求
struct LoginRequest: Codable {
    var email: String?
    var phone: String?
    var password: String
}

/// 更新用户名请求
struct UpdateUsernameRequest: Codable {
    var name: String
}

/// 用户统计响应
struct UserStatsResponse: Codable {
    var success: Bool
    var data: UserStatsData?
}

struct UserStatsData: Codable {
    var stats: UserStats
}

struct UserStats: Codable {
    var ideasCount: Int?
    var ideaCategories: [IdeaCategory]?
    var accountAge: Int?
}

struct IdeaCategory: Codable {
    var _id: String
    var count: Int
}

/// 用户API服务
class UserApiService {
    static let shared = UserApiService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 用户注册（使用邮箱）
    func register(name: String, email: String, password: String) async throws -> (token: String, user: User) {
        print("🎯 用户注册API调用开始")
        print("📊 注册数据:")
        print("   - 姓名: \(name)")
        print("   - 邮箱: \(email)")
        
        let request = RegisterRequest(name: name, email: email, phone: nil, password: password, gender: nil)
        let response: UserResponse = try await apiClient.post(
            endpoint: "/users/register",
            body: request,
            requiresAuth: false
        )
        
        guard response.success, let token = response.token, let user = response.data?.user else {
            print("❌ 注册失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "注册失败")
        }
        
        print("✅ 注册成功")
        print("📋 用户信息:")
        print("   - 用户ID: \(user.id)")
        print("   - 姓名: \(user.name)")
        print("   - 邮箱: \(user.email ?? "未设置")")
        
        return (token, user)
    }
    
    /// 用户注册（使用手机号）
    func register(name: String, phone: String, password: String, gender: String?) async throws -> (token: String, user: User) {
        print("🎯 用户注册API调用开始（手机号）")
        print("📊 注册数据:")
        print("   - 姓名: \(name)")
        print("   - 手机号: \(phone)")
        print("   - 性别: \(gender ?? "未设置")")
        
        // 如果API支持phone字段，使用phone；否则将phone作为email发送
        let request = RegisterRequest(name: name, email: nil, phone: phone, password: password, gender: gender)
        let response: UserResponse = try await apiClient.post(
            endpoint: "/users/register",
            body: request,
            requiresAuth: false
        )
        
        guard response.success, let token = response.token, let user = response.data?.user else {
            print("❌ 注册失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "注册失败")
        }
        
        print("✅ 注册成功")
        print("📋 用户信息:")
        print("   - 用户ID: \(user.id)")
        print("   - 姓名: \(user.name)")
        print("   - 手机号: \(user.phone ?? "未设置")")
        
        return (token, user)
    }
    
    /// 用户登录（使用邮箱）
    func login(email: String, password: String) async throws -> (token: String, user: User) {
        print("🎯 用户登录API调用开始")
        print("📊 登录数据:")
        print("   - 邮箱: \(email)")
        
        let request = LoginRequest(email: email, phone: nil, password: password)
        let response: UserResponse = try await apiClient.post(
            endpoint: "/users/login",
            body: request,
            requiresAuth: false
        )
        
        guard response.success, let token = response.token, let user = response.data?.user else {
            print("❌ 登录失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "登录失败")
        }
        
        print("✅ 登录成功")
        print("📋 用户信息:")
        print("   - 用户ID: \(user.id)")
        print("   - 姓名: \(user.name)")
        print("   - 邮箱: \(user.email ?? "未设置")")
        
        return (token, user)
    }
    
    /// 用户登录（使用手机号）
    func login(phone: String, password: String) async throws -> (token: String, user: User) {
        print("🎯 用户登录API调用开始（手机号）")
        print("📊 登录数据:")
        print("   - 手机号: \(phone)")
        
        // 如果API支持phone字段，使用phone；否则将phone作为email发送
        let request = LoginRequest(email: nil, phone: phone, password: password)
        let response: UserResponse = try await apiClient.post(
            endpoint: "/users/login",
            body: request,
            requiresAuth: false
        )
        
        guard response.success, let token = response.token, let user = response.data?.user else {
            print("❌ 登录失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "登录失败")
        }
        
        print("✅ 登录成功")
        print("📋 用户信息:")
        print("   - 用户ID: \(user.id)")
        print("   - 姓名: \(user.name)")
        print("   - 手机号: \(user.phone ?? "未设置")")
        
        return (token, user)
    }
    
    /// 获取当前用户信息
    func getCurrentUser() async throws -> User {
        print("🎯 获取当前用户信息API调用开始")
        
        let response: UserResponse = try await apiClient.get(
            endpoint: "/users/me",
            requiresAuth: true
        )
        
        guard response.success, let user = response.data?.user else {
            print("❌ 获取用户信息失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "获取用户信息失败")
        }
        
        print("✅ 获取用户信息成功")
        print("📋 用户信息:")
        print("   - 用户ID: \(user.id)")
        print("   - 姓名: \(user.name)")
        print("   - 邮箱: \(user.email ?? "未设置")")
        
        return user
    }
    
    /// 更新用户名
    func updateUsername(name: String) async throws -> User {
        print("🎯 更新用户名API调用开始")
        print("📊 新用户名: \(name)")
        
        let request = UpdateUsernameRequest(name: name)
        let response: UserResponse = try await apiClient.patch(
            endpoint: "/users/update-username",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let user = response.data?.user else {
            print("❌ 更新用户名失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "更新用户名失败")
        }
        
        print("✅ 更新用户名成功")
        print("📋 新用户名: \(user.name)")
        
        return user
    }
    
    /// 更新性别
    func updateGender(gender: String) async throws -> User {
        print("🎯 更新性别API调用开始")
        print("📊 新性别: \(gender)")
        
        struct UpdateGenderRequest: Codable {
            var gender: String
        }
        
        let request = UpdateGenderRequest(gender: gender)
        let response: UserResponse = try await apiClient.patch(
            endpoint: "/users/update-gender",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let user = response.data?.user else {
            print("❌ 更新性别失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "更新性别失败")
        }
        
        print("✅ 更新性别成功")
        
        return user
    }
    
    /// 更新年龄
    func updateAge(age: Int) async throws -> User {
        print("🎯 更新年龄API调用开始")
        print("📊 新年龄: \(age)")
        
        struct UpdateAgeRequest: Codable {
            var age: Int
        }
        
        let request = UpdateAgeRequest(age: age)
        let response: UserResponse = try await apiClient.patch(
            endpoint: "/users/update-age",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let user = response.data?.user else {
            print("❌ 更新年龄失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "更新年龄失败")
        }
        
        print("✅ 更新年龄成功")
        
        return user
    }
    
    /// 获取用户统计数据
    func getUserStats() async throws -> UserStats {
        print("🎯 获取用户统计数据API调用开始")
        
        let response: UserStatsResponse = try await apiClient.get(
            endpoint: "/users/stats",
            requiresAuth: true
        )
        
        guard response.success, let stats = response.data?.stats else {
            print("❌ 获取统计数据失败")
            throw APIError.serverError("获取统计数据失败")
        }
        
        print("✅ 获取统计数据成功")
        print("📊 统计数据:")
        print("   - 反馈数量: \(stats.ideasCount ?? 0)")
        print("   - 账户年龄: \(stats.accountAge ?? 0)天")
        
        return stats
    }
    
    /// 用户登出
    func logout() async throws {
        print("🎯 用户登出API调用开始")
        
        struct LogoutResponse: Codable {
            var success: Bool
            var message: String?
        }
        
        let response: LogoutResponse = try await apiClient.post(
            endpoint: "/users/logout",
            body: EmptyRequest(),
            requiresAuth: true
        )
        
        guard response.success else {
            print("❌ 登出失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "登出失败")
        }
        
        print("✅ 登出成功")
    }
    
    /// 注销账号（永久删除账号及所有数据）
    func deleteAccount() async throws {
        print("🎯 注销账号API调用开始")
        print("⚠️ 警告: 此操作将永久删除账号及所有相关数据")
        
        struct DeleteAccountResponse: Codable {
            var success: Bool
            var message: String?
            var data: String? // 通常为null
        }
        
        let response: DeleteAccountResponse = try await apiClient.delete(
            endpoint: "/users/delete-account",
            requiresAuth: true
        )
        
        guard response.success else {
            print("❌ 注销账号失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "注销账号失败")
        }
        
        print("✅ 注销账号成功")
        print("📋 服务器消息: \(response.message ?? "账号已删除")")
    }
}

struct EmptyRequest: Codable {}




