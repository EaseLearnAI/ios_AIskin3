import XCTest
@testable import AIskin

@MainActor
final class PlanPreparationStoreTests: XCTestCase {
    func testAllPrerequisiteCombinationsUseActualDataOnFirstEntry() async {
        for (report, count, expectedStep) in [
            (false, 0, PlanPreparationStore.Step.skin),
            (false, 1, .skin), (false, 2, .skin), (false, 5, .skin),
            (true, 0, .products), (true, 1, .products), (true, 2, .plan), (true, 5, .plan)
        ] {
            let client = PreparationClientStub()
            client.report = .success(report)
            client.products = .success(count)
            let store = PlanPreparationStore(client: client)
            XCTAssertFalse(store.canCreatePlan)
            await store.refresh()
            XCTAssertEqual(store.nextStep, expectedStep)
            XCTAssertEqual(store.canCreatePlan, report && count >= 2)
            XCTAssertEqual(store.isCompleted(.skin), report)
            XCTAssertEqual(store.isCompleted(.products), count >= 2)
            XCTAssertEqual(store.missingProductCount, max(0, 2 - count))
            XCTAssertEqual(store.completedCount, (report ? 1 : 0) + (count >= 2 ? 1 : 0))
            XCTAssertFalse(store.isCompleted(.plan))
        }
    }

    func testReturningAfterAddingMissingDataAutomaticallyAdvances() async {
        let client = PreparationClientStub()
        let store = PlanPreparationStore(client: client)
        await store.refresh()
        store.markPlanSaved()
        XCTAssertFalse(store.isCompleted(.plan))
        client.products = .success(1)
        await store.refresh()
        XCTAssertEqual(store.completedCount, 0)
        XCTAssertEqual(store.nextStep, .skin)
        client.report = .success(true)
        await store.refresh()
        XCTAssertFalse(store.canCreatePlan)
        XCTAssertEqual(store.nextStep, .products)
        XCTAssertEqual(store.completedCount, 1)
        store.markPlanSaved()
        XCTAssertFalse(store.isCompleted(.plan))
        client.products = .success(2)
        await store.refresh()
        XCTAssertTrue(store.canCreatePlan)
        XCTAssertEqual(store.nextStep, .plan)
        XCTAssertEqual(store.completedCount, 2)
        store.markPlanSaved()
        XCTAssertEqual(store.completedCount, 3)
        await store.refresh()
        XCTAssertEqual(store.completedCount, 3)
        XCTAssertNil(store.nextStep)
    }

    func testRemovingEitherPrerequisiteBlocksEvenAfterSavingPlan() async {
        for removeReport in [true, false] {
            let client = PreparationClientStub()
            client.report = .success(true)
            client.products = .success(2)
            let store = PlanPreparationStore(client: client)
            await store.refresh()
            store.markPlanSaved()
            if removeReport { client.report = .success(false) }
            else { client.products = .success(1) }
            await store.refresh()
            XCTAssertFalse(store.canCreatePlan)
            XCTAssertFalse(store.isCompleted(.plan))
            XCTAssertEqual(store.completedCount, 1)
            XCTAssertEqual(store.nextStep, removeReport ? .skin : .products)
            XCTAssertEqual(store.isCompleted(.products), removeReport)
        }
    }

    func testEitherRequestFailureBlocksCreationAndCanRetry() async {
        let client = PreparationClientStub()
        client.report = .success(true)
        client.products = .success(2)
        let store = PlanPreparationStore(client: client)
        await store.refresh()
        XCTAssertTrue(store.canCreatePlan)
        client.products = .failure(PreparationError.unavailable)
        await store.refresh()
        XCTAssertFalse(store.canCreatePlan)
        XCTAssertNil(store.nextStep)
        store.markPlanSaved()
        XCTAssertFalse(store.isCompleted(.plan))
        guard case .failed = store.state else { return XCTFail("Must show retry") }
        client.products = .success(2)
        client.report = .failure(PreparationError.unavailable)
        await store.refresh()
        XCTAssertFalse(store.canCreatePlan)
        client.report = .success(true)
        await store.refresh()
        XCTAssertTrue(store.canCreatePlan)
        XCTAssertEqual(store.nextStep, .plan)
    }

    func testCancellationDoesNotAllowCreation() async {
        let client = PreparationClientStub()
        client.report = .failure(CancellationError())
        let store = PlanPreparationStore(client: client)
        await store.refresh()
        XCTAssertEqual(store.state, .idle)
        XCTAssertFalse(store.canCreatePlan)
        XCTAssertNil(store.nextStep)
        client.report = .success(true)
        await store.refresh()
        XCTAssertEqual(store.nextStep, .products)
        XCTAssertFalse(store.canCreatePlan)
    }

    func testDraftAndPartialProductsDoNotCountAsAnalyzed() throws {
        let fixtures = [
            (#"{"id":"draft","name":"Draft","ingredients":[]}"#, false),
            (#"{"id":"partial","name":"Partial","ingredients":["水"]}"#, false),
            (#"{"id":"ready","name":"Ready","ingredients":["水"],"overallRating":0}"#, true)
        ]
        for (json, expected) in fixtures {
            let product = try JSONDecoder().decode(Product.self, from: Data(json.utf8))
            XCTAssertEqual(LivePlanPreparationClient.hasAnalysis(product), expected)
        }
    }
}

private enum PreparationError: Error { case unavailable }

@MainActor
private final class PreparationClientStub: PlanPreparationClient {
    var report: Result<Bool, Error> = .success(false)
    var products: Result<Int, Error> = .success(0)
    func hasSkinReport() async throws -> Bool { try report.get() }
    func analyzedProductCount() async throws -> Int { try products.get() }
}
