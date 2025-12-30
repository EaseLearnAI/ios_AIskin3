//
//  ConflictApiService.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation

/// 冲突分析API响应数据结构
struct ConflictAnalysisResponse: Codable {
    var success: Bool
    var message: String?
    var data: ConflictAnalysisData?
}

/// 冲突分析中的产品信息
struct ConflictProductInfo: Codable {
    var id: String?
    var name: String?
    var description: String?
    var imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageUrl
    }
}

struct ConflictAnalysisData: Codable {
    var conflictId: String?
    var conflicts: [Conflict]?
    var safeCombo: [SafeCombo]?
    var recommendations: ConflictRecommendations?
    var products: [ConflictProductInfo]?
}

/// 冲突分析列表响应
struct ConflictsListResponse: Codable {
    var success: Bool
    var count: Int?
    var data: ConflictsListData?
}

struct ConflictsListData: Codable {
    var conflicts: [ConflictRecord]
}

struct ConflictRecord: Codable, Identifiable {
    var id: String?
    var products: [ConflictProductInfo]?
    var conflicts: [Conflict]?
    var safeCombo: [SafeCombo]?
    var recommendations: ConflictRecommendations?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case products
        case conflicts
        case safeCombo
        case recommendations
        case createdAt
    }
}

/// 冲突分析详情响应
struct ConflictDetailResponse: Codable {
    var success: Bool
    var data: ConflictDetailData?
}

struct ConflictDetailData: Codable {
    var conflict: ConflictRecord?
}

/// 分析产品冲突请求
struct AnalyzeConflictRequest: Codable {
    var productIds: [String]
}

/// 产品冲突检测API服务
class ConflictApiService {
    static let shared = ConflictApiService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 分析产品冲突
    func analyzeConflict(productIds: [String]) async throws -> ConflictAnalysisData {
        print("\n============================================================")
        print("⚠️ 步骤: 分析产品冲突")
        print("============================================================\n")
        
        print("📡 发起冲突分析请求")
        print("📊 分析产品列表:")
        for (index, productId) in productIds.enumerated() {
            print("   \(index + 1). 产品ID: \(productId)")
        }
        
        let request = AnalyzeConflictRequest(productIds: productIds)
        
        // 打印请求详情
        if let requestData = try? JSONEncoder().encode(request),
           let requestString = String(data: requestData, encoding: .utf8) {
            print("📦 Request Body: \(requestString)")
        }
        
        print("\n📡 调用APIClient.post()方法")
        print("🔗 Endpoint: POST /conflicts")
        print("🔐 需要认证: true")
        print("⏳ 等待API响应...\n")
        
        let response: ConflictAnalysisResponse = try await apiClient.post(
            endpoint: "/conflicts",
            body: request,
            requiresAuth: true
        )
        
        print("\n📥 收到API响应")
        print("✅ Response.success: \(response.success)")
        if let message = response.message {
            print("📋 Response.message: \(message)")
        }
        
        guard response.success, let data = response.data else {
            print("\n❌ 冲突分析失败")
            print("📋 错误信息: \(response.message ?? "未知错误")")
            print("📋 Response.data: \(response.data != nil ? "有数据" : "无数据")")
            throw APIError.serverError(response.message ?? "冲突分析失败")
        }
        
        print("✅ Response.data存在，开始解析数据...")
        
        print("\n✅ 冲突分析成功")
        print("📋 分析结果详情:")
        print("   - 冲突记录ID: \(data.conflictId ?? "未知")")
        print("   - 发现冲突数: \(data.conflicts?.count ?? 0)")
        print("   - 安全组合数: \(data.safeCombo?.count ?? 0)")
        print("   - 涉及产品数: \(data.products?.count ?? 0)")
        
        // 打印产品信息
        if let products = data.products, !products.isEmpty {
            print("\n📦 涉及的产品:")
            for (index, product) in products.enumerated() {
                print("   \(index + 1). \(product.name ?? "未知产品") (ID: \(product.id ?? "未知"))")
            }
        }
        
        // 打印冲突详情
        if let conflicts = data.conflicts, !conflicts.isEmpty {
            print("\n⚠️ 检测到的冲突:")
            for (index, conflict) in conflicts.enumerated() {
                print("   \(index + 1). 冲突成分: \(conflict.components.joined(separator: " + "))")
                print("      严重程度: \(conflict.severity)度风险")
                print("      描述: \(conflict.description)")
                if let effects = conflict.effects, !effects.isEmpty {
                    print("      影响:")
                    for effect in effects {
                        print("        • \(effect)")
                    }
                }
            }
        } else {
            print("\n✅ 未检测到冲突")
        }
        
        // 打印安全组合
        if let safeCombo = data.safeCombo, !safeCombo.isEmpty {
            print("\n✅ 安全组合:")
            for (index, combo) in safeCombo.enumerated() {
                print("   \(index + 1). \(combo.components.joined(separator: " + "))")
                print("      描述: \(combo.description)")
            }
        }
        
        // 打印使用建议
        if let recommendations = data.recommendations {
            print("\n💡 使用建议:")
            
            if let pairings = recommendations.productPairings {
                if let cannotUse = pairings.cannotUseTogether, !cannotUse.isEmpty {
                    print("\n   🚫 不能一起使用:")
                    for (index, item) in cannotUse.enumerated() {
                        print("      \(index + 1). \(item.products.joined(separator: " + "))")
                        print("         原因: \(item.reason)")
                    }
                }
                
                if let canUse = pairings.canUseTogether, !canUse.isEmpty {
                    print("\n   ✅ 可以一起使用:")
                    for (index, item) in canUse.enumerated() {
                        print("      \(index + 1). \(item.products.joined(separator: " + "))")
                        print("         原因: \(item.reason)")
                    }
                }
            }
            
            if let routines = recommendations.routines {
                if let morning = routines.morning, !morning.isEmpty {
                    print("\n   ☀️ 早晨护肤步骤:")
                    for (index, step) in morning.enumerated() {
                        print("      \(index + 1). \(step)")
                    }
                }
                
                if let evening = routines.evening, !evening.isEmpty {
                    print("\n   🌙 晚上护肤步骤:")
                    for (index, step) in evening.enumerated() {
                        print("      \(index + 1). \(step)")
                    }
                }
            }
        }
        
        print("\n============================================================")
        print("✅ 冲突分析完成")
        print("============================================================\n")
        
        return data
    }
    
