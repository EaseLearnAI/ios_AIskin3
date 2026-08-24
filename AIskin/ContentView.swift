//
//  ContentView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            if sessionStore.isAuthenticated {
                AppRootView(authService: sessionStore)
                    .environmentObject(sessionStore)
            } else {
                NavigationStack {
                    LoginView()
                        .environmentObject(sessionStore)
                }
            }
        }
        .lookinName("app.root")
    }
}
