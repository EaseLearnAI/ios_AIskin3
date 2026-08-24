import Observation
import SwiftUI

/// Owns top-level selection and one independent navigation history per tab.
@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab

    private(set) var homePath: [AppRoute] = []
    private(set) var productsPath: [AppRoute] = []
    private(set) var skinAnalysisPath: [AppRoute] = []
    private(set) var profilePath: [AppRoute] = []

    /// Incremented only for an explicit conflict-selection launch so the
    /// legacy ProductView receives a fresh state container for that flow.
    private(set) var productPresentationID = 0
    private(set) var requestsConflictSelection = false

    init(selectedTab: AppTab = .home) {
        self.selectedTab = selectedTab
    }

    func select(_ tab: AppTab) {
        if tab == .products, requestsConflictSelection {
            productPresentationID += 1
        }
        selectedTab = tab
    }

    func showProducts() {
        requestsConflictSelection = false
        selectedTab = .products
    }

    func showConflictSelection() {
        requestsConflictSelection = true
        productPresentationID += 1
        selectedTab = .products
    }

    func showSkinAnalysis() {
        selectedTab = .skinAnalysis
    }

    func didPresentProductLaunchRequest() {
        requestsConflictSelection = false
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
        selectedTab = .home
        requestsConflictSelection = false
        homePath.removeAll()
        productsPath.removeAll()
        skinAnalysisPath.removeAll()
        profilePath.removeAll()
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

    /// Compatibility bridge for existing feature views. New code should call
    /// the strongly typed routing methods directly.
    func legacyTabBinding() -> Binding<Int> {
        Binding(
            get: { self.selectedTab.legacyIndex },
            set: { newValue in
                guard let tab = AppTab(legacyIndex: newValue) else { return }
                self.select(tab)
            }
        )
    }

    /// Compatibility bridge for HomeView's existing conflict-mode handoff.
    func legacyConflictModeBinding() -> Binding<Bool> {
        Binding(
            get: { self.requestsConflictSelection },
            set: { self.requestsConflictSelection = $0 }
        )
    }

    private func path(for tab: AppTab) -> [AppRoute] {
        switch tab {
        case .home: homePath
        case .products: productsPath
        case .skinAnalysis: skinAnalysisPath
        case .profile: profilePath
        }
    }

    private func setPath(_ path: [AppRoute], for tab: AppTab) {
        switch tab {
        case .home: homePath = path
        case .products: productsPath = path
        case .skinAnalysis: skinAnalysisPath = path
        case .profile: profilePath = path
        }
    }
}
