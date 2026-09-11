import Foundation
import Combine
import CryptoKit

enum MembershipPurchaseMessageKind: Equatable {
    case status, error, success
}

struct MembershipPurchaseScope: Codable, Equatable {
    let ownerID: String
    let endpoint: String
    let provider: PaymentProvider
    let environment: PaymentEnvironment
}

/// Only recovery metadata is durable. A wallet signature must never enter this record.
struct MembershipPendingPurchase: Codable, Equatable {
    let scope: MembershipPurchaseScope
    let productID: String
    var amountFen: Int
    let currency: String
    let idempotencyKey: String
    let createdAt: Date
    var orderID: String?
}

@MainActor
protocol MembershipPendingPurchaseStorage {
    func load(scope: MembershipPurchaseScope) throws -> MembershipPendingPurchase?
    func save(_ purchase: MembershipPendingPurchase) throws
    func remove(scope: MembershipPurchaseScope) throws
}

/// A failed durable write blocks checkout, including when the device is out of space.
@MainActor
final class FileMembershipPendingPurchaseStorage: MembershipPendingPurchaseStorage {
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MembershipPendingPurchases", isDirectory: true)
    }

    func load(scope: MembershipPurchaseScope) throws -> MembershipPendingPurchase? {
        let url = try fileURL(scope)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let purchase = try JSONDecoder().decode(MembershipPendingPurchase.self, from: Data(contentsOf: url))
        guard purchase.scope == scope else { throw MembershipPurchaseError.invalidRecovery }
        return purchase
    }

    func save(_ purchase: MembershipPendingPurchase) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var excludedDirectory = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try excludedDirectory.setResourceValues(values)
        try JSONEncoder().encode(purchase).write(to: fileURL(purchase.scope), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func remove(scope: MembershipPurchaseScope) throws {
        let url = try fileURL(scope)
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }

    private func fileURL(_ scope: MembershipPurchaseScope) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let digest = SHA256.hash(data: try encoder.encode(scope)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(digest).appendingPathExtension("json")
    }
}

private enum MembershipPurchaseError: LocalizedError {
    case invalidRecovery, invalidOrder, priceChanged, invalidMembership, persistence, rateLimited, staleSession

    var errorDescription: String? {
        switch self {
        case .invalidRecovery, .persistence: return "无法安全保存或读取订单，请检查设备存储空间后重试"
        case .invalidOrder: return "订单信息与所选套餐不一致，尚未发起付款，请稍后查询订单"
        case .priceChanged: return "套餐价格已更新，本次尚未发起付款；请确认页面价格后再继续"
        case .invalidMembership: return "会员状态暂未确认，请稍后查询订单，避免重复付款"
        case .rateLimited: return "查询较频繁，请稍后再试；待确认订单已保留"
        case .staleSession: return "登录状态已变化，请重新打开会员页"
        }
    }
}

@MainActor
final class MembershipPurchaseStore: ObservableObject {
    static let purchaseDisclosure = "一次购买，到期不自动续费"

    @Published private(set) var catalog: PaymentCatalog?
    @Published private(set) var membership: PaymentMembership?
    @Published private(set) var pendingOrder: PaymentOrder?
    @Published private(set) var message: String?
    @Published private(set) var messageKind: MembershipPurchaseMessageKind = .status
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var hasPendingPurchase = false

    private let client: any PaymentClient
    private let launcher: any PaymentSDKLaunching
    private let endpointScope: String
    private let storage: any MembershipPendingPurchaseStorage
    private let now: () -> Date
    private var ownerID: String?
    private var generation = UUID()
    private var pending: MembershipPendingPurchase?
    private var storageReady = false
    private var requestTimes: [Date] = []
    private var lastForegroundRefresh: Date?

    init(client: any PaymentClient, launcher: any PaymentSDKLaunching, endpointScope: String,
         storage: (any MembershipPendingPurchaseStorage)? = nil, now: @escaping () -> Date = Date.init) {
        self.client = client
        self.launcher = launcher
        self.endpointScope = endpointScope
        self.storage = storage ?? FileMembershipPendingPurchaseStorage()
        self.now = now
    }

    nonisolated deinit {}

    var isBusy: Bool { isLoading || isPurchasing || isRefreshing }
    var pendingProductID: String? { pending?.productID }

    func canPurchase(productID: String) -> Bool {
        guard !isBusy, storageReady, ownerID != nil, !endpointScope.isEmpty,
              let catalog, catalog.available, catalog.provider == .alipay,
              catalog.environment == .production, launcher.availability == .available,
              let product = catalog.products.first(where: { $0.id == productID }),
              product.amountFen > 0, product.currency == "CNY", product.durationMonths > 0, !product.autoRenew else { return false }
        if let pending {
            return pending.productID == productID && pending.amountFen == product.amountFen &&
                pending.currency == product.currency && (pendingOrder == nil || pendingOrder?.status == .pending)
        }
        return true
    }

