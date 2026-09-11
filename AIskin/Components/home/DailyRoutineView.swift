import SwiftUI

struct DailyRoutineView: View {
    @ObservedObject var planStore: PlanStore
    let onViewPlan: () -> Void
    let onHistory: () -> Void
    @State private var period: RoutinePeriod = .morning
    @State private var isUpdating = false

    var body: some View {
        AISkinCard(role: .routine) {
            VStack(spacing: AISkinSpacing.small) {
                HStack {
                    Button(action: onViewPlan) {
                        Text("每日护肤").font(AISkinTypography.homeHeading)
                            .foregroundStyle(AISkinColor.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("每日护肤，查看完整方案")
                    .accessibilityIdentifier("home.current-plan.open")
                    Spacer()
                    Button(action: onHistory) {
                        Label("历史", systemImage: "clock.arrow.circlepath")
                            .font(AISkinTypography.caption)
                            .foregroundStyle(AISkinColor.accent)
                            .frame(minHeight: AISkinLayout.minimumTapHeight)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("护肤方案历史")
                }
                AISkinSegmentedControl(
                    items: RoutinePeriod.allCases,
                    selection: $period,
                    title: { $0.title },
                    systemImage: { $0 == .morning ? "sun.max" : "moon" }
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("早晚护肤")
                VStack(spacing: 0) {
                    ForEach(Array(visibleRoutine.enumerated()), id: \.offset) { index, item in
                        AISkinChecklistRow(title: item.product ?? "护肤步骤", message: item.reason, number: index + 1, isCompleted: item.completed == true) {
                            guard !isUpdating else { return }
                            isUpdating = true
                            let selectedPeriod = period.rawValue
                            Task {
                                await planStore.toggleStep(period: selectedPeriod, index: index)
                                isUpdating = false
                            }
                        }
                        .disabled(isUpdating)
                        .accessibilityIdentifier("home.routine.\(period.rawValue).\(index)")
                        if index < visibleRoutine.count - 1 { AISkinDivider() }
                    }
                    if visibleRoutine.isEmpty {
                        AISkinStateView(content: .empty(title: "暂无\(period.title)步骤", message: "可以在完整护肤方案中查看安排。", systemImage: "list.clipboard"))
                    }
                }
            }
        }
    }

    private var visibleRoutine: [RoutineItem] { (period == .morning ? planStore.currentPlan?.morning : planStore.currentPlan?.evening) ?? [] }
}

private enum RoutinePeriod: String, CaseIterable {
    case morning, evening
    var title: String { self == .morning ? "早间" : "晚间" }
}
