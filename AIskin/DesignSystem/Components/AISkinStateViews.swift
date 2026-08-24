import SwiftUI

struct AISkinLoadingView: View {
    var message = "正在加载…"

    var body: some View {
        VStack(spacing: AISkinSpacing.small) {
            ProgressView()
                .tint(AISkinColor.brand)
            Text(message)
                .font(AISkinTypography.callout)
                .foregroundStyle(AISkinColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AISkinSpacing.xLarge)
        .accessibilityElement(children: .combine)
    }
}

struct AISkinEmptyStateView: View {
    let title: String
    let message: String
    var systemImage = "tray"
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        AISkinStateView(
            title: title,
            message: message,
            systemImage: systemImage,
            actionTitle: actionTitle,
            action: action
        )
    }
}

struct AISkinErrorStateView: View {
    var title = "加载失败"
    let message: String
    var retryTitle = "重试"
    let onRetry: () -> Void

    var body: some View {
        AISkinStateView(
            title: title,
            message: message,
            systemImage: "exclamationmark.triangle",
            actionTitle: retryTitle,
            action: onRetry
        )
    }
}

struct AISkinRetryButton: View {
    var title = "重试"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "arrow.clockwise")
        }
        .buttonStyle(AISkinSecondaryButtonStyle())
    }
}

private struct AISkinStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: AISkinSpacing.small) {
            Image(systemName: systemImage)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(AISkinColor.brand)
                .accessibilityHidden(true)
            Text(title)
                .font(AISkinTypography.cardTitle)
                .foregroundStyle(AISkinColor.textPrimary)
            Text(message)
                .font(AISkinTypography.body)
                .foregroundStyle(AISkinColor.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(AISkinSecondaryButtonStyle())
                    .padding(.top, AISkinSpacing.xxSmall)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AISkinSpacing.xLarge)
    }
}

#Preview("Shared states") {
    AISkinScreenBackground {
        ScrollView {
            VStack(spacing: AISkinSpacing.medium) {
                AISkinCard { AISkinLoadingView() }
                AISkinCard {
                    AISkinEmptyStateView(
                        title: "还没有产品",
                        message: "添加护肤品后即可开始分析",
                        actionTitle: "添加产品",
                        action: {}
                    )
                }
                AISkinCard {
                    AISkinErrorStateView(message: "网络似乎开小差了", onRetry: {})
                }
            }
            .padding()
        }
    }
}
