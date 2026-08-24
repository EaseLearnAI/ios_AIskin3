//
//  AIskinApp.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

@main
struct AIskinApp: App {
    private let dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies.sessionStore)
        }
    }
}
