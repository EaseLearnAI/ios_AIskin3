import Foundation
import Combine

@MainActor
protocol PlansClient {
    func plans() async throws -> [SkinPlan]
    func plan(id: String) async throws -> SkinPlan
    func activePlan() async throws -> SkinPlan?
    func adopt(planID: String) async throws -> SkinPlan
    func daily(planID: String, date: String, timezone: String) async throws -> PlanDailyProgress
    func updateDailyStep(planID: String, date: String, timezone: String, period: String, step: Int, completed: Bool) async throws -> PlanDailyProgress
    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan
    func latestSkinAnalysis() async throws -> SkinAnalysis?
}

@MainActor
struct LegacyPlansClient: PlansClient {
    func plans() async throws -> [SkinPlan] { try await PlanApiService.shared.getUserPlans() }
    func plan(id: String) async throws -> SkinPlan { try await PlanApiService.shared.getPlan(planId: id) }
    func activePlan() async throws -> SkinPlan? { try await PlanApiService.shared.getActivePlan() }
    func adopt(planID: String) async throws -> SkinPlan { try await PlanApiService.shared.adoptPlan(planID: planID) }
    func daily(planID: String, date: String, timezone: String) async throws -> PlanDailyProgress {
        try await PlanApiService.shared.getDailyProgress(planID: planID, date: date, timezone: timezone)
    }
    func updateDailyStep(planID: String, date: String, timezone: String, period: String, step: Int, completed: Bool) async throws -> PlanDailyProgress {
        try await PlanApiService.shared.updateDailyStep(planID: planID, date: date, timezone: timezone, period: period, step: step, completed: completed)
    }
    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan {
        try await PlanApiService.shared.createPlan(requirement: requirement, userAge: age, skinConcerns: concerns, customRequirements: customRequirements)
    }
    func latestSkinAnalysis() async throws -> SkinAnalysis? { try await SkinAnalysisApiService.shared.getLatestAnalysis() }
}

@MainActor
final class PlanStore: ObservableObject {
    enum State { case idle, loading, empty, loaded, failed(String) }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentPlan: SkinPlan?
    @Published private(set) var generatedPlan: SkinPlan?
    @Published private(set) var latestSkinAnalysis: SkinAnalysisData?
    @Published private(set) var generationError: String?
    @Published private(set) var isGenerating = false
    @Published private(set) var plans: [SkinPlan] = []
    @Published private(set) var historyError: String?
    @Published private(set) var isLoadingHistory = false
    @Published private(set) var isAdopting = false
    @Published private(set) var isUpdatingStep = false

    private let client: any PlansClient
    private let now: () -> Date
    private let timezone: () -> TimeZone
    private var loadedDate: String?
    private var loadedTimezone: String?
    private var isLoading = false

    init(client: (any PlansClient)? = nil, now: @escaping () -> Date = Date.init, timezone: @escaping () -> TimeZone = { .current }) {
        self.client = client ?? LegacyPlansClient()
        self.now = now
        self.timezone = timezone
    }

    private func day() -> (date: String, timezone: String) {
        let zone = timezone()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = "yyyy-MM-dd"
        return (formatter.string(from: now()), zone.identifier)
    }

    private func loadProgress(for plan: SkinPlan) async throws -> SkinPlan {
        let today = day()
        let daily = try await client.daily(planID: plan.id, date: today.date, timezone: today.timezone)
        loadedDate = daily.date
        loadedTimezone = daily.timezone
        return daily.applying(to: plan)
    }

    func load() async {
        guard !isLoading, !isAdopting, !isUpdatingStep else { return }
        isLoading = true
        state = .loading
        defer { isLoading = false }
        do {
            if let active = try await client.activePlan() {
                currentPlan = try await loadProgress(for: active)
                state = .loaded
            } else {
                currentPlan = nil
                loadedDate = nil
                loadedTimezone = nil
                state = .empty
            }
        } catch is CancellationError { return }
        catch { state = .failed("获取护肤方案失败：\(error.localizedDescription)") }
    }

    func loadHistory() async {
        guard !isLoadingHistory else { return }
        isLoadingHistory = true
        historyError = nil
        defer { isLoadingHistory = false }
        do { plans = try await client.plans() }
        catch is CancellationError { return }
        catch { historyError = "获取历史方案失败：\(error.localizedDescription)" }
    }

