import XCTest
import UIKit
@testable import AIskin

@MainActor
final class ProductAddFlowTests: XCTestCase {
    func testDuplicateSubmissionDoesNotCreateAnotherProduct() async {
        let client = ProductAddClientStub()
        let store = ProductsStore(client: client)
        let paused = expectation(description: "Create request started")
        client.pauseNext = .create
        client.didPause = { paused.fulfill() }
        let first = Task { await store.addProduct(from: UIImage()) }
        await fulfillment(of: [paused], timeout: 1)

        XCTAssertTrue(store.isAdding)
        XCTAssertEqual(store.addStep, .creating)
        let duplicate = await store.addProduct(from: UIImage())
        XCTAssertNil(duplicate)
        XCTAssertEqual(client.calls, [.create])

        client.resumeNext()
        let result = await first.value
        XCTAssertEqual(result, "product-1")
        XCTAssertEqual(client.calls, ProductAddClientStub.Operation.addOperations)
        XCTAssertFalse(client.calls.contains(.list), "Adding returns the product ID; the caller owns list refresh")
        XCTAssertEqual(store.addStep, .completed)
        XCTAssertFalse(store.isAdding)
        XCTAssertNil(store.addError)
    }

    func testResetRejectsOldResponsesAtEveryAwaitWithoutOverwritingNewFlow() async {
        for operation in ProductAddClientStub.Operation.addOperations {
            for oldRequestFails in [false, true] {
                let client = ProductAddClientStub()
                let store = ProductsStore(client: client)
                let paused = expectation(description: "Paused \(operation), failure: \(oldRequestFails)")
                client.pauseNext = operation
                client.didPause = { paused.fulfill() }
                let oldTask = Task { await store.addProduct(from: UIImage()) }
                await fulfillment(of: [paused], timeout: 1)

                store.resetAddFlow()
                XCTAssertFalse(store.isAdding)
                XCTAssertEqual(store.addStep, .idle)
                let newResult = await store.addProduct(from: UIImage())
                XCTAssertEqual(newResult, "product-2")
                let callsAfterNewFlow = client.calls

                client.resumeNext(error: oldRequestFails ? ProductAddError.unavailable : nil)
                let oldResult = await oldTask.value
                XCTAssertNil(oldResult)
                XCTAssertEqual(client.calls, callsAfterNewFlow, "Old flow must not start its next operation")
                XCTAssertEqual(store.addStep, .completed)
                XCTAssertFalse(store.isAdding)
                XCTAssertNil(store.addError)
            }
        }
    }

    func testOldRequestCannotUnlockOrFailANewRequestStillRunning() async {
        let client = ProductAddClientStub()
        let store = ProductsStore(client: client)
        let oldPaused = expectation(description: "Old request paused")
        client.pauseNext = .create
        client.didPause = { oldPaused.fulfill() }
        let oldTask = Task { await store.addProduct(from: UIImage()) }
        await fulfillment(of: [oldPaused], timeout: 1)

        store.resetAddFlow()
        let newPaused = expectation(description: "New request paused")
        client.pauseNext = .create
        client.didPause = { newPaused.fulfill() }
        let newTask = Task { await store.addProduct(from: UIImage()) }
        await fulfillment(of: [newPaused], timeout: 1)
        client.resumeNext(error: ProductAddError.unavailable)
        let oldResult = await oldTask.value

        XCTAssertNil(oldResult)
        XCTAssertTrue(store.isAdding)
        XCTAssertEqual(store.addStep, .creating)
        XCTAssertNil(store.addError)
        let duplicate = await store.addProduct(from: UIImage())
        XCTAssertNil(duplicate)
        XCTAssertEqual(client.calls, [.create, .create])

        client.resumeNext()
        let newResult = await newTask.value
        XCTAssertEqual(newResult, "product-2")
        XCTAssertFalse(store.isAdding)
    }

    func testTaskCancellationStopsAtEveryAwaitEvenWhenClientIgnoresCancellation() async {
        for operation in ProductAddClientStub.Operation.addOperations {
            let client = ProductAddClientStub()
            let store = ProductsStore(client: client)
            let paused = expectation(description: "Cancellation at \(operation)")
            client.pauseNext = operation
            client.didPause = { paused.fulfill() }
            let task = Task { await store.addProduct(from: UIImage()) }
            await fulfillment(of: [paused], timeout: 1)
            let callsBeforeCancellation = client.calls

            task.cancel()
            client.resumeNext()
            let result = await task.value

            XCTAssertNil(result)
            XCTAssertEqual(client.calls, callsBeforeCancellation)
            XCTAssertFalse(store.isAdding)
            XCTAssertEqual(store.addStep, .idle)
            XCTAssertNil(store.addError)
        }
    }

