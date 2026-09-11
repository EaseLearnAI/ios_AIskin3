import SwiftUI

/// One pass carries the membership identity and the primary customer benefit.
struct AISkinMembershipPass: View {
    let lead: String
    let title: String
    let summary: String
    let quota: String
    let onDetails: () -> Void

    var body: some View {
        AISkinCard(inset: .none, role: .feature) {
            VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                Text("析肤 · MEMBER")
                    .font(AISkinMembershipTokens.brand)
                    .tracking(AISkinMembershipTokens.brandTracking)
                    .foregroundStyle(AISkinColor.accent)

                Text(lead)
                    .font(AISkinMembershipTokens.lead)
                    .foregroundStyle(AISkinColor.textSecondary)
                    .padding(.top, AISkinMembershipTokens.passLeadTopInset)

                Text(title)
                    .font(AISkinMembershipTokens.passTitle)
                    .tracking(AISkinMembershipTokens.passTitleTracking)
                    .lineSpacing(AISkinMembershipTokens.passTitleLineSpacing)
                    .foregroundStyle(AISkinColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(summary)
                    .font(AISkinMembershipTokens.body)
                    .lineSpacing(AISkinMembershipTokens.bodyLineSpacing)
                    .foregroundStyle(AISkinColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AISkinMembershipTokens.passDescriptionTopInset)

                VStack(spacing: .zero) {
                    AISkinDivider()
                    Button(action: onDetails) {
                        HStack(spacing: AISkinSpacing.xSmall) {
                            Text(quota)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("查看检测内容")
                            Image(systemName: "chevron.right")
                                .font(AISkinTypography.iconCaption)
                                .accessibilityHidden(true)
                        }
                        .font(AISkinMembershipTokens.metadata)
                        .foregroundStyle(AISkinColor.accent)
                        .frame(minHeight: AISkinMembershipTokens.passDetailMinimumHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(AISkinPressableStyle())
                    .accessibilityLabel("查看冲突检测内容，\(quota)")
                    .accessibilityIdentifier("membership.conflict.details")
                }
                .padding(.top, AISkinMembershipTokens.passDetailTopInset)
            }
            .padding(.horizontal, AISkinMembershipTokens.passInset)
            .padding(.top, AISkinMembershipTokens.passInset)
            .padding(.bottom, AISkinMembershipTokens.passBottomInset)
            .background(alignment: .topTrailing) {
                decoration
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    private var decoration: some View {
        ZStack(alignment: .topTrailing) {
            ring.offset(x: AISkinMembershipTokens.outerDecorationX, y: AISkinMembershipTokens.outerDecorationY)
            ring.offset(x: AISkinMembershipTokens.innerDecorationX, y: AISkinMembershipTokens.innerDecorationY)
        }
    }

    private var ring: some View {
        Circle()
            .stroke(AISkinColor.accent.opacity(AISkinMembershipTokens.decorationOpacity), lineWidth: AISkinLayout.hairline)
            .frame(width: AISkinMembershipTokens.decorationDiameter, height: AISkinMembershipTokens.decorationDiameter)
    }
}

struct AISkinMembershipBenefitRow: View {
    let systemImage: String
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Button(action: action) {
                HStack(spacing: AISkinSpacing.small) {
                    Image(systemName: systemImage)
                        .font(AISkinMembershipTokens.benefitIcon)
                        .foregroundStyle(AISkinColor.accent)
                        .frame(width: AISkinMembershipTokens.benefitIconSize, height: AISkinMembershipTokens.benefitIconSize)
                        .background(AISkinColor.surfaceSelected, in: RoundedRectangle(cornerRadius: AISkinRadius.medium, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AISkinSpacing.xxSmall) {
                        Text(title)
                            .font(AISkinMembershipTokens.benefitTitle)
                            .foregroundStyle(AISkinColor.textPrimary)
                        Text(detail)
                            .font(AISkinMembershipTokens.metadata)
                            .foregroundStyle(AISkinColor.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(AISkinTypography.iconChevron)
                        .foregroundStyle(AISkinColor.textPrimary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, AISkinMembershipTokens.benefitVerticalInset)
                .frame(minHeight: AISkinLayout.minimumTapHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(AISkinPressableStyle())
            .accessibilityElement(children: .combine)
            AISkinDivider()
        }
    }
}

struct AISkinMembershipPlanOption: View {
    let title: String
    let price: String
    let unit: String
    let note: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AISkinCard(inset: .none, state: isSelected ? .selected : .normal, role: .action) {
                VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
                    HStack(alignment: .top, spacing: AISkinSpacing.xSmall) {
                        Text(title)
                            .font(AISkinMembershipTokens.planTitle)
                            .foregroundStyle(AISkinColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                            .font(AISkinMembershipTokens.planSelectionIcon)
                            .foregroundStyle(isSelected ? AISkinColor.accent : AISkinColor.textSecondary)
                            .frame(width: AISkinMembershipTokens.planSelectionSize, height: AISkinMembershipTokens.planSelectionSize)
                            .accessibilityHidden(true)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: AISkinSpacing.xxSmall) {
                        Text(price)
                            .font(AISkinMembershipTokens.price)
                        Text(unit)
                            .font(AISkinMembershipTokens.priceUnit)
                    }
                    .foregroundStyle(AISkinColor.textPrimary)
                    Text(note)
                        .font(AISkinMembershipTokens.metadata)
                        .foregroundStyle(AISkinColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AISkinMembershipTokens.planInset)
                .frame(maxWidth: .infinity, minHeight: AISkinMembershipTokens.planMinimumHeight, alignment: .topLeading)
            }
        }
        .buttonStyle(AISkinPressableStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(price)\(unit)，\(note)")
        .accessibilityValue(isSelected ? "已选中" : "未选中")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The purchase action and the only billing/status notice share a fixed footer.
struct AISkinMembershipFooter: View {
    let actionTitle: String
    let notice: String
    var isLoading = false
    var isPurchaseEnabled = true
    var continueTitle = "继续免费使用"
    var restoreTitle = "恢复购买"
    let onSubscribe: () -> Void
    let onContinue: () -> Void
    let onRestore: () -> Void
    let onTerms: () -> Void
    let onPrivacy: () -> Void

    var body: some View {
        VStack(spacing: AISkinSpacing.xSmall) {
            AISkinButton(isLoading: isLoading, action: onSubscribe) {
                Text(actionTitle)
                    .padding(.vertical, AISkinSpacing.xxSmall)
            }
            .disabled(!isPurchaseEnabled)
            .accessibilityIdentifier("membership.subscribe")

            Text(notice)
                .font(AISkinMembershipTokens.footerNotice)
                .lineSpacing(AISkinMembershipTokens.footerNoticeLineSpacing)
                .foregroundStyle(AISkinColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AISkinSpacing.small) {
                    continueLink
                    restoreLink
                    termsLink
                    privacyLink
                }
                VStack(spacing: .zero) {
                    HStack(spacing: AISkinSpacing.medium) {
                        continueLink
                        restoreLink
                    }
                    HStack(spacing: AISkinSpacing.medium) {
                        termsLink
                        privacyLink
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AISkinSpacing.screenEdge)
        .padding(.top, AISkinSpacing.small)
        .padding(.bottom, AISkinSpacing.xxSmall)
        .background(AISkinColor.sheetSurface)
        .overlay(alignment: .top) { AISkinDivider() }
    }

    private var continueLink: some View { footerLink(continueTitle, identifier: "membership.continue", isExit: true, action: onContinue) }
    private var restoreLink: some View { footerLink(restoreTitle, identifier: "membership.restore", action: onRestore).disabled(isLoading) }
    private var termsLink: some View { footerLink("条款", identifier: "membership.terms", action: onTerms) }
    private var privacyLink: some View { footerLink("隐私", identifier: "membership.privacy", action: onPrivacy) }

    private func footerLink(_ title: String, identifier: String, isExit: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AISkinMembershipTokens.footerLink)
                .fixedSize(horizontal: true, vertical: false)
        }
            .foregroundStyle(AISkinColor.textSecondary)
            .frame(minWidth: isExit ? AISkinMembershipTokens.continueLinkWidth : AISkinLayout.minimumTapHeight, minHeight: AISkinLayout.minimumTapHeight)
            .buttonStyle(AISkinPressableStyle())
            .accessibilityIdentifier(identifier)
    }
}

struct AISkinMembershipDetail: View {
    let title: String
    private let detailBody: String

    init(title: String, body: String) {
        self.title = title
        self.detailBody = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AISkinSpacing.xSmall) {
            Text(title)
                .font(AISkinMembershipTokens.detailTitle)
                .foregroundStyle(AISkinColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(detailBody)
                .font(AISkinMembershipTokens.detailBody)
                .lineSpacing(AISkinMembershipTokens.bodyLineSpacing)
                .foregroundStyle(AISkinColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AISkinSpacing.xSmall)
    }
}
