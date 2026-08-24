import Foundation

/// 应用唯一的依赖组合根。Feature 只接收所需协议，不自行寻找 singleton。
@MainActor
final class AppDependencies {
    let httpClient: any HTTPClient
    let credentialStore: any CredentialStore
    let authClient: any AuthClient
    let productClient: any ProductClient
    let planClient: any PlanClient
    let skinAnalysisClient: any SkinAnalysisClient
    let conflictClient: any ConflictClient
    let ingredientAnalysisClient: any IngredientAnalysisClient
    let sessionStore: SessionStore

    init(
        httpClient: any HTTPClient,
        credentialStore: any CredentialStore,
        authClient: any AuthClient,
        productClient: any ProductClient,
        planClient: any PlanClient,
        skinAnalysisClient: any SkinAnalysisClient,
        conflictClient: any ConflictClient,
        ingredientAnalysisClient: any IngredientAnalysisClient,
        sessionStore: SessionStore? = nil
    ) {
        self.httpClient = httpClient
        self.credentialStore = credentialStore
        self.authClient = authClient
        self.productClient = productClient
        self.planClient = planClient
        self.skinAnalysisClient = skinAnalysisClient
        self.conflictClient = conflictClient
        self.ingredientAnalysisClient = ingredientAnalysisClient
        self.sessionStore = sessionStore ?? SessionStore(
            authClient: authClient,
            credentialStore: credentialStore
        )
    }

    static let live = AppDependencies(
        httpClient: APIClient.shared.httpClient,
        credentialStore: KeychainCredentialStore.shared,
        authClient: UserApiService.shared,
        productClient: ProductApiService.shared,
        planClient: PlanApiService.shared,
        skinAnalysisClient: SkinAnalysisApiService.shared,
        conflictClient: ConflictApiService.shared,
        ingredientAnalysisClient: IngredientAnalysisApiService.shared,
        sessionStore: SessionStore.shared
    )

    static var preview: AppDependencies {
        makeIsolated(reason: "Preview 未配置真实接口")
    }

    static func test(
        httpClient: (any HTTPClient)? = nil,
        credentialStore: (any CredentialStore)? = nil,
        clients: UnavailableServiceClients? = nil
    ) -> AppDependencies {
        let resolvedClients = clients ?? UnavailableServiceClients(reason: "测试未注入业务 Client")
        return AppDependencies(
            httpClient: httpClient ?? UnavailableHTTPClient(reason: "测试未注入 HTTPClient"),
            credentialStore: credentialStore ?? InMemoryCredentialStore(),
            authClient: resolvedClients,
            productClient: resolvedClients,
            planClient: resolvedClients,
            skinAnalysisClient: resolvedClients,
            conflictClient: resolvedClients,
            ingredientAnalysisClient: resolvedClients
        )
    }

    private static func makeIsolated(reason: String) -> AppDependencies {
        let clients = UnavailableServiceClients(reason: reason)
        return AppDependencies(
            httpClient: UnavailableHTTPClient(reason: reason),
            credentialStore: InMemoryCredentialStore(),
            authClient: clients,
            productClient: clients,
            planClient: clients,
            skinAnalysisClient: clients,
            conflictClient: clients,
            ingredientAnalysisClient: clients
        )
    }
}
