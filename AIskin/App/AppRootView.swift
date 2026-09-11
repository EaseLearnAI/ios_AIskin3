import SwiftUI

/// Generic native shell kept separate from feature construction so it can be
/// previewed and tested without authentication or live network services.
struct AppTabShell<HomeContent: View, ProductsContent: View, SkinContent: View, PlanContent: View, ProfileContent: View>: View {
    let router: AppRouter
    @State private var isProfilePresented = false
    private let onSkinHistoryTap: (() -> Void)?
    private let onProductAddTap: (() -> Void)?
    private let homeContent: () -> HomeContent
    private let productsContent: () -> ProductsContent
    private let skinContent: () -> SkinContent
    private let planContent: () -> PlanContent
    private let profileContent: (@escaping () -> Void) -> ProfileContent

    init(
        router: AppRouter,
        onSkinHistoryTap: (() -> Void)? = nil,
        onProductAddTap: (() -> Void)? = nil,
        @ViewBuilder home: @escaping () -> HomeContent,
        @ViewBuilder products: @escaping () -> ProductsContent,
        @ViewBuilder skinAnalysis: @escaping () -> SkinContent,
        @ViewBuilder personalizedPlan: @escaping () -> PlanContent,
        @ViewBuilder profile: @escaping (@escaping () -> Void) -> ProfileContent
    ) {
        self.router = router
        self.onSkinHistoryTap = onSkinHistoryTap
        self.onProductAddTap = onProductAddTap
        self.homeContent = home
        self.productsContent = products
        self.skinContent = skinAnalysis
        self.planContent = personalizedPlan
        self.profileContent = profile
    }

    var body: some View {
        AISkinLeadingNavigationContainer(isPresented: $isProfilePresented) {
            nativeTabs
                .lookinName("app.main-tabs")
                .background(Color.clear)
        } destination: {
            profileContent { isProfilePresented = false }
        }
        .allowsHitTesting(router.planEntryToast == nil)
        .accessibilityHidden(router.planEntryToast != nil)
        .overlay(alignment: .center) {
            if let message = router.planEntryToast {
                AISkinModalOverlay {
                    AISkinToast(
                        message: message,
                        style: .centered(title: router.planEntryToastTitle),
                        systemImage: router.planEntryActions.first?.systemImage ?? "info.circle.fill",
                        onDismiss: router.dismissPlanEntryToast,
                        primaryAction: router.planEntryActions.first.map(toastAction),
                        secondaryAction: router.planEntryActions.dropFirst().first.map(toastAction)
                    )
                    .accessibilityIdentifier("plan.entry.toast")
                }
            }
        }
    }

    private func toastAction(_ action: AppRouter.PlanEntryAction) -> AISkinToastAction {
        AISkinToastAction(title: action.title) {
            isProfilePresented = false
            router.performPlanEntryAction(action)
        }
    }

    private var nativeTabs: some View {
        AISkinTabBar(selection: router.selectedTabBinding()) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack(path: router.pathBinding(for: tab)) {
                    VStack(spacing: 0) {
                        MainTabHeader(
                            title: tab.title,
                            onProfileTap: { isProfilePresented = true },
                            trailingSystemImage: tab == .skinAnalysis ? "clock.arrow.circlepath" : tab == .products ? "plus" : nil,
                            trailingAccessibilityLabel: tab == .skinAnalysis ? "历史记录" : tab == .products ? "添加护肤品" : nil,
                            onTrailingTap: tab == .skinAnalysis ? onSkinHistoryTap : tab == .products ? onProductAddTap : nil
                        )

                        rootContent(for: tab)
                    }
                    .aiSkinTransparentNavigationContainer()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .personalizedPlan: planContent()
                        }
                    }
                }
                .tabItem {
                    tab.label.accessibilityIdentifier("app.tab.\(tab.rawValue)")
                }
                .tag(tab)
                .accessibilityIdentifier("app.tab-content.\(tab.rawValue)")
                .toolbar(router.isAtRoot ? .visible : .hidden, for: .tabBar)
            }
        }
    }

    @ViewBuilder
    private func rootContent(for tab: AppTab) -> some View {
        switch tab {
        case .home: homeContent()
        case .products: productsContent()
        case .skinAnalysis: skinContent()
        }
    }
}

/// Production composition of the shell and the existing feature screens.
struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var authService: AuthService
    @State private var router: AppRouter
    @StateObject private var planStore: PlanStore
    @StateObject private var skinAnalysisStore: SkinAnalysisStore
    @StateObject private var profileStore: ProfileStore
    @StateObject private var membershipStore: MembershipPurchaseStore

    init(authService: AuthService, router: AppRouter? = nil) {
        self.authService = authService
        self._router = State(initialValue: router ?? AppRouter())
        self._planStore = StateObject(wrappedValue: PlanStore())
        self._skinAnalysisStore = StateObject(wrappedValue: SkinAnalysisStore())
        self._profileStore = StateObject(wrappedValue: ProfileStore(client: authService))
        self._membershipStore = StateObject(wrappedValue: MembershipPurchaseStore(
            client: AppDependencies.live.paymentClient,
            launcher: AppDependencies.live.paymentLauncher,
            endpointScope: AppBackendConfiguration.mode.rawValue + ":" + URLSessionHTTPClient.defaultBaseURL.absoluteString
        ))
    }

    var body: some View {
        AppTabShell(
            router: router,
            onSkinHistoryTap: { skinAnalysisStore.isHistoryPresented = true },
            onProductAddTap: { router.showProductCapture() }
        ) {
            HomeView(planStore: planStore)
        } products: {
            ProductView(requestedEntry: router.productEntryBinding())
        } skinAnalysis: {
            SkinStatusView(store: skinAnalysisStore, onCreatePlan: router.showPersonalizedPlan)
        } personalizedPlan: {
            PersonalizedPlanView(planStore: planStore)
        } profile: { close in
            ProfileView(store: profileStore, membershipStore: membershipStore, onClose: close)
                .environmentObject(authService)
        }
        .environment(router)
        .task(id: authService.currentUser?.id) {
            await membershipStore.load(ownerID: authService.currentUser?.id)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshMembership() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .aisKinPaymentReturned)) { _ in
            refreshMembership()
        }
        .onDisappear { membershipStore.resetForLogout() }
    }

    private func refreshMembership() {
        Task {
            if membershipStore.catalog == nil {
                await membershipStore.load(ownerID: authService.currentUser?.id)
            } else {
                await membershipStore.handleBecameActive()
            }
        }
    }
}

#Preview("Native app shell") {
    @Previewable @State var router = AppRouter()

    AppTabShell(router: router) {
        AISkinPreviewTab(title: "首页", icon: "house.fill")
    } products: {
        AISkinPreviewTab(title: "产品分析", icon: "shippingbox.fill")
    } skinAnalysis: {
        AISkinPreviewTab(title: "肌肤检测", icon: "sparkles")
    } personalizedPlan: {
        AISkinPreviewTab(title: "个性化方案", icon: "doc.text.fill")
    } profile: { _ in
        AISkinPreviewTab(title: "我的", icon: "person.fill")
    }
}

private struct AISkinPreviewTab: View {
    let title: String
    let icon: String

    var body: some View {
        AISkinScreenBackground {
            ContentUnavailableView(title, systemImage: icon)
        }
    }
}
