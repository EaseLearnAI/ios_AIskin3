import Foundation

@MainActor
protocol PaymentClient {
    func getCatalog() async throws -> PaymentCatalog
    func createOrder(productId: String, idempotencyKey: String) async throws -> PaymentOrderCreation
    func getOrder(orderID: String) async throws -> PaymentOrder
    func refreshOrder(orderID: String) async throws -> PaymentOrder
    func getMembership() async throws -> PaymentMembership
}

@MainActor
final class PaymentApiService: PaymentClient {
    private let httpClient: any HTTPClient

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    func getCatalog() async throws -> PaymentCatalog {
        try await load(APIRequest(path: "/payments/catalog"))
    }

    func createOrder(productId: String, idempotencyKey: String) async throws -> PaymentOrderCreation {
        // Retry identity belongs to the purchase attempt, not to an individual HTTP request.
        let request = try APIRequest<PaymentEnvelope<PaymentOrderCreation>>.json(
            path: "/payments/orders",
            method: .post,
            body: CreatePaymentOrderBody(productId: productId, idempotencyKey: idempotencyKey)
        )
        return try await load(request)
    }

    func getOrder(orderID: String) async throws -> PaymentOrder {
        let result: PaymentOrderEnvelope = try await load(APIRequest(path: try orderPath(orderID)))
        return result.order
    }

    func refreshOrder(orderID: String) async throws -> PaymentOrder {
        let result: PaymentOrderEnvelope = try await load(APIRequest(
            path: try orderPath(orderID) + "/refresh",
            method: .post
        ))
        return result.order
    }

    func getMembership() async throws -> PaymentMembership {
        try await load(APIRequest(path: "/payments/membership"))
    }

    private func orderPath(_ orderID: String) throws -> String {
        // Order identifiers are MongoDB ObjectIds, never arbitrary URL path fragments.
        guard orderID.range(of: "^[0-9a-fA-F]{24}$", options: .regularExpression) != nil else {
            throw APIError.invalidURL
        }
        return "/payments/orders/\(orderID)"
    }

    private func load<Value: Decodable>(_ request: APIRequest<PaymentEnvelope<Value>>) async throws -> Value {
        let response = try await httpClient.send(request)
        guard response.success else {
            throw APIError.serverError(response.message ?? "支付服务暂不可用，请稍后重试")
        }
        guard let data = response.data else {
            throw APIError.decodingError
        }
        return data
    }
}

private struct CreatePaymentOrderBody: Encodable {
    let productId: String
    let idempotencyKey: String
}

private struct PaymentOrderEnvelope: Decodable {
    let order: PaymentOrder
}

private struct PaymentEnvelope<Value: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: Value?
}
