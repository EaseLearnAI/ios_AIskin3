//
//  Product.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation

struct Product: Codable, Identifiable {
    var id: String
    var name: String
    var description: String?
    var imageUrl: String?
    var ingredients: [String]
    var label: String?
    var openingDate: Date?
    var openingStatus: String? = nil
    var safetyScore: Double?
    var efficacyScore: Double?
    var overallRating: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageUrl
        case ingredients
        case label
        case openingDate
        case openingStatus
        case safetyScore
        case efficacyScore
        case overallRating
    }
    
    // 辅助结构用于处理任意键名
    private struct AnyCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let anyKeyContainer = try decoder.container(keyedBy: AnyCodingKey.self)
        
        // 支持 both "id" 和 "_id" 字段
        if let idValue = try? container.decode(String.self, forKey: .id) {
            self.id = idValue
        } else if let idKey = AnyCodingKey(stringValue: "_id"), let idValue = try? anyKeyContainer.decode(String.self, forKey: idKey) {
            self.id = idValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing both 'id' and '_id' fields"))
        }
        
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        label = try container.decodeIfPresent(String.self, forKey: .label)
        openingDate = try container.decodeIfPresent(Date.self, forKey: .openingDate)
        openingStatus = try container.decodeIfPresent(String.self, forKey: .openingStatus)
        safetyScore = try container.decodeIfPresent(Double.self, forKey: .safetyScore)
        efficacyScore = try container.decodeIfPresent(Double.self, forKey: .efficacyScore)
        overallRating = try container.decodeIfPresent(Double.self, forKey: .overallRating)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encodeIfPresent(openingDate, forKey: .openingDate)
        try container.encodeIfPresent(openingStatus, forKey: .openingStatus)
        try container.encodeIfPresent(safetyScore, forKey: .safetyScore)
        try container.encodeIfPresent(efficacyScore, forKey: .efficacyScore)
        try container.encodeIfPresent(overallRating, forKey: .overallRating)
    }
}

struct IngredientAnalysis: Codable {
    var safetyIndex: Double
    var efficacyScore: Double
    var activeIngredients: Int
    var acneRisk: RiskLevel
    var irritationRisk: RiskLevel
    var allergyRisk: RiskLevel
    var efficacyAnalysis: [String]
    var potentialRisks: [String]
    var recommendations: [String]
    var overallRating: Double
    var summary: String
}

struct RiskLevel: Codable {
    var level: String
    var percentage: Double
}
