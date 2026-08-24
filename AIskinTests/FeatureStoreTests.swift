import XCTest
import UIKit
@testable import AIskin

@MainActor
final class FeatureStoreTests: XCTestCase {
    func testProductsStoreExposesEmptyAndFailureAndCanRetry() async {
        let client = ProductsClientMock()
        let store = ProductsStore(client: client)

        await store.loadProducts()
        guard case .empty = store.loadState else {
            return XCTFail("空产品列表应进入 empty 状态")
        }

        client.result = .failure(StoreTestError.expected)
        await store.loadProducts()
        guard case .failed = store.loadState else {
            return XCTFail("接口错误应进入 failed 状态")
        }

        client.result = .success([])
        await store.loadProducts()
        guard case .empty = store.loadState else {
            return XCTFail("重试成功后应恢复 empty 状态")
        }
    }

    func testConflictStoreSuccessFailureAndRetry() async {
        let client = ConflictClientMock()
        let store = ConflictAnalysisStore(client: client)

        await store.analyze(productIDs: ["one", "two"])
        guard case .loaded = store.state else {
            return XCTFail("成功响应应进入 loaded 状态")
        }

        client.shouldFail = true
        await store.analyze(productIDs: ["one", "two"])
        guard case .failed = store.state else {
            return XCTFail("失败响应应进入 failed 状态")
        }

        client.shouldFail = false
        await store.analyze(productIDs: ["one", "two"])
        guard case .loaded = store.state else {
            return XCTFail("重试应恢复 loaded 状态")
        }
    }

    func testPlanStoreEmptyAndFailure() async {
        let client = PlansClientMock()
        let store = PlanStore(client: client)

        await store.load()
        guard case .empty = store.state else {
            return XCTFail("无方案时应进入 empty 状态")
        }

        client.shouldFail = true
        await store.load()
        guard case .failed = store.state else {
            return XCTFail("加载失败应进入 failed 状态")
        }
    }
}

private enum StoreTestError: Error { case expected }

@MainActor
private final class ProductsClientMock: ProductsClient {
    var currentUserID: String? = "user"
    var result: Result<[Product], Error> = .success([])

    func products(userID: String) async throws -> [Product] { try result.get() }
    func createProduct(name: String?, description: String?, label: String?, openingDate: Date?) async throws -> Product { throw StoreTestError.expected }
    func uploadImage(productID: String, image: UIImage) async throws -> String { throw StoreTestError.expected }
    func extractIngredients(productID: String) async throws -> (name: String, ingredients: [String]) { throw StoreTestError.expected }
    func analyzeIngredients(productID: String) async throws -> IngredientAnalysis { throw StoreTestError.expected }
    func deleteProduct(productID: String) async throws {}
}

@MainActor
private final class ConflictClientMock: ConflictAnalysisClient {
    var shouldFail = false

    func analyze(productIDs: [String]) async throws -> ConflictAnalysisData {
        if shouldFail { throw StoreTestError.expected }
        return ConflictAnalysisData(
            conflictId: "result",
            conflicts: [],
            safeCombo: [],
            recommendations: nil,
            products: []
        )
    }
}

@MainActor
private final class PlansClientMock: PlansClient {
    var shouldFail = false

    func plans() async throws -> [SkinPlan] {
        if shouldFail { throw StoreTestError.expected }
        return []
    }

    func plan(id: String) async throws -> SkinPlan { throw StoreTestError.expected }
    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan { throw StoreTestError.expected }
    func updateStep(planID: String, period: String, step: Int, completed: Bool) async throws -> SkinPlan { throw StoreTestError.expected }
    func latestSkinAnalysis() async throws -> SkinAnalysis? { nil }
}
