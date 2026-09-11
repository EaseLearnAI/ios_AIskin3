import Foundation
#if canImport(AlipaySDK) && !targetEnvironment(simulator)
import AlipaySDK
#endif

@MainActor
final class AlipayPaymentLauncher: PaymentSDKLaunching {
    nonisolated static let defaultAppScheme = "aiskin-alipay"

    private let appScheme: String
    private let registeredSchemes: () -> [String]
    private let isEnabled: () -> Bool
    private var pendingID: UUID?
    private var continuation: CheckedContinuation<PaymentSDKSignal, Error>?
    private var timeoutTask: Task<Void, Never>?

    init(
        appScheme: String = AlipayPaymentLauncher.defaultAppScheme,
        registeredSchemes: @escaping () -> [String] = {
            let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] ?? []
            return types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        },
        isEnabled: @escaping () -> Bool = {
            Bundle.main.object(forInfoDictionaryKey: "AISkinAlipayEnabled") as? Bool ?? false
        }
    ) {
        self.appScheme = appScheme
        self.registeredSchemes = registeredSchemes
        self.isEnabled = isEnabled
    }

    // Match the project's back-deployment rule for main-actor objects.
    nonisolated deinit {}

    var availability: PaymentSDKAvailability {
        guard isEnabled() else { return .unavailable("当前版本暂不支持支付宝付款") }
        #if targetEnvironment(simulator)
        return .unavailable("请使用 iPhone 真机完成支付宝付款")
        #elseif canImport(AlipaySDK)
        guard registeredSchemes().contains(where: { $0.caseInsensitiveCompare(appScheme) == .orderedSame }) else {
            return .unavailable("支付返回配置尚未完成")
        }
        return .available
        #else
        return .unavailable("支付宝支付组件尚未配置")
        #endif
    }

    func launch(orderString: String, environment: String) async throws -> PaymentSDKSignal {
        // The standard iOS wallet cannot consume an APP-payment sandbox order.
        // Never change the environment or send it to the production wallet as a fallback.
        guard environment == "production" else { throw PaymentSDKError.unsupportedEnvironment }
        if case .unavailable(let reason) = availability { throw PaymentSDKError.unavailable(reason) }
        guard !orderString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              orderString.utf8.count <= 65_536 else { throw PaymentSDKError.invalidOrder }
        guard pendingID == nil else { throw PaymentSDKError.paymentInProgress }
        try Task.checkCancellation()

        #if canImport(AlipaySDK) && !targetEnvironment(simulator)
        let attemptID = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.pendingID = attemptID
                self.continuation = continuation
                timeoutTask = Task { [weak self] in
                    do { try await Task.sleep(nanoseconds: 180_000_000_000) }
                    catch { return }
                    self?.finish(attemptID, result: .failure(PaymentSDKError.callbackTimedOut))
                }
                // The signed order is opaque and is never logged or stored by this bridge.
                AlipaySDK.defaultService().payOrder(orderString, fromScheme: appScheme) { [weak self] result in
                    let signal = PaymentSDKSignal.alipay(status: result?["resultStatus"] as? String)
                    Task { @MainActor [weak self] in
                        self?.finish(attemptID, result: .success(signal))
                    }
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finish(attemptID, result: .failure(CancellationError()))
            }
        }
        #else
        throw PaymentSDKError.unavailable("当前设备不能唤起支付宝付款")
        #endif
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        guard isEnabled(),
              url.scheme?.caseInsensitiveCompare(appScheme) == .orderedSame,
              url.host?.lowercased() == "safepay" else { return false }
        #if canImport(AlipaySDK) && !targetEnvironment(simulator)
        let attemptID = pendingID
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { [weak self] result in
            let signal = PaymentSDKSignal.alipay(status: result?["resultStatus"] as? String)
            Task { @MainActor [weak self] in
                guard let attemptID else { return }
                self?.finish(attemptID, result: .success(signal))
            }
        }
        #endif
        // The caller must reconcile persisted pending orders even after a cold start.
        return true
    }

    private func finish(_ attemptID: UUID, result: Result<PaymentSDKSignal, Error>) {
        guard pendingID == attemptID, let continuation else { return }
        pendingID = nil
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation.resume(with: result)
    }
}
