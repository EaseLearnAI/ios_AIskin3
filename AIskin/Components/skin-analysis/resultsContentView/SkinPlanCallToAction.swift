import SwiftUI

struct SkinPlanCallToAction: View {
    let action: () -> Void

    var body: some View {
        AISkinCard {
            VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                Label("AI 定制护肤", systemImage: "sparkles")
                    .font(AISkinSkinReportTokens.meta).foregroundStyle(AISkinColor.accent)
                Text("把肤况分析，变成每日护肤")
                    .font(AISkinSkinReportTokens.chapter).foregroundStyle(AISkinColor.textPrimary)
                Text("用护肤柜中已有的产品，结合肌肤检测结果，安排早晚护肤步骤。")
                    .font(AISkinSkinReportTokens.small).foregroundStyle(AISkinColor.textSecondary)
                AISkinButton(action: action) {
                    Text("定制我的护肤方案")
                }
                .accessibilityIdentifier("skin.overview.customize-plan")
                .padding(.top, AISkinSpacing.xxSmall)
            }
        }
    }
}
