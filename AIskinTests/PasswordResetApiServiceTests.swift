import XCTest
@testable import AIskin

@MainActor
final class PasswordResetApiServiceTests: XCTestCase {
    func testRequestPasswordResetSendsPhoneToPublicEndpoint() async throws {
        let recorder = RequestRecorder()
        let transport: URLSessionHTTPClient.Transport = { request in
            await recorder.record(request)
            return try Self.response(
                for: request,
                json: #"{"success":true,"message":"验证码已发送"}"#
            )
        }
        let service = makeService(transport: transport)

        let message = try await service.requestPasswordReset(phone: "13800138000")
        let recordedRequest = await recorder.request
        let request = try XCTUnwrap(recordedRequest)
        let body = try JSONDecoder().decode(
            PasswordResetCodeRequest.self,
            from: XCTUnwrap(request.httpBody)
        )

        XCTAssertEqual(message, "验证码已发送")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/users/password-reset/request")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(body.phone, "13800138000")
    }

    func testConfirmPasswordResetSendsCodeAndNewPasswordToPublicEndpoint() async throws {
        let recorder = RequestRecorder()
        let transport: URLSessionHTTPClient.Transport = { request in
            await recorder.record(request)
            return try Self.response(
                for: request,
                json: #"{"success":true,"message":"密码修改成功"}"#
            )
        }
        let service = makeService(transport: transport)

        try await service.resetPassword(
            phone: "13800138000",
            verificationCode: "123456",
            newPassword: "newPassword"
        )
        let recordedRequest = await recorder.request
        let request = try XCTUnwrap(recordedRequest)
        let body = try JSONDecoder().decode(
            PasswordResetConfirmRequest.self,
            from: XCTUnwrap(request.httpBody)
        )

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.path, "/api/users/password-reset/confirm")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(body.phone, "13800138000")
        XCTAssertEqual(body.verificationCode, "123456")
        XCTAssertEqual(body.newPassword, "newPassword")
    }

    private func makeService(transport: @escaping URLSessionHTTPClient.Transport) -> UserApiService {
        let httpClient = URLSessionHTTPClient(
            baseURL: URL(string: "https://example.com/api")!,
            transport: transport
        )
        return UserApiService(apiClient: APIClient(httpClient: httpClient))
    }

    nonisolated private static func response(
        for request: URLRequest,
        json: String
    ) throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: try XCTUnwrap(request.url),
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (Data(json.utf8), response)
    }
}

private actor RequestRecorder {
    private(set) var request: URLRequest?

    func record(_ request: URLRequest) {
        self.request = request
    }
}
