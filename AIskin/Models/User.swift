//
//  User.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String
    var name: String
    var email: String?
    var phone: String?
    var avatar: String?
    var gender: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
        case phone
        case avatar
        case gender
    }
}

