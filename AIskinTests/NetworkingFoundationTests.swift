import XCTest
@testable import AIskin

@MainActor
final class NetworkingFoundationTests: XCTestCase {
    func testRequestConstructionIncludesMethodQueryAndJSONBody() throws {
        struct RequestBody: Codable { let name: String }
        struct ResponseBody: Codable { let success: Bool }

        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://example.com/api")!,
            transport: { _ in throw APIError.unknown }
        )
        var request = try APIRequest<ResponseBody>.json(
            path: "/products",
            method: .post,
            body: RequestBody(name: "cleanser")
        )
        request = APIRequest(
            path: request.path,
            method: request.method,
            queryItems: [URLQueryItem(name: "page", value: "2")],
            headers: request.headers,
            body: request.body,
            requiresAuthentication: false
        )

        let urlRequest = try client.makeURLRequest(for: request)

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://example.com/api/products?page=2")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(
            try JSONDecoder().decode(RequestBody.self, from: XCTUnwrap(urlRequest.httpBody)).name,
            "cleanser"
        )
    }

    func testAuthenticatedRequestAddsBearerTokenWithoutChangingPublicRequestAPI() throws {
        struct ResponseBody: Codable { let success: Bool }
        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://example.com/api")!,
            transport: { _ in throw APIError.unknown },
            tokenProvider: { "secret-token" }
        )

        let urlRequest = try client.makeURLRequest(
            for: APIRequest<ResponseBody>(path: "/users/me")
        )

        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
    }

    func testSuccessfulResponseDecodesModel() async throws {
        struct ResponseBody: Codable, Equatable { let success: Bool; let value: Int }
        let transport: URLSessionHTTPClient.Transport = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (Data(#"{"success":true,"value":42}"#.utf8), response)
        }
        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://example.com/api")!,
            transport: transport
        )

        let result = try await client.send(APIRequest<ResponseBody>(path: "/value"))

        XCTAssertEqual(result, ResponseBody(success: true, value: 42))
    }

    func test401MapsToUnauthorized() async {
        struct ResponseBody: Codable { let success: Bool }
        let transport: URLSessionHTTPClient.Transport = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data(#"{"success":false,"message":"unauthorized"}"#.utf8), response)
        }
        let client = URLSessionHTTPClient(
            baseURL: URL(string: "https://example.com/api")!,
            transport: transport
        )

        do {
            let _: ResponseBody = try await client.send(APIRequest(path: "/private"))
            XCTFail("Expected unauthorized error")
        } catch APIError.unauthorized {
            // Expected.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNotFoundPreservesTheBackendCode() async {
        let client = URLSessionHTTPClient(transport: { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (Data(#"{"message":"报告不存在","code":"ANALYSIS_NOT_FOUND"}"#.utf8), response)
        })
        do {
            let _: EmptyResponse = try await client.send(APIRequest(path: "/products/product/ingredient-analysis"))
            XCTFail("Expected a typed missing report error")
        } catch APIError.notFound(let message, let code) {
            XCTAssertEqual(message, "报告不存在")
            XCTAssertEqual(code, "ANALYSIS_NOT_FOUND")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTransportCancellationIsNotWrappedAsNetworkFailure() async {
        for error in [CancellationError() as Error, URLError(.cancelled)] {
            let client = URLSessionHTTPClient(transport: { _ in throw error })
            do {
                let _: EmptyResponse = try await client.send(APIRequest(path: "/cancelled"))
                XCTFail("Expected cancellation")
            } catch is CancellationError {
                // Both Swift Task and URLSession cancellation share this contract.
            } catch {
                XCTFail("Cancellation was changed into \(error)")
            }
        }
    }

    func testCancelledTaskDoesNotStartAnotherRequest() async {
        var requestCount = 0
        let client = URLSessionHTTPClient(transport: { _ in
            requestCount += 1
            throw APIError.unknown
        })
        let task = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            do {
                let _: EmptyResponse = try await client.send(APIRequest(path: "/cancelled"))
                XCTFail("Expected cancellation")
            } catch is CancellationError {
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        await task.value
        XCTAssertEqual(requestCount, 0)
    }
}
