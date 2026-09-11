//
//  AIskinApp.swift
//  AIskin
//
//  Created by terry on 2025/11/3.
//

import SwiftUI

@main
struct AIskinApp: App {
    private let dependencies = AppDependencies.live

    init() {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
#if targetEnvironment(simulator)
        if AppBackendConfiguration.mode == .live,
           arguments.contains("-AISkinUITestSession"),
           let path = ProcessInfo.processInfo.environment["AISKIN_UI_TEST_SESSION_FILE"],
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let session = try? JSONDecoder.apiDecoder.decode(UserResponse.self, from: data),
           session.success, let token = session.token, let user = session.data?.user {
            // A real local test-account session supplied by the integration harness.
            dependencies.sessionStore.login(token: token, user: user)
        }
#endif
        if arguments.contains("-uiTestingResetSession") {
            dependencies.sessionStore.resetForTesting()
        } else if AppBackendConfiguration.mode == .mock,
                  !arguments.contains("-AISkinShowLogin"),
                  !dependencies.sessionStore.isAuthenticated {
            dependencies.sessionStore.login(
                token: "mock-ui-session-token",
                user: AppBackendConfiguration.demoUser
            )
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencies.sessionStore)
                .onOpenURL { url in
                    if dependencies.paymentLauncher.handleOpenURL(url) {
                        NotificationCenter.default.post(name: .aisKinPaymentReturned, object: nil)
                    }
                }
        }
    }
}
