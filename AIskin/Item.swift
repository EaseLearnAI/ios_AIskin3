//
//  Item.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
