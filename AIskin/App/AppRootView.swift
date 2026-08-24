import SwiftUI

/// Generic native shell kept separate from feature construction so it can be
/// previewed and tested without authentication or live network services.
struct AppTabShell<HomeContent: View, ProductsContent: View, SkinContent: View, ProfileContent: View>: View {
    let router: AppRouter
    private let homeContent: () -> HomeContent
    private let productsContent: () -> ProductsContent
    private let skinContent: () -> SkinContent
    private let profileContent: () -> ProfileContent

    init(
        router: AppRouter,
        @ViewBuilder home: @escaping () -> HomeContent,
        @ViewBuilder products: @escaping () -> ProductsContent,
        @ViewBuilder skinAnalysis: @escaping () -> SkinContent,
        @ViewBuilder profile: @escaping () -> ProfileContent
    ) {
        self.router = router
        self.homeContent = home
        self.productsContent = products
        self.skinContent = skinAnalysis
        self.profileContent = profile
    }

    var body: some View {
        TabView(selection: router.selectedTabBinding()) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack(path: router.pathBinding(for: tab)) {
                    rootContent(for: tab)
                }
                .tabItem { tab.label }
                .tag(tab)
                .accessibilityIdentifier("app.tab.\(tab.legacyIndex)")
            }
        }
        .tint(AISkinColor.brand)
        .lookinName("app.main-tabs")
    }

    @ViewBuilder
    private func rootContent(for tab: AppTab) -> some View {
        switch tab {
        case .home: homeContent()
        case .products: productsContent()
        case .skinAnalysis: skinContent()
        case .profile: profileContent()
        }
    }
}

/// Production composition of the shell and the existing feature screens.
struct AppRootView: View {
    @ObservedObject var authService: AuthService
    @State private var router: AppRouter
    @StateObject private var planStore: PlanStore

    init(authService: AuthService) {
        self.authService = authService
        self._router = State(initialValue: AppRouter())
        self._planStore = StateObject(wrappedValue: PlanStore())
    }

    init(authService: AuthService, router: AppRouter) {
        self.authService = authService
        self._router = State(initialValue: router)
        self._planStore = StateObject(wrappedValue: PlanStore())
    }

    var body: some View {
        AppTabShell(router: router) {
            HomeView(
                selectedTab: router.legacyTabBinding(),
                shouldEnableConflictMode: router.legacyConflictModeBinding(),
                planStore: planStore
            )
            .appRouteDestinations(router: router, planStore: planStore)
        } products: {
            ProductView(initialConflictMode: router.requestsConflictSelection)
                .id(router.productPresentationID)
                .onAppear {
                    router.didPresentProductLaunchRequest()
                }
                .appRouteDestinations(router: router, planStore: planStore)
        } skinAnalysis: {
            SkinStatusView(selectedTab: router.legacyTabBinding())
                .appRouteDestinations(router: router, planStore: planStore)
        } profile: {
            ProfileView(store: ProfileStore(client: authService))
                .environmentObject(authService)
                .appRouteDestinations(router: router, planStore: planStore)
        }
        .environment(router)
    }
}

private extension View {
    func appRouteDestinations(router: AppRouter, planStore: PlanStore) -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .personalizedPlan:
                PersonalizedRoutineModalView(planStore: planStore)
            case .productDetail(let productID):
                IngredientView(productId: productID)
            case .conflictAnalysis(let productIDs):
                ConflictView(productIds: productIDs)
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
    } profile: {
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
