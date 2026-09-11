//
//  User.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation

struct User: Codable, Identifiable {
    static let ageRange = 13...120
    var id: String
    var name: String
    var email: String?
    var phone: String?
    var avatar: String?
    var gender: String?
    var age: Int? = nil
    var authProviders: [String]? = nil

    var authenticationMethodName: String {
        if authProviders?.contains("apple") == true { return "Apple 账户" }
        if authProviders?.contains("phone") == true || phone != nil { return "手机号账户" }
        return "未提供"
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case email
        case phone
        case avatar
        case gender
        case age
        case authProviders
    }
}
