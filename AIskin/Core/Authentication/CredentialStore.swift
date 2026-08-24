import Foundation
import Security

protocol CredentialStore {
    func readToken() -> String?
    func saveToken(_ token: String) throws
    func deleteToken() throws
}

enum CredentialStoreError: LocalizedError {
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .keychain(let status):
            return "无法访问安全凭据（Keychain: \(status)）"
        }
    }
}

final class KeychainCredentialStore: CredentialStore {
    static let shared = KeychainCredentialStore()

    private let service: String
    private let account: String
    private let legacyDefaults: UserDefaults
    private let legacyTokenKey: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "personal.AIskin",
        account: String = "api-auth-token",
        legacyDefaults: UserDefaults = .standard,
        legacyTokenKey: String = "authToken"
    ) {
        self.service = service
        self.account = account
        self.legacyDefaults = legacyDefaults
        self.legacyTokenKey = legacyTokenKey
        _ = readToken()
    }

    func readToken() -> String? {
        if let token = readKeychainToken() {
            return token
        }

        guard let legacyToken = legacyDefaults.string(forKey: legacyTokenKey),
              !legacyToken.isEmpty else {
            return nil
        }

        // 动态兜底保证升级前已运行的进程和旧调用方不会被强制退出。
        do {
            try saveToken(legacyToken)
            legacyDefaults.removeObject(forKey: legacyTokenKey)
        } catch {
#if DEBUG
            print("⚠️ 旧登录凭据迁移失败，将保留旧凭据供下次重试")
#endif
        }
        return legacyToken
    }

    private func readKeychainToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8),
              !token.isEmpty else {
            return nil
        }
        return token
    }

    func saveToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw CredentialStoreError.keychain(errSecParam)
        }

        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var insertion = baseQuery
            insertion[kSecValueData as String] = data
            insertion[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let insertionStatus = SecItemAdd(insertion as CFDictionary, nil)
            guard insertionStatus == errSecSuccess else {
                throw CredentialStoreError.keychain(insertionStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw CredentialStoreError.keychain(updateStatus)
        }
    }

    func deleteToken() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStoreError.keychain(status)
        }
        legacyDefaults.removeObject(forKey: legacyTokenKey)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

}

final class InMemoryCredentialStore: CredentialStore {
    private var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func readToken() -> String? {
        token
    }

    func saveToken(_ token: String) throws {
        self.token = token
    }

    func deleteToken() throws {
        token = nil
    }
}
