import Foundation

enum AppBackendMode: String {
    case mock
    case live
}

enum AppBackendConfiguration {
    static let mode: AppBackendMode = {
#if DEBUG
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("-AISkinUseLiveBackend") {
            return .live
        }
        if processInfo.arguments.contains("-AISkinUseMockBackend") ||
            processInfo.environment["AISKIN_BACKEND_MODE"]?.lowercased() == "mock" {
            return .mock
        }
        return .live
#else
        return .live
#endif
    }()

    static let credentialStore: any CredentialStore = {
        switch mode {
        case .mock:
            // Mock sessions exist only for the current app process. They must
            // not depend on signing entitlements or write demo credentials to
            // the user's Keychain.
            return InMemoryCredentialStore()
        case .live:
            return KeychainCredentialStore.shared
        }
    }()

    static var currentUserKey: String {
        mode == .mock ? "mockCurrentUser" : "currentUser"
    }

    static var demoUser: User {
        User(
            id: "mock-user-001",
            name: "UI 演示用户",
            email: "demo@aiskin.local",
            phone: "13800138000",
            avatar: nil,
            gender: "女"
        )
    }
}
