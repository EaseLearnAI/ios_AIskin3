import SwiftUI

enum AISkinStateContent {
    case loading(message: String)
    case processing(title: String, message: String)
    case empty(title: String, message: String, systemImage: String)
    case error(title: String, message: String)
}

struct AISkinStateView: View {
    enum Layout { case standard, inline }
    let content: AISkinStateContent
    var actionTitle: String?
    var action: (() -> Void)?
    var layout: Layout = .standard

    var body: some View {
      if layout == .inline {
        HStack(alignment: .top, spacing: AISkinSpacing.xSmall) {
            Image(systemName: "exclamationmark.circle")
            switch content {
            case .error(_, let message), .loading(let message), .empty(_, let message, _), .processing(_, let message):
                Text(message).fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(AISkinTypography.caption)
        .foregroundStyle(AISkinColor.destructive)
        .accessibilityElement(children: .combine)
      } else {
        VStack(spacing: AISkinSpacing.small) {
            visual
            copy

            if let actionTitle, let action {
                AISkinButton(variant: .secondary, action: action) {
                    Text(actionTitle)
                }
                .padding(.top, AISkinSpacing.xxSmall)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AISkinSpacing.xLarge)
        .accessibilityElement(children: .combine)
      }
    }

    @ViewBuilder
    private var visual: some View {
        switch content {
        case .loading, .processing:
            ProgressView().tint(AISkinColor.accent)
        case .empty(_, _, let systemImage):
            Image(systemName: systemImage)
                .font(AISkinTypography.iconState)
                .foregroundStyle(AISkinColor.accent)
        case .error:
            Image(systemName: "exclamationmark.triangle")
                .font(AISkinTypography.iconState)
                .foregroundStyle(AISkinColor.destructive)
        }
    }

    @ViewBuilder
    private var copy: some View {
        switch content {
        case .loading(let message):
            Text(message)
                .font(AISkinTypography.callout)
                .foregroundStyle(AISkinColor.textSecondary)
        case .processing(let title, let message), .empty(let title, let message, _), .error(let title, let message):
            Text(title)
                .font(AISkinTypography.cardTitle)
                .foregroundStyle(AISkinColor.textPrimary)
            Text(message)
                .font(AISkinTypography.body)
                .foregroundStyle(AISkinColor.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Shared states") {
    AISkinScreenBackground {
        AISkinCard {
            AISkinStateView(
                content: .empty(
                    title: "还没有产品",
                    message: "添加护肤品后即可开始分析",
                    systemImage: "shippingbox"
                ),
                actionTitle: "添加产品",
                action: {}
            )
        }
        .padding()
    }
}
