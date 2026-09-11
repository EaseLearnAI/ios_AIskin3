import Foundation

@MainActor
final class URLSessionHTTPClient: HTTPClient {
    // Keep the closure's executor explicit across the app/test module boundary.
    // Both request construction and injected transports use the same isolation.
    typealias Transport = @MainActor @Sendable (URLRequest) async throws -> (Data, URLResponse)

    static let localBaseURL = URL(string: "http://127.0.0.1:5001/api")!
    static let productionBaseURL = URL(string: "https://www.lunzo.site/api")!

    static let defaultBaseURL: URL = {
#if DEBUG
#if targetEnvironment(simulator)
        return localBaseURL
#else
        // A physical iPhone cannot use the Mac's loopback address. Keep its
        // development endpoint in the Debug build configuration.
        guard let address = Bundle.main.object(forInfoDictionaryKey: "AISkinDeviceAPIBaseURL") as? String,
              let url = URL(string: address),
              url.scheme == "http" || url.scheme == "https",
              let host = url.host, !host.isEmpty,
              host != "127.0.0.1", host != "localhost", host != "::1" else {
            preconditionFailure("Configure AISKIN_DEVICE_API_BASE_URL with the Mac's LAN address.")
        }
        return url
#endif
#else
        return productionBaseURL
#endif
    }()

    private let baseURL: URL
    private let session: URLSession?
    private let transport: Transport?
    private let tokenProvider: () -> String?
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URLSessionHTTPClient.defaultBaseURL,
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

    // There is no actor-bound cleanup. Release stored references synchronously
    // instead of scheduling an isolated deinit through the back-deployment shim.
    nonisolated deinit {}

    func send<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        try Task.checkCancellation()
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
            try Task.checkCancellation()
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
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as APIError {
            try Task.checkCancellation()
            throw error
        } catch {
            try Task.checkCancellation()
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
        if statusCode == 404 {
            return .notFound(message: message, code: envelope?.code)
        }
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
        let rawPath = url?.path ?? "<invalid-url>"
        let path = rawPath.contains("/payments/orders/")
            ? rawPath.replacingOccurrences(of: "(/payments/orders/)[^/]+", with: "$1<order>", options: .regularExpression)
            : rawPath
        let host = url?.host ?? "<invalid-host>"
        print(
            "🌐 \(method.rawValue) \(host)\(path) → \(statusCode), \(byteCount) bytes, " +
            String(format: "%.2fs", duration)
        )
#endif
    }
}

private struct APIErrorEnvelope: Decodable {
    let message: String?
    let error: String?
    let code: String?
}
