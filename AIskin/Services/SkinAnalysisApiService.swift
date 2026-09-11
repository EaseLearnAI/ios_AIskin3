//
//  SkinAnalysisApiService.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation
import UIKit

/// 皮肤分析API服务
class SkinAnalysisApiService {
    static let shared = SkinAnalysisApiService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    /// 上传并分析皮肤图片
    func analyzeSkin(image: UIImage) async throws -> SkinAnalysis {
        print("🎯 皮肤分析API调用开始")
        print("📷 上传图片信息:")
        print("   - 图片尺寸: \(image.size.width)x\(image.size.height)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 错误: 无法将图片转换为数据")
            throw APIError.unknown
        }
        
        let fileName = "faceImage-\(Int(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.prefix(8)).jpg"
        
        let response: AnalyzeSkinResponse = try await apiClient.upload(
            endpoint: "/skin-analysis/analyze",
            fileData: imageData,
            fileName: fileName,
            fieldName: "faceImage",
            mimeType: "image/jpeg",
            requiresAuth: true
        )
        
        guard response.success, let data = response.data else {
            print("❌ 皮肤分析失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "皮肤分析失败")
        }
        
        print("✅ 皮肤分析成功")
        print("📋 分析结果:")
        print("   - 分析ID: \(data.analysisId ?? "未知")")
        print("   - 健康评分: \(data.overallAssessment?.healthScore.map { String($0) } ?? "未提供")")
        print("   - 皮肤类型: \(data.skinType?.type ?? "未知")")
        print("   - 皮肤状况: \(data.overallAssessment?.skinCondition ?? "未知")")
        
        guard let analysisID = data.analysisId, !analysisID.isEmpty else {
            throw APIError.serverError("未返回分析ID")
        }
        if let persisted = data.persistedAnalysis { return persisted }
        return try await getAnalysisDetail(analysisId: analysisID)
    }
    
    /// 将SkinAnalysis转换为AnalysisResult（用于UI显示）
    func convertToAnalysisResult(_ analysis: SkinAnalysis) -> AnalysisResult {
        // 提取otherIssues中的各项数据
        let redness = analysis.otherIssues?.redness
        let hyperpigmentation = analysis.otherIssues?.hyperpigmentation
        let fineLines = analysis.otherIssues?.fineLines
        let sensitivity = analysis.otherIssues?.sensitivity
        let skinToneEvenness = analysis.otherIssues?.skinToneEvenness
        
        // 转换数据格式
        return AnalysisResult(
            healthScore: analysis.overallAssessment?.healthScore.map { Int($0) },
            summary: analysis.overallAssessment?.summary,
            skinCondition: analysis.overallAssessment?.skinCondition,
            skinType: analysis.skinType != nil ? SkinTypeData(
                type: analysis.skinType!.type,
                subtype: analysis.skinType!.subtype,
                basis: analysis.skinType!.basis
            ) : nil,
            blackheads: analysis.blackheads != nil ? BlackheadsData(
                exists: analysis.blackheads!.exists,
                severity: analysis.blackheads!.severity,
                distribution: analysis.blackheads!.distribution,
                description: analysis.blackheads!.description
            ) : nil,
            acne: analysis.acne != nil ? AcneData(
                exists: analysis.acne!.exists,
                count: analysis.acne!.count,
                types: analysis.acne!.types,
                distribution: analysis.acne!.distribution,
                severity: analysis.acne!.severity,
                activity: analysis.acne!.activity,
                description: analysis.acne!.description
            ) : nil,
            pores: analysis.pores != nil ? PoresData(
                enlarged: analysis.pores!.enlarged,
                severity: analysis.pores!.severity,
                distribution: analysis.pores!.distribution,
                description: analysis.pores!.description
            ) : nil,
            skinToneEvenness: skinToneEvenness != nil ? SkinToneEvennessData(
                score: skinToneEvenness!.score,
                description: skinToneEvenness!.description
            ) : nil,
            redness: redness != nil ? RednessData(
                exists: redness!.exists,
                severity: redness!.severity,
                description: redness!.description,
                distribution: redness!.distribution
            ) : nil,
            hyperpigmentation: hyperpigmentation != nil ? HyperpigmentationData(
                exists: hyperpigmentation!.exists,
                severity: hyperpigmentation!.severity,
                description: hyperpigmentation!.description,
                types: hyperpigmentation!.types,
                distribution: hyperpigmentation!.distribution
            ) : nil,
            fineLines: fineLines != nil ? FineLinesData(
                exists: fineLines!.exists,
                severity: fineLines!.severity,
                description: fineLines!.description,
                distribution: fineLines!.distribution
            ) : nil,
            sensitivity: sensitivity != nil ? SensitivityData(
                exists: sensitivity!.exists,
                severity: sensitivity!.severity,
                description: sensitivity!.description,
                signs: sensitivity!.signs
            ) : nil,
            oilLevel: nil, // The response has no direct oil measurement; skin type remains separate.
            moistureLevel: calculateMoistureLevel(analysis: analysis),
            poreLevel: analysis.pores?.severity,
            recommendations: analysis.overallAssessment?.recommendations,
            createdAt: analysis.createdAt,
            sourceID: analysis.id,
            context: analysis.context,
            additionalIssueDescriptions: analysis.otherIssues?.additionalDescriptions ?? [],
            imageURL: analysis.imageUrl.flatMap(URL.init(string:)),
            assessmentDetails: assessmentDetails(from: analysis)
        )
    }

