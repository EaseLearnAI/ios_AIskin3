import Foundation

final class URLSessionHTTPClient: HTTPClient {
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    static let productionBaseURL = URL(string: "https://www.lunzo.site/api")!

    private let baseURL: URL
    private let session: URLSession?
    private let transport: Transport?
    private let tokenProvider: () -> String?
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URLSessionHTTPClient.productionBaseURL,
        session: URLSession? = nil,
        transport: Transport? = nil,
        tokenProvider: @escaping () -> String? = { nil },
        decoder: JSONDecoder = .apiDecoder
    ) {
        self.baseURL = baseURL
        self.session = transport == nil ? (session ?? .shared) : nil
        self.transport = transport
        self.tokenProvider = tokenProvider
        self.decoder = decoder
    }

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        let urlRequest = try makeURLRequest(for: request)
        let startedAt = Date()

        do {
            let (data, response): (Data, URLResponse)
            if let transport {
                (data, response) = try await transport(urlRequest)
            } else if let session {
                (data, response) = try await session.data(for: urlRequest)
            } else {
                throw APIError.unknown
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }

            logCompletion(
                method: request.method,
                url: urlRequest.url,
                statusCode: httpResponse.statusCode,
                byteCount: data.count,
                duration: Date().timeIntervalSince(startedAt)
            )

            guard (200...299).contains(httpResponse.statusCode) else {
                throw mapHTTPError(statusCode: httpResponse.statusCode, data: data)
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func makeURLRequest<Response: Decodable>(for request: APIRequest<Response>) throws -> URLRequest {
        guard request.path.hasPrefix("/") else {
            throw APIError.invalidURL
        }

        guard let rawURL = URL(string: baseURL.absoluteString + request.path),
              var components = URLComponents(
                url: rawURL,
                resolvingAgainstBaseURL: false
              ) else {
            throw APIError.invalidURL
        }

        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        if request.requiresAuthentication, let token = tokenProvider(), !token.isEmpty {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }

    private func mapHTTPError(statusCode: Int, data: Data) -> APIError {
        if statusCode == 401 {
            return .unauthorized
        }

        let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
        let message = envelope?.message ?? envelope?.error ?? "HTTP \(statusCode)"
        return .serverError(message)
    }

    private func logCompletion(
        method: HTTPMethod,
        url: URL?,
        statusCode: Int,
        byteCount: Int,
        duration: TimeInterval
    ) {
#if DEBUG
        let path = url?.path ?? "<invalid-url>"
        print(
            "🌐 \(method.rawValue) \(path) → \(statusCode), \(byteCount) bytes, " +
            String(format: "%.2fs", duration)
        )
#endif
    }
}

private struct APIErrorEnvelope: Decodable {
    let message: String?
    let error: String?
}
