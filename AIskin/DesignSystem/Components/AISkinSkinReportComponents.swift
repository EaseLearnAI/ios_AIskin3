import SwiftUI

struct AISkinSkinReportLink: View {
    let title: String
    var systemImage: String = "arrow.up.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .font(AISkinSkinReportTokens.meta)
                .foregroundStyle(AISkinColor.accent)
                .frame(minHeight: AISkinLayout.minimumTapHeight)
                .contentShape(Rectangle())
        }.buttonStyle(AISkinPressableStyle())
    }
}

struct AISkinSkinReportAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: AISkinSpacing.xxSmall) {
                Image(systemName: systemImage).font(AISkinTypography.iconMedium)
                Text(title).font(AISkinSkinReportTokens.footnote)
            }
            .foregroundStyle(AISkinColor.accent)
            .frame(width: AISkinSkinReportTokens.inlineWidth, height: AISkinLayout.minimumTapHeight)
            .contentShape(Rectangle())
        }.buttonStyle(AISkinPressableStyle())
    }
}

struct AISkinSkinReportObservation: Identifiable {
    let id: String
    let title: String
    let status: String?
    let details: String
    var summary: String = ""
    var isConcern: Bool = false

    /// The summary already displays the source's opening sentence. Keep the
    /// source intact while showing its remaining explanation only once.
    var detailBody: String {
        let source = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let heading = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !heading.isEmpty else { return source }
        if source.hasPrefix(heading) {
            let remainder = source.dropFirst(heading.count)
            if remainder.isEmpty || heading.last.map({ "。！？!?".contains($0) }) == true || remainder.first?.isWhitespace == true {
                return remainder.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // A summary adds a full stop when the recorded sentence has none.
        if heading.last == "。" {
            let opening = heading.dropLast()
            if !opening.isEmpty, source.hasPrefix(opening) {
                let remainder = source.dropFirst(opening.count)
                if remainder.isEmpty || remainder.first?.isWhitespace == true {
                    return remainder.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return source
    }
}

struct AISkinSkinReportPhotoMap<Photo: View>: View {
    let observations: [AISkinSkinReportObservation]
    var assessments: [AISkinSkinReportObservation] = []
    @ViewBuilder var photo: () -> Photo
    @State private var selectedID: String?
    @State private var selectionRequest = UUID()
    @State private var detailsHeight = AISkinSkinReportTokens.observationsMaximumHeight
    private var selected: AISkinSkinReportObservation? { observations.first { $0.id == selectedID } ?? observations.first }
    private var details: [AISkinSkinReportObservation] { observations + assessments }
    private var concernCount: Int { observations.filter(\.isConcern).count }

    var body: some View {
        AISkinCard(inset: .none) {
            VStack(spacing: 0) {
                VStack(spacing: AISkinSpacing.small) {
                    Text("AI 识别问题")
                        .font(AISkinSkinReportTokens.chapter)
                        .foregroundStyle(AISkinColor.textPrimary)
                    GeometryReader { geometry in
                        let pinWidth = min(AISkinSkinReportTokens.pinMaximumWidth, max(AISkinSkinReportTokens.pinMinimumWidth, geometry.size.width * AISkinSkinReportTokens.pinWidthFraction))
                        let photoDiameter = min(AISkinSkinReportTokens.photoMaximumDiameter, max(0, geometry.size.width - 2 * (pinWidth + AISkinSkinReportTokens.pinPhotoGap)))
                        photoOrbit(diameter: photoDiameter)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        ForEach(Array(observations.prefix(AISkinSkinReportTokens.pinVerticalFractions.count).enumerated()), id: \.element.id) { index, item in
                            pin(item, width: pinWidth) {
                                selectedID = item.id
                                selectionRequest = UUID()
                            }
                            .position(x: index == 1 ? geometry.size.width - pinWidth / 2 : pinWidth / 2,
                                      y: geometry.size.height * AISkinSkinReportTokens.pinVerticalFractions[index])
                        }
                    }
                    .frame(height: AISkinSkinReportTokens.photoMapHeight)
                    Text("本次检测照片")
                        .font(AISkinSkinReportTokens.footnote)
                        .foregroundStyle(AISkinColor.textSecondary)
                }
                .padding(.horizontal, AISkinSpacing.small)
                .padding(.vertical, AISkinSpacing.medium)
                AISkinDivider()
                VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                    Text(concernCount > 0 ? "本次有 \(concernCount) 项需要关注" : "本次肌肤观察")
                        .font(AISkinSkinReportTokens.title)
                        .foregroundStyle(AISkinColor.textPrimary)
                    Text(concernCount > 0 ? "逐项了解问题，一步步安排护理。" : "逐项了解记录，结合实际肤感安排护理。")
                        .font(AISkinSkinReportTokens.small)
                        .foregroundStyle(AISkinColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AISkinSpacing.medium)
                .accessibilityIdentifier("skin.report.observation-count")
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(details) { item in
                                observationRow(item)
                                    .id(item.id)
                                if item.id != details.last?.id { AISkinDivider() }
                            }
                            if details.isEmpty {
                                Text("该次记录未提供观察明细。")
                                    .font(AISkinSkinReportTokens.body)
                                    .foregroundStyle(AISkinColor.textSecondary)
                                    .padding(.vertical, AISkinSpacing.small)
                                    .accessibilityIdentifier("skin.report.observations.empty")
                            }
                        }
                        .padding(.horizontal, AISkinSpacing.medium)
                        .padding(.bottom, AISkinSpacing.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { detailsHeight = $0 }
                    }
                    .frame(height: min(detailsHeight, AISkinSkinReportTokens.observationsMaximumHeight))
                    .scrollBounceBehavior(.basedOnSize)
                    .scrollIndicatorsFlash(trigger: detailsHeight)
                    .accessibilityIdentifier("skin.report.observations")
                    .onChange(of: selectionRequest) { _, _ in
                        if let selectedID {
                            withAnimation(AISkinMotion.standard) { proxy.scrollTo(selectedID, anchor: .top) }
                        }
                    }
                    }
                }
        }
    }

    private func photoOrbit(diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(AISkinColor.divider, style: StrokeStyle(lineWidth: AISkinLayout.hairline, dash: [AISkinSpacing.xxxSmall]))
                .frame(width: diameter + AISkinSkinReportTokens.orbitInset, height: diameter + AISkinSkinReportTokens.orbitInset)
            ForEach(AISkinSkinReportTokens.orbitSegments.indices, id: \.self) { index in
                let segment = AISkinSkinReportTokens.orbitSegments[index]
                Circle().trim(from: segment.lowerBound, to: segment.upperBound)
                    .stroke(AISkinSkinReportTokens.metricFill, style: StrokeStyle(lineWidth: AISkinSkinReportTokens.orbitStroke, lineCap: .round))
                    .frame(width: diameter + 2 * AISkinSkinReportTokens.orbitInset, height: diameter + 2 * AISkinSkinReportTokens.orbitInset)
            }
            photo()
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .overlay { Circle().stroke(AISkinColor.border, lineWidth: AISkinSkinReportTokens.photoBorder) }
        }
    }

    private func pin(_ item: AISkinSkinReportObservation, width: CGFloat, action: @escaping () -> Void) -> some View {
        let emphasis = item.isConcern ? AISkinColor.skinConcern : AISkinColor.accent
        return Button(action: action) {
            HStack(spacing: AISkinSpacing.xxSmall) {
                Circle().fill(emphasis)
                    .frame(width: AISkinSkinReportTokens.pinIndicatorDiameter, height: AISkinSkinReportTokens.pinIndicatorDiameter)
                Text(item.title).font(AISkinSkinReportTokens.pinTitle)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                if let status = item.status {
                    Text(status).font(AISkinSkinReportTokens.pinStatus)
                        .foregroundStyle(AISkinColor.textSecondary)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .foregroundStyle(item.isConcern || selected?.id == item.id ? emphasis : AISkinColor.textPrimary)
            .padding(.horizontal, AISkinSkinReportTokens.pinHorizontalPadding)
            .padding(.vertical, AISkinSkinReportTokens.pinVerticalPadding)
            .frame(width: width)
            .frame(minHeight: AISkinLayout.minimumTapHeight)
            .background {
                if selected?.id == item.id { item.isConcern ? AISkinColor.skinConcernSelected : AISkinColor.surfaceSelected }
            }
            .background(AISkinColor.surfaceElevated)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(selected?.id == item.id ? emphasis : AISkinColor.divider, lineWidth: AISkinLayout.hairline) }
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityIdentifier("skin.report.pin.\(item.id)")
        .accessibilityAddTraits(selected?.id == item.id ? .isSelected : [])
    }

    private func observationRow(_ item: AISkinSkinReportObservation) -> some View {
        let emphasis = item.isConcern ? AISkinColor.skinConcern : AISkinColor.accent
        return VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
            HStack(spacing: AISkinSpacing.xSmall) {
                Circle().fill(emphasis)
                    .frame(width: AISkinSkinReportTokens.pinIndicatorDiameter, height: AISkinSkinReportTokens.pinIndicatorDiameter)
                Text(item.title).font(AISkinSkinReportTokens.title).foregroundStyle(AISkinColor.textPrimary)
                Spacer(minLength: 0)
                if let status = item.status {
                    Text(status).font(AISkinSkinReportTokens.label).foregroundStyle(emphasis)
                }
            }
            Text(item.summary)
                .font(AISkinSkinReportTokens.observationSummary)
                .foregroundStyle(AISkinColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("skin.report.summary.\(item.id)")
            if !item.detailBody.isEmpty {
                Text(item.detailBody)
                    .font(AISkinSkinReportTokens.body)
                    .foregroundStyle(AISkinColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(AISkinSpacing.xxSmall)
                    .accessibilityIdentifier("skin.report.detail.\(item.id)")
            }
        }
        .padding(.vertical, AISkinSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(item.title)
        .accessibilityIdentifier("skin.observation.\(item.id)")
    }
}

struct AISkinSkinReportComparison: View {
    let previousDate: String?
    let previousScore: Int?
    let currentDate: String?
    let currentScore: Int?
    let hasPrevious: Bool

    var body: some View {
        AISkinCard {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                if hasPrevious {
                    HStack(spacing: AISkinSpacing.small) {
                        point(date: previousDate, score: previousScore, title: "上次记录")
                        Image(systemName: "arrow.right").font(AISkinTypography.iconSmall).foregroundStyle(AISkinColor.textSecondary)
                        point(date: currentDate, score: currentScore, title: "本次记录")
                        if let previousScore, let currentScore {
                            Text(String(format: "%+d 分", currentScore - previousScore))
                                .font(AISkinSkinReportTokens.delta).foregroundStyle(AISkinColor.accent)
                        }
                    }
                    Text("拍摄光线、角度与护肤状态可能影响结果，请结合实际肤感对照。")
                        .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: AISkinSpacing.small) {
                        Image(systemName: "clock.arrow.circlepath").font(AISkinTypography.iconTitle).foregroundStyle(AISkinColor.accent)
                        Text("第一份肌肤记录").font(AISkinSkinReportTokens.title).foregroundStyle(AISkinColor.textPrimary)
                        Text("暂无上次评分，完成下一次检测后\n即可在这里查看分数变化。")
                            .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, AISkinSpacing.medium)
                }
            }
        }
    }

    private func point(date: String?, score: Int?, title: String) -> some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
            Text(date ?? "日期未记录").font(AISkinSkinReportTokens.footnote).foregroundStyle(AISkinColor.textSecondary)
            Text(score.map { "\($0)" } ?? "—").font(AISkinSkinReportTokens.comparisonScore).foregroundStyle(AISkinColor.textPrimary)
            Text(title).font(AISkinSkinReportTokens.meta).foregroundStyle(AISkinColor.textSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AISkinSkinReportFooter: View {
    let onRetake: () -> Void
    var onCreatePlan: (() -> Void)? = nil
    var body: some View {
        AISkinReportFooter {
          HStack(spacing: AISkinSpacing.small) {
            AISkinSkinReportAction(title: "重新检测", systemImage: "viewfinder", action: onRetake)
                .accessibilityIdentifier("skin.report.retake")
            if let onCreatePlan {
                AISkinButton(action: onCreatePlan) {
                    Text("创建护肤计划")
                }.accessibilityIdentifier("skin-analysis.customize-plan")
            }
          }
        }
    }
}

struct AISkinSkinConditionOption: View {
    let title: String
    let detail: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            AISkinCard(state: isSelected ? .selected : .normal) {
                HStack(spacing: AISkinSpacing.small) {
                    Image(systemName: systemImage)
                        .font(AISkinTypography.iconMedium).foregroundStyle(AISkinColor.accent)
                        .frame(width: AISkinSkinReportTokens.conditionIconSize, height: AISkinSkinReportTokens.conditionIconSize)
                        .background(AISkinColor.surfaceSelected, in: Circle())
                    VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                        Text(title).font(AISkinSkinReportTokens.title).foregroundStyle(AISkinColor.textPrimary)
                        Text(detail).font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: isSelected ? "checkmark.circle" : "circle")
                        .font(AISkinTypography.iconSmall).foregroundStyle(isSelected ? AISkinColor.accent : AISkinColor.divider)
                }.frame(minHeight: AISkinLayout.minimumTapHeight)
            }
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityIdentifier("skin.context.option.\(title)")
        .accessibilityValue(isSelected ? "已选择" : "未选择")
    }
}
