//
//  PlanApiService.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation

/// 护肤方案API响应数据结构
struct PlanResponse: Codable {
    var success: Bool
    var message: String?
    var data: PlanData?
}

struct PlanData: Codable {
    var plan: SkinPlan
}

struct PlansListResponse: Codable {
    var success: Bool
    var count: Int?
    var data: PlansListData?
}

struct PlansListData: Codable {
    var plans: [SkinPlan]
}

/// 创建护肤方案请求
struct CreatePlanRequest: Codable {
    var requirement: String?
    var userAge: Int?
    var skinConcerns: [String]?
    var customRequirements: String?
}

/// 创建自定义方案请求
struct CreateCustomPlanRequest: Codable {
    var name: String
    var morning: [RoutineItem]
    var evening: [RoutineItem]
    var recommendations: [String]?
    var tags: [String]?
    var notes: String?
}

/// 更新步骤完成状态请求
struct UpdateStepRequest: Codable {
    var period: String  // "morning" 或 "evening"
    var step: Int       // 步骤编号（从1开始）
    var completed: Bool
}

/// 护肤方案API服务
class PlanApiService {
    static let shared = PlanApiService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 生成个性化护肤方案
    func createPlan(
        requirement: String? = nil,
        userAge: Int? = nil,
        skinConcerns: [String]? = nil,
        customRequirements: String? = nil
    ) async throws -> SkinPlan {
        print("🎯 创建个性化护肤方案API调用开始")
        print("📊 方案需求:")
        print("   - 需求描述: \(requirement ?? "默认需求")")
        print("   - 用户年龄: \(userAge?.description ?? "未设置")")
        print("   - 护肤关注点: \(skinConcerns?.joined(separator: ", ") ?? "未设置")")
        
        let request = CreatePlanRequest(
            requirement: requirement,
            userAge: userAge,
            skinConcerns: skinConcerns,
            customRequirements: customRequirements
        )
        
        let response: PlanResponse = try await apiClient.post(
            endpoint: "/plans",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let plan = response.data?.plan else {
            print("❌ 创建方案失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "创建方案失败")
        }
        
        print("✅ 方案创建成功")
        print("📋 方案详情:")
        print("   - 方案ID: \(plan.id)")
        print("   - 方案名称: \(plan.name)")
        print("   - 早晨步骤数: \(plan.morning.count)")
        print("   - 晚间步骤数: \(plan.evening.count)")
        print("   - 推荐建议数: \(plan.recommendations.count)")
        
        return plan
    }
    
    /// 获取用户的所有护肤方案
    func getUserPlans() async throws -> [SkinPlan] {
        print("🎯 获取用户护肤方案列表API调用开始")
        
        let response: PlansListResponse = try await apiClient.get(
            endpoint: "/plans",
            requiresAuth: true
        )
        
        guard response.success, let plans = response.data?.plans else {
            print("❌ 获取方案列表失败")
            throw APIError.serverError("获取方案列表失败")
        }
        
        print("✅ 获取方案列表成功")
        print("📋 方案信息:")
        print("   - 方案总数: \(plans.count)")
        for plan in plans {
            print("     • \(plan.name) (ID: \(plan.id))")
        }
        
        return plans
    }
    
    /// 获取单个护肤方案详情
    func getPlan(planId: String) async throws -> SkinPlan {
        print("🎯 获取护肤方案详情API调用开始")
        print("📊 方案ID: \(planId)")
        
        let response: PlanResponse = try await apiClient.get(
            endpoint: "/plans/\(planId)",
            requiresAuth: true
        )
        
        guard response.success, let plan = response.data?.plan else {
            print("❌ 获取方案详情失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "获取方案详情失败")
        }
        
        print("✅ 获取方案详情成功")
        print("📋 方案详情:")
        print("   - 方案名称: \(plan.name)")
        print("   - 早晨步骤数: \(plan.morning.count)")
        print("   - 晚间步骤数: \(plan.evening.count)")
        
        return plan
    }
    
    /// 更新护肤计划某个步骤的完成状态
    func updateStepCompleted(
        planId: String,
        period: String,  // "morning" 或 "evening"
        step: Int,       // 步骤编号（从1开始）
        completed: Bool
    ) async throws -> SkinPlan {
        print("🎯 更新步骤完成状态API调用开始")
        print("📊 更新信息:")
        print("   - 方案ID: \(planId)")
        print("   - 时间段: \(period)")
        print("   - 步骤编号: \(step)")
        print("   - 完成状态: \(completed ? "已完成" : "未完成")")
        
        let request = UpdateStepRequest(
            period: period,
            step: step,
            completed: completed
        )
        
        let response: PlanResponse = try await apiClient.patch(
            endpoint: "/plans/\(planId)/step",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let plan = response.data?.plan else {
            print("❌ 更新步骤状态失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "更新步骤状态失败")
        }
        
        print("✅ 更新步骤状态成功")
        
        return plan
    }
    
    /// 创建自定义护肤方案（不经过AI）
    func createCustomPlan(
        name: String,
        morning: [RoutineItem],
        evening: [RoutineItem],
        recommendations: [String]? = nil,
        tags: [String]? = nil,
        notes: String? = nil
    ) async throws -> SkinPlan {
        print("🎯 创建自定义护肤方案API调用开始")
        print("📊 方案信息:")
        print("   - 方案名称: \(name)")
        print("   - 早晨步骤数: \(morning.count)")
        print("   - 晚间步骤数: \(evening.count)")
        
        let request = CreateCustomPlanRequest(
            name: name,
            morning: morning,
            evening: evening,
            recommendations: recommendations,
            tags: tags,
            notes: notes
        )
        
        let response: PlanResponse = try await apiClient.post(
            endpoint: "/plans/custom",
            body: request,
            requiresAuth: true
        )
        
        guard response.success, let plan = response.data?.plan else {
            print("❌ 创建自定义方案失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "创建自定义方案失败")
        }
        
        print("✅ 创建自定义方案成功")
        print("📋 方案ID: \(plan.id)")
        
        return plan
    }
    
    /// 删除护肤方案
    func deletePlan(planId: String) async throws {
        print("🎯 删除护肤方案API调用开始")
        print("📊 方案ID: \(planId)")
        
        struct DeleteResponse: Codable {
            var success: Bool
            var message: String?
        }
        
        let response: DeleteResponse = try await apiClient.delete(
            endpoint: "/plans/\(planId)",
            requiresAuth: true
        )
        
        guard response.success else {
            print("❌ 删除方案失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "删除方案失败")
        }
        
        print("✅ 删除方案成功")
    }
}




