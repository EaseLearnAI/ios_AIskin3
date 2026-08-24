import Foundation
import UIKit
import Combine

@MainActor
protocol ProductsClient {
    var currentUserID: String? { get }
    func products(userID: String) async throws -> [Product]
    func createProduct(name: String?, description: String?, label: String?, openingDate: Date?) async throws -> Product
    func uploadImage(productID: String, image: UIImage) async throws -> String
    func extractIngredients(productID: String) async throws -> (name: String, ingredients: [String])
    func analyzeIngredients(productID: String) async throws -> IngredientAnalysis
    func deleteProduct(productID: String) async throws
}

@MainActor
struct LegacyProductsClient: ProductsClient {
    var currentUserID: String? { AuthService.shared.currentUser?.id }

    func products(userID: String) async throws -> [Product] {
        try await ProductApiService.shared.getUserProducts(userId: userID)
    }

    func createProduct(name: String?, description: String?, label: String?, openingDate: Date?) async throws -> Product {
        try await ProductApiService.shared.createProduct(
            name: name,
            description: description,
            label: label,
            openingDate: openingDate
        )
    }

    func uploadImage(productID: String, image: UIImage) async throws -> String {
        try await ProductApiService.shared.uploadProductImage(productId: productID, image: image)
    }

    func extractIngredients(productID: String) async throws -> (name: String, ingredients: [String]) {
        try await ProductApiService.shared.extractIngredients(productId: productID)
    }

    func analyzeIngredients(productID: String) async throws -> IngredientAnalysis {
        try await IngredientAnalysisApiService.shared.analyzeIngredients(productId: productID)
    }

    func deleteProduct(productID: String) async throws {
        try await ProductApiService.shared.deleteProduct(productId: productID)
    }
}

@MainActor
final class ProductsStore: ObservableObject {
    enum LoadState {
        case idle
        case loading
        case empty
        case loaded
        case failed(String)
    }

    enum AddStep: Int {
        case idle = 0
        case creating = 1
        case uploading = 2
        case extracting = 3
        case analyzing = 4
        case completed = 5
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published var selectedCategory = "all"
    @Published var isSelectingConflicts = false
    @Published var selectedProductIDs: Set<String> = []
    @Published private(set) var addStep: AddStep = .idle
    @Published private(set) var addError: String?

    private let client: any ProductsClient
    private var loadTask: Task<Void, Never>?

    init(client: (any ProductsClient)? = nil) {
        self.client = client ?? LegacyProductsClient()
    }

    deinit { loadTask?.cancel() }

    func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadProducts()
        }
    }

    func loadProducts() async {
        guard let userID = client.currentUserID else {
            products = []
            loadState = .failed("登录状态已失效，请重新登录")
            return
        }

        loadState = .loading
        do {
            let loadedProducts = try await client.products(userID: userID)
            try Task.checkCancellation()
            products = loadedProducts
            loadState = loadedProducts.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            products = []
            loadState = .failed("加载产品失败：\(error.localizedDescription)")
        }
    }

    func delete(productID: String) async {
        do {
            try await client.deleteProduct(productID: productID)
            products.removeAll { $0.id == productID }
            selectedProductIDs.remove(productID)
            loadState = products.isEmpty ? .empty : .loaded
        } catch {
            loadState = .failed("删除产品失败：\(error.localizedDescription)")
        }
    }

    func beginConflictSelection() {
        isSelectingConflicts = true
        selectedProductIDs.removeAll()
    }

    func cancelConflictSelection() {
        isSelectingConflicts = false
        selectedProductIDs.removeAll()
    }

    func toggleConflictSelection(productID: String) {
        if selectedProductIDs.contains(productID) {
            selectedProductIDs.remove(productID)
        } else {
            selectedProductIDs.insert(productID)
        }
    }

    func consumeConflictSelection() -> [String]? {
        guard selectedProductIDs.count >= 2 else { return nil }
        let result = Array(selectedProductIDs)
        cancelConflictSelection()
        return result
    }

    func addProduct(from image: UIImage) async -> String? {
        addError = nil
        addStep = .creating
        do {
            let product = try await client.createProduct(
                name: "未命名产品",
                description: "这是一个用于成分分析的产品",
                label: nil,
                openingDate: nil
            )
            addStep = .uploading
            _ = try await client.uploadImage(productID: product.id, image: image)
            addStep = .extracting
            _ = try await client.extractIngredients(productID: product.id)
            addStep = .analyzing
            _ = try await client.analyzeIngredients(productID: product.id)
            addStep = .completed
            await loadProducts()
            return product.id
        } catch is CancellationError {
            addStep = .idle
            return nil
        } catch {
            addError = "产品处理失败：\(error.localizedDescription)"
            addStep = .idle
            return nil
        }
    }

    func resetAddFlow() {
        addStep = .idle
        addError = nil
    }
}
