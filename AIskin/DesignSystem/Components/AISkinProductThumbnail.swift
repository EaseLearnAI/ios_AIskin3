import SwiftUI

enum AISkinProductThumbnailSize {
    case compact, detail, cabinet, report

    fileprivate var dimension: CGFloat {
        switch self {
        case .compact: AISkinLayout.productThumbnailCompact
        case .detail: AISkinLayout.productThumbnailDetail
        case .cabinet: AISkinLayout.productThumbnailCabinet
        case .report: AISkinReportTokens.thumbnailWidth
        }
    }
}

struct AISkinProductThumbnail: View {
    let url: URL?
    var label: String? = nil
    var size: AISkinProductThumbnailSize = .compact

    private var cornerRadius: CGFloat {
        switch size {
        case .report: AISkinReportTokens.thumbnailRadius
        case .cabinet: AISkinRadius.medium
        default: AISkinRadius.control
        }
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
                    .accessibilityLabel("产品照片")
                    .accessibilityIdentifier(size == .report ? "ingredient.report.photo" : "")
            case .empty where url != nil:
                ProgressView().tint(AISkinColor.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty, .failure:
                VStack(spacing: AISkinSpacing.xxSmall) {
                    Image(systemName: size == .report ? "drop" : "shippingbox")
                        .font(size == .report ? AISkinReportTokens.thumbnailIcon : AISkinTypography.iconTitle)
                    if size != .report, let label, !label.isEmpty {
                        Text(label).font(AISkinTypography.caption).lineLimit(1)
                    }
                }
                .foregroundStyle(AISkinColor.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            @unknown default:
                Image(systemName: "photo").foregroundStyle(AISkinColor.textSecondary)
            }
        }
        .frame(width: size.dimension, height: size == .report ? AISkinReportTokens.thumbnailHeight : size.dimension)
        .background(size == .report ? AISkinColor.surface : AISkinColor.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            if size == .report {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
            }
        }
        .accessibilityHidden(size != .report)
    }
}
