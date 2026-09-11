//
//  ContentView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    // Local preview keeps the existing device session intact. Disabled in Release.
    @State private var previewOnboarding: Bool = {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-AISkinPreviewOnboarding")
#else
        false
#endif
    }()

    var body: some View {
        AISkinScreenBackground {
            Group {
                if sessionStore.isAuthenticated && !previewOnboarding {
                    AppRootView(authService: sessionStore)
                        .environmentObject(sessionStore)
                } else {
                    NavigationStack {
                        LoginView(onContinueSession: { previewOnboarding = false })
                            .environmentObject(sessionStore)
                    }
                }
            }
            .lookinName("app.root")
        }
        .preferredColorScheme(.light)
    }
}
