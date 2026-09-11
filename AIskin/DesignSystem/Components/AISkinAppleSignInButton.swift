import AuthenticationServices
import SwiftUI

enum AISkinAppleSignInPresentation {
    case standard
    case onboarding
}

struct AISkinAppleSignInButton: View {
    var isLoading: Bool
    var presentation: AISkinAppleSignInPresentation = .standard
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    var body: some View {
        SignInWithAppleButton(presentation == .onboarding ? .signIn : .continue, onRequest: onRequest, onCompletion: onCompletion)
            .signInWithAppleButtonStyle(.black)
            .frame(height: AISkinAuthLayout.buttonHeight)
            .clipShape(RoundedRectangle(cornerRadius: presentation == .onboarding ? AISkinOnboardingTokens.buttonRadius : AISkinAuthLayout.buttonCornerRadius))
            .disabled(isLoading)
            .opacity(isLoading ? 0.6 : 1)
            .accessibilityIdentifier("auth.apple-sign-in")
    }
}
