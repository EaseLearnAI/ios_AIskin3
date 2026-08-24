//
//  ProfileView.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @ObservedObject var store: ProfileStore
    
    var user: User? {
        authService.currentUser
    }
    
    var body: some View {
        ZStack {
            // Background - Sakura gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.972, green: 0.733, blue: 0.816),
                    Color(red: 0.882, green: 0.745, blue: 0.906)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    AppHeader(
                        title: "我的护肤档案",
                        icon: "person.circle.fill",
                        rightIcon: "gearshape.fill"
                    )
                    
                    // Content
                    VStack(spacing: 20) {
                        // User Profile Card
                        UserProfileCard(user: user)
                        
                        // Achievement Section
                        AchievementSection()
                        
                        // Settings Menu
                        SettingsMenuSection(
                            onUsernameEdit: { store.sheet = .username },
                            onGenderEdit: { store.sheet = .gender },
                            onFeedback: { store.sheet = .feedback },
                            onLogout: { store.confirmation = .logout },
                            onDeleteAccount: { store.confirmation = .deleteAccount }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .padding(.bottom, 80)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1.0, green: 0.976, blue: 0.984),
                                Color(red: 0.961, green: 0.969, blue: 0.980)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                }
            }
        }
        .sheet(item: $store.sheet) { destination in
            switch destination {
            case .username:
                UsernameEditModal(store: store)
            case .gender:
                GenderEditModal(store: store)
            case .feedback:
                FeedbackModal()
            }
        }
        .alert(item: $store.confirmation) { action in
            switch action {
            case .logout:
                Alert(
                    title: Text("退出登录"),
                    message: Text("确定要退出登录吗？退出后需要重新登录才能使用完整功能"),
                    primaryButton: .destructive(Text("确定退出")) { Task { await store.confirm(.logout) } },
                    secondaryButton: .cancel()
                )
            case .deleteAccount:
                Alert(
                    title: Text("注销账户"),
                    message: Text("确定要注销账户吗？此操作将永久删除您的账户及所有相关数据，且无法恢复。请谨慎操作！"),
                    primaryButton: .destructive(Text("确定注销")) { Task { await store.confirm(.deleteAccount) } },
                    secondaryButton: .cancel()
                )
            }
        }
        .alert("操作失败", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "操作失败，请稍后重试")
        }
    }
}

// Modal views remain in ProfileView for convenience

struct UsernameEditModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: ProfileStore
    @State private var newUsername: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                TextField("请输入新的用户名", text: $newUsername)
                    .onAppear {
                        newUsername = store.user?.name ?? ""
                    }
                    .textFieldStyle(LoginTextFieldStyle())
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        if await store.updateUsername(newUsername) {
                            dismiss()
                        }
                    }
                }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.400, green: 0.498, blue: 0.918),
                                    Color(red: 0.463, green: 0.294, blue: 0.635)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(newUsername.isEmpty)
            }
            .navigationTitle("修改用户名")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GenderEditModal: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: ProfileStore
    @State private var selectedGender: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    GenderOption(
                        icon: "person.fill",
                        label: "男生",
                        isSelected: selectedGender == "male",
                        action: { selectedGender = "male" }
                    )
                    
                    GenderOption(
                        icon: "person.fill",
                        label: "女生",
                        isSelected: selectedGender == "female",
                        action: { selectedGender = "female" }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                Button(action: {
                    Task {
                        if await store.updateGender(selectedGender) {
                            dismiss()
                        }
                    }
                }) {
                    Text("保存")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.400, green: 0.498, blue: 0.918),
                                    Color(red: 0.463, green: 0.294, blue: 0.635)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(selectedGender.isEmpty)
            }
            .navigationTitle("修改性别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GenderOption: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? Color(red: 0.400, green: 0.498, blue: 0.918) : .gray)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? Color(red: 0.400, green: 0.498, blue: 0.918) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                isSelected ?
                Color(red: 0.400, green: 0.498, blue: 0.918).opacity(0.1) :
                Color.gray.opacity(0.05)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ?
                        Color(red: 0.400, green: 0.498, blue: 0.918) :
                        Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
    }
}

struct FeedbackModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: String = "功能建议"
    
    var body: some View {
        NavigationView {
            Form {
                Section("反馈信息") {
                    TextField("标题", text: $title)
                    Picker("类别", selection: $category) {
                        Text("功能建议").tag("功能建议")
                        Text("问题反馈").tag("问题反馈")
                        Text("界面优化").tag("界面优化")
                        Text("产品需求").tag("产品需求")
                        Text("其他").tag("其他")
                    }
                    TextEditor(text: $content)
                        .frame(height: 150)
                }
            }
            .navigationTitle("提交反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("提交") {
                        // Submit feedback logic
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
