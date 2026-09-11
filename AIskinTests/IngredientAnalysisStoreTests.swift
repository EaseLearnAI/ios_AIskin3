import XCTest
@testable import AIskin

@MainActor
final class IngredientAnalysisStoreTests: XCTestCase {
    func testDeleteFailurePreservesReportAndCanRetry() async {
        let client = IngredientStoreClientStub()
        let store = IngredientAnalysisStore(client: client)
        await store.load(productID: "product")
        client.deleteError = APIError.networkError(URLError(.notConnectedToInternet))
        let failed = await store.delete(productID: "product")
        XCTAssertFalse(failed)
        XCTAssertFalse(store.isDeleting)
        XCTAssertNotNil(store.deleteError)
        guard case .loaded(let product, _) = store.state else { return XCTFail("Delete failure must retain the report") }
        XCTAssertEqual(product.id, "product")
        client.deleteError = nil
        let retried = await store.delete(productID: "product")
        XCTAssertTrue(retried)
        XCTAssertNil(store.deleteError)
    }

    func testNoDiscomfortIsExclusiveAndIndividualFeelingsRemainMultipleChoice() {
        XCTAssertEqual(SkinAnalysisContext.togglingFeeling("无明显不适", in: ["刺痛", "泛红"]), ["无明显不适"])
        XCTAssertEqual(SkinAnalysisContext.togglingFeeling("干燥", in: ["无明显不适"]), ["干燥"])
        XCTAssertEqual(SkinAnalysisContext.togglingFeeling("紧绷", in: ["干燥"]), ["干燥", "紧绷"])
        XCTAssertEqual(SkinAnalysisContext.togglingFeeling("紧绷", in: ["干燥", "紧绷"]), ["干燥"])
    }

    func testRegistrationSavesTrimmedNameAndRetainsAnalysis() async {
        let client = IngredientStoreClientStub()
        let store = IngredientAnalysisStore(client: client)
        await store.load(productID: "product")
        let saved = await store.saveRegistration(productID: "product", name: "  自定义精华  ", label: "精华", openingStatus: "unopened", openingDate: nil)
        XCTAssertTrue(saved)
        XCTAssertEqual(client.savedName, "自定义精华")
        guard case .loaded(let product, let analysis) = store.state else { return XCTFail("Expected saved report") }
        XCTAssertEqual(product.name, "自定义精华")
        XCTAssertEqual(analysis.summary, "成分报告")
        XCTAssertEqual(client.creationRequests, 0)
    }

    func testBlankNameDoesNotSubmitAndSaveFailureCanRetry() async {
        let client = IngredientStoreClientStub()
        let store = IngredientAnalysisStore(client: client)
        await store.load(productID: "product")
        let blank = await store.saveRegistration(productID: "product", name: " \n ", label: "精华", openingStatus: "unopened", openingDate: nil)
        XCTAssertFalse(blank)
        XCTAssertNil(client.savedName)
        XCTAssertEqual(store.saveError, "请输入产品名称")
        client.saveError = APIError.serverError("暂时不可用")
        let failed = await store.saveRegistration(productID: "product", name: "新名称", label: "精华", openingStatus: "unopened", openingDate: nil)
        XCTAssertFalse(failed)
        guard case .loaded(let original, _) = store.state else { return XCTFail("Keep report on save failure") }
        XCTAssertEqual(original.name, "产品")
        client.saveError = nil
        let retried = await store.saveRegistration(productID: "product", name: "新名称", label: "精华", openingStatus: "unopened", openingDate: nil)
        XCTAssertTrue(retried)
        XCTAssertNil(store.saveError)
    }

    func testSavedReportLoadsWithOneReadAndNoGeneration() async {
        let client = IngredientStoreClientStub()
        let store = IngredientAnalysisStore(client: client)

        await store.load(productID: "product")

        XCTAssertEqual(client.analysisReads, 1)
        XCTAssertEqual(client.productReads, 0)
        XCTAssertEqual(client.creationRequests, 0)
        guard case .loaded(let product, _) = store.state else { return XCTFail("Expected saved report") }
        XCTAssertEqual(product.id, "product")
    }

