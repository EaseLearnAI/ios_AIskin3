import XCTest
@testable import AIskin

@MainActor
final class PaymentApiServiceTests: XCTestCase {
    func testCatalogUsesAuthenticatedServerPricesAndPreservesPlannedAppleChannel() async throws {
        let requests = RecordedPaymentRequests()
        let service = makeService(requests: requests, json: Self.catalogJSON)

        let catalog = try await service.getCatalog()

        let request = try XCTUnwrap(requests.values.first)
        XCTAssertEqual(request.url?.path, "/api/payments/catalog")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer payment-test-token")
        XCTAssertEqual(catalog.products.first?.amountFen, 1234)
        XCTAssertEqual(catalog.products.first?.autoRenew, false)
        XCTAssertEqual(catalog.provider, .alipay)
        XCTAssertEqual(catalog.environment, .sandbox)
        XCTAssertEqual(catalog.channels.last, PaymentChannel(provider: .apple, available: false, status: "planned"))
    }

    func testCreateOrderRetriesSendOnlyProductAndOriginalIdempotencyKey() async throws {
        let requests = RecordedPaymentRequests()
        let service = makeService(requests: requests, json: Self.creationJSON)

        let first = try await service.createOrder(productId: "member_month", idempotencyKey: "attempt-12345678")
        let second = try await service.createOrder(productId: "member_month", idempotencyKey: "attempt-12345678")

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.order.amountFen, 1234)
        XCTAssertEqual(first.payment?.orderString, "signed-test-payload")
        XCTAssertEqual(requests.values.count, 2)
        for request in requests.values {
            XCTAssertEqual(request.url?.path, "/api/payments/orders")
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer payment-test-token")
            let body = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: String])
            XCTAssertEqual(body, ["productId": "member_month", "idempotencyKey": "attempt-12345678"])
        }
    }

    func testExistingPaidAttemptCanReturnNoPaymentPayload() async throws {
        let json = Self.creationJSON
            .replacingOccurrences(of: "\"pending\"", with: "\"paid\"")
            .replacingOccurrences(of: "{\"orderString\":\"signed-test-payload\"}", with: "null")
        let service = makeService(json: json)

        let result = try await service.createOrder(productId: "member_month", idempotencyKey: "attempt-12345678")

        XCTAssertEqual(result.order.status, .paid)
        XCTAssertNil(result.payment)
    }

    func testGetAndRefreshUseOwnedOrderRoutesWithoutClientPaymentProof() async throws {
        let requests = RecordedPaymentRequests()
        let service = makeService(requests: requests, json: "{\"success\":true,\"data\":{\"order\":\(Self.orderJSON)}}")

        let order = try await service.getOrder(orderID: Self.orderID)
        let refreshed = try await service.refreshOrder(orderID: Self.orderID)

        XCTAssertEqual(order, refreshed)
        XCTAssertEqual(order.refundAmountFen, 0)
        XCTAssertNil(order.paidAt)
        XCTAssertEqual(order.expiresAt, Date(timeIntervalSince1970: 1_789_084_800))
        XCTAssertEqual(requests.values.map { $0.url?.path }, [
            "/api/payments/orders/\(Self.orderID)",
            "/api/payments/orders/\(Self.orderID)/refresh"
        ])
        XCTAssertEqual(requests.values.map(\.httpMethod), ["GET", "POST"])
        XCTAssertTrue(requests.values.allSatisfy { $0.httpBody == nil })
        XCTAssertTrue(requests.values.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer payment-test-token" })
    }

    func testFreeMembershipKeepsHistoricalExpiryWithoutGrantingMembership() async throws {
        let requests = RecordedPaymentRequests()
        let service = makeService(requests: requests, json: #"{"success":true,"data":{"tier":"free","validUntil":"2020-01-01T00:00:00Z","provider":null,"environment":"production","autoRenew":false}}"#)

        let membership = try await service.getMembership()

        XCTAssertEqual(membership.tier, .free)
        XCTAssertNotNil(membership.validUntil)
        XCTAssertNil(membership.provider)
        XCTAssertEqual(membership.environment, .production)
        XCTAssertFalse(membership.autoRenew)
        XCTAssertEqual(requests.values.first?.url?.path, "/api/payments/membership")
    }

    func testServerFailureDoesNotReturnIncludedMembershipData() async {
        let service = makeService(json: #"{"success":false,"message":"支付状态暂未同步","data":{"tier":"member","validUntil":null,"provider":"alipay","environment":"sandbox","autoRenew":false}}"#)
        do {
            _ = try await service.getMembership()
            XCTFail("An unsuccessful response must not grant membership")
        } catch APIError.serverError(let message) {
            XCTAssertEqual(message, "支付状态暂未同步")
        } catch {
            XCTFail("Expected a service failure")
        }
    }

    func testFractionalFenIsRejectedInsteadOfRoundingCheckoutPrice() async {
        let service = makeService(json: Self.catalogJSON.replacingOccurrences(of: "1234", with: "12.34"))
        do {
            _ = try await service.getCatalog()
            XCTFail("Money must be integer fen")
        } catch APIError.decodingError {
        } catch {
            XCTFail("Expected a decoding failure")
        }
    }

    func testInvalidOrderIDDoesNotReachTransport() async {
        let requests = RecordedPaymentRequests()
        let service = makeService(requests: requests, json: "{}")
        do {
            _ = try await service.refreshOrder(orderID: "../membership?admin=true")
            XCTFail("Order IDs must not escape their route")
        } catch APIError.invalidURL {
        } catch {
            XCTFail("Expected an invalid identifier failure")
        }
        XCTAssertTrue(requests.values.isEmpty)
    }

    func testUnauthorizedPaymentRequestRetainsAuthenticationError() async {
        let service = makeService(json: #"{"success":false,"message":"未登录"}"#, statusCode: 401)
        do {
            _ = try await service.getMembership()
            XCTFail("Expected authentication failure")
        } catch APIError.unauthorized {
        } catch {
            XCTFail("Expected unauthorized")
        }
    }

    func testSignedPayloadDescriptionsAreRedacted() {
        let payload = PaymentPayload(orderString: "sensitive-signature")
        XCTAssertFalse(String(describing: payload).contains("sensitive-signature"))
        XCTAssertFalse(String(reflecting: payload).contains("sensitive-signature"))
    }

    private func makeService(
        requests: RecordedPaymentRequests? = nil,
        json: String,
        statusCode: Int = 200
    ) -> PaymentApiService {
        let requests = requests ?? RecordedPaymentRequests()
        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://example.com/api")!,
            transport: { request in
                requests.values.append(request)
                let response = HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
                return (Data(json.utf8), response)
            },
            tokenProvider: { "payment-test-token" }
        )
        return PaymentApiService(httpClient: client)
    }

    private static let orderID = "0123456789abcdef01234567"
    private static let orderJSON = #"{"id":"0123456789abcdef01234567","outTradeNo":"AS-test-order","productId":"member_month","amountFen":1234,"currency":"CNY","status":"pending","expiresAt":"2026-09-11T00:00:00.000Z","paidAt":null,"refundAmountFen":0,"provider":"alipay","environment":"sandbox"}"#
    private static let creationJSON = "{\"success\":true,\"data\":{\"order\":\(orderJSON),\"payment\":{\"orderString\":\"signed-test-payload\"}}}"
    private static let catalogJSON = #"{"success":true,"data":{"provider":"alipay","environment":"sandbox","available":true,"products":[{"id":"member_month","name":"析肤会员 · 1个月","amountFen":1234,"currency":"CNY","durationMonths":1,"autoRenew":false}],"channels":[{"provider":"alipay","available":true},{"provider":"apple","available":false,"status":"planned"}]}}"#
}

@MainActor
private final class RecordedPaymentRequests {
    var values: [URLRequest] = []
}
