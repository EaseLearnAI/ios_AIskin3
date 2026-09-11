import AuthenticationServices
import Combine
import CryptoKit
import Foundation
import Security

struct AppleLoginRequest: Codable {
    let identityToken: String
    let authorizationCode: String
    let rawNonce: String
    var givenName: String?
    var familyName: String?
}

@MainActor
final class AppleLoginStore: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    private var rawNonce: String?
    private var requestState: String?

    // No actor-bound cleanup; the back-deployed isolated deinitializer crashes on this runtime.
    nonisolated deinit {}

    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = nil
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            rawNonce = nil
            errorMessage = "暂时无法开始安全登录，请重试"
            return
        }
        let nonce = bytes.map { String(format: "%02x", $0) }.joined()
        rawNonce = nonce
        requestState = UUID().uuidString
        request.requestedScopes = [.fullName, .email]
        request.nonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
        request.state = requestState
        isLoading = true
    }

    func complete(_ result: Result<ASAuthorization, Error>, session: SessionStore) async {
        defer { isLoading = false; rawNonce = nil; requestState = nil }
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = "Apple 登录未完成：\(error.localizedDescription)"
            }
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = rawNonce, let expectedState = requestState,
                  credential.state == expectedState,
                  let tokenData = credential.identityToken,
                  let codeData = credential.authorizationCode,
                  let token = String(data: tokenData, encoding: .utf8), !token.isEmpty,
                  let code = String(data: codeData, encoding: .utf8), !code.isEmpty else {
                errorMessage = "未收到有效的 Apple 登录凭据，请重试"
                return
            }
            do {
                try await session.loginWithApple(AppleLoginRequest(
                    identityToken: token, authorizationCode: code, rawNonce: nonce,
                    givenName: credential.fullName?.givenName,
                    familyName: credential.fullName?.familyName
                ))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
