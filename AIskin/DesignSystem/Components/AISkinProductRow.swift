import SwiftUI

/// A product's text shares one column; the accessory's hit area never sets the title's height.
struct AISkinProductRow<Accessory: View>: View {
    let title: String
    let summary: String?
    let category: String?
    let imageURL: URL?
    let accessibilityIdentifier: String
    let accessibilityValue: String
    let onSelect: () -> Void
    @ViewBuilder let accessory: () -> Accessory

    @ScaledMetric(relativeTo: .callout)
    private var titleLineHeight = AISkinLayout.cabinetTitleLineHeight

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: AISkinSpacing.small) {
                VStack(spacing: AISkinSpacing.xxSmall) {
                    AISkinProductThumbnail(url: imageURL, size: .cabinet)
                    if let category, !category.isEmpty {
                        Text(category)
                            .font(AISkinTypography.caption)
                            .foregroundStyle(AISkinColor.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: AISkinLayout.productThumbnailCabinet)

                VStack(alignment: .leading, spacing: AISkinSpacing.cabinetTextGap) {
                    Text(title)
                        .font(AISkinTypography.productTitle)
                        .foregroundStyle(AISkinColor.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, minHeight: titleLineHeight, alignment: .leading)

                    if let summary, !summary.isEmpty {
                        Text(summary)
                            .font(AISkinTypography.caption)
                            .foregroundStyle(AISkinColor.textSecondary)
                            .lineSpacing(AISkinSpacing.xxxSmall)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, AISkinLayout.minimumTapHeight + AISkinSpacing.xSmall)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityValue(accessibilityValue)
        // A sibling of the main Button: opening its menu cannot trigger product navigation.
        .overlay(alignment: .topTrailing) {
            accessory()
                .alignmentGuide(.top) { dimensions in
                    (dimensions.height - titleLineHeight) / 2
                }
        }
        .padding(AISkinSpacing.cabinetCardPadding)
        .frame(minHeight: AISkinLayout.cabinetCardMinimumHeight)
    }
}
