import XCTest
@testable import AIskin

@MainActor
final class MembershipPurchaseStoreTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testPersistsIdentityBeforeCreateAndReusesItAfterAmbiguousFailure() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let launcher = MembershipLauncherStub()
        let store = makeStore(client, launcher, storage)
        await store.load(ownerID: "test-owner-a")
        client.createHandler = { _, _ in
            XCTAssertEqual(storage.records.count, 1, "Must be durable before any create request")
            throw MembershipTestError.offline
        }
        await store.purchase(productID: "month")
        let key = client.keys.first
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertNil(store.pendingOrder)
        XCTAssertEqual(store.pendingProductID, "month")
        await store.purchase(productID: "month")
        XCTAssertEqual(client.keys, [key, key].compactMap { $0 })
        XCTAssertTrue(launcher.launches.isEmpty)
    }

    func testPersistenceFailurePreventsNetworkOrderAndWalletLaunch() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let launcher = MembershipLauncherStub()
        let store = makeStore(client, launcher, storage)
        await store.load(ownerID: "test-owner-a")
        storage.failWrites = true
        await store.purchase(productID: "month")
        XCTAssertTrue(client.keys.isEmpty)
        XCTAssertTrue(launcher.launches.isEmpty)
        XCTAssertEqual(store.messageKind, .error)
    }

    func testWalletSuccessWithFailedQueryRetainsPendingWithoutMembership() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let launcher = MembershipLauncherStub()
        let store = makeStore(client, launcher, storage)
        await store.load(ownerID: "test-owner-a")
        client.refreshHandler = { _ in throw MembershipTestError.offline }
        await store.purchase(productID: "month")
        XCTAssertEqual(launcher.launches.count, 1)
        XCTAssertEqual(client.refreshedIDs, [client.order.id])
        XCTAssertNotEqual(store.membership?.tier, .member)
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertEqual(storage.records.first?.orderID, client.order.id)
        XCTAssertEqual(store.messageKind, .error)
        // Retrying first queries this same order. A failed query cannot trigger a second wallet.
        await store.purchase(productID: "month")
        XCTAssertEqual(launcher.launches.count, 1)
        XCTAssertEqual(client.keys.count, 1)
    }

    func testCancelFailureAndThrownSDKAllStillQueryServer() async {
        for signal in [PaymentSDKSignal.cancelled, .failed, .pending, .returnedToApp] {
            let client = MembershipPaymentClientStub()
            let launcher = MembershipLauncherStub()
            launcher.signal = signal
            let store = makeStore(client, launcher, MembershipRecoveryStorageStub())
            await store.load(ownerID: "test-owner-a")
            await store.purchase(productID: "month")
            XCTAssertEqual(client.refreshedIDs.count, 1)
            XCTAssertEqual(store.membership?.tier, .free)
            XCTAssertTrue(store.hasPendingPurchase)
        }
        let client = MembershipPaymentClientStub()
        let launcher = MembershipLauncherStub()
        launcher.shouldThrow = true
        let store = makeStore(client, launcher, MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        await store.purchase(productID: "month")
        XCTAssertEqual(client.refreshedIDs.count, 1)
        XCTAssertTrue(store.hasPendingPurchase)
    }

    func testPaidOrderNeedsMembershipConfirmationAndCanRecoverLater() async {
        let client = MembershipPaymentClientStub()
        let store = makeStore(client, MembershipLauncherStub(), MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        client.refreshHandler = { _ in client.fixtureOrder(status: .paid) }
        client.membershipHandler = { throw MembershipTestError.offline }
        await store.purchase(productID: "month")
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertEqual(store.pendingOrder?.status, .paid)
        XCTAssertFalse(store.canPurchase(productID: "month"))
        XCTAssertNotEqual(store.membership?.tier, .member)
        client.membershipHandler = { client.fixtureMembership(tier: .member) }
        await store.refreshPendingPurchase()
        XCTAssertFalse(store.hasPendingPurchase)
        XCTAssertEqual(store.membership?.tier, .member)
        XCTAssertEqual(store.messageKind, .success)
    }

    func testPaidOrderWithServerFreeTierDoesNotClaimMembership() async {
        let client = MembershipPaymentClientStub()
        client.refreshHandler = { _ in client.fixtureOrder(status: .paid) }
        let store = makeStore(client, MembershipLauncherStub(), MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        await store.purchase(productID: "month")
        XCTAssertEqual(store.membership?.tier, .free)
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertNotEqual(store.messageKind, .success)
    }

    func testRestartRecoversAnnualAttemptWithOriginalKeyAndNeverLaunchesWallet() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let firstLauncher = MembershipLauncherStub()
        let first = makeStore(client, firstLauncher, storage)
        await first.load(ownerID: "test-owner-a")
        client.createHandler = { _, _ in throw MembershipTestError.offline }
        await first.purchase(productID: "year")
        let originalKey = client.keys[0]
        let secondLauncher = MembershipLauncherStub()
        let reopened = makeStore(client, secondLauncher, storage)
        client.createHandler = { product, _ in
            PaymentOrderCreation(order: client.fixtureOrder(productID: product), payment: PaymentPayload(orderString: "test-signature"))
        }
        await reopened.load(ownerID: "test-owner-a")
        XCTAssertEqual(client.keys, [originalKey, originalKey])
        XCTAssertEqual(reopened.pendingProductID, "year")
        XCTAssertEqual(reopened.pendingOrder?.productId, "year")
        XCTAssertFalse(reopened.canPurchase(productID: "month"))
        XCTAssertTrue(secondLauncher.launches.isEmpty)
    }

    func testRestartWithOrderIDQueriesWithoutCreatingAnotherOrder() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let first = makeStore(client, MembershipLauncherStub(), storage)
        await first.load(ownerID: "test-owner-a")
        await first.purchase(productID: "month")
        let creates = client.keys.count
        let reopened = makeStore(client, MembershipLauncherStub(), storage)
        client.refreshHandler = { _ in client.fixtureOrder(status: .paid) }
        client.membershipHandler = { client.fixtureMembership(tier: .member) }
        await reopened.load(ownerID: "test-owner-a")
        XCTAssertEqual(client.keys.count, creates)
        XCTAssertFalse(reopened.hasPendingPurchase)
        XCTAssertEqual(reopened.membership?.tier, .member)
    }

    func testDifferentOwnerEndpointAndEnvironmentDoNotRecoverAnotherScope() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let first = makeStore(client, MembershipLauncherStub(), storage)
        await first.load(ownerID: "test-owner-a")
        client.createHandler = { _, _ in throw MembershipTestError.offline }
        await first.purchase(productID: "year")
        let count = client.keys.count
        await first.load(ownerID: "test-owner-b")
        XCTAssertFalse(first.hasPendingPurchase)
        let endpointChanged = MembershipPurchaseStore(client: client, launcher: MembershipLauncherStub(), endpointScope: "https://other.test/api", storage: storage, now: { self.now })
        await endpointChanged.load(ownerID: "test-owner-a")
        XCTAssertFalse(endpointChanged.hasPendingPurchase)
        client.environment = .sandbox
        let environmentChanged = makeStore(client, MembershipLauncherStub(), storage)
        await environmentChanged.load(ownerID: "test-owner-a")
        XCTAssertFalse(environmentChanged.hasPendingPurchase)
        XCTAssertEqual(client.keys.count, count)
        XCTAssertEqual(storage.records.count, 1)
    }

    func testAccountChangeIgnoresLateCreateReplyAndSingleFlightBlocksDoubleTap() async {
        let client = MembershipPaymentClientStub()
        let storage = MembershipRecoveryStorageStub()
        let launcher = MembershipLauncherStub()
        let store = makeStore(client, launcher, storage)
        await store.load(ownerID: "test-owner-a")
        let started = expectation(description: "create started")
        var response: CheckedContinuation<PaymentOrderCreation, Error>?
        client.createHandler = { _, _ in
            try await withCheckedThrowingContinuation {
                response = $0
                started.fulfill()
            }
        }
        let purchase = Task { await store.purchase(productID: "month") }
        await fulfillment(of: [started], timeout: 1)
        await store.purchase(productID: "month")
        XCTAssertEqual(client.keys.count, 1)
        await store.load(ownerID: "test-owner-b")
        response?.resume(returning: PaymentOrderCreation(order: client.order, payment: PaymentPayload(orderString: "test-signature")))
        await purchase.value
        XCTAssertFalse(store.hasPendingPurchase)
        XCTAssertNil(store.pendingOrder)
        XCTAssertEqual(store.membership?.tier, .free)
        XCTAssertFalse(store.isBusy)
        XCTAssertTrue(launcher.launches.isEmpty)
        XCTAssertTrue(client.refreshedIDs.isEmpty)
        XCTAssertEqual(storage.records.first?.scope.ownerID, "test-owner-a")
        XCTAssertNil(storage.records.first?.orderID)
    }

    func testLogoutWhileWalletOpenIgnoresLateResult() async {
        let client = MembershipPaymentClientStub()
        let launcher = MembershipLauncherStub()
        let store = makeStore(client, launcher, MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        let started = expectation(description: "wallet started")
        var response: CheckedContinuation<PaymentSDKSignal, Error>?
        launcher.handler = {
            try await withCheckedThrowingContinuation {
                response = $0
                started.fulfill()
            }
        }
        let purchase = Task { await store.purchase(productID: "month") }
        await fulfillment(of: [started], timeout: 1)
        store.resetForLogout()
        response?.resume(returning: .returnedToApp)
        await purchase.value
        XCTAssertNil(store.membership)
        XCTAssertNil(store.message)
        XCTAssertFalse(store.hasPendingPurchase)
        XCTAssertTrue(client.refreshedIDs.isEmpty)
    }

    func testChangedServerPriceRequiresAnotherUserActionAndPreservesOrderID() async {
        let client = MembershipPaymentClientStub()
        let launcher = MembershipLauncherStub()
        let storage = MembershipRecoveryStorageStub()
        let store = makeStore(client, launcher, storage)
        await store.load(ownerID: "test-owner-a")
        client.monthAmountFen = 9_999
        client.createHandler = { _, _ in
            PaymentOrderCreation(order: client.fixtureOrder(amountFen: 9_999), payment: PaymentPayload(orderString: "test-signature"))
        }
        await store.purchase(productID: "month")
        XCTAssertTrue(launcher.launches.isEmpty)
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertEqual(storage.records.count, 1)
        XCTAssertEqual(storage.records.first?.orderID, client.order.id)
        XCTAssertEqual(store.catalog?.products.first?.amountFen, 9_999)
        XCTAssertEqual(store.messageKind, .error)
        XCTAssertTrue(store.message?.contains("价格已更新") == true)
        let originalKey = client.keys[0]
        await store.purchase(productID: "month")
        XCTAssertEqual(launcher.launches.count, 1)
        XCTAssertEqual(client.keys, [originalKey, originalKey])
    }

    func testRefundUpdatesServerMembershipAndClearsRecovery() async {
        let client = MembershipPaymentClientStub()
        let store = makeStore(client, MembershipLauncherStub(), MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        await store.purchase(productID: "month")
        client.refreshHandler = { _ in client.fixtureOrder(status: .refunded) }
        await store.refreshPendingPurchase()
        XCTAssertFalse(store.hasPendingPurchase)
        XCTAssertEqual(store.membership?.tier, .free)
        XCTAssertTrue(store.message?.contains("退款") == true)
    }

    func testFailedMembershipRecheckDoesNotExposePreviouslyConfirmedMember() async {
        let client = MembershipPaymentClientStub()
        client.membershipHandler = { client.fixtureMembership(tier: .member) }
        let store = makeStore(client, MembershipLauncherStub(), MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        XCTAssertEqual(store.membership?.tier, .member)
        client.membershipHandler = { throw MembershipTestError.offline }
        await store.refreshPendingPurchase()
        XCTAssertNil(store.membership)
        XCTAssertEqual(store.messageKind, .error)
    }

    func testFailedOrderQueryWithdrawsPreviousMembershipConfirmation() async {
        let client = MembershipPaymentClientStub()
        client.membershipHandler = { client.fixtureMembership(tier: .member) }
        let store = makeStore(client, MembershipLauncherStub(), MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        XCTAssertEqual(store.membership?.tier, .member)
        client.refreshHandler = { _ in throw MembershipTestError.offline }
        await store.purchase(productID: "month")
        XCTAssertNil(store.membership)
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertEqual(store.messageKind, .error)
    }

    func testUnavailableSandboxAndRecurringProductsNeverCreateOrders() async {
        for variation in 0..<4 {
            let client = MembershipPaymentClientStub()
            let launcher = MembershipLauncherStub()
            if variation == 0 { client.available = false }
            if variation == 1 { client.environment = .sandbox }
            if variation == 2 { launcher.availability = .unavailable("测试设备不可付款") }
            if variation == 3 { client.autoRenew = true }
            let store = makeStore(client, launcher, MembershipRecoveryStorageStub())
            await store.load(ownerID: "test-owner-a")
            XCTAssertNotNil(store.catalog, "Benefits remain readable")
            XCTAssertFalse(store.canPurchase(productID: "month"))
            await store.purchase(productID: "month")
            XCTAssertTrue(client.keys.isEmpty)
        }
    }

    func testManualRefreshBudgetIsBoundedAndDoesNotLosePendingOrder() async {
        let client = MembershipPaymentClientStub()
        let store = makeStore(client, MembershipLauncherStub(), MembershipRecoveryStorageStub())
        await store.load(ownerID: "test-owner-a")
        await store.purchase(productID: "month")
        for _ in 0..<50 { await store.refreshPendingPurchase() }
        XCTAssertLessThanOrEqual(client.requestCount, 24)
        XCTAssertTrue(store.hasPendingPurchase)
        XCTAssertEqual(store.messageKind, .error)
    }

    func testFileRecoveryRoundTripContainsOnlyMetadata() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let scope = MembershipPurchaseScope(ownerID: "test-owner-a", endpoint: "https://example.test/api", provider: .alipay, environment: .production)
        let record = MembershipPendingPurchase(scope: scope, productID: "year", amountFen: 19_900, currency: "CNY", idempotencyKey: "test-key", createdAt: now, orderID: "000000000000000000000001")
        try FileMembershipPendingPurchaseStorage(directory: directory).save(record)
        let reopened = FileMembershipPendingPurchaseStorage(directory: directory)
        XCTAssertEqual(try reopened.load(scope: scope), record)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.count, 1)
        let contents = try String(contentsOf: files[0], encoding: .utf8)
        XCTAssertFalse(contents.contains("orderString"))
        XCTAssertFalse(contents.contains("test-signature"))
        try reopened.remove(scope: scope)
        XCTAssertNil(try reopened.load(scope: scope))
    }

    private func makeStore(_ client: MembershipPaymentClientStub, _ launcher: MembershipLauncherStub, _ storage: MembershipRecoveryStorageStub) -> MembershipPurchaseStore {
        MembershipPurchaseStore(client: client, launcher: launcher, endpointScope: "https://example.test/api", storage: storage, now: { self.now })
    }
}

private enum MembershipTestError: Error { case offline }

@MainActor
private final class MembershipRecoveryStorageStub: MembershipPendingPurchaseStorage {
    var records: [MembershipPendingPurchase] = []
    var failWrites = false

    func load(scope: MembershipPurchaseScope) throws -> MembershipPendingPurchase? { records.first { $0.scope == scope } }
    func save(_ purchase: MembershipPendingPurchase) throws {
        if failWrites { throw MembershipTestError.offline }
        records.removeAll { $0.scope == purchase.scope }
        records.append(purchase)
    }
    func remove(scope: MembershipPurchaseScope) throws { records.removeAll { $0.scope == scope } }
}

@MainActor
private final class MembershipLauncherStub: PaymentSDKLaunching {
    var availability: PaymentSDKAvailability = .available
    var signal: PaymentSDKSignal = .returnedToApp
    var shouldThrow = false
    var launches: [String] = []
    var handler: (() async throws -> PaymentSDKSignal)?
    func launch(orderString: String, environment: String) async throws -> PaymentSDKSignal {
        launches.append(orderString)
        if shouldThrow { throw MembershipTestError.offline }
        if let handler { return try await handler() }
        return signal
    }
    func handleOpenURL(_ url: URL) -> Bool { false }
}

@MainActor
private final class MembershipPaymentClientStub: PaymentClient {
    var keys: [String] = []
    var refreshedIDs: [String] = []
    var requestCount = 0
    var environment: PaymentEnvironment = .production
    var available = true
    var autoRenew = false
    var monthAmountFen = 2_900
    var createHandler: ((String, String) async throws -> PaymentOrderCreation)?
    var refreshHandler: ((String) async throws -> PaymentOrder)?
    var membershipHandler: (() async throws -> PaymentMembership)?
    var order: PaymentOrder { fixtureOrder() }

    func getCatalog() async throws -> PaymentCatalog {
        requestCount += 1
        return PaymentCatalog(provider: .alipay, environment: environment, available: available, products: [
            PaymentProduct(id: "month", name: "月卡", amountFen: monthAmountFen, currency: "CNY", durationMonths: 1, autoRenew: autoRenew),
            PaymentProduct(id: "year", name: "年卡", amountFen: 19_900, currency: "CNY", durationMonths: 12, autoRenew: autoRenew)
        ], channels: [PaymentChannel(provider: .alipay, available: available, status: nil)])
    }
    func createOrder(productId: String, idempotencyKey: String) async throws -> PaymentOrderCreation {
        requestCount += 1
        keys.append(idempotencyKey)
        if let createHandler { return try await createHandler(productId, idempotencyKey) }
        return PaymentOrderCreation(order: fixtureOrder(productID: productId), payment: PaymentPayload(orderString: "test-signature"))
    }
    func getOrder(orderID: String) async throws -> PaymentOrder {
        requestCount += 1
        return order
    }
    func refreshOrder(orderID: String) async throws -> PaymentOrder {
        requestCount += 1
        refreshedIDs.append(orderID)
        if let refreshHandler { return try await refreshHandler(orderID) }
        return order
    }
    func getMembership() async throws -> PaymentMembership {
        requestCount += 1
        if let membershipHandler { return try await membershipHandler() }
        return fixtureMembership(tier: .free)
    }
    func fixtureOrder(productID: String = "month", status: PaymentOrderStatus = .pending, amountFen: Int? = nil) -> PaymentOrder {
        let amount = amountFen ?? (productID == "year" ? 19_900 : monthAmountFen)
        return PaymentOrder(id: "000000000000000000000001", outTradeNo: "TEST-ORDER", productId: productID,
                            amountFen: amount, currency: "CNY", status: status,
                            expiresAt: Date(timeIntervalSince1970: 1_800_001_800),
                            paidAt: status == .paid ? Date(timeIntervalSince1970: 1_800_000_000) : nil,
                            refundAmountFen: status == .refunded ? amount : 0,
                            provider: .alipay, environment: environment)
    }
    func fixtureMembership(tier: PaymentMembershipTier) -> PaymentMembership {
        PaymentMembership(tier: tier, validUntil: tier == .member ? Date(timeIntervalSince1970: 1_802_592_000) : nil,
                          provider: tier == .member ? .alipay : nil, environment: environment, autoRenew: false)
    }
}
