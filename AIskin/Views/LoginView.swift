//
//  LoginView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var sessionStore: SessionStore
    
    var body: some View {
        ZStack {
            // 背景渐变
            AISkinAuthStyle.pageGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 头部组件
                AuthHeader(
                    title: "欢迎回来",
                    subtitle: "开始你的护肤之旅喵～",
                    showBackButton: false
                )
                
                // 登录表单
                VStack {
                    LoginForm { user in
                        // 登录成功回调
                        // authService.isAuthenticated会自动更新，ContentView会切换到主界面
                        print("登录成功: \(user.name)")
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
        LoginView()
            .environmentObject(AppDependencies.preview.sessionStore)
    }
}
