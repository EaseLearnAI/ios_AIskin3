import SwiftUI

struct AIRecommendations: View {
    let recommendations: [String]

    var body: some View {
        AISkinCard(inset: .none) {
            VStack(alignment: .leading, spacing: 0) {
                if recommendations.isEmpty {
                    Text("该次记录未提供护肤建议。")
                        .font(AISkinSkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                        .padding(AISkinSpacing.large)
                } else {
                    ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                        if index > 0 { AISkinDivider() }
                        VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                            Text("建议 \(index + 1)").font(AISkinSkinReportTokens.title).foregroundStyle(AISkinColor.textPrimary)
                            Text(recommendation).font(AISkinSkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(AISkinSpacing.xxSmall)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, AISkinSkinReportTokens.summaryBottom)
                    }
                }
            }
            .padding(.horizontal, AISkinSkinReportTokens.summaryHorizontal)
        }
    }
}
