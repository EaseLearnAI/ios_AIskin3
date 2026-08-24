import Foundation
import UIKit

protocol AuthClient {
    func register(name: String, email: String, password: String) async throws -> (token: String, user: User)
    func register(name: String, phone: String, password: String, gender: String?) async throws -> (token: String, user: User)
    func login(email: String, password: String) async throws -> (token: String, user: User)
    func login(phone: String, password: String) async throws -> (token: String, user: User)
    func requestPasswordReset(phone: String) async throws -> String
    func resetPassword(phone: String, verificationCode: String, newPassword: String) async throws
    func getCurrentUser() async throws -> User
    func updateUsername(name: String) async throws -> User
    func updateGender(gender: String) async throws -> User
    func updateAge(age: Int) async throws -> User
    func getUserStats() async throws -> UserStats
    func logout() async throws
    func deleteAccount() async throws
}

protocol ProductClient {
    func createProduct(
        name: String?,
        description: String?,
        label: String?,
        openingDate: Date?
    ) async throws -> Product
    func uploadProductImage(productId: String, image: UIImage) async throws -> String
    func extractIngredients(productId: String) async throws -> (name: String, ingredients: [String])
    func getProducts(page: Int, limit: Int) async throws -> [Product]
    func getProduct(productId: String) async throws -> Product
    func getUserProducts(userId: String) async throws -> [Product]
    func getUserProductsByLabel(userId: String, label: String) async throws -> [Product]
    func updateProduct(
        productId: String,
        name: String?,
        description: String?,
        label: String?
    ) async throws -> Product
    func deleteProduct(productId: String) async throws
}

protocol PlanClient {
    func createPlan(
        requirement: String?,
        userAge: Int?,
        skinConcerns: [String]?,
        customRequirements: String?
    ) async throws -> SkinPlan
    func getUserPlans() async throws -> [SkinPlan]
    func getPlan(planId: String) async throws -> SkinPlan
    func updateStepCompleted(
        planId: String,
        period: String,
        step: Int,
        completed: Bool
    ) async throws -> SkinPlan
    func createCustomPlan(
        name: String,
        morning: [RoutineItem],
        evening: [RoutineItem],
        recommendations: [String]?,
        tags: [String]?,
        notes: String?
    ) async throws -> SkinPlan
    func deletePlan(planId: String) async throws
}

protocol SkinAnalysisClient {
    func analyzeSkin(image: UIImage) async throws -> SkinAnalysis
    func getAnalysisHistory(page: Int, limit: Int) async throws -> (analyses: [SkinAnalysis], pagination: Pagination?)
    func getAnalysisDetail(analysisId: String) async throws -> SkinAnalysis
    func getLatestAnalysis() async throws -> SkinAnalysis?
    func getAnalysisStats() async throws -> SkinAnalysisStats
    func deleteAnalysis(analysisId: String) async throws
}

protocol ConflictClient {
    func analyzeConflict(productIds: [String]) async throws -> ConflictAnalysisData
    func getUserConflicts() async throws -> [ConflictRecord]
    func getConflict(conflictId: String) async throws -> ConflictRecord
    func deleteConflict(conflictId: String) async throws
}

protocol IngredientAnalysisClient {
    func analyzeIngredients(productId: String) async throws -> IngredientAnalysis
    func getIngredientAnalysis(productId: String) async throws -> (product: Product, analysis: IngredientAnalysis)
}

// 兼容适配：旧 Service 原样保留，同时可以作为新 Store 的协议依赖注入。
extension UserApiService: AuthClient {}
extension ProductApiService: ProductClient {}
extension PlanApiService: PlanClient {}
extension SkinAnalysisApiService: SkinAnalysisClient {}
extension ConflictApiService: ConflictClient {}
extension IngredientAnalysisApiService: IngredientAnalysisClient {}

