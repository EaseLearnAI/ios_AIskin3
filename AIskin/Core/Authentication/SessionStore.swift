import Foundation
import Combine

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore(
        authClient: UserApiService.shared,
        credentialStore: AppBackendConfiguration.credentialStore,
        userKey: AppBackendConfiguration.currentUserKey
    )

    // internal setter 暂时保留给旧测试；业务页面只应读取，由 SessionStore 方法写入。
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let authClient: any AuthClient
    private let credentialStore: any CredentialStore
    private let userDefaults: UserDefaults
    private let userKey: String

    init(
        authClient: any AuthClient,
        credentialStore: any CredentialStore,
        userDefaults: UserDefaults = .standard,
        userKey: String = "currentUser"
    ) {
        self.authClient = authClient
        self.credentialStore = credentialStore
        self.userDefaults = userDefaults
        self.userKey = userKey
        restorePersistedSession()
    }

    func register(name: String, email: String, password: String) async throws {
        let credentials = try await authClient.register(name: name, email: email, password: password)
        try establishSession(token: credentials.token, user: credentials.user)
    }

    func register(name: String, phone: String, password: String, gender: String?) async throws {
        let credentials = try await authClient.register(
            name: name,
            phone: phone,
            password: password,
            gender: gender
        )
        try establishSession(token: credentials.token, user: credentials.user)
    }

    func login(email: String, password: String) async throws {
        let credentials = try await authClient.login(email: email, password: password)
        try establishSession(token: credentials.token, user: credentials.user)
    }

    func login(phone: String, password: String) async throws {
        let credentials = try await authClient.login(phone: phone, password: password)
        try establishSession(token: credentials.token, user: credentials.user)
    }

    func loginWithApple(_ request: AppleLoginRequest) async throws {
        let credentials = try await authClient.loginWithApple(request)
        try establishSession(token: credentials.token, user: credentials.user)
    }

    func requestPasswordReset(phone: String) async throws -> String {
        try await authClient.requestPasswordReset(phone: phone)
    }

    func resetPassword(
        phone: String,
        verificationCode: String,
        newPassword: String
    ) async throws {
        try await authClient.resetPassword(
            phone: phone,
            verificationCode: verificationCode,
            newPassword: newPassword
        )
    }

    func login(token: String, user: User) {
        do {
            try establishSession(token: token, user: user)
        } catch {
#if DEBUG
            print("❌ 无法安全保存登录凭据: \(error.localizedDescription)")
#endif
        }
    }

    func logout() async throws {
        do {
            try await authClient.logout()
        } catch {
#if DEBUG
            print("⚠️ 服务端退出失败，已继续清理本地会话: \(error.localizedDescription)")
#endif
        }
        try clearLocalSession()
    }

    func deleteAccount() async throws {
        try await authClient.deleteAccount()
        try clearLocalSession()
    }

    func refreshCurrentUser() async throws {
        let user = try await authClient.getCurrentUser()
        setCurrentUser(user)
    }

    func updateUsername(name: String) async throws {
        let user = try await authClient.updateUsername(name: name)
        setCurrentUser(user)
    }

    func updateGender(gender: String) async throws {
        let user = try await authClient.updateGender(gender: gender)
        setCurrentUser(user)
    }

    func updateAge(age: Int) async throws {
        guard User.ageRange.contains(age) else {
            throw APIError.serverError("请输入 13–120 的年龄")
        }
        guard let userID = currentUser?.id else { throw APIError.unauthorized }
        let user = try await authClient.updateAge(age: age)
        // A late response must not restore a logged-out or different account.
        guard currentUser?.id == userID, user.id == userID else { throw APIError.unauthorized }
        guard user.age == age else {
            throw APIError.serverError("年龄未保存成功，请重试")
        }
        setCurrentUser(user)
    }

    func getToken() -> String? {
        credentialStore.readToken()
    }

    func saveUser(_ user: User) {
        setCurrentUser(user)
    }

    func getCurrentUser() -> User? {
        guard let data = userDefaults.data(forKey: userKey) else { return nil }
        return try? JSONDecoder.apiDecoder.decode(User.self, from: data)
    }

    // 兼容已有测试和旧页面的可写属性；业务代码应通过会话方法更新。
    func resetForTesting() {
        try? clearLocalSession()
    }

    private func establishSession(token: String, user: User) throws {
        try credentialStore.saveToken(token)
        setCurrentUser(user)
        isAuthenticated = true
    }

    private func setCurrentUser(_ user: User) {
        currentUser = user
        if let encoded = try? JSONEncoder.apiEncoder.encode(user) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }

    private func clearLocalSession() throws {
        var credentialError: Error?
        do {
            try credentialStore.deleteToken()
        } catch {
            credentialError = error
        }
        userDefaults.removeObject(forKey: userKey)
        currentUser = nil
        isAuthenticated = false
        if let credentialError {
            throw credentialError
        }
    }

    private func restorePersistedSession() {
        guard let token = credentialStore.readToken(), !token.isEmpty else { return }
        currentUser = getCurrentUser()
        isAuthenticated = true
    }
}
