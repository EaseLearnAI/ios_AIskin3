//
//  SkinPlan.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation

struct SkinPlan: Codable, Identifiable {
    var id: String
    var name: String
    var tags: [String]
    var creatorNote: String?
    var notes: String?
    var morning: [RoutineItem]
    var evening: [RoutineItem]
    var recommendations: [String]
    var createdAt: Date?
    var createdByName: String?
    var origin: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case tags
        case creatorNote
        case notes
        case morning
        case evening
        case recommendations
        case createdAt
        case createdByName
        case origin
    }
}

struct RoutineItem: Codable {
    var step: Int?
    var product: String?
    var reason: String?
    var done: Bool?
    var completed: Bool?
    
    var isDone: Bool {
        return done ?? completed ?? false
    }
}

