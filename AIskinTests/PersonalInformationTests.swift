import XCTest
@testable import AIskin

@MainActor
final class PersonalInformationTests: XCTestCase {
    func testAgeDecodesAndRemainsCompatibleWithOlderUsers() throws {
        let decoder = JSONDecoder.apiDecoder
        let user = try decoder.decode(User.self, from: Data(#"{"_id":"one","name":"User","age":28}"#.utf8))
        XCTAssertEqual(user.age, 28)
        let legacy = try decoder.decode(User.self, from: Data(#"{"_id":"one","name":"User"}"#.utf8))
        XCTAssertNil(legacy.age)
    }

    func testSavedAgeSurvivesSessionRecreationAndLogoutClearsIt() async throws {
        let suite = "age-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let client = AgeClient()
        let credentials = InMemoryCredentialStore()
        let session = SessionStore(authClient: client, credentialStore: credentials, userDefaults: defaults)
        session.login(token: "test-session", user: client.user)
        try await session.updateAge(age: 28)
        XCTAssertEqual(session.currentUser?.age, 28)
        let restored = SessionStore(authClient: client, credentialStore: credentials, userDefaults: defaults)
        XCTAssertEqual(restored.currentUser?.age, 28)
        try await restored.logout()
        XCTAssertNil(restored.getCurrentUser())
    }

    func testInvalidOrFailedSavePreservesExistingAge() async throws {
        let suite = "age-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let client = AgeClient()
        let session = SessionStore(authClient: client, credentialStore: InMemoryCredentialStore(), userDefaults: defaults)
        session.login(token: "test-session", user: client.user)
        for age in [0, 12, 121] {
            do { try await session.updateAge(age: age); XCTFail("Invalid age must fail") } catch {}
        }
        XCTAssertEqual(client.requests, 0)
        client.shouldFail = true
        do { try await session.updateAge(age: 30); XCTFail("Network failure must be propagated") } catch {}
        XCTAssertEqual(session.currentUser?.age, 24)
        XCTAssertEqual(session.getCurrentUser()?.age, 24)
        client.shouldFail = false
        client.ignoreAge = true
        do { try await session.updateAge(age: 30); XCTFail("An unchanged response must not report success") } catch {}
        XCTAssertEqual(session.getCurrentUser()?.age, 24)
    }
}

@MainActor
private final class AgeClient: AuthClient {
    var user = User(id: "one", name: "User", age: 24)
    var requests = 0
    var shouldFail = false
    var ignoreAge = false

    func updateAge(age: Int) async throws -> User {
        requests += 1
        if shouldFail { throw APIError.unknown }
        if !ignoreAge { user.age = age }
        return user
    }
    func logout() async throws {}
    func register(name: String, email: String, password: String) async throws -> (token: String, user: User) { throw APIError.unknown }
    func register(name: String, phone: String, password: String, gender: String?) async throws -> (token: String, user: User) { throw APIError.unknown }
    func login(email: String, password: String) async throws -> (token: String, user: User) { throw APIError.unknown }
    func login(phone: String, password: String) async throws -> (token: String, user: User) { throw APIError.unknown }
    func requestPasswordReset(phone: String) async throws -> String { throw APIError.unknown }
    func resetPassword(phone: String, verificationCode: String, newPassword: String) async throws { throw APIError.unknown }
    func getCurrentUser() async throws -> User { user }
    func updateUsername(name: String) async throws -> User { throw APIError.unknown }
    func updateGender(gender: String) async throws -> User { throw APIError.unknown }
    func getUserStats() async throws -> UserStats { throw APIError.unknown }
    func deleteAccount() async throws { throw APIError.unknown }
}
