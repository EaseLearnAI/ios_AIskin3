import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @ObservedObject var store: ProfileStore
    @ObservedObject var membershipStore: MembershipPurchaseStore
    var onClose: (() -> Void)? = nil
    @State private var showsMembership = false

    private var user: User? { authService.currentUser }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(title: "我的", backAction: { close() })
                .accessibilityIdentifier("profile.back")
            GeometryReader { geometry in
              ScrollView {
                AISkinProfilePanel(minimumHeight: geometry.size.height) {
                    VStack(alignment: .leading, spacing: AISkinAccountPlanTokens.profileSectionGap) {
                        AISkinProfileIdentity(
                            name: user?.name ?? "析肤用户",
                            avatarURL: (user?.avatar).flatMap(URL.init(string:)),
                            onUpgrade: { showsMembership = true }
                        )
                        VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                            profileSectionLabel("我的记录")
                            AISkinCard(inset: .none) {
                                VStack(spacing: 0) {
                                    NavigationLink { ProfileSkinHistoryView() } label: {
                                        AISkinSettingsRow(systemImage: "faceid", title: "检测历史")
                                    }.buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("profile.skin-history")
                                    AISkinDivider()
                                    NavigationLink { ConflictHistoryView() } label: {
                                        AISkinSettingsRow(systemImage: "square.3.layers.3d", title: "冲突检测")
                                    }.buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("profile.conflict-history")
                                }
                            }
                        }
                        ProfileAccountSection(store: store)
                        Text("让每一步护肤更清楚").font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            }
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showsMembership) {
            MembershipView(purchaseStore: membershipStore, ownerID: user?.id)
        }
        .accessibilityAction(.escape) { close() }
        .alert(item: $store.confirmation) { action in
            switch action {
            case .logout:
                Alert(
                    title: Text("退出登录"),
                    message: Text("确定要退出当前账户吗？"),
                    primaryButton: .destructive(Text("退出登录")) {
                        Task { await store.confirm(.logout) }
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            case .deleteAccount:
                Alert(
                    title: Text("注销账户"),
                    message: Text("账户注销入口位于“账户与安全”页面。"),
                    dismissButton: .default(Text("知道了"))
                )
            }
        }
        .profileErrorAlert(store: store)
        .fullScreenCover(isPresented: Binding(get: { store.isWorking }, set: { _ in })) {
            AISkinProcessingScreen(title: "退出登录", message: "正在退出登录", detail: "正在结束当前会话…")
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

private func profileSectionLabel(_ title: String) -> some View {
    Text(title).font(AISkinAccountPlanTokens.sectionLabel).foregroundStyle(AISkinColor.textSecondary)
        .padding(.leading, AISkinSpacing.xxSmall)
}

private struct ProfileAccountSection: View {
    @ObservedObject var store: ProfileStore
    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
            profileSectionLabel("账户")
            AISkinCard(inset: .none) {
                VStack(spacing: 0) {
                    NavigationLink { PersonalInformationView() } label: {
                        AISkinSettingsRow(systemImage: "person.text.rectangle", title: "个人信息")
                    }.buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("profile.personal-information")
                    AISkinDivider()
                    NavigationLink { AccountSecurityView(store: store) } label: {
                        AISkinSettingsRow(systemImage: "checkmark.shield", title: "账户与安全")
                    }.buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("profile.account-security")
                    AISkinDivider()
                    Button(role: .destructive) { store.confirmation = .logout } label: {
                        AISkinSettingsRow(systemImage: "rectangle.portrait.and.arrow.right", title: "退出登录", isDestructive: true, showsChevron: false)
                    }.buttonStyle(AISkinPressableStyle()).disabled(store.isWorking).accessibilityIdentifier("profile.logout")
                }
            }
        }
    }
}

private struct AccountSecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ProfileStore
    @State private var legalDocument: LegalDocument?

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(title: "账户与安全", backAction: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: AISkinAccountPlanTokens.profileSectionGap) {
                    VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                        profileSectionLabel("账户信息")
                        AISkinCard(inset: .none) {
                            VStack(spacing: 0) {
                                AISkinSettingsRow(title: "昵称", value: store.user?.name ?? "析肤用户", showsChevron: false)
                                    .accessibilityElement(children: .combine).accessibilityIdentifier("account-security.nickname")
                                AISkinDivider()
                                AISkinSettingsRow(title: "登录方式", value: store.user?.authenticationMethodName ?? "未提供", showsChevron: false)
                                    .accessibilityElement(children: .combine).accessibilityIdentifier("account-security.sign-in-method")
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                        profileSectionLabel("了解更多")
                        AISkinCard(inset: .none) {
                            VStack(spacing: 0) {
                                Button { legalDocument = .terms } label: { AISkinSettingsRow(systemImage: "doc.text", title: "使用条款") }
                                    .buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("account-security.terms")
                                AISkinDivider()
                                Button { legalDocument = .privacy } label: { AISkinSettingsRow(systemImage: "lock", title: "隐私政策") }
                                    .buttonStyle(AISkinPressableStyle()).accessibilityIdentifier("account-security.privacy")
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                        profileSectionLabel("账户管理")
                        AISkinCard(inset: .none) {
                            Button(role: .destructive) { store.confirmation = .deleteAccount } label: {
                                AISkinSettingsRow(systemImage: "person.crop.circle.badge.xmark", title: "注销账户", isDestructive: true)
                            }.buttonStyle(AISkinPressableStyle()).disabled(store.isWorking).accessibilityIdentifier("account-security.delete-account")
                        }
                        Text("注销后将删除账户及相关数据，且无法恢复。")
                            .font(AISkinReportTokens.caption).foregroundStyle(AISkinColor.textSecondary)
                    }
                }
                .padding(AISkinSpacing.screenEdge)
            }
        }
        .sheet(item: $legalDocument) { LegalDocumentView(document: $0) }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .alert(item: $store.confirmation) { action in
            switch action {
            case .deleteAccount:
                Alert(
                    title: Text("注销账户"),
                    message: Text("确定要永久注销账户吗？此操作将删除账户及相关数据，且无法恢复。"),
                    primaryButton: .destructive(Text("确定注销")) {
                        Task { await store.confirm(.deleteAccount) }
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            case .logout:
                Alert(
                    title: Text("退出登录"),
                    message: Text("请返回个人页面执行退出登录。"),
                    dismissButton: .default(Text("知道了"))
                )
            }
        }
        .profileErrorAlert(store: store)
        .fullScreenCover(isPresented: Binding(get: { store.isWorking }, set: { _ in })) {
            AISkinProcessingScreen(title: "注销账户", message: "正在注销账户", detail: "正在处理注销请求…")
        }
    }
}

private extension View {
    func profileErrorAlert(store: ProfileStore) -> some View {
        alert(
            "操作失败",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.clearError() } }
            )
        ) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "操作失败，请稍后重试")
        }
    }
}

private struct ProfileSkinHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @StateObject private var store = SkinAnalysisStore()
    @State private var showsReport = false
    @State private var opensPlanAfterReport = false

    var body: some View {
        VStack(spacing: AISkinSpacing.medium) {
            AppHeader(title: "检测历史", backAction: { dismiss() })
            SkinHistoryList(store: store, scope: .profile) { record in
                store.selectHistory(record)
                showsReport = true
            }
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.loadHistory() }
        .fullScreenCover(isPresented: $showsReport, onDismiss: {
            if opensPlanAfterReport {
                opensPlanAfterReport = false
                router.showPersonalizedPlan()
            }
        }) {
            NavigationStack {
                AISkinScreenBackground {
                    if store.result != nil {
                        SkinReportView(store: store, onBack: { showsReport = false }, onRetake: { store.reset() }, onCreatePlan: {
                            opensPlanAfterReport = true
                            showsReport = false
                        })
                    } else {
                        VStack(spacing: 0) {
                            AppHeader(title: "肌肤检测", backAction: { showsReport = false })
                            SkinStatusView(store: store, startsInCapture: true)
                        }
                    }
                }
            }
        }
    }
}
