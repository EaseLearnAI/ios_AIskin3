import SwiftUI

/// Membership presentation values. Content and purchase state stay in the feature.
enum AISkinMembershipTokens {
    static let brand = Font.system(size: 12, weight: .medium)
    static let brandTracking: CGFloat = 3
    static let passTitle = Font.system(size: 28, weight: .semibold)
    static let passTitleTracking: CGFloat = -0.5
    static let passTitleLineSpacing: CGFloat = 5
    static let lead = Font.system(size: 12, weight: .medium)
    static let body = Font.system(size: 13)
    static let bodyLineSpacing: CGFloat = 5
    static let metadata = Font.system(size: 12)
    static let benefitTitle = Font.system(size: 14, weight: .semibold)
    static let planTitle = Font.system(size: 14)
    static let price = Font.system(size: 27, weight: .semibold)
    static let priceUnit = Font.system(size: 12)
    static let footerNotice = Font.system(size: 11)
    static let footerLink = Font.system(size: 12)
    static let continueLinkWidth: CGFloat = 96
    static let footerNoticeLineSpacing: CGFloat = 3
    static let detailTitle = Font.system(size: 16, weight: .semibold)
    static let detailBody = Font.system(size: 14)
    static let passInset: CGFloat = 22
    static let passBottomInset = AISkinSpacing.xxSmall
    static let passLeadTopInset = AISkinSpacing.large
    static let passDescriptionTopInset = AISkinSpacing.small
    static let passDetailTopInset = AISkinSpacing.medium
    static let passDetailMinimumHeight: CGFloat = 48
    static let benefitIconSize: CGFloat = 38
    static let benefitIcon = Font.system(size: 21, weight: .regular)
    static let benefitVerticalInset = AISkinSpacing.medium
    static let planMinimumHeight: CGFloat = 112
    static let planInset = AISkinSpacing.small
    static let planSelectionSize: CGFloat = 17
    static let planSelectionIcon = Font.system(size: 17, weight: .regular)
    static let decorationDiameter: CGFloat = 165
    static let outerDecorationX: CGFloat = 55
    static let outerDecorationY: CGFloat = -48
    static let innerDecorationX: CGFloat = 25
    static let innerDecorationY: CGFloat = -17
    static let decorationOpacity: Double = 0.15
}