    private func assessmentDetails(from analysis: SkinAnalysis) -> [SkinIssueDescription] {
        var rows: [SkinIssueDescription] = []
        func add(_ title: String, _ values: [String?]) {
            let texts = values.compactMap { $0 }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if !texts.isEmpty { rows.append(SkinIssueDescription(field: title, texts: texts)) }
        }
        add("肤质判断依据", [analysis.skinType?.subtype, analysis.skinType?.basis])
        add("整体肤况", [analysis.overallAssessment?.skinCondition])
        let metrics: [(String, Double?)] = [
            ("综合评分原值", analysis.overallAssessment?.healthScore),
            ("水分", analysis.moisture), ("光泽度", analysis.glossiness),
            ("弹性", analysis.elasticity), ("问题区域评分", analysis.problemAreaScore)
        ]
        for (name, value) in metrics {
            if let value { add(name, [String(value) + "（本次模型估计值）"]) }
        }
        return rows
    }

    func updateContext(analysisID: String, condition: String?, light: String?, feelings: [String]?) async throws -> SkinAnalysis {
        let response: SkinAnalysisDetailResponse = try await apiClient.patch(
            endpoint: "/skin-analysis/\(analysisID)/context",
            body: SkinAnalysisContext(condition: condition, light: light, feelings: feelings),
            requiresAuth: true
        )
        guard response.success, let analysis = response.data?.analysis else {
            throw APIError.serverError("保存检测备注失败")
        }
        return analysis
    }
    
    /// 计算水分水平
    private func calculateMoistureLevel(analysis: SkinAnalysis) -> String? {
        guard let moisture = analysis.moisture else {
            return nil
        }
        if moisture >= 80 {
            return "高"
        } else if moisture >= 60 {
            return "正常"
        } else if moisture >= 40 {
            return "偏低"
        } else {
            return "低"
        }
    }
    
    /// 获取用户的皮肤分析历史记录
    func getAnalysisHistory(page: Int = 1, limit: Int = 10) async throws -> (analyses: [SkinAnalysis], pagination: Pagination?) {
        print("🎯 获取皮肤分析历史API调用开始")
        print("📊 分页参数:")
        print("   - 页码: \(page)")
        print("   - 每页数量: \(limit)")
        
        let response: SkinAnalysisListResponse = try await apiClient.get(
            endpoint: "/skin-analysis",
            requiresAuth: true,
            queryParams: [
                "page": "\(page)",
                "limit": "\(limit)"
            ]
        )
        
        guard response.success, let analyses = response.data?.analyses else {
            print("❌ 获取分析历史失败")
            throw APIError.serverError("获取分析历史失败")
        }
        
        print("✅ 获取分析历史成功")
        print("📋 历史记录信息:")
        print("   - 总数: \(response.data?.pagination?.total ?? 0)")
        print("   - 当前页数量: \(analyses.count)")
        for analysis in analyses {
            let score = analysis.overallAssessment?.healthScore.map { String($0) } ?? "未提供"
            print("     • 分析ID: \(analysis.id), 健康评分: \(score), 创建时间: \(analysis.createdAt?.description ?? "未知")")
        }
        
        return (analyses, response.data?.pagination)
    }
    