    func loadLatestSkinAnalysis() async {
        guard let analysis = try? await client.latestSkinAnalysis(), let score = analysis.overallAssessment?.healthScore else { return }
        latestSkinAnalysis = SkinAnalysisData(skinType: analysis.skinType?.type ?? "未知", healthScore: Int(score), skinCondition: analysis.overallAssessment?.skinCondition ?? "未知", createdAt: analysis.createdAt ?? now())
    }

    func generate(requirement: String, age: Int, concerns: [String], customRequirements: String?) async {
        guard !isGenerating else { return }
        do { try Task.checkCancellation() } catch { return }
        isGenerating = true
        generationError = nil
        generatedPlan = nil
        defer { isGenerating = false }
        do {
            let plan = try await client.createPlan(requirement: requirement, age: age, concerns: concerns, customRequirements: customRequirements)
            try Task.checkCancellation()
            generatedPlan = plan
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            generationError = error.localizedDescription
        }
    }

    func resetGeneratedPlan() { generatedPlan = nil; generationError = nil }

#if DEBUG && targetEnvironment(simulator)
    /// Read-only visual inspection of the actual preview using a saved local
    /// plan. No generation or adoption request is made by this opt-in route.
    func loadSavedPreviewForUITesting() async {
        let process = ProcessInfo.processInfo
        guard AppBackendConfiguration.mode == .live,
              URLSessionHTTPClient.defaultBaseURL.host == "127.0.0.1",
              process.arguments.contains("-AISkinUITestSession"),
              process.arguments.contains("-AISkinPreviewSavedPlan"),
              let id = process.environment["AISKIN_UI_PREVIEW_PLAN_ID"], !id.isEmpty else { return }
        do { generatedPlan = try await client.plan(id: id) }
        catch { generationError = error.localizedDescription }
    }
#endif

    @discardableResult
    func acceptGeneratedPlan(_ plan: SkinPlan) async -> Bool {
        let accepted = await adopt(plan: plan)
        if accepted { generatedPlan = nil }
        return accepted
    }

    @discardableResult
    func adopt(plan: SkinPlan) async -> Bool {
        guard !isAdopting, !isLoading, !isUpdatingStep else { return false }
        isAdopting = true
        historyError = nil
        generationError = nil
        defer { isAdopting = false }
        let previousDate = loadedDate
        let previousTimezone = loadedTimezone
        do {
            // Read progress first, so failure cannot leave a server selection that the UI rejected.
            let withProgress = try await loadProgress(for: plan)
            let saved = try await client.adopt(planID: plan.id)
            guard saved.id == plan.id else { throw APIError.serverError("服务端返回的方案不一致") }
            currentPlan = withProgress
            state = .loaded
            return true
        } catch {
            loadedDate = previousDate
            loadedTimezone = previousTimezone
            let message = "采用方案失败：\(error.localizedDescription)"
            historyError = message
            generationError = message
            state = .failed(message)
            return false
        }
    }

    func toggleStep(period: String, index: Int) async {
        guard period == "morning" || period == "evening", !isUpdatingStep, !isAdopting, !isLoading else { return }
        let today = day()
        if loadedDate != today.date || loadedTimezone != today.timezone { await load() }
        guard let original = currentPlan, loadedDate == today.date, loadedTimezone == today.timezone else { return }
        let routine = period == "morning" ? original.morning : original.evening
        guard routine.indices.contains(index) else { return }
        let item = routine[index]
        let completed = !item.isDone
        isUpdatingStep = true
        defer { isUpdatingStep = false }
        var optimistic = original
        if period == "morning" {
            optimistic.morning[index].completed = completed
            optimistic.morning[index].done = completed
        } else {
            optimistic.evening[index].completed = completed
            optimistic.evening[index].done = completed
        }
        currentPlan = optimistic
        do {
            let daily = try await client.updateDailyStep(planID: original.id, date: today.date, timezone: today.timezone, period: period, step: item.step ?? index + 1, completed: completed)
            currentPlan = daily.applying(to: original)
            state = .loaded
        } catch {
            currentPlan = original
            state = .failed("更新护肤步骤失败：\(error.localizedDescription)")
        }
    }
}
