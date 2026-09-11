import Foundation
import Combine

@MainActor
protocol FeatureIngredientAnalysisClient {
    func product(id: String) async throws -> Product
    func analysis(productID: String) async throws -> (product: Product, analysis: IngredientAnalysis)
    func createAnalysis(productID: String) async throws -> IngredientAnalysis
    func deleteProduct(id: String) async throws
    func saveRegistration(id: String, name: String, label: String, openingStatus: String, openingDate: Date?) async throws -> Product
}

extension FeatureIngredientAnalysisClient {
    func saveRegistration(id: String, name: String, label: String, openingStatus: String, openingDate: Date?) async throws -> Product {
        throw APIError.serverError("当前客户端未配置产品信息保存")
    }
}

@MainActor
struct LegacyIngredientAnalysisClient: FeatureIngredientAnalysisClient {
    func saveRegistration(id: String, name: String, label: String, openingStatus: String, openingDate: Date?) async throws -> Product {
        try await ProductApiService.shared.saveRegistration(productId: id, name: name, label: label, openingStatus: openingStatus, openingDate: openingDate)
    }
    func product(id: String) async throws -> Product {
        try await ProductApiService.shared.getProduct(productId: id)
    }

    func analysis(productID: String) async throws -> (product: Product, analysis: IngredientAnalysis) {
        try await IngredientAnalysisApiService.shared.getIngredientAnalysis(productId: productID)
    }

    func createAnalysis(productID: String) async throws -> IngredientAnalysis {
        try await IngredientAnalysisApiService.shared.analyzeIngredients(productId: productID)
    }

    func deleteProduct(id: String) async throws {
        try await ProductApiService.shared.deleteProduct(productId: id)
    }
}

@MainActor
final class IngredientAnalysisStore: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(product: Product, analysis: IngredientAnalysis)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var isSaving = false
    @Published private(set) var saveError: String?
    @Published private(set) var isDeleting = false
    @Published private(set) var deleteError: String?
    private let client: any FeatureIngredientAnalysisClient
    private var loadRequestID: UUID?

    init(client: (any FeatureIngredientAnalysisClient)? = nil) {
        self.client = client ?? LegacyIngredientAnalysisClient()
    }

    func load(productID: String) async {
        let requestID = UUID()
        loadRequestID = requestID
        state = .loading
        defer { if loadRequestID == requestID { loadRequestID = nil } }
        do {
            try Task.checkCancellation()
            let report: (product: Product, analysis: IngredientAnalysis)
            do {
                report = try await client.analysis(productID: productID)
            } catch APIError.notFound(let message, let code) where
                code == "ANALYSIS_NOT_FOUND" || (code == nil && message == "该产品尚未进行成分分析，请先分析成分") {
                try Task.checkCancellation()
                guard loadRequestID == requestID else { return }
                let product = try await client.product(id: productID)
                try Task.checkCancellation()
                guard loadRequestID == requestID else { return }
                guard !product.ingredients.isEmpty else {
                    state = .failed("产品尚未提取成分，请先上传图片并提取成分")
                    return
                }
                report = (product, try await client.createAnalysis(productID: productID))
            }
            try Task.checkCancellation()
            guard loadRequestID == requestID else { return }
            state = .loaded(product: report.product, analysis: report.analysis)
        } catch is CancellationError {
            if loadRequestID == requestID { state = .idle }
            return
        } catch {
            guard loadRequestID == requestID else { return }
            guard !Task.isCancelled else { state = .idle; return }
            state = .failed("加载产品信息失败：\(error.localizedDescription)")
        }
    }

    func saveRegistration(productID: String, name: String, label: String, openingStatus: String, openingDate: Date?) async -> Bool {
        guard !isSaving else { return false }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            saveError = "请输入产品名称"
            return false
        }
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            let updated = try await client.saveRegistration(id: productID, name: trimmedName, label: label, openingStatus: openingStatus, openingDate: openingDate)
            if case let .loaded(_, analysis) = state { state = .loaded(product: updated, analysis: analysis) }
            return true
        } catch {
            saveError = "保存失败：\(error.localizedDescription)"
            return false
        }
    }

    func delete(productID: String) async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        deleteError = nil
        defer { isDeleting = false }
        do {
            try await client.deleteProduct(id: productID)
            return true
        } catch {
            deleteError = "删除产品失败：\(error.localizedDescription)"
            return false
        }
    }
}
