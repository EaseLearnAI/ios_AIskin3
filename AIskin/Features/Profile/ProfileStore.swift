import Foundation
import Combine

@MainActor
protocol ProfileClient: AnyObject {
    var currentUser: User? { get }
    func updateUsername(_ name: String) async throws
    func updateGender(_ gender: String) async throws
    func logout() async throws
    func deleteAccount() async throws
}

extension AuthService: ProfileClient {
    func updateUsername(_ name: String) async throws { try await updateUsername(name: name) }
    func updateGender(_ gender: String) async throws { try await updateGender(gender: gender) }
}

@MainActor
final class ProfileStore: ObservableObject {
    enum SheetDestination: String, Identifiable {
        case username
        case gender
        case feedback
        var id: String { rawValue }
    }

    enum Confirmation: String, Identifiable {
        case logout
        case deleteAccount
        var id: String { rawValue }
    }

    @Published var sheet: SheetDestination?
    @Published var confirmation: Confirmation?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isWorking = false

    let client: any ProfileClient

    init(client: any ProfileClient) {
        self.client = client
    }

    // No actor-bound cleanup is needed; avoid the isolated-deinit back-deployment path.
    nonisolated deinit {}

    var user: User? { client.currentUser }

    func updateUsername(_ name: String) async -> Bool {
        await perform { try await client.updateUsername(name) }
    }

    func updateGender(_ gender: String) async -> Bool {
        await perform { try await client.updateGender(gender) }
    }

    func confirm(_ confirmation: Confirmation) async {
        self.confirmation = nil
        switch confirmation {
        case .logout:
            _ = await perform { try await client.logout() }
        case .deleteAccount:
            _ = await perform { try await client.deleteAccount() }
        }
    }

    func clearError() { errorMessage = nil }

    private func perform(_ action: () async throws -> Void) async -> Bool {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await action()
            objectWillChange.send()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