    /// 获取单个皮肤分析详情
    func getAnalysisDetail(analysisId: String) async throws -> SkinAnalysis {
        print("🎯 获取皮肤分析详情API调用开始")
        print("📊 分析ID: \(analysisId)")
        
        let response: SkinAnalysisDetailResponse = try await apiClient.get(
            endpoint: "/skin-analysis/\(analysisId)",
            requiresAuth: true
        )
        
        guard response.success, let analysis = response.data?.analysis else {
            print("❌ 获取分析详情失败")
            throw APIError.serverError("获取分析详情失败")
        }
        
        print("✅ 获取分析详情成功")
        print("📋 分析详情:")
        print("   - 分析ID: \(analysis.id)")
        print("   - 健康评分: \(analysis.overallAssessment?.healthScore.map { String($0) } ?? "未提供")")
        print("   - 皮肤类型: \(analysis.skinType?.type ?? "未知")")
        print("   - 皮肤状况: \(analysis.overallAssessment?.skinCondition ?? "未知")")
        print("   - 水分: \(analysis.moisture ?? 0)")
        print("   - 光泽度: \(analysis.glossiness ?? 0)")
        print("   - 弹性: \(analysis.elasticity ?? 0)")
        
        return analysis
    }
    
    /// 获取用户最新皮肤分析
    func getLatestAnalysis() async throws -> SkinAnalysis? {
        print("🎯 获取最新皮肤分析API调用开始")
        
        let response: SkinAnalysisDetailResponse = try await apiClient.get(
            endpoint: "/skin-analysis/latest",
            requiresAuth: true
        )
        
        guard response.success else {
            print("⚠️ 未找到最新分析记录")
            return nil
        }
        
        guard let analysis = response.data?.analysis else {
            print("⚠️ 未找到最新分析记录")
            return nil
        }
        
        print("✅ 获取最新分析成功")
        print("📋 最新分析信息:")
        print("   - 分析ID: \(analysis.id)")
        print("   - 健康评分: \(analysis.overallAssessment?.healthScore.map { String($0) } ?? "未提供")")
        print("   - 创建时间: \(analysis.createdAt?.description ?? "未知")")
        
        return analysis
    }
    
    /// 获取用户皮肤分析统计数据
    func getAnalysisStats() async throws -> SkinAnalysisStats {
        print("🎯 获取皮肤分析统计数据API调用开始")
        
        let response: SkinAnalysisStatsResponse = try await apiClient.get(
            endpoint: "/skin-analysis/stats",
            requiresAuth: true
        )
        
        guard response.success, let stats = response.data?.stats else {
            print("❌ 获取统计数据失败")
            throw APIError.serverError("获取统计数据失败")
        }
        
        print("✅ 获取统计数据成功")
        print("📊 统计信息:")
        print("   - 总分析次数: \(stats.totalAnalyses)")
        print("   - 平均健康评分: \(stats.averageHealthScore ?? 0)")
        print("   - 最新皮肤状况: \(stats.latestSkinCondition ?? "未知")")
        print("   - 最新分析时间: \(stats.latestAnalysisDate?.description ?? "未知")")
        
        return stats
    }
    
    /// 删除皮肤分析记录
    func deleteAnalysis(analysisId: String) async throws {
        print("🎯 删除皮肤分析记录API调用开始")
        print("📊 分析ID: \(analysisId)")
        
        struct DeleteResponse: Codable {
            var success: Bool
            var message: String?
        }
        
        let response: DeleteResponse = try await apiClient.delete(
            endpoint: "/skin-analysis/\(analysisId)",
            requiresAuth: true
        )
        
        guard response.success else {
            print("❌ 删除分析记录失败: \(response.message ?? "未知错误")")
            throw APIError.serverError(response.message ?? "删除分析记录失败")
        }
        
        print("✅ 删除分析记录成功")
    }
}