final class UnavailableServiceClients:
    AuthClient,
    ProductClient,
    PlanClient,
    SkinAnalysisClient,
    ConflictClient,
    IngredientAnalysisClient
{
    private let reason: String

    init(reason: String = "当前预览或测试未注入对应 Client") {
        self.reason = reason
    }

    private func unavailable<T>() throws -> T {
        throw APIError.serverError(reason)
    }

    func register(name: String, email: String, password: String) async throws -> (token: String, user: User) { try unavailable() }
    func register(name: String, phone: String, password: String, gender: String?) async throws -> (token: String, user: User) { try unavailable() }
    func login(email: String, password: String) async throws -> (token: String, user: User) { try unavailable() }
    func login(phone: String, password: String) async throws -> (token: String, user: User) { try unavailable() }
    func requestPasswordReset(phone: String) async throws -> String { try unavailable() }
    func resetPassword(phone: String, verificationCode: String, newPassword: String) async throws { throw APIError.serverError(reason) }
    func getCurrentUser() async throws -> User { try unavailable() }
    func updateUsername(name: String) async throws -> User { try unavailable() }
    func updateGender(gender: String) async throws -> User { try unavailable() }
    func updateAge(age: Int) async throws -> User { try unavailable() }
    func getUserStats() async throws -> UserStats { try unavailable() }
    func logout() async throws { throw APIError.serverError(reason) }
    func deleteAccount() async throws { throw APIError.serverError(reason) }

    func createProduct(name: String?, description: String?, label: String?, openingDate: Date?) async throws -> Product { try unavailable() }
    func uploadProductImage(productId: String, image: UIImage) async throws -> String { try unavailable() }
    func extractIngredients(productId: String) async throws -> (name: String, ingredients: [String]) { try unavailable() }
    func getProducts(page: Int, limit: Int) async throws -> [Product] { try unavailable() }
    func getProduct(productId: String) async throws -> Product { try unavailable() }
    func getUserProducts(userId: String) async throws -> [Product] { try unavailable() }
    func getUserProductsByLabel(userId: String, label: String) async throws -> [Product] { try unavailable() }
    func updateProduct(productId: String, name: String?, description: String?, label: String?) async throws -> Product { try unavailable() }
    func deleteProduct(productId: String) async throws { throw APIError.serverError(reason) }

    func createPlan(requirement: String?, userAge: Int?, skinConcerns: [String]?, customRequirements: String?) async throws -> SkinPlan { try unavailable() }
    func getUserPlans() async throws -> [SkinPlan] { try unavailable() }
    func getPlan(planId: String) async throws -> SkinPlan { try unavailable() }
    func updateStepCompleted(planId: String, period: String, step: Int, completed: Bool) async throws -> SkinPlan { try unavailable() }
    func createCustomPlan(name: String, morning: [RoutineItem], evening: [RoutineItem], recommendations: [String]?, tags: [String]?, notes: String?) async throws -> SkinPlan { try unavailable() }
    func deletePlan(planId: String) async throws { throw APIError.serverError(reason) }

    func analyzeSkin(image: UIImage) async throws -> SkinAnalysis { try unavailable() }
    func getAnalysisHistory(page: Int, limit: Int) async throws -> (analyses: [SkinAnalysis], pagination: Pagination?) { try unavailable() }
    func getAnalysisDetail(analysisId: String) async throws -> SkinAnalysis { try unavailable() }
    func getLatestAnalysis() async throws -> SkinAnalysis? { try unavailable() }
    func getAnalysisStats() async throws -> SkinAnalysisStats { try unavailable() }
    func deleteAnalysis(analysisId: String) async throws { throw APIError.serverError(reason) }

    func analyzeConflict(productIds: [String]) async throws -> ConflictAnalysisData { try unavailable() }
    func getUserConflicts() async throws -> [ConflictRecord] { try unavailable() }
    func getConflict(conflictId: String) async throws -> ConflictRecord { try unavailable() }
    func deleteConflict(conflictId: String) async throws { throw APIError.serverError(reason) }

    func analyzeIngredients(productId: String) async throws -> IngredientAnalysis { try unavailable() }
    func getIngredientAnalysis(productId: String) async throws -> (product: Product, analysis: IngredientAnalysis) { try unavailable() }
}
