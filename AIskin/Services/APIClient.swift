import Foundation

/// 后端通用响应结构。字段名称保持与现有服务端 JSON 完全一致。
struct APIResponse<T: Codable>: Codable {
    var success: Bool
    var message: String?
    var data: T?
    var error: String?
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case notFound(message: String, code: String?)
    case unauthorized
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有返回数据"
        case .decodingError:
            return "数据解析错误"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .notFound(let message, _):
            return message
        case .unauthorized:
            return "未授权，请重新登录"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .unknown:
            return "未知错误"
        }
    }
}

/// 旧 Service 的兼容入口。所有请求已委托给统一 HTTPClient，调用方无需一次性迁移。
final class APIClient {
    static let shared = APIClient()

    let httpClient: any HTTPClient

    init(httpClient: (any HTTPClient)? = nil) {
        if let httpClient {
            self.httpClient = httpClient
            return
        }
#if DEBUG
        if AppBackendConfiguration.mode == .mock {
            self.httpClient = MockBackendHTTPClient()
            print("🧪 AISkin 使用完整 UI Mock 后端（添加 -AISkinUseLiveBackend 可切换真实接口）")
            return
        }
#endif

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 120
#if DEBUG && !targetEnvironment(simulator)
        // The first LAN request can wait while the user answers iOS's
        // local-network permission prompt, within the existing 120s limit.
        configuration.waitsForConnectivity = true
#endif
        let session = URLSession(configuration: configuration)
        self.httpClient = URLSessionHTTPClient(
            session: session,
            tokenProvider: { AppBackendConfiguration.credentialStore.readToken() }
        )
    }

    func get<T: Codable>(
        endpoint: String,
        requiresAuth: Bool = true,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        let queryItems = (queryParams ?? [:])
            .sorted(by: { $0.key < $1.key })
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        let request = APIRequest<T>(
            path: endpoint,
            method: .get,
            queryItems: queryItems,
            headers: ["Content-Type": "application/json"],
            requiresAuthentication: requiresAuth
        )
        return try await httpClient.send(request)
    }

    func post<T: Codable, U: Codable>(
        endpoint: String,
        body: U,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try APIRequest<T>.json(
            path: endpoint,
            method: .post,
            body: body,
            requiresAuthentication: requiresAuth
        )
        return try await httpClient.send(request)
    }

    func upload<T: Codable>(
        endpoint: String,
        fileData: Data,
        fileName: String,
        fieldName: String,
        mimeType: String = "image/jpeg",
        requiresAuth: Bool = true
    ) async throws -> T {
        let multipart = MultipartBody(
            files: [
                MultipartFile(
                    fieldName: fieldName,
                    fileName: fileName,
                    mimeType: mimeType,
                    data: fileData
                )
            ]
        )
        let request = APIRequest<T>(
            path: endpoint,
            method: .post,
            headers: ["Content-Type": multipart.contentType],
            body: multipart.encoded(),
            requiresAuthentication: requiresAuth
        )
        return try await httpClient.send(request)
    }

    func put<T: Codable, U: Codable>(
        endpoint: String,
        body: U,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try APIRequest<T>.json(
            path: endpoint,
            method: .put,
            body: body,
            requiresAuthentication: requiresAuth
        )
        return try await httpClient.send(request)
    }

    func patch<T: Codable, U: Codable>(
        endpoint: String,
        body: U,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = try APIRequest<T>.json(
            path: endpoint,
            method: .patch,
            body: body,
            requiresAuthentication: requiresAuth
        )
        return try await httpClient.send(request)
    }

    func delete<T: Codable>(
        endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> T {
        let request = APIRequest<T>(
            path: endpoint,
            method: .delete,
            headers: ["Content-Type": "application/json"],
            requiresAuthentication: requiresAuth
        )
        return try await httpClient.send(request)
    }
}

struct EmptyResponse: Codable {}
