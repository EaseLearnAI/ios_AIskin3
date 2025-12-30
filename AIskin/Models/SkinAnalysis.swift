//
//  SkinAnalysis.swift
//  AIskin
//
//  Created by AI Assistant
//

import Foundation

/// 皮肤分析记录
struct SkinAnalysis: Codable, Identifiable {
    var id: String
    var imageUrl: String?
    var imageName: String?
    var skinType: SkinType?
    var blackheads: BlackheadsInfo?
    var acne: AcneInfo?
    var pores: PoresInfo?
    var otherIssues: OtherIssues?
    var overallAssessment: OverallAssessment?
    var analysisConfig: AnalysisConfig?
    var moisture: Double?
    var glossiness: Double?
    var elasticity: Double?
    var problemAreaScore: Double?
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageUrl
        case imageName
        case skinType
        case blackheads
        case acne
        case pores
        case otherIssues
        case overallAssessment
        case analysisConfig
        case moisture
        case glossiness
        case elasticity
        case problemAreaScore
        case createdAt
        case updatedAt
    }
}

struct SkinType: Codable {
    var type: String
    var subtype: String?
    var basis: String?
}

struct BlackheadsInfo: Codable {
    var exists: Bool?
    var severity: String?
    var distribution: [String]?
    var description: String?
}

struct AcneInfo: Codable {
    var exists: Bool?
    var count: String?
    var types: [String]?
    var activity: String?
    var distribution: [String]?
    var severity: String?
    var description: String?
}

struct PoresInfo: Codable {
    var enlarged: Bool?
    var severity: String?
    var distribution: [String]?
    var description: String?
}

struct OtherIssues: Codable {
    var redness: RednessInfo?
    var hyperpigmentation: HyperpigmentationInfo?
    var fineLines: FineLinesInfo?
    var sensitivity: SensitivityInfo?
    var skinToneEvenness: SkinToneEvennessInfo?
}

struct RednessInfo: Codable {
    var exists: Bool?
    var severity: String?
    var distribution: [String]?
}

struct HyperpigmentationInfo: Codable {
    var exists: Bool?
    var types: [String]?
    var distribution: [String]?
    var severity: String?
    var description: String?
}

struct FineLinesInfo: Codable {
    var exists: Bool?
    var severity: String?
    var distribution: [String]?
    var description: String?
}

struct SensitivityInfo: Codable {
    var exists: Bool?
    var signs: [String]?
    var severity: String?
    var description: String?
}

struct SkinToneEvennessInfo: Codable {
    var score: Int?
    var description: String?
}

struct OverallAssessment: Codable {
    var healthScore: Double
    var summary: String?
    var recommendations: [String]?
    var skinCondition: String?
}

struct AnalysisConfig: Codable {
    var model: String?
    var analysisDate: Date?
    var processingTime: Double?
}

/// 皮肤分析列表响应
struct SkinAnalysisListResponse: Codable {
    var success: Bool
    var data: SkinAnalysisListData?
}

struct SkinAnalysisListData: Codable {
    var analyses: [SkinAnalysis]
    var pagination: Pagination?
}

struct Pagination: Codable {
    var page: Int
    var limit: Int
    var total: Int
    var pages: Int
}

/// 皮肤分析详情响应
struct SkinAnalysisDetailResponse: Codable {
    var success: Bool
    var data: SkinAnalysisDetailData?
}

struct SkinAnalysisDetailData: Codable {
    var analysis: SkinAnalysis
}

/// 皮肤分析统计响应
struct SkinAnalysisStatsResponse: Codable {
    var success: Bool
    var data: SkinAnalysisStatsData?
}

struct SkinAnalysisStatsData: Codable {
    var stats: SkinAnalysisStats
}

struct SkinAnalysisStats: Codable {
    var totalAnalyses: Int
    var averageHealthScore: Double?
    var latestSkinCondition: String?
    var latestAnalysisDate: Date?
}

/// 上传并分析皮肤响应
struct AnalyzeSkinResponse: Codable {
    var success: Bool
    var message: String?
    var data: AnalyzeSkinData?
}

struct AnalyzeSkinData: Codable {
    var analysisId: String?
    var imageUrl: String?
    var analysisConfig: AnalysisConfig?
    var overallAssessment: OverallAssessment?
    var skinType: SkinType?
    var blackheads: BlackheadsInfo?
    var acne: AcneInfo?
    var pores: PoresInfo?
    var otherIssues: OtherIssues?
    var moisture: Double?
    var glossiness: Double?
    var elasticity: Double?
    var problemAreaScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case analysisId
        case imageUrl
        case analysisConfig
        case overallAssessment
        case skinType
        case blackheads
        case acne
        case pores
        case otherIssues
        case moisture
        case glossiness
        case elasticity
        case problemAreaScore
    }
}




