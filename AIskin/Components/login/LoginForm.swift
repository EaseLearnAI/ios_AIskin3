//
//  LoginForm.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct LoginForm: View {
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var rememberMe: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var validationErrors: [String: String] = [:]
    
    @EnvironmentObject var sessionStore: SessionStore
    var onLoginSuccess: ((User) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // 错误消息
            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Color(red: 0.718, green: 0.110, blue: 0.110))
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.718, green: 0.110, blue: 0.110))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(red: 1.0, green: 0.922, blue: 0.933))
                .cornerRadius(8)
                .padding(.bottom, 16)
            }
            
            VStack(spacing: 20) {
                // 手机号输入
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                        Text("手机号")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                    }
                    
                    TextField("请输入手机号", text: $phone)
                        .textFieldStyle(AuthTextFieldStyle(isError: validationErrors["phone"] != nil))
                        .keyboardType(.phonePad)
                        .autocapitalization(.none)
                    
                    if let error = validationErrors["phone"] {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // 密码输入
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                        Text("密码")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                    }
                    
                    HStack {
                        if showPassword {
                            TextField("请输入密码", text: $password)
                                .textFieldStyle(.plain)
                        } else {
                            SecureField("请输入密码", text: $password)
                                .textFieldStyle(.plain)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.gray)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                validationErrors["password"] != nil ?
                                Color(red: 0.957, green: 0.263, blue: 0.212) :
                                Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    
                    if let error = validationErrors["password"] {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // 记住我和忘记密码
                HStack {
                    Button(action: {
                        rememberMe.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                .font(.system(size: 16))
                                .foregroundColor(rememberMe ? Color(red: 0.973, green: 0.733, blue: 0.816) : Color.gray)
                            Text("记住我")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                        }
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("忘记密码？")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                    }
                }
                .padding(.vertical, 4)
                
                // 登录按钮
                Button(action: handleLogin) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("登录")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.973, green: 0.733, blue: 0.816),
                                Color(red: 0.882, green: 0.745, blue: 0.906)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                .shadow(color: Color(red: 0.973, green: 0.733, blue: 0.816).opacity(0.3), radius: 8, x: 0, y: 4)
                .disabled(isLoading)
                .padding(.top, 8)
                
                // 注册链接
                HStack(spacing: 4) {
                    Text("还没有账号？")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    NavigationLink(destination: RegisterView()) {
                        Text("立即注册")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(red: 0.973, green: 0.733, blue: 0.816).opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
    
    private func validateForm() -> Bool {
        validationErrors = [:]
        var isValid = true
        
        // 验证手机号
        if phone.isEmpty {
            validationErrors["phone"] = "请输入手机号"
            isValid = false
        } else if !isValidPhone(phone) {
            validationErrors["phone"] = "请输入有效的手机号"
            isValid = false
        }
        
        // 验证密码
        if password.isEmpty {
            validationErrors["password"] = "请输入密码"
            isValid = false
        }
        
        return isValid
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // 中国手机号验证：1开头，第二位3-9，共11位
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
    
    private func handleLogin() {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 使用手机号作为email字段（如果API支持）或直接使用phone
                // 这里假设API接受phone作为登录凭证
                try await sessionStore.login(phone: phone, password: password)
                
                await MainActor.run {
                    if let user = sessionStore.currentUser {
                        onLoginSuccess?(user)
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// 占位视图 - 忘记密码页面
struct ForgotPasswordView: View {
    var body: some View {
        Text("忘记密码功能")
            .navigationTitle("忘记密码")
    }
}

#Preview {
    LoginForm()
        .environmentObject(AppDependencies.preview.sessionStore)
        .padding()
        .background(Color(red: 1.0, green: 0.976, blue: 0.984))
}
