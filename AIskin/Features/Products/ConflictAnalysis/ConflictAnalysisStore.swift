import Foundation
import Combine

@MainActor
protocol ConflictAnalysisClient {
    func analyze(productIDs: [String]) async throws -> ConflictAnalysisData
}

@MainActor
struct LegacyConflictAnalysisClient: ConflictAnalysisClient {
    func analyze(productIDs: [String]) async throws -> ConflictAnalysisData {
        try await ConflictApiService.shared.analyzeConflict(productIds: productIDs)
    }
}

@MainActor
final class ConflictAnalysisStore: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(ConflictAnalysisData)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private let client: any ConflictAnalysisClient

    init(client: (any ConflictAnalysisClient)? = nil) {
        self.client = client ?? LegacyConflictAnalysisClient()
    }

    func analyze(productIDs: [String]) async {
        guard productIDs.count >= 2 else {
            state = .failed("未选择产品，请返回产品页面选择至少两个产品进行冲突分析")
            return
        }
        state = .loading
        do {
            let result = try await client.analyze(productIDs: productIDs)
            try Task.checkCancellation()
            state = .loaded(result)
        } catch is CancellationError {
            return
        } catch {
            state = .failed("分析产品冲突失败：\(error.localizedDescription)")
        }
    }
}
