import Foundation

protocol HTTPClient {
    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response
}

struct UnavailableHTTPClient: HTTPClient {
    let reason: String

    init(reason: String = "当前环境未配置网络客户端") {
        self.reason = reason
    }

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        throw APIError.serverError(reason)
    }
}
