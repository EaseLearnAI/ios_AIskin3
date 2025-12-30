//
//  IngredientAnalysisApiService.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation

/// 成分分析API响应数据结构
struct IngredientAnalysisResponse: Codable {
    var success: Bool
    var message: String?
    var data: IngredientAnalysisData?
}

struct IngredientAnalysisData: Codable {
    var ingredientAnalysis: IngredientAnalysis
    var description: String?
}

/// 成分分析详情响应（包含产品信息）
struct IngredientAnalysisDetailResponse: Codable {
    var success: Bool
    var data: IngredientAnalysisDetailData?
}

struct IngredientAnalysisDetailData: Codable {
    var product: Product
    var ingredientAnalysis: IngredientAnalysis
}

/// 成分分析API服务
class IngredientAnalysisApiService {
    static let shared = IngredientAnalysisApiService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 分析产品成分
    func analyzeIngredients(productId: String) async throws -> IngredientAnalysis {
        print("\n===== 🧪 分析产品成分 ======")
        print("📊 产品ID: \(productId)")
        
        struct AnalyzeRequest: Codable {}
        
        let response: IngredientAnalysisResponse = try await apiClient.post(
            endpoint: "/products/\(productId)/analyze-ingredients",
            body: AnalyzeRequest(),
            requiresAuth: true
        )
        
        guard response.success, let data = response.data else {
            print("❌ 成分分析失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "成分分析失败")
        }
        
        print("✅ 成分分析成功")
        print("📋 分析结果详情:")
        print("   - 安全性指数: \(data.ingredientAnalysis.safetyIndex)")
        print("   - 功效评分: \(data.ingredientAnalysis.efficacyScore)")
        print("   - 活性成分数: \(data.ingredientAnalysis.activeIngredients)")
        print("   - 整体评级: \(data.ingredientAnalysis.overallRating)/5.0")
        print("   - 痘痘风险: \(data.ingredientAnalysis.acneRisk.level) (\(data.ingredientAnalysis.acneRisk.percentage)%)")
        print("   - 刺激风险: \(data.ingredientAnalysis.irritationRisk.level) (\(data.ingredientAnalysis.irritationRisk.percentage)%)")
        print("   - 过敏风险: \(data.ingredientAnalysis.allergyRisk.level) (\(data.ingredientAnalysis.allergyRisk.percentage)%)")
        print("   - 功效分析:")
        for (index, efficacy) in data.ingredientAnalysis.efficacyAnalysis.enumerated() {
            print("     \(index + 1). \(efficacy)")
        }
        print("   - 潜在风险:")
        for (index, risk) in data.ingredientAnalysis.potentialRisks.enumerated() {
            print("     \(index + 1). \(risk)")
        }
        print("   - 使用建议:")
        for (index, recommendation) in data.ingredientAnalysis.recommendations.enumerated() {
            print("     \(index + 1). \(recommendation)")
        }
        print("   - 总结: \(data.ingredientAnalysis.summary)")
        if let description = data.description {
            print("   - 更新后的产品描述: \(description)")
        }
        
        return data.ingredientAnalysis
    }
    
    /// 获取成分分析结果
    func getIngredientAnalysis(productId: String) async throws -> (product: Product, analysis: IngredientAnalysis) {
        print("\n===== 🧪 获取成分分析结果 ======")
        print("📊 产品ID: \(productId)")
        
        let response: IngredientAnalysisDetailResponse = try await apiClient.get(
            endpoint: "/products/\(productId)/ingredient-analysis",
            requiresAuth: true
        )
        
        guard response.success, let data = response.data else {
            print("❌ 获取成分分析结果失败")
            throw APIError.serverError("获取成分分析结果失败")
        }
        
        print("✅ 获取成分分析结果成功")
        print("📋 产品信息:")
        print("   - 产品ID: \(data.product.id)")
        print("   - 产品名称: \(data.product.name)")
        print("   - 产品描述: \(data.product.description ?? "无")")
        print("   - 产品标签: \(data.product.label ?? "未设置")")
        print("   - 成分数量: \(data.product.ingredients.count)")
        if data.product.ingredients.count > 0 {
            print("   - 成分列表: \(data.product.ingredients.prefix(5).joined(separator: ", "))\(data.product.ingredients.count > 5 ? "..." : "")")
        }
        print("📋 分析结果:")
        print("   - 安全性指数: \(data.ingredientAnalysis.safetyIndex)")
        print("   - 功效评分: \(data.ingredientAnalysis.efficacyScore)")
        print("   - 活性成分数: \(data.ingredientAnalysis.activeIngredients)")
        print("   - 整体评级: \(data.ingredientAnalysis.overallRating)/5.0")
        print("   - 痘痘风险: \(data.ingredientAnalysis.acneRisk.level) (\(data.ingredientAnalysis.acneRisk.percentage)%)")
        print("   - 刺激风险: \(data.ingredientAnalysis.irritationRisk.level) (\(data.ingredientAnalysis.irritationRisk.percentage)%)")
        print("   - 过敏风险: \(data.ingredientAnalysis.allergyRisk.level) (\(data.ingredientAnalysis.allergyRisk.percentage)%)")
        print("   - 功效分析数量: \(data.ingredientAnalysis.efficacyAnalysis.count)")
        print("   - 潜在风险数量: \(data.ingredientAnalysis.potentialRisks.count)")
        print("   - 使用建议数量: \(data.ingredientAnalysis.recommendations.count)")
        print("   - 总结: \(data.ingredientAnalysis.summary)")
        
        return (data.product, data.ingredientAnalysis)
    }
}




