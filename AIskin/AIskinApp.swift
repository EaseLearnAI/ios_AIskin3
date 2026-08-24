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

    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestingResetSession") {
            dependencies.sessionStore.resetForTesting()
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies.sessionStore)
        }
    }
}
