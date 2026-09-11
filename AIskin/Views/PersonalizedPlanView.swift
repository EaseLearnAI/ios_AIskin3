import SwiftUI

struct PersonalizedPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: SessionStore
    @ObservedObject var planStore: PlanStore
    @StateObject private var preparationStore = PlanPreparationStore()
    @StateObject private var sourceStore = SkinAnalysisStore()
    @State private var showsSourceReport = false
    @State private var hasLoaded = false
    @State private var validationToast: String?
    @State private var toastID = UUID()
    @State private var formError: String?
    @State private var showsAgeEditor = false
    @State private var selectedConcerns: Set<String> = []
    @State private var customRequirements = ""
    @State private var isInCycle = false
    @State private var cycleDay = "1"
    @State private var showCycleDetails = false
    @State private var generationTask: Task<Void, Never>?

    private let skinConcerns: [(label: String, value: String, icon: String)] = [
        ("补水", "hydration", "drop"), ("修护", "repair", "bandage"),
        ("控油", "oil-control", "drop.halffull"), ("抗老", "anti-aging", "clock"),
        ("提亮", "brightening", "sun.max"), ("祛痘", "acne", "cross.case")
    ]

    var body: some View {
        ZStack {
            if planStore.isGenerating {
                AISkinProcessingScreen(title: "定制方案", message: "正在生成护肤方案", onCancel: cancelGeneration)
            } else {
                formBody
            }
        }
        .aiSkinTransparentNavigationContainer()
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear(perform: cancelGeneration)
        .sheet(isPresented: $showsAgeEditor) { AgeEditorView() }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            showCycleDetails = session.currentUser?.age == nil
            await planStore.load()
            await planStore.loadLatestSkinAnalysis()
#if DEBUG && targetEnvironment(simulator)
            await planStore.loadSavedPreviewForUITesting()
#endif
        }
        .fullScreenCover(isPresented: $showsSourceReport, onDismiss: {
            Task {
                await planStore.loadLatestSkinAnalysis()
            }
        }) {
            NavigationStack {
                AISkinScreenBackground {
                    if sourceStore.result != nil {
                        SkinReportView(store: sourceStore, onBack: { showsSourceReport = false }, onRetake: {
                            sourceStore.reset()
                        }, onCreatePlan: { showsSourceReport = false })
                    } else {
                        VStack(spacing: 0) {
                            AppHeader(title: "肌肤检测", backAction: { showsSourceReport = false })
                            SkinStatusView(store: sourceStore, startsInCapture: true)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .center) {
            if let validationToast {
                AISkinToast(message: validationToast, style: .centered(title: "请先补齐方案资料"), onDismiss: { self.validationToast = nil })
                    .padding(AISkinSpacing.screenEdge)
                    .accessibilityIdentifier("plan.validation.toast")
            }
        }
        .task(id: toastID) {
            guard validationToast != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { validationToast = nil }
        }
    }

    private var creationForm: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xLarge) {
            Text("根据护肤柜中已有的产品，结合肌肤检测结果与护肤目标，为你安排早晚使用顺序和步骤。\n请先将正在使用的产品添加到护肤柜。")
                .font(AISkinAccountPlanTokens.planCopy).foregroundStyle(AISkinColor.textSecondary)
            if let formError { AISkinStateView(content: .error(title: "暂时无法生成方案", message: formError)) }
            PlanInputForm(
                userAge: session.currentUser?.age, onEditAge: { showsAgeEditor = true }, selectedConcerns: $selectedConcerns,
                customRequirements: $customRequirements, isInCycle: $isInCycle,
                cycleDay: $cycleDay, showCycleDetails: $showCycleDetails,
                latestSkinAnalysis: planStore.latestSkinAnalysis, skinConcerns: skinConcerns,
                onViewSource: showSource
            )
        }
    }

    private func preview(_ plan: SkinPlan) -> some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                Text("方案预览").font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.accent)
                Text(plan.name).font(AISkinAccountPlanTokens.previewTitle).foregroundStyle(AISkinColor.textPrimary)
                if let note = plan.creatorNote, !note.isEmpty {
                    Text(note).font(AISkinAccountPlanTokens.planCopy).foregroundStyle(AISkinColor.textSecondary)
                }
                ViewThatFits(in: .horizontal) {
                    HStack { ForEach(Array(plan.tags.enumerated()), id: \.offset) { _, tag in AISkinTag(title: tag, tone: .accent) }; AISkinTag(title: "待采用") }
                    VStack(alignment: .leading) { ForEach(Array(plan.tags.enumerated()), id: \.offset) { _, tag in AISkinTag(title: tag, tone: .accent) }; AISkinTag(title: "待采用") }
                }
            }
            planPeriod(title: "早间护肤", systemImage: "sun.max", items: plan.morning)
            planPeriod(title: "晚间护肤", systemImage: "moon", items: plan.evening)
            if !plan.recommendations.isEmpty {
                DisclosureGroup("更多使用建议") {
                    VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                        ForEach(Array(plan.recommendations.enumerated()), id: \.offset) { _, tip in AISkinReportTextItem(text: tip) }
                    }.padding(.top, AISkinSpacing.small)
                }.font(AISkinAccountPlanTokens.planCopy).tint(AISkinColor.accent)
            }
            if let error = planStore.generationError { AISkinStateView(content: .error(title: "采用方案失败", message: error)) }
            Text("请按方案顺序安排早晚护肤。\n实际使用请结合产品说明与个人感受调整。")
                .font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary)
                .aiSkinGeneratedResult()
        }
    }

    private func planPeriod(title: String, systemImage: String, items: [RoutineItem]) -> some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.small) {
            Label(title, systemImage: systemImage).font(AISkinAccountPlanTokens.sectionLabel).foregroundStyle(AISkinColor.textSecondary)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 { AISkinDivider() }
                    AISkinPlanRoutineRow(number: index + 1, title: item.product ?? "步骤名称未提供", detail: item.reason)
                }
            }
        }
    }

    @ViewBuilder
    private var formBody: some View {
        VStack(spacing: 0) {
            AppHeader(title: planStore.generatedPlan == nil ? "定制方案" : "方案预览", rightIcon: planStore.generatedPlan == nil ? nil : "slider.horizontal.3", rightAction: {
                planStore.resetGeneratedPlan()
            }, backAction: {
                cancelGeneration()
                if planStore.generatedPlan != nil { planStore.resetGeneratedPlan() } else { dismiss() }
            })
            .accessibilityIdentifier("personalized-plan.header")
            ScrollView {
                VStack(alignment: .leading, spacing: AISkinSpacing.xLarge) {
                    if let plan = planStore.generatedPlan {
                        preview(plan)
                    } else {
                        creationForm
                    }
                }
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .padding(.top, AISkinSpacing.medium)
                .padding(.bottom, AISkinSpacing.xLarge)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    @ViewBuilder
    private var footer: some View {
        if !planStore.isGenerating {
            AISkinReportFooter {
                if let plan = planStore.generatedPlan {
                    AISkinButton(isLoading: planStore.isAdopting, action: {
                        Task {
                            if await planStore.acceptGeneratedPlan(plan) {
                                dismiss()
                            }
                        }
                    }) { Label("采用这份方案", systemImage: "checkmark") }
                    .accessibilityIdentifier("personalized-plan.save")
                } else {
                    AISkinButton(isLoading: generationTask != nil, action: generatePlan) {
                        Label("生成我的方案", systemImage: "sparkles")
                    }
                    .accessibilityIdentifier("plan.form.generate")
                }
            }
        }
    }

    private func showSource() {
        guard planStore.latestSkinAnalysis != nil else {
            sourceStore.reset()
            showsSourceReport = true
            return
        }
        Task {
            await sourceStore.loadHistory()
            if let latest = sourceStore.lastResult {
                sourceStore.selectHistory(latest)
                showsSourceReport = true
            } else {
                showValidationToast(sourceStore.historyError ?? "未找到肌肤报告，请先完成肌肤检测。")
            }
        }
    }

    private func showValidationToast(_ message: String) {
        validationToast = message
        toastID = UUID()
    }

    private func generatePlan() {
        guard generationTask == nil else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        validationToast = nil
        formError = nil
        generationTask = Task {
            defer { generationTask = nil }
            // Recheck current saved data on every attempt, including after deletion.
            await preparationStore.refresh()
            guard !Task.isCancelled else { return }
            if case .failed(let message) = preparationStore.state {
                showValidationToast(message + "，请稍后重试。")
                return
            }
            guard preparationStore.state == .ready else { return }
            var missing = preparationStore.missingRequirements
            let age = session.currentUser?.age
            if age.map({ User.ageRange.contains($0) }) != true {
                missing.append("请在「其他个人状态」中填写有效年龄")
            }
            if selectedConcerns.isEmpty { missing.append("请至少选择一个护肤目标") }
            if isInCycle && Int(cycleDay).map({ (1...7).contains($0) }) != true {
                missing.append("请输入 1–7 的周期天数")
            }
            guard missing.isEmpty, let age else {
                showValidationToast(missing.joined(separator: "；") + "。")
                return
            }
            let labels = skinConcerns.filter { selectedConcerns.contains($0.value) }.map(\.label)
            var notes = customRequirements
            if isInCycle { notes += (notes.isEmpty ? "" : "\n") + "补充个人状态：当前处于生理周期第\(cycleDay)天。" }
            await planStore.generate(requirement: labels.joined(separator: "、"), age: age, concerns: Array(selectedConcerns), customRequirements: notes.isEmpty ? nil : notes)
            guard !Task.isCancelled else { return }
            if let error = planStore.generationError { formError = "生成方案失败：\(error)" }
        }
    }

    private func cancelGeneration() {
        generationTask?.cancel()
    }
}
