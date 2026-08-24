import Foundation
import Combine

@MainActor
protocol FeatureIngredientAnalysisClient {
    func product(id: String) async throws -> Product
    func analysis(productID: String) async throws -> IngredientAnalysis
    func createAnalysis(productID: String) async throws -> IngredientAnalysis
    func updateProduct(id: String, label: String?) async throws -> Product
    func deleteProduct(id: String) async throws
}

@MainActor
struct LegacyIngredientAnalysisClient: FeatureIngredientAnalysisClient {
    func product(id: String) async throws -> Product {
        try await ProductApiService.shared.getProduct(productId: id)
    }

    func analysis(productID: String) async throws -> IngredientAnalysis {
        try await IngredientAnalysisApiService.shared.getIngredientAnalysis(productId: productID).analysis
    }

    func createAnalysis(productID: String) async throws -> IngredientAnalysis {
        try await IngredientAnalysisApiService.shared.analyzeIngredients(productId: productID)
    }

    func updateProduct(id: String, label: String?) async throws -> Product {
        try await ProductApiService.shared.updateProduct(
            productId: id,
            name: nil,
            description: nil,
            label: label
        )
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
    private let client: any FeatureIngredientAnalysisClient

    init(client: (any FeatureIngredientAnalysisClient)? = nil) {
        self.client = client ?? LegacyIngredientAnalysisClient()
    }

    func load(productID: String) async {
        state = .loading
        do {
            let product = try await client.product(id: productID)
            let analysis: IngredientAnalysis
            do {
                analysis = try await client.analysis(productID: productID)
            } catch {
                guard !product.ingredients.isEmpty else {
                    state = .failed("产品尚未提取成分，请先上传图片并提取成分")
                    return
                }
                analysis = try await client.createAnalysis(productID: productID)
            }
            try Task.checkCancellation()
            state = .loaded(product: product, analysis: analysis)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("加载产品信息失败：\(error.localizedDescription)")
        }
    }

    func saveLabel(productID: String, label: String?) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await client.updateProduct(id: productID, label: label)
            if case let .loaded(_, analysis) = state {
                state = .loaded(product: updated, analysis: analysis)
            }
            return true
        } catch {
            state = .failed("保存标签失败：\(error.localizedDescription)")
            return false
        }
    }

    func delete(productID: String) async -> Bool {
        do {
            try await client.deleteProduct(id: productID)
            return true
        } catch {
            state = .failed("删除产品失败：\(error.localizedDescription)")
            return false
        }
    }
}
