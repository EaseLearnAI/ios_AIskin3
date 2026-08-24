import Foundation

struct APIRequest<Response: Decodable> {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: Data?
    let requiresAuthentication: Bool

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil,
        requiresAuthentication: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.requiresAuthentication = requiresAuthentication
    }

    static func json<Body: Encodable>(
        path: String,
        method: HTTPMethod,
        body: Body,
        requiresAuthentication: Bool = true,
        encoder: JSONEncoder = .apiEncoder
    ) throws -> Self {
        APIRequest(
            path: path,
            method: method,
            headers: ["Content-Type": "application/json"],
            body: try encoder.encode(body),
            requiresAuthentication: requiresAuthentication
        )
    }
}

extension JSONEncoder {
    static var apiEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
