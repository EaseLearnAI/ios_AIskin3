import AuthenticationServices
import XCTest
@testable import AIskin

@MainActor
final class AppleLoginStoreTests: XCTestCase {
    func testEveryAuthorizationRequestHasFreshStateAndHashedNonce() {
        let store = AppleLoginStore()
        let first = ASAuthorizationAppleIDProvider().createRequest()
        let second = ASAuthorizationAppleIDProvider().createRequest()
        store.prepare(first)
        store.prepare(second)
        XCTAssertTrue(store.isLoading)
        XCTAssertEqual(first.nonce?.count, 64)
        XCTAssertNotNil(first.state)
        XCTAssertNotEqual(first.nonce, second.nonce)
        XCTAssertNotEqual(first.state, second.state)
        XCTAssertEqual(first.requestedScopes, [.fullName, .email])
    }

    func testCancellationEndsLoadingWithoutCreatingSessionOrError() async {
        let store = AppleLoginStore()
        let session = SessionStore(authClient: UnavailableServiceClients(reason: "No authentication is expected"), credentialStore: InMemoryCredentialStore())
        store.prepare(ASAuthorizationAppleIDProvider().createRequest())
        await store.complete(.failure(NSError(domain: ASAuthorizationError.errorDomain, code: ASAuthorizationError.canceled.rawValue)), session: session)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.errorMessage)
        XCTAssertFalse(session.isAuthenticated)
    }
}
