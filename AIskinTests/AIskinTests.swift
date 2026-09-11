//
//  AIskinTests.swift
//  AIskinTests
//
//  Created by terry on 2025/11/3.
//

import XCTest
import SwiftUI
import UIKit
@testable import AIskin

final class AIskinTests: XCTestCase {

    @MainActor
    func testMainNavigationSymbolsExistInTheRuntimeCatalog() {
        let symbols = AppTab.allCases.flatMap { [$0.systemImage, $0.selectedSystemImage] } + ["faceid"]
        for symbol in Set(symbols) {
            XCTAssertNotNil(UIImage(systemName: symbol), "Unsupported SF Symbol: \(symbol)")
        }
    }

    @MainActor
    func testMainNavigationContainsThreeTabs() {
        XCTAssertEqual(AppTab.allCases, [.home, .products, .skinAnalysis])
        XCTAssertEqual(AppTab.allCases.map(\.title), ["首页", "护肤柜", "肌肤检测"])
        XCTAssertEqual(AppTab.allCases.map(\.rawValue), [0, 1, 2])
        XCTAssertNil(AppTab(rawValue: 3))
    }

    @MainActor
    func testPlanEntryPushesWithinTheCurrentTabAndKeepsItsHistory() async {
        let router = AppRouter(selectedTab: .skinAnalysis, planPreparationClient: ReadyPlanEntryClient())
        await router.validateAndShowPersonalizedPlan()
        XCTAssertEqual(router.selectedTab, .skinAnalysis)
        XCTAssertEqual(router.skinAnalysisPath, [.personalizedPlan])
        XCTAssertFalse(router.isAtRoot)
        await router.validateAndShowPersonalizedPlan()
        XCTAssertEqual(router.skinAnalysisPath, [.personalizedPlan])
        router.selectedTabBinding().wrappedValue = .products
        XCTAssertTrue(router.isAtRoot)
        router.selectedTabBinding().wrappedValue = .skinAnalysis
        XCTAssertEqual(router.skinAnalysisPath, [.personalizedPlan])
        router.popToRoot()
        XCTAssertTrue(router.skinAnalysisPath.isEmpty)
        XCTAssertTrue(router.isAtRoot)
    }

    @MainActor
    func testNavigationHistoriesAndBackBindingsAreIndependent() {
        let router = AppRouter()
        router.navigate(to: .personalizedPlan)
        router.navigate(to: .personalizedPlan, in: .products)
        router.navigate(to: .personalizedPlan, in: .skinAnalysis)

        router.pathBinding(for: .products).wrappedValue = []
        XCTAssertEqual(router.selectedTab, .skinAnalysis)
        XCTAssertEqual(router.homePath, [.personalizedPlan])
        XCTAssertTrue(router.productsPath.isEmpty)
        XCTAssertEqual(router.skinAnalysisPath, [.personalizedPlan])

        router.popToRoot(in: .home)
        XCTAssertTrue(router.homePath.isEmpty)
        XCTAssertEqual(router.skinAnalysisPath, [.personalizedPlan])
        XCTAssertEqual(router.selectedTabBinding().wrappedValue, .skinAnalysis)
    }

    @MainActor
    func testProductEntryRequestsReplaceEachOtherAndCanBeConsumed() {
        let router = AppRouter(selectedTab: .skinAnalysis)
        router.showConflictSelection(productID: "product-a")
        XCTAssertEqual(router.selectedTab, .products)
        XCTAssertEqual(router.requestedProductEntry, .conflictSelection(productID: "product-a"))

        router.showProductCapture()
        XCTAssertEqual(router.selectedTab, .products)
        XCTAssertEqual(router.requestedProductEntry, .capture)

        router.productEntryBinding().wrappedValue = nil
        XCTAssertNil(router.requestedProductEntry)
        XCTAssertEqual(router.selectedTab, .products)

        router.showProductCapture()
        XCTAssertEqual(router.productEntryBinding().wrappedValue, .capture,
                       "A consumed entry must be available again without replacing the product screen")
        router.showProducts()
        XCTAssertEqual(router.requestedProductEntry, .library)
        router.showConflictSelection()
        XCTAssertEqual(router.requestedProductEntry, .conflictSelection(productID: nil))
    }

    @MainActor
    func testExplicitProductEntrancesReachTheRootAndPreserveOtherTabs() {
        let router = AppRouter()
        router.navigate(to: .personalizedPlan)
        router.navigate(to: .personalizedPlan, in: .skinAnalysis)

        let entrances: [() -> Void] = [
            { router.showProducts() },
            { router.showProductCapture() },
            { router.showConflictSelection() }
        ]
        for enterProducts in entrances {
            router.navigate(to: .personalizedPlan, in: .products)
            enterProducts()
            XCTAssertEqual(router.selectedTab, .products)
            XCTAssertTrue(router.productsPath.isEmpty)
            XCTAssertTrue(router.isAtRoot)
            XCTAssertEqual(router.homePath, [.personalizedPlan])
            XCTAssertEqual(router.skinAnalysisPath, [.personalizedPlan])
            router.productEntryBinding().wrappedValue = nil
        }
    }

    @MainActor
    func testResetClearsEveryHistoryAndUnconsumedProductEntry() {
        let router = AppRouter()
        router.showProductCapture()
        for tab in AppTab.allCases {
            router.navigate(to: .personalizedPlan, in: tab)
        }

        router.reset()

        XCTAssertEqual(router.selectedTab, .home)
        XCTAssertTrue(router.isAtRoot)
        XCTAssertNil(router.requestedProductEntry)
        for tab in AppTab.allCases {
            XCTAssertTrue(router.pathBinding(for: tab).wrappedValue.isEmpty)
        }
    }
}

@MainActor
private struct ReadyPlanEntryClient: PlanPreparationClient {
    func hasSkinReport() async throws -> Bool { true }
    func analyzedProductCount() async throws -> Int { 2 }
}
