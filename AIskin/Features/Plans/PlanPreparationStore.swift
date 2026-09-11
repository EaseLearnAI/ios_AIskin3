import Combine
import Foundation

@MainActor
protocol PlanPreparationClient {
    func hasSkinReport() async throws -> Bool
    func analyzedProductCount() async throws -> Int
}

@MainActor
struct LivePlanPreparationClient: PlanPreparationClient {
    func hasSkinReport() async throws -> Bool {
        let history = try await SkinAnalysisApiService.shared.getAnalysisHistory(page: 1, limit: 1)
        return !history.analyses.isEmpty
    }

    func analyzedProductCount() async throws -> Int {
        guard let userID = AuthService.shared.currentUser?.id else {
            throw APIError.serverError("登录状态已失效，请重新登录")
        }
        let products = try await ProductApiService.shared.getUserProducts(userId: userID)
        return products.filter(Self.hasAnalysis).count
    }

    static func hasAnalysis(_ product: Product) -> Bool {
        !product.ingredients.isEmpty && (
            product.overallRating != nil || product.safetyScore != nil || product.efficacyScore != nil
        )
    }
}

@MainActor
final class PlanPreparationStore: ObservableObject {
    static let minimumProductCount = 2

    enum State: Equatable {
        case idle, checking, ready
        case failed(String)
    }

    enum Step: Int {
        case skin = 1, products, plan
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var hasSkinReport = false
    @Published private(set) var productCount = 0
    @Published private(set) var hasSavedPlan = false
    private let client: any PlanPreparationClient

    init(client: (any PlanPreparationClient)? = nil) {
        self.client = client ?? LivePlanPreparationClient()
    }

    var canCreatePlan: Bool {
        state == .ready && hasSkinReport && hasEnoughProducts
    }

    var hasEnoughProducts: Bool { productCount >= Self.minimumProductCount }

    var missingProductCount: Int { max(0, Self.minimumProductCount - productCount) }

    var entryNoticeTitle: String {
        if !hasSkinReport && !hasEnoughProducts { return "从了解你开始" }
        if !hasEnoughProducts { return "还需添加 \(missingProductCount) 件护肤品" }
        return "请先完成肌肤检测"
    }

    var entryNoticeMessage: String {
        if !hasSkinReport && !hasEnoughProducts {
            return "测测肤况，添上日常护肤品。"
        }
        if !hasEnoughProducts {
            return "用你已有的产品，安排早晚护肤。\n去护肤柜补齐 \(Self.minimumProductCount) 件已分析产品，即可定制。"
        }
        return "结合肌肤检测结果与护肤柜里的产品，\n为你安排早晚护肤步骤。"
    }

    var missingRequirements: [String] {
        var messages: [String] = []
        if !hasSkinReport { messages.append("请先完成肌肤检测") }
        if !hasEnoughProducts {
            messages.append("方案根据护肤柜里的产品生成，请再添加并分析 \(missingProductCount) 件（至少需要 \(Self.minimumProductCount) 件）")
        }
        return messages
    }

    var completedCount: Int {
        [Step.skin, .products, .plan].filter(isCompleted).count
    }

    var nextStep: Step? {
        guard state == .ready else { return nil }
        if !hasSkinReport { return .skin }
        if !hasEnoughProducts { return .products }
        return hasSavedPlan ? nil : .plan
    }

    func isCompleted(_ step: Step) -> Bool {
        switch step {
        case .skin: hasSkinReport
        case .products: hasEnoughProducts
        case .plan: hasSavedPlan
        }
    }

    func markPlanSaved() {
        guard canCreatePlan else { return }
        hasSavedPlan = true
    }

    func refresh() async {
        guard state != .checking else { return }
        state = .checking
        do {
            async let report = client.hasSkinReport()
            async let products = client.analyzedProductCount()
            let snapshot = try await (report, products)
            try Task.checkCancellation()
            hasSkinReport = snapshot.0
            productCount = snapshot.1
            if !hasSkinReport || !hasEnoughProducts {
                hasSavedPlan = false
            }
            state = .ready
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed("暂时无法检查已有资料：\(error.localizedDescription)")
        }
    }
}
