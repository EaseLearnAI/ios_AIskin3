import SwiftUI

struct AISkinSummaryMetric {
    let title: String
    let value: String
    let level: Int
}

/// One summary surface shared by the dashboard and the independent report.
struct AISkinSkinSummaryCard: View {
    let score: Int?
    let skinType: String
    let condition: String
    let metrics: [AISkinSummaryMetric]
    let conclusion: String
    var onScoreInfo: (() -> Void)? = nil

    var body: some View {
        AISkinCard(inset: .none) {
            VStack(spacing: 0) {
                HStack(spacing: AISkinSpacing.small) {
                    Text(skinType).font(AISkinSkinReportTokens.title).foregroundStyle(AISkinColor.textPrimary)
                    Spacer(minLength: 0)
                    AISkinTag(title: condition, tone: .neutral)
                }
                .padding(.horizontal, AISkinSkinReportTokens.summaryHorizontal)
                .padding(.top, AISkinSpacing.small)
                HStack(spacing: AISkinSkinReportTokens.summaryGap) {
                    if let onScoreInfo {
                        Button(action: onScoreInfo) { scoreRing }
                            .buttonStyle(AISkinPressableStyle())
                            .accessibilityLabel(scoreDescription)
                            .accessibilityHint("查看评分说明")
                            .accessibilityIdentifier("skin.summary.score-info")
                    } else {
                        scoreRing
                            .accessibilityLabel(scoreDescription)
                            .accessibilityAddTraits(.isStaticText)
                            .accessibilityIdentifier("skin.summary.score")
                    }
                    metricList
                }
                .padding(.horizontal, AISkinSpacing.large)
                .padding(.top, AISkinSpacing.small)
                .padding(.bottom, AISkinSkinReportTokens.summaryBottom)
                AISkinDivider()
                VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                    Label("本次结论", systemImage: "sparkles")
                        .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.accent)
                    Text(conclusion.isEmpty ? "该次记录暂无结论" : conclusion)
                        .font(AISkinSkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                        .lineSpacing(AISkinSpacing.xxSmall)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AISkinSkinReportTokens.summaryHorizontal)
                .padding(.vertical, AISkinSpacing.medium)
            }
        }
    }

    private var scoreRing: some View {
        ZStack {
            Circle().stroke(AISkinColor.surfaceSelected, lineWidth: AISkinSkinReportTokens.ringStroke)
            Circle().trim(from: 0, to: CGFloat(min(100, max(0, score ?? 0))) / 100)
                .stroke(AISkinColor.accent, style: StrokeStyle(lineWidth: AISkinSkinReportTokens.ringStroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: AISkinSpacing.xSmall) {
                Text(score.map(String.init) ?? "—")
                    .font(AISkinSkinReportTokens.score).foregroundStyle(AISkinColor.textPrimary).monospacedDigit()
                Text(onScoreInfo == nil ? "综合评分" : "综合评分 ⓘ").font(AISkinSkinReportTokens.footnote).foregroundStyle(AISkinColor.textSecondary)
            }
        }
        .padding(AISkinSkinReportTokens.ringStroke)
        .frame(width: AISkinSkinReportTokens.ringDiameter, height: AISkinSkinReportTokens.ringDiameter)
        .accessibilityElement(children: .ignore)
    }

    private var scoreDescription: String {
        score.map { "综合评分，\($0) 分，满分 100 分" } ?? "未提供综合评分"
    }

    private var metricList: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.small) {
            ForEach(Array(metrics.prefix(3).enumerated()), id: \.offset) { _, metric in
                VStack(spacing: AISkinSpacing.xxSmall) {
                    HStack(spacing: AISkinSpacing.xSmall) {
                        Text(metric.title).font(AISkinSkinReportTokens.label).foregroundStyle(AISkinColor.textPrimary)
                        Spacer(minLength: 0)
                        Text(metric.value).font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.accent)
                    }
                    HStack(spacing: AISkinSkinReportTokens.metricGap) {
                        ForEach(1...5, id: \.self) { index in
                            Capsule().fill(index <= metric.level ? AISkinSkinReportTokens.metricFill : AISkinColor.surfaceSelected)
                                .frame(height: AISkinSkinReportTokens.metricHeight)
                        }
                    }.accessibilityHidden(true)
                }.accessibilityElement(children: .combine)
            }
            if metrics.isEmpty {
                Text("该次记录未保存问题明细").font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary)
            }
        }.frame(maxWidth: .infinity)
    }
}