    /// 获取用户的所有冲突分析记录
    func getUserConflicts() async throws -> [ConflictRecord] {
        print("\n============================================================")
        print("📚 步骤: 获取用户冲突分析记录")
        print("============================================================\n")
        
        print("📡 发起获取冲突记录请求")
        print("🔗 Endpoint: GET /conflicts")
        
        let response: ConflictsListResponse = try await apiClient.get(
            endpoint: "/conflicts",
            requiresAuth: true
        )
        
        guard response.success, let conflicts = response.data?.conflicts else {
            print("\n❌ 获取冲突记录失败")
            throw APIError.serverError("获取冲突记录失败")
        }
        
        print("\n✅ 获取冲突记录成功")
        print("📋 冲突记录信息:")
        print("   - 记录总数: \(conflicts.count)")
        print("   - 响应中的count: \(response.count ?? 0)")
        
        for (index, conflict) in conflicts.enumerated() {
            print("\n   📋 记录 \(index + 1):")
            print("      - 记录ID: \(conflict.id ?? "未知")")
            print("      - 涉及产品数: \(conflict.products?.count ?? 0)")
            print("      - 冲突数量: \(conflict.conflicts?.count ?? 0)")
            print("      - 安全组合数: \(conflict.safeCombo?.count ?? 0)")
            print("      - 创建时间: \(conflict.createdAt?.description ?? "未知")")
            
            if let products = conflict.products, !products.isEmpty {
                print("      - 产品列表:")
                for product in products {
                    print("        • \(product.name ?? "未知") (ID: \(product.id ?? "未知"))")
                }
            }
        }
        
        print("\n============================================================")
        print("✅ 获取冲突记录完成")
        print("============================================================\n")
        
        return conflicts
    }
    
    /// 获取单个冲突分析详情
    func getConflict(conflictId: String) async throws -> ConflictRecord {
        print("\n============================================================")
        print("🔍 步骤: 获取冲突分析详情")
        print("============================================================\n")
        
        print("📡 发起获取冲突详情请求")
        print("📊 冲突记录ID: \(conflictId)")
        print("🔗 Endpoint: GET /conflicts/\(conflictId)")
        
        let response: ConflictDetailResponse = try await apiClient.get(
            endpoint: "/conflicts/\(conflictId)",
            requiresAuth: true
        )
        
        guard response.success, let data = response.data, let conflict = data.conflict else {
            print("\n❌ 获取冲突详情失败")
            throw APIError.serverError("获取冲突详情失败")
        }
        
        print("\n✅ 获取冲突详情成功")
        print("📋 冲突详情:")
        print("   - 冲突记录ID: \(conflict.id ?? "未知")")
        print("   - 涉及产品数: \(conflict.products?.count ?? 0)")
        print("   - 冲突数量: \(conflict.conflicts?.count ?? 0)")
        print("   - 安全组合数: \(conflict.safeCombo?.count ?? 0)")
        print("   - 创建时间: \(conflict.createdAt?.description ?? "未知")")
        
        if let products = conflict.products, !products.isEmpty {
            print("\n📦 涉及的产品:")
            for (index, product) in products.enumerated() {
                print("   \(index + 1). \(product.name ?? "未知产品") (ID: \(product.id ?? "未知"))")
            }
        }
        
        if let conflicts = conflict.conflicts, !conflicts.isEmpty {
            print("\n⚠️ 冲突详情:")
            for (index, conflictItem) in conflicts.enumerated() {
                print("   \(index + 1). \(conflictItem.components.joined(separator: " + ")) - \(conflictItem.severity)度风险")
            }
        }
        
        print("\n============================================================")
        print("✅ 获取冲突详情完成")
        print("============================================================\n")
        
        return conflict
    }
    
    /// 删除冲突分析记录
    func deleteConflict(conflictId: String) async throws {
        print("\n============================================================")
        print("🗑️ 步骤: 删除冲突分析记录")
        print("============================================================\n")
        
        print("📡 发起删除冲突记录请求")
        print("📊 冲突记录ID: \(conflictId)")
        print("🔗 Endpoint: DELETE /conflicts/\(conflictId)")
        
        struct DeleteResponse: Codable {
            var success: Bool
            var message: String?
        }
        
        let response: DeleteResponse = try await apiClient.delete(
            endpoint: "/conflicts/\(conflictId)",
            requiresAuth: true
        )
        
        guard response.success else {
            print("\n❌ 删除冲突记录失败")
            print("📋 错误信息: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "删除冲突记录失败")
        }
        
        print("\n✅ 删除冲突记录成功")
        if let message = response.message {
            print("📋 响应消息: \(message)")
        }
        
        print("\n============================================================")
        print("✅ 删除冲突记录完成")
        print("============================================================\n")
    }
}