    func load(ownerID: String?) async {
        guard let ownerID, !ownerID.isEmpty else { resetForLogout(); return }
        if self.ownerID != ownerID {
            resetForLogout()
            self.ownerID = ownerID
        }
        guard !isBusy else { return }
        let token = generation
        isLoading = true
        membership = nil
        defer { if token == generation { isLoading = false } }
        do {
            try reserveRequest()
            let catalog = try await client.getCatalog()
            try checkSession(token)
            self.catalog = catalog
            let scope = scope(for: catalog, ownerID: ownerID)
            do {
                let recovered = try storage.load(scope: scope)
                guard recovered == nil || recovered?.scope == scope else { throw MembershipPurchaseError.invalidRecovery }
                pending = recovered
                hasPendingPurchase = recovered != nil
                pendingOrder = nil
                storageReady = true
            } catch {
                storageReady = false
                throw MembershipPurchaseError.invalidRecovery
            }
            if pending != nil {
                try await reconcile(token: token)
            } else {
                try await syncMembership(token: token)
                availabilityMessage()
            }
        } catch {
            await show(error, token: token, fallback: "暂时无法加载会员信息，请稍后重试")
        }
    }

    func purchase(productID: String) async {
        guard canPurchase(productID: productID), let catalog, let ownerID,
              let product = catalog.products.first(where: { $0.id == productID }) else { return }
        let token = generation
        isPurchasing = true
        setMessage("正在准备订单…")
        defer { if token == generation { isPurchasing = false } }
        do {
            if pending != nil {
                // A previous wallet launch may have paid even if its callback was lost.
                try await reconcile(token: token)
                guard let pending, pendingOrder?.status == .pending else { return }
                guard pending.productID == productID else { return }
            } else {
                let purchase = MembershipPendingPurchase(scope: scope(for: catalog, ownerID: ownerID),
                    productID: product.id, amountFen: product.amountFen, currency: product.currency,
                    idempotencyKey: UUID().uuidString.lowercased(), createdAt: now(), orderID: nil)
                try persist(purchase)
            }
            guard let attempt = pending else { return }
            try reserveRequest()
            let creation = try await client.createOrder(productId: attempt.productID, idempotencyKey: attempt.idempotencyKey)
            try checkSession(token)
            try accept(creation.order, for: attempt)
            guard creation.order.status == .pending else {
                try await applyOrder(creation.order, token: token)
                return
            }
            guard creation.order.expiresAt > now(), let payload = creation.payment, !payload.orderString.isEmpty else {
                try await reconcile(token: token)
                return
            }
            setMessage("请在支付宝完成付款，返回后将查询订单")
            do {
                _ = try await launcher.launch(orderString: payload.orderString, environment: catalog.environment.rawValue)
            } catch {
                // Cancellation, SDK failure and timeout can all race a successful payment.
            }
            try checkSession(token)
            try await reconcile(token: token)
        } catch {
            await show(error, token: token, fallback: "支付结果暂未确认，订单已保留，请查询订单后再试")
        }
    }

    func refreshPendingPurchase() async {
        guard !isBusy, ownerID != nil, catalog != nil else { return }
        let token = generation
        isRefreshing = true
        defer { if token == generation { isRefreshing = false } }
        do {
            if pending != nil { try await reconcile(token: token) }
            else {
                try await syncMembership(token: token)
                setMessage("会员状态已同步")
            }
        } catch {
            await show(error, token: token, fallback: "暂未确认订单结果，请稍后再查，避免重复付款")
        }
    }

    func handleBecameActive() async {
        guard !isBusy else { return }
        if let lastForegroundRefresh, now().timeIntervalSince(lastForegroundRefresh) < 5 { return }
        lastForegroundRefresh = now()
        await refreshPendingPurchase()
    }

    /// Keep another account's durable recovery record, but never its visible state or late replies.
    func resetForLogout() {
        generation = UUID()
        ownerID = nil
        catalog = nil
        membership = nil
        pendingOrder = nil
        pending = nil
        hasPendingPurchase = false
        storageReady = false
        isLoading = false
        isPurchasing = false
        isRefreshing = false
        message = nil
        messageKind = .status
        lastForegroundRefresh = nil
    }

    private func reconcile(token: UUID) async throws {
        guard let attempt = pending else { return }
        membership = nil
        try reserveRequest()
        let order: PaymentOrder
        if let orderID = attempt.orderID {
            order = try await client.refreshOrder(orderID: orderID)
        } else {
            // Recover an ambiguous create response with the original key. Never launch here.
            let creation = try await client.createOrder(productId: attempt.productID, idempotencyKey: attempt.idempotencyKey)
            order = creation.order
        }
        try checkSession(token)
        try accept(order, for: attempt)
        try await applyOrder(order, token: token)
    }

