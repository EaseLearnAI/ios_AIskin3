import Foundation
import Combine

@MainActor
protocol PlansClient {
    func plans() async throws -> [SkinPlan]
    func plan(id: String) async throws -> SkinPlan
    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan
    func updateStep(planID: String, period: String, step: Int, completed: Bool) async throws -> SkinPlan
    func latestSkinAnalysis() async throws -> SkinAnalysis?
}

@MainActor
struct LegacyPlansClient: PlansClient {
    func plans() async throws -> [SkinPlan] {
        try await PlanApiService.shared.getUserPlans()
    }

    func plan(id: String) async throws -> SkinPlan {
        try await PlanApiService.shared.getPlan(planId: id)
    }

    func createPlan(requirement: String?, age: Int?, concerns: [String]?, customRequirements: String?) async throws -> SkinPlan {
        try await PlanApiService.shared.createPlan(
            requirement: requirement,
            userAge: age,
            skinConcerns: concerns,
            customRequirements: customRequirements
        )
    }

    func updateStep(planID: String, period: String, step: Int, completed: Bool) async throws -> SkinPlan {
        try await PlanApiService.shared.updateStepCompleted(
            planId: planID,
            period: period,
            step: step,
            completed: completed
        )
    }

    func latestSkinAnalysis() async throws -> SkinAnalysis? {
        try await SkinAnalysisApiService.shared.getLatestAnalysis()
    }
}

@MainActor
final class PlanStore: ObservableObject {
    enum State {
        case idle
        case loading
        case empty
        case loaded
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var currentPlan: SkinPlan?
    @Published private(set) var generatedPlan: SkinPlan?
    @Published private(set) var latestSkinAnalysis: SkinAnalysisData?
    @Published private(set) var generationError: String?
    @Published private(set) var isGenerating = false

    private let client: any PlansClient

    init(client: (any PlansClient)? = nil) {
        self.client = client ?? LegacyPlansClient()
    }

    func load() async {
        state = .loading
        do {
            let plans = try await client.plans()
            if let latest = plans.first {
                currentPlan = try await client.plan(id: latest.id)
                state = .loaded
            } else {
                currentPlan = nil
                state = .empty
            }
        } catch is CancellationError {
            return
        } catch {
            currentPlan = nil
            state = .failed("获取护肤方案失败：\(error.localizedDescription)")
        }
    }

    func loadLatestSkinAnalysis() async {
        guard let analysis = try? await client.latestSkinAnalysis() else { return }
        latestSkinAnalysis = SkinAnalysisData(
            skinType: analysis.skinType?.type ?? "未知",
            healthScore: Int(analysis.overallAssessment?.healthScore ?? 0),
            skinCondition: analysis.overallAssessment?.skinCondition ?? "未知",
            createdAt: analysis.createdAt ?? Date()
        )
    }

    func generate(requirement: String, age: Int, concerns: [String], customRequirements: String?) async {
        isGenerating = true
        generationError = nil
        defer { isGenerating = false }
        do {
            generatedPlan = try await client.createPlan(
                requirement: requirement,
                age: age,
                concerns: concerns,
                customRequirements: customRequirements
            )
        } catch {
            generationError = error.localizedDescription
        }
    }

    func resetGeneratedPlan() {
        generatedPlan = nil
        generationError = nil
    }

    func acceptGeneratedPlan(_ plan: SkinPlan) {
        currentPlan = plan
        state = .loaded
        generatedPlan = nil
    }

    func toggleStep(period: String, index: Int) async {
        guard var plan = currentPlan else { return }
        var routine = period == "morning" ? plan.morning : plan.evening
        guard routine.indices.contains(index) else { return }

        let oldItem = routine[index]
        let step = oldItem.step ?? index + 1
        let completed = !(oldItem.completed ?? false)
        routine[index].completed = completed
        if period == "morning" { plan.morning = routine } else { plan.evening = routine }
        currentPlan = plan

        do {
            currentPlan = try await client.updateStep(
                planID: plan.id,
                period: period,
                step: step,
                completed: completed
            )
        } catch {
            currentPlan = plan
            var rollback = period == "morning" ? plan.morning : plan.evening
            rollback[index] = oldItem
            if period == "morning" { currentPlan?.morning = rollback } else { currentPlan?.evening = rollback }
            state = .failed("更新护肤步骤失败：\(error.localizedDescription)")
        }
    }
}
