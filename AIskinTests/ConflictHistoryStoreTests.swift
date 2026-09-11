import XCTest
@testable import AIskin

@MainActor
final class ConflictHistoryStoreTests: XCTestCase {
    func testProductReportDecodesScoreAdviceAndHistoryProductIDs() throws {
        let json = #"{"_id":"r1","reportVersion":2,"riskScore":2.5,"summary":"叠加需注意","products":[{"_id":"a","name":"产品A"},{"_id":"b","name":"产品B"}],"productPairs":[{"productIds":["a","b"],"status":"caution","explanation":"需观察耐受"}],"recommendations":{"advice":[{"productIds":["a","b"],"title":"分开使用","detail":"先分别确认耐受。"}]}}"#
        let record = try JSONDecoder().decode(ConflictRecord.self, from: Data(json.utf8))
        let report = record.reportData
        XCTAssertTrue(report.hasProductReport)
        XCTAssertEqual(report.riskScore, 2.5)
        XCTAssertEqual(report.productName(for: "b"), "产品B")
        XCTAssertEqual(report.recommendations?.advice?.count, 1)
        XCTAssertEqual(report.overallStatus, "叠加需注意")
        let decoded = try JSONDecoder().decode(ConflictAnalysisData.self, from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded.riskScore, report.riskScore)
        XCTAssertEqual(decoded.productPairs?.first?.productIds, ["a", "b"])
    }

    func testOldReportsAndUnknownResultsNeverInventScoreOrProductConclusion() throws {
        let old = try JSONDecoder().decode(ConflictRecord.self, from: Data(#"{"_id":"old","conflicts":[],"safeCombo":[],"recommendations":{"routines":{"morning":["洁面","保湿"]}}}"#.utf8))
        XCTAssertFalse(old.reportData.hasProductReport)
        XCTAssertNil(old.reportData.riskScore)
        XCTAssertNil(old.reportData.recommendations?.advice)
        XCTAssertEqual(old.reportData.overallStatus, "历史报告")
        let unknown = ConflictAnalysisData(reportVersion: 2, productPairs: [ConflictProductPair(productIds: ["a", "b"], status: .unknown, explanation: "缺少信息")])
        XCTAssertNil(unknown.riskScore)
        XCTAssertEqual(unknown.overallStatus, "部分产品无法判断")
    }

    func testHistoryKeepsSavedProductSnapshotsAndSortsNewestFirst() async {
        let client = HistoryClientStub()
        let old = ConflictRecord(id: "old", products: [ConflictProductInfo(id: "deleted-product", name: "检测时的产品名称")], createdAt: Date(timeIntervalSince1970: 1))
        let new = ConflictRecord(id: "new", products: [], createdAt: Date(timeIntervalSince1970: 2))
        client.result = .success([old, new])
        let store = ConflictHistoryStore(client: client)
        await store.load()
        guard case .loaded(let records) = store.state else { return XCTFail("Expected loaded history") }
        XCTAssertEqual(records.compactMap(\.id), ["new", "old"])
        XCTAssertEqual(records.last?.products?.first?.name, "检测时的产品名称")
        XCTAssertEqual(client.calls, 1)
    }

    func testFailureIsDistinctFromEmptyAndRetryRecovers() async {
        let client = HistoryClientStub()
        client.result = .failure(HistoryError.offline)
        let store = ConflictHistoryStore(client: client)
        await store.load()
        guard case .failed = store.state else { return XCTFail("Failure must not appear as empty history") }
        client.result = .success([])
        await store.load()
        guard case .loaded(let records) = store.state else { return XCTFail("Retry should recover") }
        XCTAssertTrue(records.isEmpty)
    }
}

private enum HistoryError: Error { case offline }

@MainActor
private final class HistoryClientStub: ConflictHistoryClient {
    var result: Result<[ConflictRecord], Error> = .success([])
    var calls = 0
    func records() async throws -> [ConflictRecord] {
        calls += 1
        return try result.get()
    }
}
