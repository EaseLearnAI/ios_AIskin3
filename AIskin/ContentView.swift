//
//  ContentView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
                    .environmentObject(authService)
            } else {
                NavigationView {
                    LoginView()
                        .environmentObject(authService)
                    }
                }
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthService
    @State private var shouldEnableConflictMode = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content Views
            Group {
                switch selectedTab {
                case 0:
                    HomeView(selectedTab: $selectedTab, shouldEnableConflictMode: $shouldEnableConflictMode)
                case 1:
                    ProductView(initialConflictMode: shouldEnableConflictMode)
                        .onAppear {
                            // Reset conflict mode flag after using it
                            if shouldEnableConflictMode {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    shouldEnableConflictMode = false
                                }
                            }
                        }
                case 2:
                    SkinStatusView(selectedTab: $selectedTab)
                case 3:
                    ProfileView()
                        .environmentObject(authService)
                default:
                    HomeView(selectedTab: $selectedTab, shouldEnableConflictMode: $shouldEnableConflictMode)
        }
    }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Bottom Navigation
            VStack(spacing: 0) {
                Spacer()
                BottomNavigationView(selectedTab: $selectedTab)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
                    )
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}
