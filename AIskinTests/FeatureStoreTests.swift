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

    func testPlanGenerationRejectsDuplicateAndIgnoresCancelledCompletion() async {
        let plan = SkinPlan(id: "generated", name: "方案", tags: [], morning: [], evening: [], recommendations: [])
        let responses: [Result<SkinPlan, Error>] = [.success(plan), .failure(StoreTestError.expected)]
        for response in responses {
            let client = PlansClientMock()
            let store = PlanStore(client: client)
            let started = expectation(description: "Plan generation is in flight")
            var pending: CheckedContinuation<SkinPlan, Error>?
            client.generateHandler = {
                try await withCheckedThrowingContinuation {
                    pending = $0
                    started.fulfill()
                }
            }
            let operation = Task {
                await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)
            }
            await fulfillment(of: [started], timeout: 1)
            await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)
            XCTAssertEqual(client.generationRequests, 1)
            XCTAssertTrue(store.isGenerating)

            operation.cancel()
            pending?.resume(with: response)
            await operation.value

            XCTAssertNil(store.generatedPlan)
            XCTAssertNil(store.generationError)
            XCTAssertFalse(store.isGenerating)
            client.generateHandler = { plan }
            await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)
            XCTAssertEqual(store.generatedPlan?.id, "generated", "A fresh request after cancellation should succeed")
            XCTAssertEqual(client.generationRequests, 2)
        }
    }

    func testPlanGenerationCancellationErrorDoesNotShowFailure() async {
        let client = PlansClientMock()
        client.generateHandler = { throw CancellationError() }
        let store = PlanStore(client: client)

        await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)

        XCTAssertNil(store.generatedPlan)
        XCTAssertNil(store.generationError)
        XCTAssertFalse(store.isGenerating)
    }

    func testAlreadyCancelledGenerationDoesNotSubmit() async {
        let client = PlansClientMock()
        let store = PlanStore(client: client)
        let operation = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)
        }
        await operation.value
        XCTAssertEqual(client.generationRequests, 0)
        XCTAssertNil(store.generationError)
        XCTAssertFalse(store.isGenerating)
    }

    func testConflictAnalysisRejectsDuplicateAndIgnoresCancelledCompletion() async {
        let report = ConflictAnalysisData(conflictId: "result", conflicts: [], safeCombo: [], recommendations: nil, products: [])
        let responses: [Result<ConflictAnalysisData, Error>] = [.success(report), .failure(StoreTestError.expected)]
        for response in responses {
            let client = ConflictClientMock()
            let store = ConflictAnalysisStore(client: client)
            let started = expectation(description: "Conflict analysis is in flight")
            var pending: CheckedContinuation<ConflictAnalysisData, Error>?
            client.analyzeHandler = {
                try await withCheckedThrowingContinuation {
                    pending = $0
                    started.fulfill()
                }
            }
            let operation = Task { await store.analyze(productIDs: ["one", "two"]) }
            await fulfillment(of: [started], timeout: 1)
            await store.analyze(productIDs: ["one", "two"])
            XCTAssertEqual(client.analysisRequests, 1)

            operation.cancel()
            pending?.resume(with: response)
            await operation.value

            guard case .idle = store.state else { return XCTFail("Cancellation must end loading without showing a result or error") }
            client.analyzeHandler = { report }
            await store.analyze(productIDs: ["one", "two"])
            guard case .loaded = store.state else { return XCTFail("A fresh request after cancellation should succeed") }
            XCTAssertEqual(client.analysisRequests, 2)
        }
    }

    func testConflictCancellationErrorReturnsToIdle() async {
        let client = ConflictClientMock()
        client.analyzeHandler = { throw CancellationError() }
        let store = ConflictAnalysisStore(client: client)

        await store.analyze(productIDs: ["one", "two"])

        guard case .idle = store.state else { return XCTFail("Cancellation should not show a failure") }
    }

    func testAlreadyCancelledConflictAnalysisDoesNotSubmit() async {
        let client = ConflictClientMock()
        let store = ConflictAnalysisStore(client: client)
        let operation = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await store.analyze(productIDs: ["one", "two"])
        }
        await operation.value
        XCTAssertEqual(client.analysisRequests, 0)
        guard case .idle = store.state else { return XCTFail("No request should have started") }
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
    var analysisRequests = 0
    var analyzeHandler: (() async throws -> ConflictAnalysisData)?

    func analyze(productIDs: [String]) async throws -> ConflictAnalysisData {
        analysisRequests += 1
        if let analyzeHandler { return try await analyzeHandler() }
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
    var generationRequests = 0
    var generateHandler: (() async throws -> SkinPlan)?

    func activePlan() async throws -> SkinPlan? {
        if shouldFail { throw StoreTestError.expected }
        return nil
    }
    func adopt(planID: String) async throws -> SkinPlan { throw StoreTestError.expected }
    func daily(planID: String, date: String, timezone: String) async throws -> PlanDailyProgress { throw StoreTestError.expected }
    func updateDailyStep(planID: String, date: String, timezone: String, period: String, step: Int, completed: Bool) async throws -> PlanDailyProgress { throw StoreTestError.expected }

    func plans() async throws -> [SkinPlan] {
        if shouldFail { throw StoreTestError.expected }
        return []
    }

    func plan(id: String) async throws -> SkinPlan { throw StoreTestError.expected }
    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan {
        generationRequests += 1
        if let generateHandler { return try await generateHandler() }
        throw StoreTestError.expected
    }
    func updateStep(planID: String, period: String, step: Int, completed: Bool) async throws -> SkinPlan { throw StoreTestError.expected }
    func latestSkinAnalysis() async throws -> SkinAnalysis? { nil }
}
