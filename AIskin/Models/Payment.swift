import Foundation

enum PaymentProvider: String, Codable, Sendable {
    case alipay
    case apple
}

enum PaymentEnvironment: String, Codable, Sendable {
    case sandbox
    case production
}

enum PaymentOrderStatus: String, Codable, Sendable {
    case pending
    case paid
    case closed
    case refunded
}

enum PaymentMembershipTier: String, Codable, Sendable {
    case free
    case member
}

struct PaymentProduct: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    /// The server owns pricing. Keep money in integer fen through checkout.
    let amountFen: Int
    let currency: String
    let durationMonths: Int
    let autoRenew: Bool
}

struct PaymentChannel: Codable, Equatable, Sendable {
    let provider: PaymentProvider
    let available: Bool
    let status: String?
}

struct PaymentCatalog: Codable, Equatable, Sendable {
    let provider: PaymentProvider
    let environment: PaymentEnvironment
    let available: Bool
    let products: [PaymentProduct]
    let channels: [PaymentChannel]
}

struct PaymentOrder: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let outTradeNo: String
    let productId: String
    let amountFen: Int
    let currency: String
    let status: PaymentOrderStatus
    let expiresAt: Date
    let paidAt: Date?
    let refundAmountFen: Int
    let provider: PaymentProvider
    let environment: PaymentEnvironment
}

/// A signed SDK payload is held in memory only, never logged or persisted by this client.
struct PaymentPayload: Decodable, Equatable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    let orderString: String

    var description: String { "PaymentPayload(<redacted>)" }
    var debugDescription: String { description }
}

struct PaymentOrderCreation: Decodable, Equatable, Sendable {
    let order: PaymentOrder
    /// A previous purchase attempt can return an already paid or expired order without a payload.
    let payment: PaymentPayload?
}

struct PaymentMembership: Codable, Equatable, Sendable {
    /// Use the server tier: an expired free account may still have a historical validUntil.
    let tier: PaymentMembershipTier
    let validUntil: Date?
    let provider: PaymentProvider?
    let environment: PaymentEnvironment
    let autoRenew: Bool
}
