import XCTest
import UIKit
import Combine
@testable import AIskin

@MainActor
final class SkinAnalysisFlowTests: XCTestCase {
    func testResetIgnoresDelayedFailureFromCancelledRequest() async {
        let client = SuspendedSkinClient()
        let store = SkinAnalysisStore(client: client)
        await start(store, client: client)
        store.reset()
        let changed = expectation(description: "Cancelled analysis must not replace welcome")
        changed.isInverted = true
        let observation = store.$flow.dropFirst().sink { _ in changed.fulfill() }

        client.finish(0, with: .failure(APIError.networkError(URLError(.cancelled))))

        await fulfillment(of: [changed], timeout: 0.1)
        guard case .welcome = store.flow else { return XCTFail("Reset must remain welcome") }
        withExtendedLifetime(observation) {}
    }

    func testOldFailureCannotReplaceNewAnalysisAndNewResultCompletes() async {
        let client = SuspendedSkinClient()
        let store = SkinAnalysisStore(client: client)
        await start(store, client: client)
        await start(store, client: client)
        let failed = expectation(description: "Old request must not show an error")
        failed.isInverted = true
        let failedObservation = store.$flow.sink { if case .failed = $0 { failed.fulfill() } }
        client.finish(0, with: .failure(APIError.serverError("旧请求失败")))
        await fulfillment(of: [failed], timeout: 0.1)
        guard case .analyzing = store.flow else { return XCTFail("New request should remain in progress") }

        let completed = expectation(description: "New request completes")
        let resultObservation = store.$flow.sink {
            if case .result(let result) = $0, result.sourceID == "new" { completed.fulfill() }
        }
        client.finish(1, with: .success(SkinAnalysis(id: "new")))
        await fulfillment(of: [completed], timeout: 1)
        XCTAssertEqual(store.result?.sourceID, "new")
        withExtendedLifetime((failedObservation, resultObservation)) {}
    }

    func testSelectingHistoryIgnoresDelayedSuccessFromAnalysis() async {
        let client = SuspendedSkinClient()
        let store = SkinAnalysisStore(client: client)
        await start(store, client: client)
        store.selectHistory(AnalysisResult(healthScore: 70, sourceID: "saved"))
        let changed = expectation(description: "Selected history must not be replaced by an old analysis")
        changed.isInverted = true
        let observation = store.$flow.dropFirst().sink { _ in changed.fulfill() }

        client.finish(0, with: .success(SkinAnalysis(id: "old")))

        await fulfillment(of: [changed], timeout: 0.1)
        XCTAssertEqual(store.result?.sourceID, "saved")
        XCTAssertEqual(client.historyReads, 0)
        withExtendedLifetime(observation) {}
    }

    private func start(_ store: SkinAnalysisStore, client: SuspendedSkinClient) async {
        let started = expectation(description: "Analysis request starts")
        client.onStart = { started.fulfill() }
        store.selectedImage = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        store.processSelectedImage()
        await fulfillment(of: [started], timeout: 1)
    }
}

@MainActor
private final class SuspendedSkinClient: FeatureSkinAnalysisClient {
    var onStart: (() -> Void)?
    var historyReads = 0
    private var requests: [Int: CheckedContinuation<SkinAnalysis, Error>] = [:]
    private var nextID = 0

    func analyze(image: UIImage) async throws -> SkinAnalysis {
        let id = nextID
        nextID += 1
        return try await withCheckedThrowingContinuation { continuation in
            requests[id] = continuation
            onStart?()
        }
    }

    func finish(_ id: Int, with result: Result<SkinAnalysis, Error>) {
        requests.removeValue(forKey: id)?.resume(with: result)
    }

    func history(page: Int, limit: Int) async throws -> [SkinAnalysis] {
        historyReads += 1
        return []
    }

    func result(from analysis: SkinAnalysis) -> AnalysisResult {
        AnalysisResult(healthScore: 70, sourceID: analysis.id)
    }
}
