//
//  RegisterForm.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct RegisterForm: View {
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var gender: String = ""
    @State private var agreeTerms: Bool = false
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var validationErrors: [String: String] = [:]
    
    @EnvironmentObject var sessionStore: SessionStore
    var onRegisterSuccess: ((User) -> Void)?
    
    var body: some View {
        ScrollView {
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
                    // 用户名输入
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                            Text("用户名")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                        }
                        
                        TextField("请输入用户名", text: $name)
                            .textFieldStyle(AuthTextFieldStyle(isError: validationErrors["name"] != nil))
                            .autocapitalization(.none)
                        
                        if let error = validationErrors["name"] {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 性别选择
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                            Text("性别")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                        }
                        
                        HStack(spacing: 12) {
                            // 男生选项
                            Button(action: {
                                gender = "male"
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "mars")
                                        .font(.system(size: 16))
                                    Text("男生")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    gender == "male" ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.973, green: 0.733, blue: 0.816).opacity(0.1),
                                            Color(red: 0.882, green: 0.745, blue: 0.906).opacity(0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0.98, green: 0.98, blue: 0.98)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(
                                    gender == "male" ?
                                    Color(red: 0.973, green: 0.733, blue: 0.816) :
                                    Color(red: 0.259, green: 0.259, blue: 0.259)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            gender == "male" ?
                                            Color(red: 0.973, green: 0.733, blue: 0.816) :
                                            Color.gray.opacity(0.2),
                                            lineWidth: gender == "male" ? 2 : 1
                                        )
                                )
                            }
                            
                            // 女生选项
                            Button(action: {
                                gender = "female"
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "venus")
                                        .font(.system(size: 16))
                                    Text("女生")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    gender == "female" ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.973, green: 0.733, blue: 0.816).opacity(0.1),
                                            Color(red: 0.882, green: 0.745, blue: 0.906).opacity(0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0.98, green: 0.98, blue: 0.98)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(
                                    gender == "female" ?
                                    Color(red: 0.973, green: 0.733, blue: 0.816) :
                                    Color(red: 0.259, green: 0.259, blue: 0.259)
                                )
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            gender == "female" ?
                                            Color(red: 0.973, green: 0.733, blue: 0.816) :
                                            Color.gray.opacity(0.2),
                                            lineWidth: gender == "female" ? 2 : 1
                                        )
                                )
                            }
                        }
                        
                        if let error = validationErrors["gender"] {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
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
                                TextField("请输入密码（至少6个字符）", text: $password)
                                    .textFieldStyle(.plain)
                            } else {
                                SecureField("请输入密码（至少6个字符）", text: $password)
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
                    
                    // 确认密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                            Text("确认密码")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                        }
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("请再次输入密码", text: $confirmPassword)
                                    .textFieldStyle(.plain)
                            } else {
                                SecureField("请再次输入密码", text: $confirmPassword)
                                    .textFieldStyle(.plain)
                            }
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
                                    validationErrors["confirmPassword"] != nil ?
                                    Color(red: 0.957, green: 0.263, blue: 0.212) :
                                    Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        
                        if let error = validationErrors["confirmPassword"] {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 条款同意
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top, spacing: 8) {
                            Button(action: {
                                agreeTerms.toggle()
                            }) {
                                Image(systemName: agreeTerms ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 16))
                                    .foregroundColor(agreeTerms ? Color(red: 0.973, green: 0.733, blue: 0.816) : Color.gray)
                                    .padding(.top, 2)
                            }
                            
                            (Text("我已阅读并同意 ")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                             + Text("使用条款")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                             + Text(" 和 ")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.259, green: 0.259, blue: 0.259))
                             + Text("隐私政策")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let error = validationErrors["agreeTerms"] {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.957, green: 0.263, blue: 0.212))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 24)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // 注册按钮
                    Button(action: handleRegister) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("注册账号")
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
                    
                    // 登录链接
                    HStack(spacing: 4) {
                        Text("已有账号？")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        NavigationLink(destination: LoginView()) {
                            Text("立即登录")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.973, green: 0.733, blue: 0.816))
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color(red: 0.973, green: 0.733, blue: 0.816).opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
    
    private func validateForm() -> Bool {
        validationErrors = [:]
        var isValid = true
        
        // 验证用户名
        if name.isEmpty {
            validationErrors["name"] = "请输入用户名"
            isValid = false
        }
        
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
        } else if password.count < 6 {
            validationErrors["password"] = "密码长度至少6个字符"
            isValid = false
        }
        
        // 验证确认密码
        if confirmPassword.isEmpty {
            validationErrors["confirmPassword"] = "请确认密码"
            isValid = false
        } else if password != confirmPassword {
            validationErrors["confirmPassword"] = "两次输入的密码不一致"
            isValid = false
        }
        
        // 验证性别
        if gender.isEmpty {
            validationErrors["gender"] = "请选择性别"
            isValid = false
        }
        
        // 验证条款同意
        if !agreeTerms {
            validationErrors["agreeTerms"] = "请阅读并同意条款和政策"
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
    
    private func handleRegister() {
        guard validateForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 使用手机号注册，如果API需要email，可以使用phone作为email
                try await sessionStore.register(name: name, phone: phone, password: password, gender: gender)
                
                await MainActor.run {
                    if let user = sessionStore.currentUser {
                        onRegisterSuccess?(user)
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

#Preview {
    RegisterForm()
        .environmentObject(AppDependencies.preview.sessionStore)
        .padding()
        .background(Color(red: 1.0, green: 0.976, blue: 0.984))
}
