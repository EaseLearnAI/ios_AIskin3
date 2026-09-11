import SwiftUI

/// A feature entry shares the standard card surface and press states.
struct AISkinActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AISkinCard(role: .feature) {
                VStack(alignment: .leading, spacing: AISkinSpacing.small) {
                    HStack {
                        Image(systemName: systemImage)
                            .font(AISkinTypography.featureIcon)
                            .foregroundStyle(AISkinColor.accent)
                            .frame(width: AISkinLayout.actionIconDiameter, height: AISkinLayout.actionIconDiameter)
                            .background(AISkinColor.surfaceElevated, in: Circle())
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(AISkinTypography.iconCaption)
                            .foregroundStyle(AISkinColor.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                        Text(title).font(AISkinTypography.featureTitle).foregroundStyle(AISkinColor.textPrimary)
                        Text(subtitle).font(AISkinTypography.featureSubtitle).foregroundStyle(AISkinColor.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, minHeight: AISkinLayout.actionTileHeight, alignment: .leading)
            }
        }
        .buttonStyle(AISkinPressableStyle())
    }
}
