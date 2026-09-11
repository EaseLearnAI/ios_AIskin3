import Foundation

extension Notification.Name {
    static let aisKinPaymentReturned = Notification.Name("AISkinPaymentReturned")
}

enum PaymentSDKAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
}

/// A wallet result is a reason to query the server, never proof of membership.
enum PaymentSDKSignal: Equatable, Sendable {
    case returnedToApp
    case cancelled
    case pending
    case failed

    nonisolated static func alipay(status: String?) -> Self {
        switch status {
        case "9000": return .returnedToApp
        case "6001": return .cancelled
        case "8000", "6004", nil: return .pending
        default: return .failed
        }
    }
}

@MainActor
protocol PaymentSDKLaunching: AnyObject {
    var availability: PaymentSDKAvailability { get }
    func launch(orderString: String, environment: String) async throws -> PaymentSDKSignal
    @discardableResult func handleOpenURL(_ url: URL) -> Bool
}

enum PaymentSDKError: LocalizedError {
    case unavailable(String)
    case unsupportedEnvironment
    case invalidOrder
    case paymentInProgress
    case callbackTimedOut

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason): return reason
        case .unsupportedEnvironment:
            return "当前是支付测试环境，暂不能在 iPhone 上付款"
        case .invalidOrder: return "未取得有效的支付订单，请重试"
        case .paymentInProgress: return "已有支付正在处理，请先确认这笔订单的状态"
        case .callbackTimedOut: return "暂未收到支付结果，请查询订单状态"
        }
    }
}
