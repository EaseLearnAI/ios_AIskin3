import XCTest
@testable import AIskin

@MainActor
final class PlanLifecycleTests: XCTestCase {
    func testGenerationDoesNotAdoptUntilExplicitAcceptance() async throws {
        let client = LifecyclePlansClient()
        let store = makeStore(client)
        await store.load()
        await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)
        let generated = try XCTUnwrap(store.generatedPlan)
        XCTAssertEqual(store.currentPlan?.id, "current")
        XCTAssertEqual(generated.id, "generated")
        XCTAssertEqual(client.adoptedIDs, [])

        let accepted = await store.acceptGeneratedPlan(generated)
        XCTAssertTrue(accepted)
        XCTAssertEqual(client.adoptedIDs, ["generated"])
        XCTAssertEqual(store.currentPlan?.id, "generated")
        XCTAssertNil(store.generatedPlan)
    }

    func testFailedAdoptionKeepsCurrentAndGeneratedPlansForRetry() async throws {
        let client = LifecyclePlansClient()
        let store = makeStore(client)
        await store.load()
        await store.generate(requirement: "补水", age: 28, concerns: ["补水"], customRequirements: nil)
        client.shouldFailAdoption = true
        let accepted = await store.acceptGeneratedPlan(try XCTUnwrap(store.generatedPlan))
        XCTAssertFalse(accepted)
        XCTAssertEqual(store.currentPlan?.id, "current")
        XCTAssertEqual(store.generatedPlan?.id, "generated")
        XCTAssertEqual(client.active?.id, "current")
        XCTAssertNotNil(store.generationError)
        XCTAssertNotNil(store.historyError)
        XCTAssertFalse(store.isAdopting)
    }

    func testFailedDailySaveRollsBackOptimisticProgress() async {
        let client = LifecyclePlansClient()
        let store = makeStore(client)
        await store.load()
        client.shouldFailUpdate = true
        var sawOptimisticCompletion = false
        client.onUpdate = {
            sawOptimisticCompletion = store.currentPlan?.morning.first?.isDone == true
            XCTAssertTrue(store.isUpdatingStep)
        }
        await store.toggleStep(period: "morning", index: 0)
        XCTAssertTrue(sawOptimisticCompletion)
        XCTAssertFalse(store.currentPlan?.morning.first?.isDone ?? true)
        XCTAssertFalse(store.isUpdatingStep)
        guard case .failed = store.state else { return XCTFail("Failed update must remain visible") }
    }

    func testStepAfterMidnightRefreshesBeforeTogglingTheNewDay() async {
        let client = LifecyclePlansClient()
        client.completedByDay["2026-09-09"] = true
        let clock = LifecycleClock(date: date("2026-09-09T15:59:00Z"))
        let store = PlanStore(client: client, now: { clock.date }, timezone: { TimeZone(identifier: "Asia/Shanghai")! })
        await store.load()
        XCTAssertTrue(store.currentPlan?.morning.first?.isDone ?? false)
        clock.date = date("2026-09-09T16:01:00Z")
        await store.toggleStep(period: "morning", index: 0)
        XCTAssertEqual(client.dailyDates, ["2026-09-09", "2026-09-10"])
        XCTAssertEqual(client.updateDates, ["2026-09-10"])
        XCTAssertEqual(client.updatedStates, [true], "New day starts unchecked and must toggle to checked")
        XCTAssertEqual(client.completedByDay["2026-09-09"], true)
        XCTAssertEqual(client.completedByDay["2026-09-10"], true)
    }

    func testTwoLoadsOfTheSamePlanRefreshDailyProgress() async {
        let client = LifecyclePlansClient()
        let store = makeStore(client)
        await store.load()
        XCTAssertFalse(store.currentPlan?.morning.first?.isDone ?? true)
        client.completedByDay["2026-09-09"] = true
        await store.load()
        XCTAssertEqual(store.currentPlan?.id, "current")
        XCTAssertTrue(store.currentPlan?.morning.first?.isDone ?? false)
        XCTAssertEqual(client.dailyDates, ["2026-09-09", "2026-09-09"])
    }

    func testFailedAdoptionAfterMidnightDoesNotMarkOldProgressAsFresh() async {
        let client = LifecyclePlansClient()
        client.completedByDay["2026-09-09"] = true
        let clock = LifecycleClock(date: date("2026-09-09T15:59:00Z"))
        let store = PlanStore(client: client, now: { clock.date }, timezone: { TimeZone(identifier: "Asia/Shanghai")! })
        await store.load()
        clock.date = date("2026-09-09T16:01:00Z")
        client.shouldFailAdoption = true
        let accepted = await store.adopt(plan: LifecyclePlansClient.fixture("generated"))
        XCTAssertFalse(accepted)
        await store.toggleStep(period: "morning", index: 0)
        XCTAssertEqual(client.updatedStates, [true], "Failure must not reuse yesterday's checked state for today's toggle")
    }

    func testAPIDecoderAcceptsMongoFractionalTimestampAndWholeSeconds() throws {
        struct Timestamp: Decodable { let createdAt: Date }
        let decoder = JSONDecoder.apiDecoder
        let fractional = try decoder.decode(Timestamp.self, from: Data(#"{"createdAt":"2026-09-09T03:51:50.123Z"}"#.utf8))
        let whole = try decoder.decode(Timestamp.self, from: Data(#"{"createdAt":"2026-09-09T03:51:50Z"}"#.utf8))
        XCTAssertEqual(fractional.createdAt.timeIntervalSince(whole.createdAt), 0.123, accuracy: 0.001)
    }

    private func makeStore(_ client: LifecyclePlansClient) -> PlanStore {
        let now = date("2026-09-09T03:00:00Z")
        return PlanStore(client: client, now: { now }, timezone: { TimeZone(identifier: "Asia/Shanghai")! })
    }

    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
}

@MainActor
private final class LifecycleClock {
    var date: Date
    init(date: Date) { self.date = date }
}

@MainActor
private final class LifecyclePlansClient: PlansClient {
    var active: SkinPlan? = LifecyclePlansClient.fixture("current")
    var adoptedIDs: [String] = []
    var dailyDates: [String] = []
    var updateDates: [String] = []
    var updatedStates: [Bool] = []
    var completedByDay: [String: Bool] = [:]
    var shouldFailAdoption = false
    var shouldFailUpdate = false
    var onUpdate: (() -> Void)?

    func plans() async throws -> [SkinPlan] { [Self.fixture("current"), Self.fixture("generated")] }
    func plan(id: String) async throws -> SkinPlan { Self.fixture(id) }
    func activePlan() async throws -> SkinPlan? { active }
    func adopt(planID: String) async throws -> SkinPlan {
        adoptedIDs.append(planID)
        if shouldFailAdoption { throw LifecycleError.failed }
        let plan = Self.fixture(planID)
        active = plan
        return plan
    }
    func daily(planID: String, date: String, timezone: String) async throws -> PlanDailyProgress {
        dailyDates.append(date)
        return progress(planID: planID, date: date, timezone: timezone)
    }
    func updateDailyStep(planID: String, date: String, timezone: String, period: String, step: Int, completed: Bool) async throws -> PlanDailyProgress {
        updateDates.append(date)
        updatedStates.append(completed)
        onUpdate?()
        if shouldFailUpdate { throw LifecycleError.failed }
        completedByDay[date] = completed
        return progress(planID: planID, date: date, timezone: timezone)
    }
    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan { Self.fixture("generated") }
    func latestSkinAnalysis() async throws -> SkinAnalysis? { nil }

    private func progress(planID: String, date: String, timezone: String) -> PlanDailyProgress {
        let completed = completedByDay[date] ?? false
        return PlanDailyProgress(planId: planID, date: date, timezone: timezone, morning: [.init(step: 1, completed: completed)], evening: [], completedCount: completed ? 1 : 0, totalCount: 1)
    }

    static func fixture(_ id: String) -> SkinPlan {
        SkinPlan(id: id, name: "护肤方案", tags: [], morning: [RoutineItem(step: 1, product: "温和洁面", reason: "清洁", done: false, completed: false)], evening: [], recommendations: [])
    }
}

private enum LifecycleError: Error { case failed }
