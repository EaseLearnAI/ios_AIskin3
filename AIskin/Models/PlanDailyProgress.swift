import Foundation

struct PlanDailyProgress: Codable {
    struct Step: Codable { var step: Int; var completed: Bool }
    var planId: String
    var date: String
    var timezone: String
    var morning: [Step]
    var evening: [Step]
    var completedCount: Int
    var totalCount: Int

    func applying(to source: SkinPlan) -> SkinPlan {
        var plan = source
        func apply(_ items: [RoutineItem], _ steps: [Step]) -> [RoutineItem] {
            items.enumerated().map { index, item in
                var result = item
                let completed = steps.first { $0.step == (item.step ?? index + 1) }?.completed ?? false
                result.completed = completed
                result.done = completed
                return result
            }
        }
        plan.morning = apply(plan.morning, morning)
        plan.evening = apply(plan.evening, evening)
        return plan
    }
}
