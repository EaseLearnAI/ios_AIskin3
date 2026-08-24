import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var phone: String
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showsNewPassword = false
    @State private var showsConfirmPassword = false
    @State private var isSendingCode = false
    @State private var isResettingPassword = false
    @State private var cooldownSeconds = 0
    @State private var countdownTask: Task<Void, Never>?
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var validationErrors: [Field: String] = [:]
    @State private var didResetPassword = false

    init(initialPhone: String = "") {
        _phone = State(initialValue: initialPhone)
    }

    var body: some View {
        ZStack {
            AISkinAuthStyle.pageGradient
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 0) {
                    AuthHeader(
                        title: "找回密码",
                        subtitle: "验证手机号后设置新密码",
                        showBackButton: true,
                        onBack: { dismiss() }
                    )

                    Group {
                        if didResetPassword {
                            successCard
                        } else {
                            resetForm
                        }
                    }
                    .padding(.top, -20)
                    .padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .onDisappear {
            countdownTask?.cancel()
        }
    }

    private var resetForm: some View {
        VStack(spacing: 20) {
            feedbackMessages

            authField(
                title: "手机号",
                icon: "phone.fill",
                error: validationErrors[.phone]
            ) {
                TextField("请输入注册手机号", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel(title: "验证码", icon: "message.fill")

                HStack(spacing: 8) {
                    TextField("6位短信验证码", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .onChange(of: verificationCode) { _, newValue in
                            verificationCode = String(newValue.filter(\.isNumber).prefix(6))
                        }

                    Divider()
                        .frame(height: 22)

                    Button(action: sendVerificationCode) {
                        Group {
                            if isSendingCode {
                                ProgressView()
                                    .tint(AISkinAuthStyle.pink)
                            } else {
                                Text(cooldownSeconds > 0 ? "\(cooldownSeconds)s" : "获取验证码")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .frame(minWidth: 76, minHeight: 44)
                    }
                    .foregroundStyle(AISkinAuthStyle.pink)
                    .disabled(isSendingCode || cooldownSeconds > 0)
                    .accessibilityLabel(cooldownSeconds > 0 ? "\(cooldownSeconds)秒后可重新获取验证码" : "获取验证码")
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(fieldBorder(for: .verificationCode), lineWidth: 1)
                }

                validationMessage(for: .verificationCode)
            }

            passwordField(
                title: "新密码",
                placeholder: "至少6个字符",
                text: $newPassword,
                isVisible: $showsNewPassword,
                field: .newPassword
            )

            passwordField(
                title: "确认新密码",
                placeholder: "请再次输入新密码",
                text: $confirmPassword,
                isVisible: $showsConfirmPassword,
                field: .confirmPassword
            )

            Button(action: resetPassword) {
                ZStack {
                    if isResettingPassword {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("确认修改密码")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AISkinAuthStyle.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isResettingPassword)
            .shadow(color: AISkinAuthStyle.pink.opacity(0.28), radius: 8, x: 0, y: 4)

            Text("验证码仅用于确认账号归属，请勿转发给他人。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AISkinAuthStyle.pink.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var feedbackMessages: some View {
        if let errorMessage {
            feedbackBanner(
                text: errorMessage,
                icon: "exclamationmark.circle.fill",
                foreground: Color(red: 0.718, green: 0.110, blue: 0.110),
                background: Color(red: 1.0, green: 0.922, blue: 0.933)
            )
        } else if let infoMessage {
            feedbackBanner(
                text: infoMessage,
                icon: "checkmark.circle.fill",
                foreground: Color(red: 0.14, green: 0.50, blue: 0.34),
                background: Color(red: 0.91, green: 0.98, blue: 0.94)
            )
        }
    }

    private var successCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.91, green: 0.98, blue: 0.94))
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(red: 0.14, green: 0.50, blue: 0.34))
            }

            VStack(spacing: 8) {
                Text("密码修改成功")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color(red: 0.259, green: 0.259, blue: 0.259))
                Text("请使用新密码重新登录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("返回登录") {
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AISkinAuthStyle.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: AISkinAuthStyle.pink.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }

    private func authField<Content: View>(
        title: String,
        icon: String,
        error: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title: title, icon: icon)
            content()
                .padding(.horizontal, 12)
                .frame(minHeight: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(error == nil ? Color.gray.opacity(0.2) : errorColor, lineWidth: 1)
                }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(errorColor)
            }
        }
    }

    private func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title: title, icon: "lock.fill")

            HStack {
                Group {
                    if isVisible.wrappedValue {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .textContentType(.newPassword)

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(isVisible.wrappedValue ? "隐藏密码" : "显示密码")
            }
            .padding(.leading, 12)
            .frame(minHeight: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(fieldBorder(for: field), lineWidth: 1)
            }

            validationMessage(for: field)
        }
    }

    private func fieldLabel(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AISkinAuthStyle.pink)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(red: 0.259, green: 0.259, blue: 0.259))
        }
    }

    @ViewBuilder
    private func validationMessage(for field: Field) -> some View {
        if let message = validationErrors[field] {
            Text(message)
                .font(.caption)
                .foregroundStyle(errorColor)
        }
    }

    private func feedbackBanner(
        text: String,
        icon: String,
        foreground: Color,
        background: Color
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(foreground)
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func fieldBorder(for field: Field) -> Color {
        validationErrors[field] == nil ? Color.gray.opacity(0.2) : errorColor
    }

    private var errorColor: Color {
        Color(red: 0.957, green: 0.263, blue: 0.212)
    }

    private func sendVerificationCode() {
        validationErrors[.phone] = phoneValidationMessage
        guard validationErrors[.phone] == nil else { return }

        isSendingCode = true
        errorMessage = nil
        infoMessage = nil

        Task {
            do {
                let message = try await sessionStore.requestPasswordReset(phone: phone)
                infoMessage = message
                startCooldown()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSendingCode = false
        }
    }

    private func resetPassword() {
        guard validateResetForm() else { return }

        isResettingPassword = true
        errorMessage = nil
        infoMessage = nil

        Task {
            do {
                try await sessionStore.resetPassword(
                    phone: phone,
                    verificationCode: verificationCode,
                    newPassword: newPassword
                )
                countdownTask?.cancel()
                didResetPassword = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isResettingPassword = false
        }
    }

    private func validateResetForm() -> Bool {
        validationErrors = [:]
        validationErrors[.phone] = phoneValidationMessage

        if verificationCode.count != 6 || !verificationCode.allSatisfy(\.isNumber) {
            validationErrors[.verificationCode] = "请输入6位短信验证码"
        }
        if newPassword.count < 6 {
            validationErrors[.newPassword] = "密码长度至少6个字符"
        }
        if confirmPassword.isEmpty {
            validationErrors[.confirmPassword] = "请再次输入新密码"
        } else if confirmPassword != newPassword {
            validationErrors[.confirmPassword] = "两次输入的密码不一致"
        }

        return validationErrors.isEmpty
    }

    private var phoneValidationMessage: String? {
        if phone.isEmpty {
            return "请输入手机号"
        }
        let predicate = NSPredicate(format: "SELF MATCHES %@", "^1[3-9]\\d{9}$")
        return predicate.evaluate(with: phone) ? nil : "请输入有效的手机号"
    }

    private func startCooldown() {
        countdownTask?.cancel()
        cooldownSeconds = 60
        countdownTask = Task {
            while !Task.isCancelled && cooldownSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                cooldownSeconds -= 1
            }
        }
    }
}

private extension ForgotPasswordView {
    enum Field: Hashable {
        case phone
        case verificationCode
        case newPassword
        case confirmPassword
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(initialPhone: "13800138000")
            .environmentObject(AppDependencies.preview.sessionStore)
    }
}
