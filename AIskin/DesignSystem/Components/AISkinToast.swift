import SwiftUI

enum AISkinToastStyle {
    case compact
    case centered(title: String)
}

struct AISkinToastAction {
    let title: String
    let perform: () -> Void
}

struct AISkinToast: View {
    let message: String
    var style: AISkinToastStyle = .compact
    var systemImage = "info.circle.fill"
    var dismissAccessibilityLabel = "关闭提示"
    var onDismiss: (() -> Void)? = nil
    var primaryAction: AISkinToastAction? = nil
    var secondaryAction: AISkinToastAction? = nil

    @ViewBuilder var body: some View {
        switch style {
        case .compact: compactToast
        case .centered(let title): centeredToast(title: title)
        }
    }

    private func centeredToast(title: String) -> some View {
        AISkinCard(role: .overlay) {
            VStack(spacing: AISkinSpacing.large) {
                if primaryAction != nil {
                    Image(systemName: systemImage)
                        .font(AISkinTypography.featureIcon)
                        .foregroundStyle(AISkinColor.accent)
                        .frame(width: AISkinLayout.noticeMinimumHeight, height: AISkinLayout.noticeMinimumHeight)
                        .background(AISkinColor.surfaceSelected, in: Circle())
                        .accessibilityHidden(true)
                }
                VStack(spacing: AISkinSpacing.xSmall) {
                    Text(title)
                        .font(AISkinTypography.toastTitle)
                        .foregroundStyle(AISkinColor.textPrimary)
                    Text(message)
                        .font(AISkinTypography.reportBody)
                        .foregroundStyle(AISkinColor.textSecondary)
                }
                if let primaryAction {
                    HStack(spacing: AISkinSpacing.xSmall) {
                        AISkinButton(action: primaryAction.perform) { Text(primaryAction.title) }
                            .accessibilityIdentifier("toast.primary-action")
                        if let secondaryAction {
                            AISkinButton(variant: .secondary, action: secondaryAction.perform) { Text(secondaryAction.title) }
                                .accessibilityIdentifier("toast.secondary-action")
                        }
                    }
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.top, primaryAction != nil || onDismiss == nil ? AISkinSpacing.small : AISkinSpacing.xxLarge)
            .padding(.bottom, AISkinSpacing.xSmall)
        }
        .overlay(alignment: .topTrailing) {
            if let onDismiss {
                AISkinIconButton(systemName: "xmark", accessibilityLabel: dismissAccessibilityLabel, action: onDismiss)
                    .padding(AISkinSpacing.xSmall)
            }
        }
        .frame(maxWidth: AISkinLayout.centeredToastMaxWidth)
        .aiSkinShadow(.card)
        .accessibilityElement(children: .contain)
    }

    private var compactToast: some View {
        HStack(spacing: AISkinSpacing.xSmall) {
            Image(systemName: systemImage)
                .font(AISkinTypography.iconControl)
                .foregroundStyle(AISkinColor.accent)
                .accessibilityHidden(true)

            Text(message)
                .font(AISkinTypography.callout)
                .foregroundStyle(AISkinColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let onDismiss {
                AISkinIconButton(
                    systemName: "xmark",
                    accessibilityLabel: dismissAccessibilityLabel,
                    action: onDismiss
                )
            }
        }
        .padding(.horizontal, AISkinSpacing.medium)
        .frame(minHeight: AISkinLayout.noticeMinimumHeight)
        .background(AISkinColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AISkinRadius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AISkinRadius.control, style: .continuous)
                .stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline)
        }
        .aiSkinShadow(.floating)
        .accessibilityElement(children: .contain)
    }
}

/// Shared modal presentation keeps the scrim and interaction boundary together.
struct AISkinModalOverlay<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AISkinColor.scrim
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }
                .accessibilityHidden(true)
            content
                .padding(AISkinSpacing.screenEdge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityAddTraits(.isModal)
    }
}

#Preview("Toast") {
    AISkinScreenBackground {
        VStack {
            Spacer()
            AISkinToast(
                message: "请选择 2 个产品进行冲突检测",
                systemImage: "checkmark.circle.fill"
            )
            .padding(AISkinSpacing.screenEdge)
            AISkinToast(
                message: "请选择 2 个产品进行冲突检测",
                systemImage: "checkmark.circle.fill",
                dismissAccessibilityLabel: "退出冲突检测",
                onDismiss: {}
            )
            .padding(AISkinSpacing.screenEdge)
        }
    }
}
