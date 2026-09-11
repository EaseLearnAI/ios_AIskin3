import SwiftUI

struct SkinDetectionWelcome: View {
    let onTakePhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: AISkinSpacing.large)
            VStack(alignment: .leading, spacing: AISkinSkinReportTokens.emptyCopyGap) {
                VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                    Text("一张照片，").font(AISkinSkinReportTokens.emptyTitle).foregroundStyle(AISkinColor.textPrimary)
                    Text("了解你的肌肤。").font(AISkinSkinReportTokens.emptyEmphasis).foregroundStyle(AISkinColor.accent)
                }
                Text("拍摄清晰的正面照片，\n查看肤况分析与护肤建议。")
                    .font(AISkinSkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                    .lineSpacing(AISkinSpacing.xSmall)
            }
            .padding(.bottom, AISkinSkinReportTokens.emptyBottomSpace)
            Spacer(minLength: AISkinSpacing.large)
            AISkinButton(action: onTakePhoto) {
                Label("开始肌肤检测", systemImage: "camera")
            }
            .accessibilityIdentifier("skin.capture.start")
            Text("自然光　·　无遮挡　·　无美颜")
                .font(AISkinSkinReportTokens.meta).foregroundStyle(AISkinColor.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, AISkinSpacing.medium)
        }
        .frame(maxWidth: .infinity, minHeight: AISkinSkinReportTokens.emptyMinimumHeight, alignment: .leading)
        .padding(.horizontal, AISkinSpacing.xSmall)
        .padding(.bottom, AISkinSpacing.xLarge)
    }
}
