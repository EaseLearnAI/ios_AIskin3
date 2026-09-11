import Foundation
import Combine

@MainActor
protocol ConflictHistoryClient {
    func records() async throws -> [ConflictRecord]
}

@MainActor
struct LegacyConflictHistoryClient: ConflictHistoryClient {
    func records() async throws -> [ConflictRecord] { try await ConflictApiService.shared.getUserConflicts() }
}

@MainActor
final class ConflictHistoryStore: ObservableObject {
    enum State {
        case idle, loading
        case loaded([ConflictRecord])
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private let client: any ConflictHistoryClient

    init(client: (any ConflictHistoryClient)? = nil) {
        self.client = client ?? LegacyConflictHistoryClient()
    }

    func load() async {
        state = .loading
        do {
            let records = try await client.records()
            try Task.checkCancellation()
            state = .loaded(records.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) })
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
