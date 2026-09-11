import SwiftUI

struct MainTabHeader: View {
    let title: String
    let onProfileTap: () -> Void
    var trailingSystemImage: String? = nil
    var trailingAccessibilityLabel: String? = nil
    var onTrailingTap: (() -> Void)? = nil

    var body: some View {
        AISkinHeader {
            AISkinIconButton(
                systemName: "person.crop.circle.fill",
                accessibilityLabel: "我的",
                variant: .surface,
                action: onProfileTap
            )
            .accessibilityHint("打开个人中心")
            .accessibilityIdentifier("app.header.profile")
        } title: {
            Text(title)
                .font(AISkinTypography.screenTitle)
                .foregroundStyle(AISkinColor.textPrimary)
                .lineLimit(1)
        } trailing: {
            if let trailingSystemImage,
               let trailingAccessibilityLabel,
               let onTrailingTap {
                AISkinIconButton(
                    systemName: trailingSystemImage,
                    accessibilityLabel: trailingAccessibilityLabel,
                    variant: .surface,
                    action: onTrailingTap
                )
                .accessibilityHint(trailingAccessibilityLabel)
                .accessibilityIdentifier(trailingSystemImage == "plus" ? "app.header.add-product" : "app.header.skin-history")
            } else {
                Color.clear.accessibilityHidden(true)
            }
        }
        .lookinName("shared.main-tab-header.\(title)")
    }
}

struct AppHeader: View {
    var title: String
    var subtitle: String? = nil
    var layout: AISkinHeaderLayout = .centered
    var icon: String? = nil
    var rightIcon: String? = nil
    var rightAction: (() -> Void)? = nil
    var rightAccessibilityLabel: String? = nil
    var backAction: (() -> Void)? = nil

    var body: some View {
        AISkinHeader(layout: layout) {
            if let backAction {
                AISkinIconButton(
                    systemName: "chevron.left",
                    accessibilityLabel: "返回",
                    variant: layout == .leadingTitleSubtitle ? .plain : .navigation,
                    action: backAction
                )
            } else {
                Color.clear.accessibilityHidden(true)
            }
        } title: {
            VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
             HStack(spacing: AISkinSpacing.xSmall) {
                if let icon {
                    Image(systemName: icon)
                        .font(AISkinTypography.iconControl)
                        .foregroundStyle(AISkinColor.accent)
                }

                Text(title)
                    .font(AISkinTypography.screenTitle)
                    .foregroundStyle(AISkinColor.textPrimary)
                    .lineLimit(1)
             }
             if let subtitle {
                 Text(subtitle).font(AISkinTypography.caption).foregroundStyle(AISkinColor.textSecondary)
             }
            }
        } trailing: {
            if let rightIcon, let rightAction {
                AISkinIconButton(
                    systemName: rightIcon,
                    accessibilityLabel: rightAccessibilityLabel ?? title,
                    variant: .surface,
                    action: rightAction
                )
                .accessibilityIdentifier("app.header.\(rightIcon)")
            } else {
                Color.clear.accessibilityHidden(true)
            }
        }
        .lookinName("shared.header.\(title)")
    }
}
