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

struct ConflictRecommendations: Codable {
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