    func testCancellationReportedByClientIsNotAnAddFailure() async {
        let client = ProductAddClientStub()
        let store = ProductsStore(client: client)
        let paused = expectation(description: "Upload paused")
        client.pauseNext = .upload
        client.didPause = { paused.fulfill() }
        let task = Task { await store.addProduct(from: UIImage()) }
        await fulfillment(of: [paused], timeout: 1)
        client.resumeNext(error: CancellationError())
        let result = await task.value

        XCTAssertNil(result)
        XCTAssertNil(store.addError)
        XCTAssertEqual(store.addStep, .idle)
        XCTAssertFalse(store.isAdding)
        XCTAssertEqual(client.calls, [.create, .upload])
    }

    func testFailedAnalysisCanRetryAndClearsItsError() async {
        let client = ProductAddClientStub()
        client.failureAt = .analyze
        let store = ProductsStore(client: client)
        let failedResult = await store.addProduct(from: UIImage())
        XCTAssertNil(failedResult)
        XCTAssertNotNil(store.addError)
        XCTAssertEqual(store.addStep, .idle)
        XCTAssertFalse(store.isAdding)

        client.failureAt = nil
        let retryResult = await store.addProduct(from: UIImage())
        XCTAssertEqual(retryResult, "product-2")
        XCTAssertNil(store.addError)
        XCTAssertEqual(store.addStep, .completed)
        XCTAssertFalse(store.isAdding)
    }

    func testAddingDoesNotReadOrChangeTheProductList() async throws {
        let client = ProductAddClientStub()
        client.listResult = .success([try client.product(id: "existing")])
        let store = ProductsStore(client: client)
        await store.loadProducts()
        client.calls = []
        client.listResult = .failure(ProductAddError.unavailable)
        let result = await store.addProduct(from: UIImage())

        XCTAssertEqual(result, "product-1")
        XCTAssertEqual(store.addStep, .completed)
        XCTAssertNil(store.addError)
        XCTAssertFalse(store.isAdding)
        XCTAssertEqual(client.calls, ProductAddClientStub.Operation.addOperations)
        XCTAssertEqual(store.products.map(\.id), ["existing"])
        guard case .loaded = store.loadState else {
            return XCTFail("The caller owns product list refresh after adding")
        }
    }
}

private enum ProductAddError: Error { case unavailable }

@MainActor
private final class ProductAddClientStub: ProductsClient {
    enum Operation {
        case create, upload, extract, analyze, list
        static let addOperations: [Operation] = [.create, .upload, .extract, .analyze]
    }

    var currentUserID: String? = "user"
    var calls: [Operation] = []
    var pauseNext: Operation?
    var failureAt: Operation?
    var didPause: (() -> Void)?
    var listResult: Result<[Product], Error> = .success([])
    private var pending: [CheckedContinuation<Void, Error>] = []
    private var createCount = 0

    func resumeNext(error: Error? = nil) {
        guard !pending.isEmpty else { return XCTFail("Expected a pending client operation") }
        let continuation = pending.removeFirst()
        if let error { continuation.resume(throwing: error) }
        else { continuation.resume() }
    }

    func product(id: String) throws -> Product {
        let data = try JSONSerialization.data(withJSONObject: ["id": id, "name": "护肤品"])
        return try JSONDecoder().decode(Product.self, from: data)
    }

    private func perform(_ operation: Operation) async throws {
        calls.append(operation)
        if failureAt == operation { throw ProductAddError.unavailable }
        if pauseNext == operation {
            pauseNext = nil
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                pending.append(continuation)
                didPause?()
            }
        }
    }

    func products(userID: String) async throws -> [Product] {
        let result = listResult
        try await perform(.list)
        return try result.get()
    }

    func createProduct(name: String?, description: String?, label: String?, openingDate: Date?) async throws -> Product {
        createCount += 1
        let id = "product-\(createCount)"
        try await perform(.create)
        return try product(id: id)
    }

    func uploadImage(productID: String, image: UIImage) async throws -> String {
        try await perform(.upload)
        return "image-url"
    }

    func extractIngredients(productID: String) async throws -> (name: String, ingredients: [String]) {
        try await perform(.extract)
        return ("护肤品", ["水"])
    }

    func analyzeIngredients(productID: String) async throws -> IngredientAnalysis {
        try await perform(.analyze)
        return IngredientAnalysis(
            safetyIndex: 90, efficacyScore: 80, activeIngredients: 1,
            acneRisk: RiskLevel(level: "低", percentage: 0),
            irritationRisk: RiskLevel(level: "低", percentage: 0),
            allergyRisk: RiskLevel(level: "低", percentage: 0),
            efficacyAnalysis: [], potentialRisks: [], recommendations: [],
            overallRating: 85, summary: "成分分析完成"
        )
    }

    func deleteProduct(productID: String) async throws {}
}
