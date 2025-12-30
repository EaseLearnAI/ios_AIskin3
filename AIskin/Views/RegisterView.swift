//
//  RegisterView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.976, blue: 0.984), // #fff9fb
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 头部组件
                AuthHeader(
                    title: "创建账号",
                    subtitle: "加入我们的护肤社区喵～",
                    showBackButton: true,
                    onBack: {
                        dismiss()
                    }
                )
                
                // 注册表单
                VStack {
                    RegisterForm { user in
                        // 注册成功回调
                        // authService.isAuthenticated会自动更新，ContentView会切换到主界面
                        print("注册成功: \(user.name)")
                        // 如果是通过NavigationLink进入的，可以dismiss
                        dismiss()
                    }
                }
                .padding(.top, -20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        RegisterView()
            .environmentObject(AuthService.shared)
    }
}

