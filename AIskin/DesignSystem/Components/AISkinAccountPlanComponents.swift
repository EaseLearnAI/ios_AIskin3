import SwiftUI

/// Profile cover and lower translucent panel are a single shared structure.
struct AISkinProfilePanel<Content: View>: View {
    var minimumHeight: CGFloat = 0
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: AISkinAccountPlanTokens.profileCoverHeight)
            content
                .padding(.horizontal, AISkinSpacing.screenEdge)
                .padding(.bottom, AISkinSpacing.xxLarge)
                .frame(maxWidth: .infinity, minHeight: max(0, minimumHeight - AISkinAccountPlanTokens.profileCoverHeight), alignment: .topLeading)
                .background(AISkinColor.surface, in: UnevenRoundedRectangle(topLeadingRadius: AISkinAccountPlanTokens.profilePanelRadius, topTrailingRadius: AISkinAccountPlanTokens.profilePanelRadius))
        }
    }
}

struct AISkinProfileIdentity: View {
    let name: String
    let avatarURL: URL?
    var onUpgrade: (() -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.medium) {
            AsyncImage(url: avatarURL) { image in image.resizable().scaledToFill() } placeholder: {
                Image(systemName: "person").font(AISkinAccountPlanTokens.avatarIcon)
                    .foregroundStyle(AISkinColor.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: AISkinAccountPlanTokens.avatarSize, height: AISkinAccountPlanTokens.avatarSize)
            .background(AISkinColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AISkinAccountPlanTokens.avatarRadius))
            .overlay { RoundedRectangle(cornerRadius: AISkinAccountPlanTokens.avatarRadius).stroke(AISkinColor.surface, lineWidth: AISkinAccountPlanTokens.avatarBorder) }
            .aiSkinShadow()
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                HStack(alignment: .center, spacing: AISkinSpacing.medium) {
                    HStack(spacing: AISkinSpacing.xxSmall) {
                        Text(name).font(AISkinAccountPlanTokens.profileName).foregroundStyle(AISkinColor.textPrimary)
                            .lineLimit(1).truncationMode(.tail)
                        if let onUpgrade {
                            AISkinIconButton(systemName: "seal", accessibilityLabel: "了解会员权益", variant: .plain, action: onUpgrade)
                                .accessibilityIdentifier("profile.membership-badge")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let onUpgrade {
                        AISkinButton(variant: .surface, layout: .compact, action: onUpgrade) {
                            Text("升级")
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityHint("查看析肤会员权益")
                        .accessibilityIdentifier("profile.upgrade")
                    }
                }
                Text("每一次护肤，都有迹可循").font(AISkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
            }
        }
        .padding(.top, -AISkinAccountPlanTokens.avatarOverlap)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AISkinSettingsRow: View {
    var systemImage: String? = nil
    let title: String
    var value: String? = nil
    var isDestructive = false
    var showsChevron = true
    var body: some View {
        HStack(spacing: AISkinSpacing.small) {
            if let systemImage {
                Image(systemName: systemImage).font(AISkinTypography.iconMedium)
                    .foregroundStyle(isDestructive ? AISkinColor.destructive : AISkinColor.textSecondary)
                    .frame(width: AISkinAccountPlanTokens.settingsIconWidth)
            }
            Text(title).font(AISkinAccountPlanTokens.rowTitle)
                .foregroundStyle(isDestructive ? AISkinColor.destructive : AISkinColor.textPrimary)
            Spacer(minLength: AISkinSpacing.small)
            if let value { Text(value).font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.textSecondary) }
            if showsChevron { Image(systemName: "chevron.right").font(AISkinTypography.iconCaption).foregroundStyle(AISkinColor.textSecondary) }
        }
        .padding(.horizontal, AISkinSpacing.medium)
        .frame(minHeight: AISkinAccountPlanTokens.settingsHeight)
        .contentShape(Rectangle())
    }
}

struct AISkinPlanSourceRow: View {
    let title: String
    let detail: String
    let actionTitle: String
    let action: () -> Void
    var body: some View {
        AISkinCard(inset: .none) {
          HStack(spacing: AISkinSpacing.small) {
            Image(systemName: "faceid").font(AISkinTypography.iconMedium).foregroundStyle(AISkinColor.accent)
            VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                Text(title).font(AISkinAccountPlanTokens.fieldTitle).foregroundStyle(AISkinColor.textPrimary)
                Text(detail).font(AISkinAccountPlanTokens.planCopy).foregroundStyle(AISkinColor.textSecondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
            Button(actionTitle, action: action).font(AISkinAccountPlanTokens.fieldTitle).foregroundStyle(AISkinColor.accent)
                .frame(minWidth: AISkinLayout.minimumTapHeight, minHeight: AISkinLayout.minimumTapHeight)
          }
          .padding(.horizontal, AISkinSpacing.medium)
          .padding(.vertical, AISkinSpacing.xSmall)
        }
    }
}

struct AISkinPlanRoutineRow: View {
    let number: Int
    let title: String
    let detail: String?
    var body: some View {
        HStack(alignment: .top, spacing: AISkinSpacing.small) {
            Text(String(format: "%02d", number)).font(AISkinReportTokens.metadata).foregroundStyle(AISkinColor.accent)
                .frame(width: AISkinLayout.stepIndicatorDiameter, height: AISkinLayout.stepIndicatorDiameter)
                .background(AISkinColor.surface, in: Circle())
                .overlay { Circle().stroke(AISkinColor.border, lineWidth: AISkinLayout.hairline) }
            VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                Text(title).font(AISkinAccountPlanTokens.fieldTitle).foregroundStyle(AISkinColor.textPrimary)
                if let detail, !detail.isEmpty {
                    Text(detail).font(AISkinReportTokens.body).foregroundStyle(AISkinColor.textSecondary)
                        .lineSpacing(AISkinReportTokens.bodyLineSpacing)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.vertical, AISkinSpacing.medium)
    }
}
