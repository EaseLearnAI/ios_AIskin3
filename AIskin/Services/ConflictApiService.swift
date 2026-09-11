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
    var reportVersion: Int?
    var riskScore: Double?
    var summary: String?
    var productPairs: [ConflictProductPair]?
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
    var reportVersion: Int?
    var riskScore: Double?
    var summary: String?
    var productPairs: [ConflictProductPair]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case products
        case conflicts
        case safeCombo
        case recommendations
        case createdAt
        case reportVersion, riskScore, summary, productPairs
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

    func analyzeConflict(productIds: [String]) async throws -> ConflictAnalysisData {
        let response: ConflictAnalysisResponse = try await apiClient.post(
            endpoint: "/conflicts", body: AnalyzeConflictRequest(productIds: productIds), requiresAuth: true
        )
        guard response.success, let data = response.data else {
            throw APIError.serverError(response.message ?? "冲突分析失败")
        }
        return data
    }

    func getUserConflicts() async throws -> [ConflictRecord] {
        let response: ConflictsListResponse = try await apiClient.get(endpoint: "/conflicts", requiresAuth: true)
        guard response.success, let conflicts = response.data?.conflicts else {
            throw APIError.serverError("获取冲突记录失败")
        }
        return conflicts
    }

    func getConflict(conflictId: String) async throws -> ConflictRecord {
        let response: ConflictDetailResponse = try await apiClient.get(endpoint: "/conflicts/\(conflictId)", requiresAuth: true)
        guard response.success, let conflict = response.data?.conflict else {
            throw APIError.serverError("获取冲突详情失败")
        }
        return conflict
    }

    func deleteConflict(conflictId: String) async throws {
        struct DeleteResponse: Codable {
            var success: Bool
            var message: String?
        }
        let response: DeleteResponse = try await apiClient.delete(endpoint: "/conflicts/\(conflictId)", requiresAuth: true)
        guard response.success else {
            throw APIError.serverError(response.message ?? "删除冲突记录失败")
        }
    }
}

// History returns Mongo _id; newly generated reports return id.
extension ConflictProductInfo {
    init(from decoder: Decoder) throws {
        enum Keys: String, CodingKey { case id, mongoID = "_id", name, description, imageUrl }
        let values = try decoder.container(keyedBy: Keys.self)
        id = try values.decodeIfPresent(String.self, forKey: .id) ?? values.decodeIfPresent(String.self, forKey: .mongoID)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try values.decodeIfPresent(String.self, forKey: .imageUrl)
    }
}

extension ConflictRecord {
    var reportData: ConflictAnalysisData {
        ConflictAnalysisData(conflictId: id, conflicts: conflicts, safeCombo: safeCombo,
                             recommendations: recommendations, products: products,
                             reportVersion: reportVersion, riskScore: riskScore, summary: summary, productPairs: productPairs)
    }
}

extension ConflictAnalysisData {
    var hasProductReport: Bool { reportVersion == 2 && productPairs?.isEmpty == false }

    var overallStatus: String {
        guard hasProductReport, let pairs = productPairs else { return "历史报告" }
        if pairs.contains(where: { $0.status == .unknown }) { return "部分产品无法判断" }
        if pairs.contains(where: { $0.status == .avoid }) { return ConflictPairStatus.avoid.title }
        if pairs.contains(where: { $0.status == .caution }) { return ConflictPairStatus.caution.title }
        return ConflictPairStatus.compatible.title
    }

    func productName(for id: String) -> String {
        guard let index = products?.firstIndex(where: { $0.id == id }), let product = products?[index] else {
            return "产品信息未提供"
        }
        return product.name?.isEmpty == false ? product.name! : "产品 \(index + 1)"
    }
}
