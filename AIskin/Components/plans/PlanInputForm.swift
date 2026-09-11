import SwiftUI

struct PlanInputForm: View {
    let userAge: Int?
    let onEditAge: () -> Void
    @Binding var selectedConcerns: Set<String>
    @Binding var customRequirements: String
    @Binding var isInCycle: Bool
    @Binding var cycleDay: String
    @Binding var showCycleDetails: Bool
    let latestSkinAnalysis: SkinAnalysisData?
    let skinConcerns: [(label: String, value: String, icon: String)]
    let onViewSource: () -> Void
    @FocusState private var focusedField: PlanInputField?

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xLarge) {
            sourceRow
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                HStack(alignment: .firstTextBaseline) {
                    fieldTitle("护肤目标")
                    Spacer()
                    Text("已选 \(selectedConcerns.count)/3 项")
                        .font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AISkinAccountPlanTokens.goalGridGap), count: 3), spacing: AISkinAccountPlanTokens.goalGridGap) {
                    ForEach(skinConcerns, id: \.value) { concern in
                        AISkinTag(title: concern.label, tone: .accent, state: selectedConcerns.contains(concern.value) ? .selected : .normal, size: .regular, variant: .selectionCell) {
                            focusedField = nil
                            if selectedConcerns.contains(concern.value) { selectedConcerns.remove(concern.value) }
                            else if selectedConcerns.count < 3 { selectedConcerns.insert(concern.value) }
                        }
                        .accessibilityIdentifier("plan.form.goal.\(concern.value)")
                    }
                }
            }
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                HStack {
                    fieldTitle("补充需求")
                    Text("选填").font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary)
                    Spacer()
                    if focusedField == .requirements { dismissKeyboardButton }
                }
                AISkinField(state: focusedField == .requirements ? .focused : .normal, variant: .form) {
                    ZStack(alignment: .topLeading) {
                        if customRequirements.isEmpty {
                            Text("例如：希望步骤少一点，最近两颊容易干燥。")
                                .foregroundStyle(AISkinColor.textSecondary)
                                .padding(.top, AISkinSpacing.xSmall).allowsHitTesting(false)
                        }
                        TextEditor(text: $customRequirements)
                            .keyboardType(.default)
                            .accessibilityIdentifier("plan.form.requirements")
                            .scrollContentBackground(.hidden).focused($focusedField, equals: .requirements)
                            .frame(minHeight: AISkinAccountPlanTokens.noteHeight)
                            .onChange(of: customRequirements) { _, value in
                                if value.count > 300 { customRequirements = String(value.prefix(300)) }
                            }
                    }
                }
                Text("可以填写产品偏好、使用习惯或希望避开的成分。")
                    .font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary)
            }
            DisclosureGroup("其他个人状态", isExpanded: $showCycleDetails) {
                VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                    PersonalAgeRow(age: userAge, accessibilityID: "plan.form.age") {
                        focusedField = nil
                        onEditAge()
                    }
                    Toggle("当前处于生理周期", isOn: $isInCycle).tint(AISkinColor.accent)
                    if isInCycle {
                        AISkinField(state: focusedField == .cycleDay ? .focused : .normal, variant: .form) {
                            Text("周期第几天")
                            Spacer()
                            TextField("1–7", text: $cycleDay).keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing).frame(width: AISkinAccountPlanTokens.cycleFieldWidth)
                                .focused($focusedField, equals: .cycleDay)
                            Text("天")
                            if focusedField == .cycleDay { dismissKeyboardButton }
                        }
                    }
                }.padding(.top, AISkinSpacing.small)
            }
            .font(AISkinAccountPlanTokens.planCopy).foregroundStyle(AISkinColor.textSecondary).tint(AISkinColor.accent)
        }
    }

    private var dismissKeyboardButton: some View {
        AISkinIconButton(systemName: "keyboard.chevron.compact.down", accessibilityLabel: "收起键盘", variant: .plain) {
            focusedField = nil
        }
        .accessibilityIdentifier("plan.form.dismiss-keyboard")
    }

    private var sourceRow: some View {
        AISkinPlanSourceRow(
            title: latestSkinAnalysis == nil ? "先了解你的肌肤" : "已关联最近检测",
            detail: latestSkinAnalysis.map { "\($0.skinType) · \($0.createdAt.formatted(date: .abbreviated, time: .omitted))" } ?? "完成肌肤检测后，为你定制更合适的护肤步骤。",
            actionTitle: latestSkinAnalysis == nil ? "去检测" : "查看",
            action: onViewSource
        )
    }

    private func fieldTitle(_ title: String) -> some View {
        Text(title).font(AISkinAccountPlanTokens.fieldTitle).foregroundStyle(AISkinColor.textPrimary)
    }
}

private enum PlanInputField: Hashable { case cycleDay, requirements }