    private func applyOrder(_ order: PaymentOrder, token: UUID) async throws {
        try await syncMembership(token: token)
        switch order.status {
        case .pending:
            setMessage("订单待确认，可查询状态或继续本笔付款，请勿重复下单")
        case .paid:
            guard membership?.tier == .member, let validUntil = membership?.validUntil, validUntil > now() else {
                setMessage("付款已确认，会员权益同步中，请稍后查询订单", kind: .status)
                return
            }
            try clearPending()
            setMessage("会员已开通。" + Self.purchaseDisclosure, kind: .success)
        case .closed:
            try clearPending()
            setMessage("订单已关闭，会员状态已同步")
        case .refunded:
            try clearPending()
            setMessage("订单已退款，会员状态已同步")
        }
    }

    private func syncMembership(token: UUID) async throws {
        membership = nil
        try reserveRequest()
        let membership = try await client.getMembership()
        try checkSession(token)
        guard membership.environment == catalog?.environment else { throw MembershipPurchaseError.invalidMembership }
        self.membership = membership
    }

    private func accept(_ order: PaymentOrder, for attempt: MembershipPendingPurchase) throws {
        guard order.provider == attempt.scope.provider, order.environment == attempt.scope.environment,
              order.productId == attempt.productID, order.amountFen > 0,
              order.currency == attempt.currency, !order.id.isEmpty,
              attempt.orderID == nil || order.id == attempt.orderID,
              order.refundAmountFen >= 0, order.refundAmountFen <= order.amountFen else {
            throw MembershipPurchaseError.invalidOrder
        }
        var updated = attempt
        updated.orderID = order.id
        updated.amountFen = order.amountFen
        try persist(updated)
        pendingOrder = order
        // Preserve this server order so a catalogue change never strands the original key.
        // Throw before SDK launch; only a later user action can accept the refreshed price.
        if order.amountFen != attempt.amountFen { throw MembershipPurchaseError.priceChanged }
    }

    private func persist(_ purchase: MembershipPendingPurchase) throws {
        do { try storage.save(purchase) }
        catch { throw MembershipPurchaseError.persistence }
        pending = purchase
        hasPendingPurchase = true
    }

    private func clearPending() throws {
        guard let pending else { return }
        do { try storage.remove(scope: pending.scope) }
        catch { throw MembershipPurchaseError.persistence }
        self.pending = nil
        hasPendingPurchase = false
        pendingOrder = nil
    }

    private func scope(for catalog: PaymentCatalog, ownerID: String) -> MembershipPurchaseScope {
        MembershipPurchaseScope(ownerID: ownerID, endpoint: endpointScope, provider: catalog.provider, environment: catalog.environment)
    }

    private func checkSession(_ token: UUID) throws {
        guard token == generation, ownerID != nil else { throw MembershipPurchaseError.staleSession }
    }

    /// Every API request shares this budget. No automatic polling loop is used.
    private func reserveRequest() throws {
        let date = now()
        requestTimes.removeAll { date.timeIntervalSince($0) >= 60 }
        guard requestTimes.count < 24 else { throw MembershipPurchaseError.rateLimited }
        requestTimes.append(date)
    }

    private func availabilityMessage() {
        if catalog?.available != true { setMessage("支付服务正在准备中，可先查看会员权益") }
        else if catalog?.environment != .production { setMessage("当前是支付测试环境，暂不能在 iPhone 上付款") }
        else if case .unavailable(let reason) = launcher.availability { setMessage(reason) }
        else { setMessage(Self.purchaseDisclosure) }
    }

    private func setMessage(_ text: String, kind: MembershipPurchaseMessageKind = .status) {
        message = text
        messageKind = kind
    }

    private func show(_ error: Error, token: UUID, fallback: String) async {
        guard token == generation else { return }
        if case MembershipPurchaseError.priceChanged = error {
            let priorCatalog = catalog
            catalog = nil
            do {
                try reserveRequest()
                let refreshed = try await client.getCatalog()
                try checkSession(token)
                guard refreshed.provider == priorCatalog?.provider,
                      refreshed.environment == priorCatalog?.environment else { throw MembershipPurchaseError.invalidOrder }
                catalog = refreshed
            } catch {
                // Keep the recovery record; an unavailable catalogue cannot enable checkout.
            }
        }
        guard token == generation else { return }
        let text = (error as? MembershipPurchaseError)?.errorDescription ?? fallback
        setMessage(text, kind: .error)
    }
}
