//
//  Conflict.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation

struct Conflict: Codable, Identifiable {
    var id: String?
    var components: [String]
    var description: String
    var severity: String
    var effects: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case components
        case description
        case severity
        case effects
    }
}

struct SafeCombo: Codable {
    var components: [String]
    var description: String
}

struct ConflictAdvice: Codable {
    var productIds: [String]
    var title: String
    var detail: String
}

enum ConflictPairStatus: String, Codable {
    case compatible, caution, avoid, unknown

    var title: String {
        switch self {
        case .compatible: return "未发现明确冲突"
        case .caution: return "叠加需注意"
        case .avoid: return "不建议同时使用"
        case .unknown: return "暂时无法判断"
        }
    }
}

struct ConflictProductPair: Codable {
    var productIds: [String]
    var status: ConflictPairStatus
    var explanation: String
}

struct ConflictRecommendations: Codable {
    var advice: [ConflictAdvice]?
    var productPairings: ProductPairings?
    var routines: Routines?
}

struct ProductPairings: Codable {
    var cannotUseTogether: [Pairing]?
    var canUseTogether: [Pairing]?
}

struct Pairing: Codable {
    var products: [String]
    var reason: String
}

struct Routines: Codable {
    var morning: [String]?
    var evening: [String]?
}