    func testOnlyExplicitMissingReportGeneratesAnalysis() async {
        let client = IngredientStoreClientStub()
        client.analysisError = APIError.notFound(message: "报告不存在", code: "ANALYSIS_NOT_FOUND")
        let store = IngredientAnalysisStore(client: client)

        await store.load(productID: "product")

        XCTAssertEqual(client.productReads, 1)
        XCTAssertEqual(client.creationRequests, 1)
        guard case .loaded = store.state else { return XCTFail("Missing report should be generated from extracted ingredients") }
    }

    func testReadFailuresNeverTriggerGenerationAndCanRetry() async {
        let errors: [Error] = [
            APIError.unauthorized,
            APIError.networkError(URLError(.notConnectedToInternet)),
            APIError.serverError("服务暂时不可用"),
            APIError.decodingError,
            APIError.notFound(message: "产品不存在", code: "PRODUCT_NOT_FOUND"),
            APIError.notFound(message: "接口不存在", code: nil)
        ]
        for error in errors {
            let client = IngredientStoreClientStub()
            client.analysisError = error
            let store = IngredientAnalysisStore(client: client)

            await store.load(productID: "product")

            XCTAssertEqual(client.productReads, 0)
            XCTAssertEqual(client.creationRequests, 0)
            guard case .failed = store.state else { return XCTFail("Read failure must be visible: \(error)") }
            client.analysisError = nil
            await store.load(productID: "product")
            guard case .loaded = store.state else { return XCTFail("Retry should load the existing report") }
        }
    }

    func testKnownLegacyMissingReportResponseCanStillGenerate() async {
        let client = IngredientStoreClientStub()
        client.analysisError = APIError.notFound(message: "该产品尚未进行成分分析，请先分析成分", code: nil)
        let store = IngredientAnalysisStore(client: client)

        await store.load(productID: "product")

        XCTAssertEqual(client.creationRequests, 1)
        guard case .loaded = store.state else { return XCTFail("Legacy missing report response should remain supported") }
    }

    func testCancellationDuringReadDoesNotGenerateOrShowFailure() async {
        let client = IngredientStoreClientStub()
        client.analysisError = CancellationError()
        let store = IngredientAnalysisStore(client: client)

        await store.load(productID: "product")

        XCTAssertEqual(client.productReads, 0)
        XCTAssertEqual(client.creationRequests, 0)
        guard case .idle = store.state else { return XCTFail("Cancellation should end loading without an error") }
    }

    func testMissingIngredientsDoNotStartAnalysis() async {
        let client = IngredientStoreClientStub()
        client.analysisError = APIError.notFound(message: "报告不存在", code: "ANALYSIS_NOT_FOUND")
        client.product.ingredients = []
        let store = IngredientAnalysisStore(client: client)

        await store.load(productID: "product")

        XCTAssertEqual(client.creationRequests, 0)
        guard case .failed(let message) = store.state else { return XCTFail("Expected actionable extraction error") }
        XCTAssertTrue(message.contains("尚未提取成分"))
    }
}

@MainActor
private final class IngredientStoreClientStub: FeatureIngredientAnalysisClient {
    var product = try! JSONDecoder().decode(Product.self, from: Data(#"{"id":"product","name":"产品","ingredients":["水"]}"#.utf8))
    var analysisError: Error?
    var deleteError: Error?
    var saveError: Error?
    var savedName: String?
    var analysisReads = 0
    var productReads = 0
    var creationRequests = 0
    private let report = IngredientAnalysis(
        safetyIndex: 90, efficacyScore: 80, activeIngredients: 1,
        acneRisk: RiskLevel(level: "低", percentage: 10),
        irritationRisk: RiskLevel(level: "低", percentage: 10),
        allergyRisk: RiskLevel(level: "低", percentage: 10),
        efficacyAnalysis: [], potentialRisks: [], recommendations: [], overallRating: 4, summary: "成分报告"
    )

    func product(id: String) async throws -> Product {
        productReads += 1
        return product
    }

    func analysis(productID: String) async throws -> (product: Product, analysis: IngredientAnalysis) {
        analysisReads += 1
        if let analysisError { throw analysisError }
        return (product, report)
    }

    func createAnalysis(productID: String) async throws -> IngredientAnalysis {
        creationRequests += 1
        return report
    }

    func saveRegistration(id: String, name: String, label: String, openingStatus: String, openingDate: Date?) async throws -> Product {
        savedName = name
        if let saveError { throw saveError }
        product.name = name
        product.label = label
        return product
    }

    func deleteProduct(id: String) async throws { if let deleteError { throw deleteError } }
}
