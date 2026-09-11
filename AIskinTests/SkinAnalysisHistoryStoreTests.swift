import XCTest
import UIKit
@testable import AIskin

@MainActor
final class SkinAnalysisHistoryStoreTests: XCTestCase {
    func testPaginationDeduplicatesAndRetryKeepsCursorAndExistingRows() async {
        let client = SkinHistoryStub()
        client.pages[1] = .success((1...10).map { client.analysis(id: "\($0)") })
        client.pages[2] = .failure(SkinHistoryError.offline)
        let store = SkinAnalysisStore(client: client)
        await store.loadHistory()
        XCTAssertEqual(store.history.count, 10)
        XCTAssertTrue(store.hasMoreHistory)

        await store.loadMoreHistory()
        XCTAssertNotNil(store.historyError)
        XCTAssertEqual(store.history.count, 10)
        XCTAssertTrue(store.hasMoreHistory)

        client.pages[2] = .success([client.analysis(id: "10"), client.analysis(id: "11")])
        await store.retryHistory()
        XCTAssertEqual(client.requestedPages, [1, 2, 2])
        XCTAssertEqual(store.history.compactMap(\.sourceID), (1...11).map(String.init))
        XCTAssertFalse(store.hasMoreHistory)
        XCTAssertNil(store.historyError)
        await store.loadMoreHistory()
        XCTAssertEqual(client.requestedPages, [1, 2, 2])
    }

    func testHistoryFailureIsNotAnEmptySuccessAndRefreshRetainsLoadedRows() async {
        let client = SkinHistoryStub()
        client.pages[1] = .failure(SkinHistoryError.offline)
        let store = SkinAnalysisStore(client: client)
        await store.loadHistory()
        XCTAssertTrue(store.history.isEmpty)
        XCTAssertNotNil(store.historyError)

        client.pages[1] = .success([client.analysis(id: "saved")])
        await store.retryHistory()
        XCTAssertNil(store.historyError)
        XCTAssertEqual(store.history.count, 1)
        client.pages[1] = .failure(SkinHistoryError.offline)
        await store.loadHistory()
        XCTAssertEqual(store.history.first?.sourceID, "saved")
        XCTAssertNotNil(store.historyError)
    }

    func testContextFailurePreservesReportAndRetryUpdatesBothHistoryAndSelectedResult() async throws {
        let client = SkinHistoryStub()
        let original = client.analysis(id: "saved", condition: "纯素颜")
        client.pages[1] = .success([original])
        let store = SkinAnalysisStore(client: client)
        await store.loadHistory()
        store.selectHistory(try XCTUnwrap(store.history.first))

        client.contextFails = true
        let failed = await store.updateContext(analysisID: "saved", condition: "护肤后", light: "室内光", feelings: ["干燥"])
        XCTAssertFalse(failed)
        XCTAssertEqual(store.result?.context?.condition, "纯素颜")
        XCTAssertEqual(store.history.first?.context?.condition, "纯素颜")
        XCTAssertNotNil(store.contextSaveError)
        XCTAssertFalse(store.isSavingContext)

        client.contextFails = false
        let saved = await store.updateContext(analysisID: "saved", condition: "护肤后", light: "室内光", feelings: ["干燥"])
        XCTAssertTrue(saved)
        XCTAssertEqual(store.result?.context?.condition, "护肤后")
        XCTAssertEqual(store.history.first?.context?.feelings, ["干燥"])
        XCTAssertNil(store.contextSaveError)
    }
}

private enum SkinHistoryError: Error { case offline }

@MainActor
private final class SkinHistoryStub: FeatureSkinAnalysisClient {
    var pages: [Int: Result<[SkinAnalysis], Error>] = [:]
    var requestedPages: [Int] = []
    var contextFails = false

    func analysis(id: String, condition: String? = nil) -> SkinAnalysis {
        SkinAnalysis(id: id, context: condition.map { SkinAnalysisContext(condition: $0, light: nil, feelings: nil) })
    }

    func history(page: Int, limit: Int) async throws -> [SkinAnalysis] {
        requestedPages.append(page)
        return try (pages[page] ?? .success([])).get()
    }
    func analyze(image: UIImage) async throws -> SkinAnalysis { throw SkinHistoryError.offline }
    func result(from analysis: SkinAnalysis) -> AnalysisResult {
        AnalysisResult(healthScore: 70, sourceID: analysis.id, context: analysis.context)
    }
    func updateContext(analysisID: String, condition: String?, light: String?, feelings: [String]?) async throws -> SkinAnalysis {
        if contextFails { throw SkinHistoryError.offline }
        return SkinAnalysis(id: analysisID, context: SkinAnalysisContext(condition: condition, light: light, feelings: feelings))
    }
}
