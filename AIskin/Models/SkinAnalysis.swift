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
    var context: SkinAnalysisContext? = nil
    
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
        case context
    }
}

struct SkinAnalysisContext: Codable, Equatable {
    static func togglingFeeling(_ option: String, in selected: Set<String>) -> Set<String> {
        var updated = selected
        if updated.contains(option) {
            updated.remove(option)
        } else if option == "无明显不适" {
            updated = [option]
        } else {
            updated.remove("无明显不适")
            updated.insert(option)
        }
        return updated
    }
    var condition: String?
    var light: String?
    var feelings: [String]?
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

/// Descriptions without structured clinical fields stay as observations.
struct SkinIssueDescription: Equatable, Identifiable {
    var field: String
    var texts: [String]
    var id: String { field }

    var title: String {
        switch field {
        case "redness": "泛红观察"
        case "hyperpigmentation": "色素观察"
        case "fineLines": "细纹观察"
        case "sensitivity": "敏感观察"
        case "skinToneEvenness": "肤色观察"
        case "texture": "肤质纹理观察"
        default: field
        }
    }
}

struct SkinObservation: Codable, Equatable {
    var category: String
    var details: [String]
}

struct OtherIssues: Codable {
    var redness: RednessInfo?
    var hyperpigmentation: HyperpigmentationInfo?
    var fineLines: FineLinesInfo?
    var sensitivity: SensitivityInfo?
    var skinToneEvenness: SkinToneEvennessInfo?
    var observations: [SkinObservation] = []
    private var additionalValues: [String: SkinIssueJSONValue] = [:]

    var additionalDescriptions: [SkinIssueDescription] {
        var descriptions: [SkinIssueDescription] = []
        func append(field: String, texts: [String]) {
            guard !texts.isEmpty else { return }
            if let index = descriptions.firstIndex(where: { $0.field == field }) {
                descriptions[index].texts.append(contentsOf: texts)
            } else {
                descriptions.append(SkinIssueDescription(field: field, texts: texts))
            }
        }
        for observation in observations {
            append(field: observation.category, texts: observation.details)
        }
        for key in additionalValues.keys.sorted() {
            append(field: key, texts: additionalValues[key]?.textValues ?? [])
        }
        return descriptions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: IssueKey.self)
        func structured<T: Decodable>(_ type: T.Type, _ name: String) throws -> T? {
            let key = IssueKey(name)
            guard container.contains(key), try !container.decodeNil(forKey: key) else { return nil }
            let raw = try container.decode(SkinIssueJSONValue.self, forKey: key)
            if case .object = raw { return try container.decode(T.self, forKey: key) }
            additionalValues[name] = raw
            return nil
        }
        redness = try structured(RednessInfo.self, "redness")
        hyperpigmentation = try structured(HyperpigmentationInfo.self, "hyperpigmentation")
        fineLines = try structured(FineLinesInfo.self, "fineLines")
        sensitivity = try structured(SensitivityInfo.self, "sensitivity")
        skinToneEvenness = try structured(SkinToneEvennessInfo.self, "skinToneEvenness")
        observations = try container.decodeIfPresent([SkinObservation].self, forKey: IssueKey("observations")) ?? []
        let known: Set<String> = ["redness", "hyperpigmentation", "fineLines", "sensitivity", "skinToneEvenness", "observations"]
        for key in container.allKeys where !known.contains(key.stringValue) {
            additionalValues[key.stringValue] = try container.decode(SkinIssueJSONValue.self, forKey: key)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: IssueKey.self)
        if !observations.isEmpty { try container.encode(observations, forKey: IssueKey("observations")) }
        for (name, value) in additionalValues { try container.encode(value, forKey: IssueKey(name)) }
        try container.encodeIfPresent(redness, forKey: IssueKey("redness"))
        try container.encodeIfPresent(hyperpigmentation, forKey: IssueKey("hyperpigmentation"))
        try container.encodeIfPresent(fineLines, forKey: IssueKey("fineLines"))
        try container.encodeIfPresent(sensitivity, forKey: IssueKey("sensitivity"))
        try container.encodeIfPresent(skinToneEvenness, forKey: IssueKey("skinToneEvenness"))
    }
}

private struct IssueKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ value: String) { stringValue = value }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

/// Retain unknown fields losslessly, while exposing only supplied text in the UI.
private indirect enum SkinIssueJSONValue: Codable {
    case string(String), array([SkinIssueJSONValue]), object([String: SkinIssueJSONValue]), number(Double), bool(Bool), null

    var textValues: [String] {
        switch self {
        case .string(let value): value.isEmpty ? [] : [value]
        case .array(let values): values.flatMap(\.textValues)
        case .object(let values): values.keys.sorted().flatMap { values[$0]?.textValues ?? [] }
        default: []
        }
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let text = try? value.decode(String.self) { self = .string(text) }
        else if let array = try? value.decode([SkinIssueJSONValue].self) { self = .array(array) }
        else if let object = try? value.decode([String: SkinIssueJSONValue].self) { self = .object(object) }
        else if let boolean = try? value.decode(Bool.self) { self = .bool(boolean) }
        else { self = .number(try value.decode(Double.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var value = encoder.singleValueContainer()
        switch self {
        case .string(let text): try value.encode(text)
        case .array(let array): try value.encode(array)
        case .object(let object): try value.encode(object)
        case .number(let number): try value.encode(number)
        case .bool(let boolean): try value.encode(boolean)
        case .null: try value.encodeNil()
        }
    }
}

struct RednessInfo: Codable {
    var exists: Bool?
    var severity: String?
    var distribution: [String]?
    var description: String? = nil
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
    var healthScore: Double?
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
    var context: SkinAnalysisContext? = nil
    var createdAt: Date? = nil
    var updatedAt: Date? = nil

    /// Use the server's persisted snapshot for the immediate report. Older
    /// responses without timestamps fall back to the detail endpoint.
    var persistedAnalysis: SkinAnalysis? {
        guard let analysisId, !analysisId.isEmpty, let createdAt, let updatedAt else { return nil }
        return SkinAnalysis(
            id: analysisId, imageUrl: imageUrl, imageName: nil,
            skinType: skinType, blackheads: blackheads, acne: acne,
            pores: pores, otherIssues: otherIssues, overallAssessment: overallAssessment,
            analysisConfig: analysisConfig, moisture: moisture, glossiness: glossiness,
            elasticity: elasticity, problemAreaScore: problemAreaScore,
            createdAt: createdAt, updatedAt: updatedAt, context: context
        )
    }
    
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
        case context
        case createdAt
        case updatedAt
    }
}

