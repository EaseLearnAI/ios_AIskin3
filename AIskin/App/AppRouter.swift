import Observation
import SwiftUI

/// Owns top-level selection and one independent navigation history per tab.
@MainActor
@Observable
final class AppRouter {
    enum PlanEntryAction {
        case products, skinAnalysis, retry

        var title: String {
            switch self {
            case .products: "添加产品"
            case .skinAnalysis: "肌肤检测"
            case .retry: "重新检查"
            }
        }

        var systemImage: String {
            switch self {
            case .products: "shippingbox"
            case .skinAnalysis: "faceid"
            case .retry: "arrow.clockwise"
            }
        }
    }

    var selectedTab: AppTab
    var isAtRoot: Bool { path(for: selectedTab).isEmpty }

    private(set) var homePath: [AppRoute] = []
    private(set) var productsPath: [AppRoute] = []
    private(set) var skinAnalysisPath: [AppRoute] = []
    private(set) var requestedProductEntry: ProductEntry?
    private(set) var planEntryToast: String?
    private(set) var planEntryToastTitle = "暂时无法检查资料"
    private(set) var planEntryToastID = UUID()
    private(set) var planEntryActions: [PlanEntryAction] = []
    @ObservationIgnored private var planEntryTask: Task<Void, Never>?
    @ObservationIgnored private let planPreparationClient: any PlanPreparationClient

    init(selectedTab: AppTab = .home, planPreparationClient: (any PlanPreparationClient)? = nil) {
        self.selectedTab = selectedTab
        self.planPreparationClient = planPreparationClient ?? LivePlanPreparationClient()
    }

    // There is no actor-bound teardown. Avoid the isolated-deinit back-deploy
    // path that crashes in the Swift 6.2.4 / iOS 26.3 simulator runtime.
    nonisolated deinit {}

    func select(_ tab: AppTab) {
        selectedTab = tab
    }

    func showProducts() {
        showProductEntry(.library)
    }

    func showProductCapture() {
        showProductEntry(.capture)
    }

    func showConflictSelection(productID: String? = nil) {
        showProductEntry(.conflictSelection(productID: productID))
    }

    func showSkinAnalysis() {
        selectedTab = .skinAnalysis
    }

    func showPersonalizedPlan() {
        guard planEntryTask == nil, path(for: selectedTab).last != .personalizedPlan else { return }
        planEntryTask = Task {
            defer { planEntryTask = nil }
            await validateAndShowPersonalizedPlan()
        }
    }

    func validateAndShowPersonalizedPlan() async {
        let originTab = selectedTab
        let originPath = path(for: originTab)
        guard originPath.last != .personalizedPlan else { return }
        dismissPlanEntryToast()
        let prerequisites = PlanPreparationStore(client: planPreparationClient)
        await prerequisites.refresh()
        guard !Task.isCancelled, selectedTab == originTab, path(for: originTab) == originPath else { return }
        if prerequisites.canCreatePlan {
            navigate(to: .personalizedPlan, in: originTab)
        } else {
            if case .failed(let message) = prerequisites.state {
                planEntryToastTitle = "暂时无法检查资料"
                planEntryToast = message + "，请稍后重试。"
                planEntryActions = [.retry]
            } else {
                planEntryToastTitle = prerequisites.entryNoticeTitle
                planEntryToast = prerequisites.entryNoticeMessage
                planEntryActions = []
                if !prerequisites.hasSkinReport { planEntryActions.append(.skinAnalysis) }
                if !prerequisites.hasEnoughProducts { planEntryActions.append(.products) }
            }
            planEntryToastID = UUID()
        }
    }

    func dismissPlanEntryToast() {
        planEntryToast = nil
        planEntryActions = []
    }

    func performPlanEntryAction(_ action: PlanEntryAction) {
        dismissPlanEntryToast()
        switch action {
        case .products: showProducts()
        case .skinAnalysis:
            popToRoot(in: .skinAnalysis)
            showSkinAnalysis()
        case .retry: showPersonalizedPlan()
        }
    }

    private func showProductEntry(_ entry: ProductEntry) {
        requestedProductEntry = entry
        productsPath.removeAll()
        selectedTab = .products
    }

    func navigate(to route: AppRoute, in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab
        setPath(path(for: targetTab) + [route], for: targetTab)
        selectedTab = targetTab
    }

    func popToRoot(in tab: AppTab? = nil) {
        setPath([], for: tab ?? selectedTab)
    }

    func reset() {
        planEntryTask?.cancel()
        planEntryToast = nil
        selectedTab = .home
        requestedProductEntry = nil
        homePath.removeAll()
        productsPath.removeAll()
        skinAnalysisPath.removeAll()
    }

    func selectedTabBinding() -> Binding<AppTab> {
        Binding(
            get: { self.selectedTab },
            set: { self.select($0) }
        )
    }

    func pathBinding(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(
            get: { self.path(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    /// The feature consumes each entry once, keeping its existing store alive.
    func productEntryBinding() -> Binding<ProductEntry?> {
        Binding(
            get: { self.requestedProductEntry },
            set: { self.requestedProductEntry = $0 }
        )
    }

    private func path(for tab: AppTab) -> [AppRoute] {
        switch tab {
        case .home: homePath
        case .products: productsPath
        case .skinAnalysis: skinAnalysisPath
        }
    }

    private func setPath(_ path: [AppRoute], for tab: AppTab) {
        switch tab {
        case .home: homePath = path
        case .products: productsPath = path
        case .skinAnalysis: skinAnalysisPath = path
        }
    }
}
