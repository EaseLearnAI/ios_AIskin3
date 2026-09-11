import SwiftUI

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @ObservedObject var planStore: PlanStore
    @State private var isHistoryPresented = false
    @State private var viewedPlan: SkinPlan?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AISkinSpacing.sectionGap) {
                CoreFeaturesView()
                if planStore.currentPlan != nil {
                    DailyRoutineView(
                        planStore: planStore,
                        onViewPlan: { viewedPlan = planStore.currentPlan },
                        onHistory: { isHistoryPresented = true }
                    )
                } else {
                    AISkinCard {
                        VStack(spacing: AISkinSpacing.small) {
                            routineHeading
                            routineState
                        }
                    }
                }
                if case .failed(let message) = planStore.state, planStore.currentPlan != nil {
                    AISkinCard {
                        AISkinStateView(content: .error(title: "保存未成功", message: message))
                    }
                }
            }
            .padding(.horizontal, AISkinSpacing.screenEdge)
            .padding(.top, AISkinSpacing.medium)
            .padding(.bottom, AISkinSpacing.xLarge)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await planStore.load()
        }
        .refreshable { await planStore.load() }
        .sheet(isPresented: $isHistoryPresented) {
            PlanHistorySheet(planStore: planStore)
        }
        .sheet(item: $viewedPlan) { plan in
            CurrentPlanDetailSheet(plan: plan)
        }
    }

    private var routineHeading: some View {
        HStack {
            AISkinSectionHeading(title: "每日护肤")
            AISkinIconButton(systemName: "clock.arrow.circlepath", accessibilityLabel: "护肤方案历史", variant: .surface) {
                isHistoryPresented = true
            }
        }
    }

    @ViewBuilder private var routineState: some View {
        switch planStore.state {
        case .idle, .loading:
            AISkinStateView(content: .loading(message: "正在获取护肤方案…"))
        case .failed(let message):
            AISkinStateView(content: .error(title: "暂时无法获取护肤方案", message: message), actionTitle: "重新加载") {
                Task { await planStore.load() }
            }
        case .empty, .loaded:
            AISkinStateView(content: .empty(
                title: "还没有护肤计划",
                message: "根据护肤柜里的产品和肌肤检测结果，安排早晚护肤。",
                systemImage: "list.clipboard"
            ), actionTitle: "创建护肤计划", action: router.showPersonalizedPlan)
        }
    }

}

private struct CurrentPlanDetailSheet: View {
    let plan: SkinPlan
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AISkinScreenBackground {
                ScrollView {
                    PersonalizedRoutinePlanContent(plan: plan)
                        .padding(AISkinSpacing.screenEdge)
                        .accessibilityIdentifier("home.current-plan.content")
                }
            }
            .navigationTitle("当前护肤方案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .accessibilityIdentifier("home.current-plan.done")
                }
            }
            .aiSkinTransparentNavigationContainer()
        }
    }
}

private struct PlanHistorySheet: View {
    @ObservedObject var planStore: PlanStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AISkinScreenBackground {
                ScrollView {
                    VStack(spacing: AISkinSpacing.medium) {
                        if planStore.isLoadingHistory {
                            AISkinStateView(content: .loading(message: "正在加载护肤方案…"))
                        } else if let error = planStore.historyError {
                            AISkinStateView(content: .error(title: "加载失败", message: error), actionTitle: "重试") {
                                Task { await planStore.loadHistory() }
                            }
                        } else if planStore.plans.isEmpty {
                            AISkinStateView(content: .empty(title: "暂无历史方案", message: "保存后的护肤方案会显示在这里。", systemImage: "clock"))
                        }
                        ForEach(planStore.plans) { plan in
                            AISkinCard {
                                VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                                    AISkinSectionHeading(title: plan.name, detail: plan.createdAt?.formatted(date: .abbreviated, time: .omitted))
                                    Text("早间 \(plan.morning.count) 步 · 晚间 \(plan.evening.count) 步")
                                        .font(AISkinTypography.callout).foregroundStyle(AISkinColor.textSecondary)
                                    DisclosureGroup("查看护肤步骤") {
                                        PersonalizedRoutinePlanContent(plan: plan)
                                            .padding(.top, AISkinSpacing.small)
                                    }
                                    .font(AISkinTypography.callout)
                                    .tint(AISkinColor.accent)
                                    if planStore.currentPlan?.id == plan.id {
                                        AISkinTag(title: "当前方案", systemImage: "checkmark", tone: .accent)
                                    } else {
                                        AISkinButton(variant: .secondary, isLoading: planStore.isAdopting, action: {
                                            Task { if await planStore.adopt(plan: plan) { dismiss() } }
                                        }) { Text("使用此方案") }
                                        .accessibilityIdentifier("home.plan-history.adopt.\(plan.id)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(AISkinSpacing.screenEdge)
                }
            }
            .navigationTitle("护肤方案历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            .aiSkinTransparentNavigationContainer()
        }
        .task { await planStore.loadHistory() }
    }
}
