//
//  AIskinApp.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI
import SwiftData

@main
struct AIskinApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
